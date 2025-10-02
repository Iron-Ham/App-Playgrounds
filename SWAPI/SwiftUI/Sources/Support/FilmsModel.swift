import FluentPersistence
import Foundation
import os.log
import SwiftUI

@MainActor
final class FilmsModel: ObservableObject {
  typealias Film = PersistenceCoordinator.Film

  private let coordinator: PersistenceCoordinator
  private var observationTask: Task<Void, Never>?
  private var refreshTask: Task<[Film], Error>?

  @Published var films: [Film] = []
  @Published var selectedFilm: Film?
  @Published var isLoading = false
  @Published var hasLoadedInitialData = false
  @Published var error: Error?

  init(coordinator: PersistenceCoordinator) {
    self.coordinator = coordinator
  }

  deinit {
    observationTask?.cancel()
    refreshTask?.cancel()
  }

  func loadInitialIfNeeded() async {
    guard !hasLoadedInitialData else { return }
    await refresh(force: false)
  }

  func refresh(force: Bool) async {
    if let refreshTask {
      if force {
        refreshTask.cancel()
        self.refreshTask = nil
      } else {
        do {
          _ = try await refreshTask.value
          return
        } catch {
          // Let the force branch below retry.
        }
      }
    }

    isLoading = true

    let task = Task<[Film], Error> {
      try await self.coordinator.loadFilms(force: force)
    }

    refreshTask = task

    do {
      let films = try await task.value
      applyLoadedFilms(films)
      error = nil
      hasLoadedInitialData = true
      startObservingChangesIfNeeded()
    } catch is CancellationError {
      // Ignore cancellation and allow the caller to retry.
    } catch {
      self.error = error
    }

    refreshTask = nil
    isLoading = false
  }

  func updateSelection(_ film: Film?) {
    selectedFilm = film
  }
}

private extension FilmsModel {
  func applyLoadedFilms(_ newFilms: [Film]) {
    let currentSelectionID = selectedFilm?.id
    films = newFilms

    if let currentSelectionID,
      let matchingFilm = newFilms.first(where: { $0.id == currentSelectionID })
    {
      selectedFilm = matchingFilm
    } else {
      selectedFilm = newFilms.first
    }
  }

  func startObservingChangesIfNeeded() {
    guard observationTask == nil else { return }

    observationTask = Task { [weak self] in
      guard let self else { return }

      do {
        while !Task.isCancelled {
          let stream = try await coordinator.observeChanges()
          for await _ in stream {
            guard !Task.isCancelled else { return }
            await self.refresh(force: true)
          }
        }
      } catch {
        await MainActor.run {
          self.error = error
        }
      }
    }
  }
}
