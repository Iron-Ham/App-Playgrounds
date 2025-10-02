import Combine
import FluentPersistence
import SwiftUI

@MainActor
final class RootSplitViewModel: ObservableObject {
  typealias Film = PersistenceCoordinator.Film

  let filmsModel: FilmsModel
  let detailModel: FilmDetailModel
  private var cancellables: Set<AnyCancellable> = []

  init(
    coordinator: PersistenceCoordinator,
    persistenceService: FluentPersistenceService,
    configurePersistence: @escaping @Sendable () async throws -> Void
  ) {
    self.filmsModel = FilmsModel(coordinator: coordinator)
    self.detailModel = FilmDetailModel(
      coordinator: coordinator,
      persistenceService: persistenceService,
      configurePersistence: configurePersistence
    )

    filmsModel.objectWillChange
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.objectWillChange.send()
      }
      .store(in: &cancellables)

    detailModel.objectWillChange
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.objectWillChange.send()
      }
      .store(in: &cancellables)

    filmsModel.$selectedFilm
      .receive(on: DispatchQueue.main)
      .sink { [weak self] film in
        self?.detailModel.updateSelectedFilm(film)
      }
      .store(in: &cancellables)
  }

  var films: [Film] { filmsModel.films }

  var isLoadingFilms: Bool { filmsModel.isLoading }

  var filmsError: Error? { filmsModel.error }

  var selectedFilm: Film? {
    get { filmsModel.selectedFilm }
    set { selectFilm(newValue) }
  }

  var hasLoadedInitialData: Bool { filmsModel.hasLoadedInitialData }

  func loadInitialIfNeeded() async {
    await filmsModel.loadInitialIfNeeded()
  }

  func refresh(force: Bool) async {
    await filmsModel.refresh(force: force)
  }

  func selectFilm(_ film: Film?) {
    filmsModel.updateSelection(film)
  }
}
