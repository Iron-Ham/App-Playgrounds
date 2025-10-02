@MainActor
extension PersistenceService {
  public static func live() -> PersistenceService {
    let container = PersistenceContainer()

    return PersistenceService(
      setup: { configuration in
        try await container.configure(configuration)
      },
      importSnapshot: { snapshot in
        try await container.importSnapshot(snapshot)
      },
      observeChanges: {
        await container.observeChanges()
      },
      shutdown: {
        try await container.shutdown()
      },
      fetchFilms: {
        try await container.filmsOrderedByReleaseDate()
      },
      fetchRelationshipSummary: { filmURL in
        try await container.relationshipSummary(forFilmWithURL: filmURL)
      },
      fetchRelationshipEntities: { filmURL, relationship in
        try await container.relationshipEntities(
          forFilmWithURL: filmURL,
          relationship: relationship
        )
      }
    )
  }
}
