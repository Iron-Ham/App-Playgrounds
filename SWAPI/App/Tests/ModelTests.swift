import API
import Foundation
import Persistence
import Testing

@testable import StarWarsDB

@MainActor
@Suite("FilmsModel")
struct FilmsModelTests {
  @Test
  func loadInitialSetsFilmsAndSelection() async throws {
    let initialFilms = [
      TestData.film(id: 1, title: "A New Hope"),
      TestData.film(id: 2, title: "The Empire Strikes Back"),
    ]

    let harness = await FilmsModelHarness(initialFilms: initialFilms)

    await harness.model.loadInitialIfNeeded()

    #expect(harness.model.films.map(\.title) == initialFilms.map(\.title))
    #expect(harness.model.selectedFilm?.id == initialFilms.first?.id)
    #expect(harness.model.hasLoadedInitialData)
    #expect(!harness.model.isLoading)
  }

  @Test
  func refreshKeepsSelectionWhenFilmStillExists() async throws {
    let initialFilms = [
      TestData.film(id: 1, title: "A New Hope"),
      TestData.film(id: 2, title: "The Empire Strikes Back"),
    ]
    let harness = await FilmsModelHarness(initialFilms: initialFilms)

    await harness.model.loadInitialIfNeeded()
    let selected = try #require(harness.model.films.last)
    harness.model.updateSelection(selected)

    let updatedSelection = TestData.film(id: 2, title: "Empire Remastered")
    let refreshedList = [TestData.film(id: 1, title: "A New Hope"), updatedSelection]
    await harness.storage.replaceFilms(with: refreshedList)

    await harness.model.refresh(force: true)

    #expect(harness.model.selectedFilm?.id == updatedSelection.id)
    #expect(harness.model.selectedFilm?.title == updatedSelection.title)
  }

  @Test
  func changeStreamRefreshesFilms() async throws {
    let initialFilms = [
      TestData.film(id: 1, title: "A New Hope"),
      TestData.film(id: 2, title: "The Empire Strikes Back"),
    ]
    let harness = await FilmsModelHarness(initialFilms: initialFilms)

    await harness.model.loadInitialIfNeeded()

    let refreshedList = [
      TestData.film(id: 1, title: "A New Hope"),
      TestData.film(id: 2, title: "Empire Extended"),
      TestData.film(id: 3, title: "Return of the Jedi"),
    ]
    await harness.storage.replaceFilms(with: refreshedList)

    let observerReady = await harness.storage.waitForObserverRegistration()
    #expect(observerReady)

    await harness.storage.sendChangeEvent()

    let updated = await waitUntil {
      harness.model.films.map(\.title) == refreshedList.map(\.title)
    }

    #expect(updated)
  }
}

@MainActor
@Suite("FilmDetailModel")
struct FilmDetailModelTests {
  @Test
  func updateSelectedFilmLoadsSummary() async throws {
    let film = TestData.film(id: 10, title: "Rogue One")
    let summary = PersistenceService.FilmRelationshipSummary(
      characterCount: 5,
      planetCount: 1,
      speciesCount: 0,
      starshipCount: 2,
      vehicleCount: 1
    )

    let serviceSpy = FilmDetailServiceSpy(
      films: [film],
      summary: summary,
      relationships: [.characters: TestData.characterEntities(names: ["Jyn Erso"])]
    )
    let harness = await FilmDetailModelHarness(serviceSpy: serviceSpy)

    harness.model.updateSelectedFilm(film)

    let summaryLoaded = await waitUntil {
      harness.model.summary == summary
    }

    #expect(summaryLoaded)
    #expect(harness.model.summaryError == nil)
    #expect(await serviceSpy.summaryCalls() == 1)
    #expect(await serviceSpy.configureCalls() >= 1)
  }

  @Test
  func expandingRelationshipFetchesEntities() async throws {
    let film = TestData.film(id: 20, title: "The Last Jedi")
    let summary = PersistenceService.FilmRelationshipSummary(characterCount: 1)
    let characters = TestData.characterEntities(names: ["Rey"])

    let serviceSpy = FilmDetailServiceSpy(
      films: [film],
      summary: summary,
      relationships: [.characters: characters]
    )
    let harness = await FilmDetailModelHarness(serviceSpy: serviceSpy)

    harness.model.updateSelectedFilm(film)
    _ = await waitUntil { harness.model.summary == summary }

    harness.model.toggleRelationship(.characters)

    let loaded = await waitUntil {
      loadedEntities(in: harness.model, for: .characters) == characters
    }

    #expect(loaded)
    #expect(await serviceSpy.entitiesCalls(for: .characters) == 1)
  }

  @Test
  func changeObservationReloadsExpandedRelationships() async throws {
    let film = TestData.film(id: 42, title: "A Test Hope")
    let initialCharacters = TestData.characterEntities(names: ["Luke Skywalker"])
    let updatedCharacters = TestData.characterEntities(names: ["Luke Skywalker", "Han Solo"])

    let serviceSpy = FilmDetailServiceSpy(
      films: [film],
      summary: .init(characterCount: 1),
      relationships: [.characters: initialCharacters]
    )
    let harness = await FilmDetailModelHarness(serviceSpy: serviceSpy)

    harness.model.updateSelectedFilm(film)
    _ = await waitUntil { harness.model.summary.characterCount == 1 }

    harness.model.toggleRelationship(.characters)
    _ = await waitUntil { loadedEntities(in: harness.model, for: .characters) == initialCharacters }

    await serviceSpy.updateSummary(.init(characterCount: 2))
    await serviceSpy.setEntities(.characters, entities: updatedCharacters)

    try await Task.sleep(nanoseconds: 50_000_000)
    await serviceSpy.emitChange()

    let summaryUpdated = await waitUntil {
      harness.model.summary.characterCount == 2
    }
    let relationshipsUpdated = await waitUntil {
      loadedEntities(in: harness.model, for: .characters) == updatedCharacters
    }

    #expect(summaryUpdated)
    #expect(relationshipsUpdated)
    #expect(await serviceSpy.summaryCalls() >= 2)
    #expect(await serviceSpy.entitiesCalls(for: .characters) >= 2)
  }
}

@MainActor
private struct FilmsModelHarness {
  let storage: FilmsServiceStorage
  let model: FilmsModel

  init(initialFilms: [PersistenceCoordinator.Film]) async {
    let storage = FilmsServiceStorage(films: initialFilms)
    let service = await storage.makeService()
    let coordinator = PersistenceCoordinator(
      persistenceService: service,
      configurationProvider: {
        await storage.recordConfiguration()
        return .init(storage: .inMemory(identifier: "films-model-tests"))
      },
      snapshotProvider: {
        .init()
      }
    )

    self.storage = storage
    self.model = FilmsModel(coordinator: coordinator)
  }
}

private actor FilmsServiceStorage {
  private var films: [PersistenceCoordinator.Film]
  private var configurationCount = 0
  private var changeContinuation: AsyncStream<PersistenceService.ChangeBatch>.Continuation?

  init(films: [PersistenceCoordinator.Film]) {
    self.films = films
  }

  func makeService() -> PersistenceService {
    PersistenceService(
      setup: { _ in await self.incrementConfiguration() },
      importSnapshot: { _ in },
      observeChanges: { await self.makeChangeStream() },
      shutdown: {},
      fetchFilms: { await self.films },
      fetchRelationshipSummary: { _ in PersistenceService.FilmRelationshipSummary() },
      fetchRelationshipEntities: { _, _ in [] }
    )
  }

  func replaceFilms(with newFilms: [PersistenceCoordinator.Film]) {
    films = newFilms
  }

  func sendChangeEvent() {
    changeContinuation?.yield(.init(entities: [.film]))
  }

  func waitForObserverRegistration(timeout: TimeInterval = 1) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if changeContinuation != nil { return true }
      try? await Task.sleep(nanoseconds: 20_000_000)
    }
    return changeContinuation != nil
  }

  func recordConfiguration() {
    configurationCount += 1
  }

  private func incrementConfiguration() {
    configurationCount += 1
  }

  private func makeChangeStream() async -> AsyncStream<PersistenceService.ChangeBatch> {
    AsyncStream { continuation in
      Task { await self.registerContinuation(continuation) }
    }
  }

  private func registerContinuation(
    _ continuation: AsyncStream<PersistenceService.ChangeBatch>.Continuation
  ) async {
    await Task.yield()
    changeContinuation?.finish()
    changeContinuation = continuation
  }
}

@MainActor
private struct FilmDetailModelHarness {
  let model: FilmDetailModel
  let coordinator: PersistenceCoordinator

  init(serviceSpy: FilmDetailServiceSpy) async {
    let service = await serviceSpy.makeService()
    let coordinator = PersistenceCoordinator(
      persistenceService: service,
      configurationProvider: {
        await serviceSpy.configure()
        return .init(storage: .inMemory(identifier: "film-detail-tests"))
      },
      snapshotProvider: {
        .init()
      }
    )

    self.coordinator = coordinator
    self.model = FilmDetailModel(
      coordinator: coordinator,
      persistenceService: service,
      configurePersistence: {
        await serviceSpy.configure()
      }
    )
  }
}

private actor FilmDetailServiceSpy {
  typealias Film = PersistenceService.FilmDetails
  typealias Relationship = PersistenceService.Relationship
  typealias RelationshipEntity = PersistenceService.RelationshipEntity
  typealias RelationshipSummary = PersistenceService.FilmRelationshipSummary

  private var films: [Film]
  private var summaryResult: RelationshipSummary
  private var relationshipResults: [Relationship: [RelationshipEntity]]
  private var summaryCallCount = 0
  private var relationshipCallCounts: [Relationship: Int] = [:]
  private var configureCallCount = 0
  private var changeContinuation: AsyncStream<PersistenceService.ChangeBatch>.Continuation?

  init(
    films: [Film],
    summary: RelationshipSummary,
    relationships: [Relationship: [RelationshipEntity]]
  ) {
    self.films = films
    self.summaryResult = summary
    self.relationshipResults = relationships
  }

  func makeService() -> PersistenceService {
    PersistenceService(
      setup: { _ in },
      importSnapshot: { _ in },
      observeChanges: { await self.makeChangeStream() },
      shutdown: {},
      fetchFilms: { await self.films },
      fetchRelationshipSummary: { _ in await self.recordSummaryAccess() },
      fetchRelationshipEntities: { _, relationship in
        await self.recordEntitiesAccess(for: relationship)
      }
    )
  }

  func configure() {
    configureCallCount += 1
  }

  func updateSummary(_ summary: RelationshipSummary) {
    summaryResult = summary
  }

  func setEntities(_ relationship: Relationship, entities: [RelationshipEntity]) {
    relationshipResults[relationship] = entities
  }

  func emitChange() {
    changeContinuation?.yield(.init(entities: [.relationship("characters")]))
  }

  func summaryCalls() -> Int {
    summaryCallCount
  }

  func entitiesCalls(for relationship: Relationship) -> Int {
    relationshipCallCounts[relationship, default: 0]
  }

  func configureCalls() -> Int {
    configureCallCount
  }

  private func makeChangeStream() async -> AsyncStream<PersistenceService.ChangeBatch> {
    AsyncStream { continuation in
      Task { await self.registerContinuation(continuation) }
    }
  }

  private func registerContinuation(
    _ continuation: AsyncStream<PersistenceService.ChangeBatch>.Continuation
  ) async {
    await Task.yield()
    changeContinuation?.finish()
    changeContinuation = continuation
  }

  private func recordSummaryAccess() -> RelationshipSummary {
    summaryCallCount += 1
    return summaryResult
  }

  private func recordEntitiesAccess(for relationship: Relationship) -> [RelationshipEntity] {
    relationshipCallCounts[relationship, default: 0] += 1
    return relationshipResults[relationship] ?? []
  }
}

private enum TestData {
  static func film(id: Int, title: String) -> PersistenceService.FilmDetails {
    PersistenceService.FilmDetails(
      id: URL(string: "https://example.com/films/\(id)")!,
      title: title,
      episodeId: id,
      openingCrawl: "Opening crawl for \(title)",
      director: "Director",
      producers: ["Producer"],
      releaseDate: Date(timeIntervalSince1970: TimeInterval(id) * 10_000),
      created: Date(),
      edited: Date()
    )
  }

  static func characterEntities(
    names: [String]
  )
    -> [PersistenceService.RelationshipEntity]
  {
    names.enumerated().map { index, name in
      .character(
        .init(
          id: URL(string: "https://example.com/people/\(index)")!,
          name: name,
          gender: PersonResponse.Gender.male,
          birthYear: PersonResponse.BirthYear(rawValue: "19BBY"),
          height: "180",
          mass: "80",
          hairColors: [],
          skinColors: [],
          eyeColors: [],
          homeworld: nil,
          species: [],
          starships: [],
          vehicles: [],
          films: []
        )
      )
    }
  }
}

@discardableResult
private func waitUntil(
  timeout: TimeInterval = 1,
  pollInterval: TimeInterval = 0.02,
  condition: @MainActor @Sendable () -> Bool
) async -> Bool {
  let deadline = Date().addingTimeInterval(timeout)
  while Date() < deadline {
    if await MainActor.run(body: condition) { return true }
    let delay = UInt64(pollInterval * 1_000_000_000)
    try? await Task.sleep(nanoseconds: delay)
  }
  return await MainActor.run(body: condition)
}

@MainActor
private func loadedEntities(
  in model: FilmDetailModel,
  for relationship: PersistenceService.Relationship
) -> [PersistenceService.RelationshipEntity]? {
  switch model.relationshipStates[relationship] ?? .idle {
  case .loaded(let entities):
    return entities
  default:
    return nil
  }
}
