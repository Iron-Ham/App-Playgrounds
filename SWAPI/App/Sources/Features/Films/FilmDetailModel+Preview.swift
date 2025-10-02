#if DEBUG && canImport(Persistence)
  import Persistence
  import Foundation

  extension FilmDetailModel {
    static func preview(film: Film = .preview) -> FilmDetailModel {
      let previewService = PersistenceService(
        setup: { _ in },
        importSnapshot: { _ in },
        observeChanges: {
          AsyncStream { continuation in
            continuation.finish()
          }
        },
        shutdown: {},
        fetchFilms: { [film] },
        fetchRelationshipSummary: { _ in .empty },
        fetchRelationshipEntities: { _, _ in [] }
      )

      let coordinator = PersistenceCoordinator(
        persistenceService: previewService,
        configurationProvider: {
          .init(storage: .inMemory(identifier: "preview"))
        },
        snapshotProvider: { .init() }
      )

      let model = FilmDetailModel(
        coordinator: coordinator,
        persistenceService: previewService,
        configurePersistence: {
          try await coordinator.preparePersistence()
        }
      )

      model.updateSelectedFilm(film)
      return model
    }
  }

  extension FilmDetailModel.Film {
    static let preview = Self(
      id: URL(string: "https://swapi.dev/api/films/1/")!,
      title: "A New Hope",
      episodeId: 4,
      openingCrawl: "It is a period of civil war...",
      director: "George Lucas",
      producers: ["Gary Kurtz", "Rick McCallum"],
      releaseDate: Date(timeIntervalSince1970: 236_102_400),
      created: Date(timeIntervalSince1970: 236_102_400),
      edited: Date(timeIntervalSince1970: 236_102_400)
    )
  }
#endif
