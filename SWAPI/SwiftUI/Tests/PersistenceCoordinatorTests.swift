import FluentPersistence
import Foundation
import Testing

@testable import StarWarsDB

@Suite("PersistenceCoordinator")
struct PersistenceCoordinatorTests {
  @Test
  func returnsExistingFilmsWithoutImport() async throws {
    let storage = PersistenceServiceStorage(
      films: [Self.sampleFilm(title: "Cached Hope")]
    )

    let service = await storage.makeService()
    let snapshotProvider = SnapshotProviderRecorder(result: .init())

    let coordinator = PersistenceCoordinator(
      persistenceService: service,
      configurationProvider: {
        await storage.recordConfiguration()
        return .init(storage: .inMemory(identifier: "test"))
      },
      snapshotProvider: {
        try await snapshotProvider.provide()
      }
    )

    let films = try await coordinator.loadFilms()

    let imports = await storage.importedSnapshotsCount
    let snapshotCalls = await snapshotProvider.callCount

    #expect(films.count == 1)
    #expect(imports == 0)
    #expect(snapshotCalls == 0)
  }

  @Test
  func importsSnapshotWhenStoreIsEmpty() async throws {
    let storage = PersistenceServiceStorage(films: [])
    let snapshot = FluentPersistenceService.Snapshot(
      films: [],
      people: [],
      planets: [],
      species: [],
      starships: [],
      vehicles: []
    )
    let service = await storage.makeService(changingFilmsTo: [
      Self.sampleFilm(title: "Fetched Hope")
    ])
    let snapshotProvider = SnapshotProviderRecorder(result: snapshot)

    let coordinator = PersistenceCoordinator(
      persistenceService: service,
      configurationProvider: {
        await storage.recordConfiguration()
        return .init(storage: .inMemory(identifier: "test"))
      },
      snapshotProvider: {
        try await snapshotProvider.provide()
      }
    )

    let films = try await coordinator.loadFilms()

    let imports = await storage.importedSnapshotsCount
    let snapshotCalls = await snapshotProvider.callCount

    #expect(films.count == 1)
    #expect(imports == 1)
    #expect(snapshotCalls == 1)
  }

  @Test
  func forceReloadBypassesCache() async throws {
    let storage = PersistenceServiceStorage(
      films: [Self.sampleFilm(title: "First Cache")]
    )
    let service = await storage.makeService(changingFilmsTo: [Self.sampleFilm(title: "Reloaded")])
    let snapshotProvider = SnapshotProviderRecorder(result: .init())

    let coordinator = PersistenceCoordinator(
      persistenceService: service,
      configurationProvider: {
        await storage.recordConfiguration()
        return .init(storage: .inMemory(identifier: "test"))
      },
      snapshotProvider: {
        try await snapshotProvider.provide()
      }
    )

    let initial = try await coordinator.loadFilms()
    let reloaded = try await coordinator.loadFilms(force: true)

    let imports = await storage.importedSnapshotsCount
    let snapshotCalls = await snapshotProvider.callCount

    #expect(initial.map(\.title) == ["First Cache"])
    #expect(reloaded.map(\.title) == ["Reloaded"])
    #expect(imports == 1)
    #expect(snapshotCalls == 1)
  }
}

extension PersistenceCoordinatorTests {
  fileprivate static func sampleFilm(title: String) -> FluentPersistenceService.FilmDetails {
    FluentPersistenceService.FilmDetails(
      id: URL(string: "https://example.com/films/\(UUID().uuidString)")!,
      title: title,
      episodeId: 1,
      openingCrawl: "Once upon a clone...",
      director: "Director",
      producers: ["Producer"],
      releaseDate: Date(timeIntervalSince1970: 0),
      created: Date(),
      edited: Date()
    )
  }
}

private actor PersistenceServiceStorage {
  private(set) var films: [FluentPersistenceService.FilmDetails]
  private(set) var importedSnapshots: [FluentPersistenceService.Snapshot] = []
  private(set) var configurationCount = 0

  init(films: [FluentPersistenceService.FilmDetails]) {
    self.films = films
  }

  func makeService(
    changingFilmsTo newFilms: [FluentPersistenceService.FilmDetails]? = nil
  )
    -> FluentPersistenceService
  {
    FluentPersistenceService(
      setup: { _ in
        await self.incrementConfiguration()
      },
      importSnapshot: { snapshot in
        await self.recordImport(snapshot)
        if let newFilms {
          await self.replaceFilms(with: newFilms)
        }
      },
      observeChanges: {
        AsyncStream { continuation in
          continuation.finish()
        }
      },
      shutdown: {},
      fetchFilms: {
        await self.films
      },
      fetchRelationshipSummary: { _ in FluentPersistenceService.FilmRelationshipSummary() },
      fetchRelationshipEntities: { _, _ in [] }
    )
  }

  func replaceFilms(with newFilms: [FluentPersistenceService.FilmDetails]) {
    films = newFilms
  }

  func incrementConfiguration() {
    configurationCount += 1
  }

  func recordConfiguration() {
    configurationCount += 1
  }

  func recordImport(_ snapshot: FluentPersistenceService.Snapshot) {
    importedSnapshots.append(snapshot)
  }

  var importedSnapshotsCount: Int {
    importedSnapshots.count
  }
}

private actor SnapshotProviderRecorder {
  private(set) var callCountValue = 0
  private let result: FluentPersistenceService.Snapshot

  init(result: FluentPersistenceService.Snapshot) {
    self.result = result
  }

  func provide() async throws -> FluentPersistenceService.Snapshot {
    callCountValue += 1
    return result
  }

  var callCount: Int {
    callCountValue
  }
}
