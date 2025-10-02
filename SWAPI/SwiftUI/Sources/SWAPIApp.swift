import API
import Dependencies
import FluentPersistence
import SwiftUI

@main
struct StarWarsDBApp: App {
  private let client: Client
  private let persistenceService: FluentPersistenceService
  private let persistenceCoordinator: PersistenceCoordinator
  @StateObject
  private var rootViewModel: RootSplitViewModel

  init() {
    let appClient = Client()
    self.client = appClient

    let appService = FluentPersistenceService.live()
    self.persistenceService = appService

    let storageURL: URL
    do {
      storageURL = try Self.persistenceURL()
    } catch {
      fatalError("Unable to resolve persistence storage URL: \(error)")
    }

    let coordinator = PersistenceCoordinator(
      persistenceService: appService,
      configurationProvider: {
        .init(
          storage: .file(storageURL),
          loggingLevel: .error
        )
      },
      snapshotProvider: {
        async let films = appClient.films()
        async let people = appClient.people()
        async let planets = appClient.planets()
        async let species = appClient.species()
        async let starships = appClient.starships()
        async let vehicles = appClient.vehicles()

        return .init(
          films: try await films,
          people: try await people,
          planets: try await planets,
          species: try await species,
          starships: try await starships,
          vehicles: try await vehicles
        )
      }
    )

    self.persistenceCoordinator = coordinator

    let configurePersistenceClosure: @Sendable () async throws -> Void = {
      try await coordinator.preparePersistence()
    }

    prepareDependencies { values in
      values.client = appClient
      values.persistenceService = appService
      values.configurePersistence = configurePersistenceClosure
      values.persistenceCoordinator = coordinator
    }

    _rootViewModel = StateObject(
      wrappedValue: RootSplitViewModel(
        coordinator: coordinator,
        persistenceService: appService,
        configurePersistence: configurePersistenceClosure
      )
    )
  }

  var body: some Scene {
    WindowGroup {
      RootSplitView(model: rootViewModel)
    }
  }
}

extension StarWarsDBApp {
  fileprivate static func persistenceURL() throws -> URL {
    let applicationSupport = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let directory = applicationSupport.appendingPathComponent("StarWarsDB", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let fileURL = directory.appendingPathComponent("persistence.sqlite")
    #if swift(>=6.0)
      let decodedPath = fileURL.path(percentEncoded: false)
      return URL(fileURLWithPath: decodedPath, isDirectory: false)
    #else
      return URL(fileURLWithPath: fileURL.path, isDirectory: false)
    #endif
  }
}
