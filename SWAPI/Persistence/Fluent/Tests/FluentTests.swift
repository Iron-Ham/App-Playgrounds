import API
import Foundation
import Logging
import Testing

@testable import FluentPersistence

@MainActor
@Suite("FluentPersistenceContainerTests", .serialized)
struct FluentPersistenceContainerTests {
  @Test
  func configureTwiceThrows() async throws {
    let container = FluentPersistenceContainer()
    defer { Task { try? await container.shutdown() } }
    try await container.configure(
      .init(storage: .inMemory(identifier: #function), loggingLevel: .critical))

    await #expect(throws: FluentPersistenceError.self) {
      try await container.configure(
        .init(storage: .inMemory(identifier: UUID().uuidString), loggingLevel: .critical))
    }
  }

  @Test
  func importingSnapshotEmitsChangeBatch() async throws {
    let container = FluentPersistenceContainer()
    defer { Task { try? await container.shutdown() } }
    try await container.configure(
      .init(storage: .inMemory(identifier: #function), loggingLevel: .critical))

    var iterator = container.observeChanges().makeAsyncIterator()
    let snapshot = try SampleSnapshot.make()

    try await container.importSnapshot(snapshot)

    let changeBatch = try #require(await iterator.next())
    let entityNames = changeBatch.entities.map(\.name)
    #expect(entityNames == ["film", "planet", "person", "species", "starship", "vehicle"])
  }

  @Test
  func fetchingFilmsAndRelationships() async throws {
    let container = FluentPersistenceContainer()
    defer { Task { try? await container.shutdown() } }
    try await container.configure(
      .init(storage: .inMemory(identifier: #function), loggingLevel: .critical))

    let snapshot = try SampleSnapshot.make()
    try await container.importSnapshot(snapshot)

    let films = try await container.filmsOrderedByReleaseDate()
    #expect(films.count == 1)

    let filmURL = try #require(films.first?.id)
    let summary = try await container.relationshipSummary(forFilmWithURL: filmURL)
    #expect(summary.characterCount == 1)
    #expect(summary.planetCount == 1)
    #expect(summary.speciesCount == 1)
    #expect(summary.starshipCount == 1)
    #expect(summary.vehicleCount == 1)

    let characters = try await container.relationshipEntities(
      forFilmWithURL: filmURL, relationship: .characters)
    #expect(characters.count == 1)

    let starships = try await container.relationshipEntities(
      forFilmWithURL: filmURL, relationship: .starships)
    #expect(starships.count == 1)
  }

  @Test
  func liveServiceSupportsFetching() async throws {
    let service = FluentPersistenceService.live()
    defer { Task { try? await service.shutdown() } }

    try await service.setup(
      .init(storage: .inMemory(identifier: #function), loggingLevel: .critical))

    let snapshot = try SampleSnapshot.make()
    try await service.importSnapshot(snapshot)

    let films = try await service.films()
    #expect(films.count == 1)

    let filmURL = try #require(films.first?.id)
    let summary = try await service.relationshipSummary(forFilmWithURL: filmURL)
    #expect(summary.characterCount == 1)

    let relationships = try await service.relationshipEntities(
      forFilmWithURL: filmURL, relationship: .vehicles)
    #expect(relationships.count == 1)
  }
}

extension FluentPersistenceService.ChangeBatch.Entity {
  fileprivate var name: String {
    switch self {
    case .film: return "film"
    case .planet: return "planet"
    case .person: return "person"
    case .species: return "species"
    case .starship: return "starship"
    case .vehicle: return "vehicle"
    case .relationship(let identifier):
      return "relationship:\(identifier)"
    }
  }
}

private enum SampleSnapshot {
  static func make() throws -> FluentPersistenceService.Snapshot {
    FluentPersistenceService.Snapshot(
      films: try FilmResponse.films(from: Self.films),
      people: try PersonResponse.people(from: Self.people),
      planets: try PlanetResponse.planets(from: Self.planets),
      species: try SpeciesResponse.species(from: Self.species),
      starships: try StarshipResponse.starships(from: Self.starships),
      vehicles: try VehicleResponse.vehicles(from: Self.vehicles)
    )
  }

  private static let films = Data(
    #"""
    [
      {
        "title": "A New Hope",
        "episode_id": 4,
        "opening_crawl": "It is a period of civil war...",
        "director": "George Lucas",
        "producer": "Gary Kurtz, Rick McCallum",
        "release_date": "1977-05-25",
        "characters": ["https://swapi.info/api/people/1"],
        "planets": ["https://swapi.info/api/planets/1"],
        "starships": ["https://swapi.info/api/starships/10"],
        "vehicles": ["https://swapi.info/api/vehicles/14"],
        "species": ["https://swapi.info/api/species/1"],
        "created": "2014-12-10T14:23:31Z",
        "edited": "2014-12-20T19:49:45Z",
        "url": "https://swapi.info/api/films/1"
      }
    ]
    """#.utf8)

  private static let people = Data(
    #"""
    [
      {
        "name": "Luke Skywalker",
        "height": "172",
        "mass": "77",
        "hair_color": "blond",
        "skin_color": "fair",
        "eye_color": "blue",
        "birth_year": "19BBY",
        "gender": "male",
        "homeworld": "https://swapi.info/api/planets/1",
        "films": ["https://swapi.info/api/films/1"],
        "species": [],
        "vehicles": ["https://swapi.info/api/vehicles/14"],
        "starships": [],
        "created": "2014-12-09T13:50:51Z",
        "edited": "2014-12-20T21:17:56Z",
        "url": "https://swapi.info/api/people/1"
      }
    ]
    """#.utf8)

  private static let planets = Data(
    #"""
    [
      {
        "name": "Tatooine",
        "rotation_period": "23",
        "orbital_period": "304",
        "diameter": "10465",
        "climate": "arid",
        "gravity": "1 standard",
        "terrain": "desert",
        "surface_water": "1",
        "population": "200000",
        "residents": ["https://swapi.info/api/people/1"],
        "films": ["https://swapi.info/api/films/1"],
        "created": "2014-12-09T13:50:49Z",
        "edited": "2014-12-20T20:58:18Z",
        "url": "https://swapi.info/api/planets/1"
      }
    ]
    """#.utf8)

  private static let species = Data(
    #"""
    [
      {
        "name": "Human",
        "classification": "mammal",
        "designation": "sentient",
        "average_height": "180",
        "average_lifespan": "120",
        "skin_colors": "caucasian, black, asian, hispanic",
        "hair_colors": "blond, brown, black, red",
        "eye_colors": "brown, blue, green, hazel, grey, amber",
        "homeworld": "https://swapi.info/api/planets/1",
        "language": "Galactic Basic",
        "people": ["https://swapi.info/api/people/1"],
        "films": ["https://swapi.info/api/films/1"],
        "created": "2014-12-10T13:52:11Z",
        "edited": "2014-12-20T21:36:42Z",
        "url": "https://swapi.info/api/species/1"
      }
    ]
    """#.utf8)

  private static let starships = Data(
    #"""
    [
      {
        "name": "Millennium Falcon",
        "model": "YT-1300 light freighter",
        "manufacturer": "Corellian Engineering Corporation",
        "cost_in_credits": "100000",
        "length": "34.37",
        "max_atmosphering_speed": "1050",
        "crew": "4",
        "passengers": "6",
        "cargo_capacity": "100000",
        "consumables": "2 months",
        "hyperdrive_rating": "0.5",
        "MGLT": "75",
        "starship_class": "Light freighter",
        "pilots": [],
        "films": ["https://swapi.info/api/films/1"],
        "created": "2014-12-10T16:59:45Z",
        "edited": "2014-12-20T21:23:49Z",
        "url": "https://swapi.info/api/starships/10"
      }
    ]
    """#.utf8)

  private static let vehicles = Data(
    #"""
    [
      {
        "name": "Snowspeeder",
        "model": "t-47 airspeeder",
        "manufacturer": "Incom Corporation",
        "cost_in_credits": "Unknown",
        "length": "4.5",
        "max_atmosphering_speed": "650",
        "crew": "2",
        "passengers": "0",
        "cargo_capacity": "10",
        "consumables": "none",
        "vehicle_class": "airspeeder",
        "pilots": [],
        "films": ["https://swapi.info/api/films/1"],
        "created": "2014-12-15T12:22:12Z",
        "edited": "2014-12-20T21:30:21Z",
        "url": "https://swapi.info/api/vehicles/14"
      }
    ]
    """#.utf8)
}
