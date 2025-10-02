import Persistence
import Foundation
import Observation

@MainActor
@Observable
final class FilmDetailModel {
  typealias Film = PersistenceService.FilmDetails
  typealias Relationship = PersistenceService.Relationship
  typealias RelationshipSummary = PersistenceService.FilmRelationshipSummary
  typealias RelationshipEntity = PersistenceService.RelationshipEntity

  @ObservationIgnored
  private let coordinator: PersistenceCoordinator
  @ObservationIgnored
  private let persistenceService: PersistenceService
  @ObservationIgnored
  private let configurePersistence: @Sendable () async throws -> Void
  @ObservationIgnored
  private let relationshipStore: RelationshipStore

  @ObservationIgnored
  private var summaryTask: Task<RelationshipSummary, Error>?
  @ObservationIgnored
  private var observationTask: Task<Void, Never>?

  var film: Film?
  var summary: RelationshipSummary = .empty
  var summaryError: Error?
  var isLoadingSummary = false
  var expandedRelationships: Set<Relationship> = []
  var navigationPath: [RelationshipDetailScreens.Screen] = []
  var relationshipStates: [Relationship: RelationshipItemsState] =
    Relationship.defaultStates()

  init(
    coordinator: PersistenceCoordinator,
    persistenceService: PersistenceService,
    configurePersistence: @escaping @Sendable () async throws -> Void
  ) {
    self.coordinator = coordinator
    self.persistenceService = persistenceService
    self.configurePersistence = configurePersistence
    self.relationshipStore = RelationshipStore(
      persistenceService: persistenceService,
      configurePersistence: configurePersistence
    )
  }

  deinit {
    summaryTask?.cancel()
    observationTask?.cancel()
  }

  func updateSelectedFilm(_ film: Film?) {
    guard film?.id != self.film?.id else { return }

    summaryTask?.cancel()
    observationTask?.cancel()

    if let previousFilmID = self.film?.id {
      Task {
        await relationshipStore.cancelLoads(for: previousFilmID)
      }
    }

    self.film = film
    navigationPath = []
    expandedRelationships.removeAll()
    relationshipStates = Relationship.defaultStates()

    guard let film else {
      summary = .empty
      summaryError = nil
      return
    }

    Task {
      await loadSummary(for: film, force: false)
    }

    Task {
      await bootstrapRelationshipState(for: film)
    }

    startObservingChanges(for: film)
  }

  func toggleRelationship(_ relationship: Relationship) {
    guard let film else { return }

    if expandedRelationships.contains(relationship) {
      expandedRelationships.remove(relationship)
      return
    }

    expandedRelationships.insert(relationship)

    Task {
      await loadRelationship(relationship, for: film, force: false)
    }
  }

  func retryRelationship(_ relationship: Relationship) {
    guard let film else { return }

    Task {
      await loadRelationship(relationship, for: film, force: true)
    }
  }

  func navigate(to entity: RelationshipEntity) {
    let destination = RelationshipDetailScreens.Screen(entity: entity)
    guard navigationPath != [destination] else { return }
    navigationPath = [destination]
  }
}

extension FilmDetailModel {
  fileprivate func loadSummary(for film: Film, force: Bool) async {
    if isLoadingSummary, !force {
      return
    }

    isLoadingSummary = true

    let task = Task<RelationshipSummary, Error> {
      try await configurePersistence()
      return try await persistenceService.relationshipSummary(forFilmWithURL: film.id)
    }

    summaryTask = task

    defer {
      isLoadingSummary = false
    }

    do {
      let summary = try await task.value
      guard !Task.isCancelled else { return }
      self.summary = summary
      summaryError = nil
    } catch is CancellationError {
      // Ignore cancellation.
    } catch {
      guard !Task.isCancelled else { return }
      summaryError = error
    }
  }

  fileprivate func bootstrapRelationshipState(for film: Film) async {
    let cached = await relationshipStore.cachedEntities(for: film.id)
    var currentStates = Relationship.defaultStates()

    for (relationship, entities) in cached {
      currentStates[relationship] = .loaded(entities)
    }

    relationshipStates = currentStates
  }

  fileprivate func loadRelationship(
    _ relationship: Relationship,
    for film: Film,
    force: Bool
  ) async {
    let currentState = relationshipStates[relationship] ?? .idle
    if currentState.isLoading, !force { return }
    if currentState.isLoaded, !force { return }

    relationshipStates[relationship] = .loading

    do {
      let entities = try await relationshipStore.entities(
        for: film,
        relationship: relationship,
        force: force
      )
      guard !Task.isCancelled else { return }
      relationshipStates[relationship] = .loaded(entities)
    } catch is CancellationError {
      if !force {
        relationshipStates[relationship] = .idle
      }
    } catch {
      guard !Task.isCancelled else { return }
      relationshipStates[relationship] = .failed(error.localizedDescription)
    }
  }

  fileprivate func startObservingChanges(for film: Film) {
    observationTask = Task { [weak self] in
      guard let self else { return }
      let filmID = film.id

      while !Task.isCancelled {
        do {
          let stream = try await coordinator.observeChanges()
          for await _ in stream {
            guard !Task.isCancelled else { return }
            await self.refreshCurrentFilm(expectedFilmID: filmID)
          }
        } catch {
          await MainActor.run {
            self.summaryError = error
          }
          try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
      }
    }
  }

  fileprivate func refreshCurrentFilm(expectedFilmID: Film.ID) async {
    guard let film, film.id == expectedFilmID else { return }

    await loadSummary(for: film, force: true)

    let expanded = expandedRelationships
    for relationship in expanded {
      await loadRelationship(relationship, for: film, force: true)
    }
  }
}

extension FilmDetailModel {
  enum RelationshipItemsState: Equatable {
    case idle
    case loading
    case loaded([RelationshipEntity])
    case failed(String)

    var isLoading: Bool {
      if case .loading = self { return true }
      return false
    }

    var isLoaded: Bool {
      if case .loaded = self { return true }
      return false
    }

    var animationID: Int {
      switch self {
      case .idle: 0
      case .loading: 1
      case .loaded(let entities): 2 + entities.count
      case .failed: 3
      }
    }
  }
}

extension FilmDetailModel.Relationship {
  fileprivate static func defaultStates() -> [Self: FilmDetailModel.RelationshipItemsState] {
    Dictionary(uniqueKeysWithValues: Self.allCases.map { ($0, .idle) })
  }
}

private actor RelationshipStore {
  typealias Film = FilmDetailModel.Film
  typealias Relationship = FilmDetailModel.Relationship
  typealias RelationshipEntity = FilmDetailModel.RelationshipEntity

  private let persistenceService: PersistenceService
  private let configurePersistence: @Sendable () async throws -> Void

  private var cache: [Film.ID: [Relationship: [RelationshipEntity]]] = [:]
  private var activeTasks: [Film.ID: [Relationship: Task<[RelationshipEntity], Error>]] = [:]

  init(
    persistenceService: PersistenceService,
    configurePersistence: @escaping @Sendable () async throws -> Void
  ) {
    self.persistenceService = persistenceService
    self.configurePersistence = configurePersistence
  }

  func cachedEntities(for filmID: Film.ID) -> [Relationship: [RelationshipEntity]] {
    cache[filmID] ?? [:]
  }

  func cancelLoads(for filmID: Film.ID) {
    guard let tasks = activeTasks.removeValue(forKey: filmID) else { return }
    for task in tasks.values {
      task.cancel()
    }
  }

  func entities(
    for film: Film,
    relationship: Relationship,
    force: Bool
  ) async throws -> [RelationshipEntity] {
    let filmID = film.id

    if !force, let cached = cache[filmID]?[relationship] {
      return cached
    }

    if var relationshipTasks = activeTasks[filmID], let task = relationshipTasks[relationship] {
      if force {
        task.cancel()
        relationshipTasks[relationship] = nil
        activeTasks[filmID] = relationshipTasks
      } else {
        return try await task.value
      }
    }

    let task = Task<[RelationshipEntity], Error> {
      try await configurePersistence()
      return try await persistenceService.relationshipEntities(
        forFilmWithURL: filmID,
        relationship: relationship
      )
    }

    var tasks = activeTasks[filmID] ?? [:]
    tasks[relationship] = task
    activeTasks[filmID] = tasks

    do {
      let entities = try await task.value
      store(entities, for: filmID, relationship: relationship)
      return entities
    } catch {
      activeTasks[filmID]?[relationship] = nil
      throw error
    }
  }

  private func store(
    _ entities: [RelationshipEntity],
    for filmID: Film.ID,
    relationship: Relationship
  ) {
    var relationships = cache[filmID] ?? [:]
    relationships[relationship] = entities
    cache[filmID] = relationships
    activeTasks[filmID]?[relationship] = nil
  }
}
