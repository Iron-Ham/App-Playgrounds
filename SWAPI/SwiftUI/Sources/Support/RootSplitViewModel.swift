import SwiftUI

@MainActor
final class RootSplitViewModel: ObservableObject {
  private let coordinator: PersistenceCoordinator

  @Published var films: [Film] = []
  @Published var selectedFilm: Film?
  @Published var isLoading = false
  @Published var hasLoadedInitialData = false
  @Published var error: Error?

  init(coordinator: PersistenceCoordinator) {
    self.coordinator = coordinator
  }

  func loadInitialIfNeeded() async {
    guard !hasLoadedInitialData else { return }
    await refresh(force: false)
  }

  func refresh(force: Bool) async {
    if isLoading { return }
    isLoading = true
    defer {
      isLoading = false
      hasLoadedInitialData = true
    }

    do {
      let fetchedFilms = try await coordinator.loadFilms(force: force)
      updateFilms(with: fetchedFilms)
      error = nil
    } catch {
      guard !Task.isCancelled else { return }
      self.error = error
    }
  }

  private func updateFilms(with newFilms: [Film]) {
    let previouslySelectedID = selectedFilm?.id
    films = newFilms

    if let previouslySelectedID,
       let match = newFilms.first(where: { $0.id == previouslySelectedID }) {
      selectedFilm = match
    } else if let firstFilm = newFilms.first {
      selectedFilm = firstFilm
    } else {
      selectedFilm = nil
    }
  }
}
