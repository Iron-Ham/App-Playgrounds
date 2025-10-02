import Dependencies
import Foundation
import Persistence
import XCTestDynamicOverlay

private enum PersistenceServiceKey: DependencyKey {
  static let liveValue: PersistenceService = .unimplemented(
    "PersistenceServiceKey.liveValue")
  static let testValue: PersistenceService = .unimplemented(
    "PersistenceServiceKey.testValue")
  static let previewValue: PersistenceService = .preview
}

private enum PersistenceCoordinatorKey: DependencyKey {
  static let liveValue: PersistenceCoordinator = .unimplemented(
    "PersistenceCoordinatorKey.liveValue")
  static let testValue: PersistenceCoordinator = .unimplemented(
    "PersistenceCoordinatorKey.testValue")
  static let previewValue: PersistenceCoordinator = .preview
}

private enum ConfigurePersistenceKey: DependencyKey {
  static let liveValue: @Sendable () async throws -> Void = {
    dependencyFailure("ConfigurePersistenceKey.liveValue")
  }
  static let testValue: @Sendable () async throws -> Void = {
    dependencyFailure("ConfigurePersistenceKey.testValue")
  }
  static let previewValue: @Sendable () async throws -> Void = {}
}

extension DependencyValues {
  public var persistenceService: PersistenceService {
    get { self[PersistenceServiceKey.self] }
    set { self[PersistenceServiceKey.self] = newValue }
  }

  public var configurePersistence: @Sendable () async throws -> Void {
    get { self[ConfigurePersistenceKey.self] }
    set { self[ConfigurePersistenceKey.self] = newValue }
  }

  var persistenceCoordinator: PersistenceCoordinator {
    get { self[PersistenceCoordinatorKey.self] }
    set { self[PersistenceCoordinatorKey.self] = newValue }
  }
}

extension PersistenceService {
  fileprivate static func unimplemented(_ message: @autoclosure () -> String) -> Self {
    let label = message()
    let failure: @Sendable () -> Never = { dependencyFailure(label) }
    return Self(
      setup: { _ in failure() },
      importSnapshot: { _ in failure() },
      observeChanges: {
        return failure()
      },
      shutdown: {
        failure()
      },
      fetchFilms: {
        return failure()
      },
      fetchRelationshipSummary: { _ in
        return failure()
      },
      fetchRelationshipEntities: { _, _ in
        return failure()
      }
    )
  }

  fileprivate static var preview: Self {
    let sampleFilm = PersistenceService.FilmDetails(
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

    return Self(
      setup: { _ in },
      importSnapshot: { _ in },
      observeChanges: {
        AsyncStream { continuation in
          continuation.finish()
        }
      },
      shutdown: {},
      fetchFilms: { [sampleFilm] },
      fetchRelationshipSummary: { _ in .empty },
      fetchRelationshipEntities: { _, _ in [] }
    )
  }
}

extension PersistenceCoordinator {
  fileprivate static func unimplemented(
    _ message: @autoclosure () -> String
  ) -> PersistenceCoordinator {
    let label = message()
    return PersistenceCoordinator(
      persistenceService: .unimplemented(label),
      configurationProvider: {
        dependencyFailure(label)
      },
      snapshotProvider: {
        dependencyFailure(label)
      }
    )
  }

  fileprivate static var preview: PersistenceCoordinator {
    return PersistenceCoordinator(
      persistenceService: .preview,
      configurationProvider: {
        .init(storage: .inMemory(identifier: "preview"))
      },
      snapshotProvider: {
        .init()
      }
    )
  }
}

private func dependencyFailure(_ message: @autoclosure () -> String) -> Never {
  #if DEBUG
    XCTFail(message())
  #endif
  fatalError(message())
}
