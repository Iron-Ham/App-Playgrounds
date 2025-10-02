import API
import Dependencies
import FluentPersistence
import SwiftUI

@main
struct SWAPIApp: App {
  private let client: Client
  private let persistenceService: FluentPersistenceService
  private let persistenceSetupTask: Task<Void, Error>

  init() {
    client = Client()
    let service = FluentPersistenceService.live()
    persistenceService = service

    let setupTask = Task {
      let storageURL = try Self.persistenceURL()
      try await service.setup(
        .init(
          storage: .file(storageURL),
          loggingLevel: .error
        )
      )
    }
    persistenceSetupTask = setupTask

    prepareDependencies {
      $0.client = client
      $0.persistenceService = service
      $0.configurePersistence = {
        try await setupTask.value
      }
    }
  }

  var body: some Scene {
    WindowGroup {
      RootSplitView()
    }
  }
}

extension SWAPIApp {
  fileprivate static func persistenceURL() throws -> URL {
    let applicationSupport = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let directory = applicationSupport.appendingPathComponent("SWAPI", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("persistence.sqlite")
  }
}
