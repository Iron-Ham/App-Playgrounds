import Persistence
import Observation

@MainActor
@Observable
final class RootSplitViewModel {
  typealias Film = PersistenceCoordinator.Film

  let filmsModel: FilmsModel
  let detailModel: FilmDetailModel

  init(
    coordinator: PersistenceCoordinator,
    persistenceService: PersistenceService,
    configurePersistence: @escaping @Sendable () async throws -> Void
  ) {
    self.filmsModel = FilmsModel(coordinator: coordinator)
    self.detailModel = FilmDetailModel(
      coordinator: coordinator,
      persistenceService: persistenceService,
      configurePersistence: configurePersistence
    )

    filmsModel.onSelectionChange { [detailModel] film in
      detailModel.updateSelectedFilm(film)
    }
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
