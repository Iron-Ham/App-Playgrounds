import FluentPersistence
import Foundation

actor PersistenceCoordinator {
  typealias Film = FluentPersistenceService.FilmDetails
  typealias Snapshot = FluentPersistenceService.Snapshot

  private let persistenceService: FluentPersistenceService
  private let configurationProvider: @Sendable () async throws -> FluentPersistenceConfiguration
  private let snapshotProvider: @Sendable () async throws -> Snapshot

  private var setupTask: Task<Void, Error>?
  private var refreshTask: Task<[Film], Error>?
  private var cachedFilms: [Film] = []

  init(
    persistenceService: FluentPersistenceService,
    configurationProvider: @escaping @Sendable () async throws -> FluentPersistenceConfiguration,
    snapshotProvider: @escaping @Sendable () async throws -> Snapshot
  ) {
    self.persistenceService = persistenceService
    self.configurationProvider = configurationProvider
    self.snapshotProvider = snapshotProvider
  }

  func preparePersistence() async throws {
    if let setupTask {
      return try await setupTask.value
    }

    let task = Task {
      let configuration = try await configurationProvider()
      try await persistenceService.setup(configuration)
    }

    setupTask = task

    do {
      try await task.value
    } catch {
      setupTask = nil
      throw error
    }
  }

  func loadFilms(force: Bool = false) async throws -> [Film] {
    if !force, !cachedFilms.isEmpty {
      return cachedFilms
    }

    if force {
      refreshTask?.cancel()
      refreshTask = nil
    } else if let refreshTask {
      return try await refreshTask.value
    }

    let task = Task<[Film], Error> {
      try await self.performRefresh(force: force)
    }

    refreshTask = task

    do {
      let films = try await task.value
      refreshTask = nil
      return films
    } catch {
      refreshTask = nil
      throw error
    }
  }

  func observeChanges() async throws -> AsyncStream<FluentPersistenceService.ChangeBatch> {
    try await preparePersistence()
    return await persistenceService.observeChanges()
  }

  func clearCache() {
    cachedFilms = []
    refreshTask?.cancel()
    refreshTask = nil
  }

  private func performRefresh(force: Bool) async throws -> [Film] {
    try await preparePersistence()

    if !force {
      let existingFilms = try await persistenceService.films()
      if !existingFilms.isEmpty {
        cachedFilms = existingFilms
        return existingFilms
      }
    }

    let snapshot = try await snapshotProvider()
    try Task.checkCancellation()

    try await persistenceService.importSnapshot(snapshot)
    let films = try await persistenceService.films()
    cachedFilms = films
    return films
  }
}
