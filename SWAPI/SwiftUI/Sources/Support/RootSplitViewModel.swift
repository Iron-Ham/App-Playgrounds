import FluentPersistence
import SwiftUI

@MainActor
final class RootSplitViewModel: ObservableObject {
  typealias Film = PersistenceCoordinator.Film

  let filmsModel: FilmsModel
  let detailModel: FilmDetailModel

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
    detailModel.updateSelectedFilm(filmsModel.selectedFilm)
  }

  func refresh(force: Bool) async {
    await filmsModel.refresh(force: force)
    detailModel.updateSelectedFilm(filmsModel.selectedFilm)
  }

  func selectFilm(_ film: Film?) {
    filmsModel.updateSelection(film)
    detailModel.updateSelectedFilm(film)
  }
}
