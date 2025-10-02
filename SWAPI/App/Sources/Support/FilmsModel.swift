import Foundation
import Observation
import Persistence
import os.log

@MainActor
@Observable
final class FilmsModel {
  typealias Film = PersistenceCoordinator.Film

  @ObservationIgnored
  private let coordinator: PersistenceCoordinator
  @ObservationIgnored
  private var observationTask: Task<Void, Never>?
  @ObservationIgnored
  private var refreshTask: Task<[Film], Error>?
  @ObservationIgnored
  private var selectionChangeHandler: (@MainActor (Film?) -> Void)?

  var films: [Film] = []
  var selectedFilm: Film?
  var isLoading = false
  var hasLoadedInitialData = false
  var error: Error?

  init(coordinator: PersistenceCoordinator) {
    self.coordinator = coordinator
  }

  deinit {
    observationTask?.cancel()
    refreshTask?.cancel()
  }

  func onSelectionChange(_ handler: @escaping @MainActor (Film?) -> Void) {
    selectionChangeHandler = handler
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
    guard selectedFilm != film else { return }
    selectedFilm = film
    selectionChangeHandler?(film)
  }
}

extension FilmsModel {
  fileprivate func applyLoadedFilms(_ newFilms: [Film]) {
    let currentSelectionID = selectedFilm?.id
    let previousSelection = selectedFilm
    films = newFilms

    let newSelection: Film?

    if let currentSelectionID,
      let matchingFilm = newFilms.first(where: { $0.id == currentSelectionID })
    {
      newSelection = matchingFilm
    } else {
      newSelection = newFilms.first
    }

    selectedFilm = newSelection
    if previousSelection != newSelection {
      selectionChangeHandler?(newSelection)
    }
  }

  fileprivate func startObservingChangesIfNeeded() {
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
