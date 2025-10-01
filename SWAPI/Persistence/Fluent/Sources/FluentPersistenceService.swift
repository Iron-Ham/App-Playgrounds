import API
import Fluent
import FluentSQLiteDriver
import Foundation
import Logging

public struct FluentPersistenceService: Sendable {
  public var setup: @Sendable (_ configuration: FluentPersistenceConfiguration) async throws -> Void
  public var importSnapshot: @Sendable (_ snapshot: Snapshot) async throws -> Void
  public var observeChanges: @Sendable () async -> AsyncStream<ChangeBatch>
  public var shutdown: @Sendable () async throws -> Void

  public init(
    setup: @escaping @Sendable (_ configuration: FluentPersistenceConfiguration) async throws -> Void,
    importSnapshot: @escaping @Sendable (_ snapshot: Snapshot) async throws -> Void,
    observeChanges: @escaping @Sendable () async -> AsyncStream<ChangeBatch>,
    shutdown: @escaping @Sendable () async throws -> Void
  ) {
    self.setup = setup
    self.importSnapshot = importSnapshot
    self.observeChanges = observeChanges
    self.shutdown = shutdown
  }
}

public struct FluentPersistenceConfiguration: Sendable {
  public enum Storage: Sendable {
    case file(URL)
    case inMemory(identifier: String = UUID().uuidString)
  }

  public var storage: Storage
  public var loggingLevel: Logger.Level

  public init(storage: Storage, loggingLevel: Logger.Level = .info) {
    self.storage = storage
    self.loggingLevel = loggingLevel
  }
}

public extension FluentPersistenceService {
  struct Snapshot: Sendable {
    public var films: [FilmResponse]
    public var people: [PersonResponse]
    public var planets: [PlanetResponse]
    public var species: [SpeciesResponse]
    public var starships: [StarshipResponse]
    public var vehicles: [VehicleResponse]

    public init(
      films: [FilmResponse] = [],
      people: [PersonResponse] = [],
      planets: [PlanetResponse] = [],
      species: [SpeciesResponse] = [],
      starships: [StarshipResponse] = [],
      vehicles: [VehicleResponse] = []
    ) {
      self.films = films
      self.people = people
      self.planets = planets
      self.species = species
      self.starships = starships
      self.vehicles = vehicles
    }
  }

  struct ChangeBatch: Sendable {
    public enum Entity: Sendable {
      case film
      case planet
      case person
      case species
      case starship
      case vehicle
      case relationship(String)
    }

    public var entities: [Entity]

    public init(entities: [Entity]) {
      self.entities = entities
    }
  }
}
