import API
import Fluent
import FluentSQLiteDriver
import Foundation
import Logging

public struct PersistenceService: Sendable {
  public var setup: @Sendable (_ configuration: PersistenceConfiguration) async throws -> Void
  public var importSnapshot: @Sendable (_ snapshot: Snapshot) async throws -> Void
  public var observeChanges: @Sendable () async -> AsyncStream<ChangeBatch>
  public var shutdown: @Sendable () async throws -> Void
  public var fetchFilms: @Sendable () async throws -> [FilmDetails]
  public var fetchRelationshipSummary:
    @Sendable (_ filmURL: URL) async throws -> FilmRelationshipSummary
  public var fetchRelationshipEntities:
    @Sendable (
      _ filmURL: URL,
      _ relationship: Relationship
    ) async throws -> [RelationshipEntity]

  public init(
    setup:
      @escaping @Sendable (_ configuration: PersistenceConfiguration) async throws -> Void,
    importSnapshot: @escaping @Sendable (_ snapshot: Snapshot) async throws -> Void,
    observeChanges: @escaping @Sendable () async -> AsyncStream<ChangeBatch>,
    shutdown: @escaping @Sendable () async throws -> Void,
    fetchFilms: @escaping @Sendable () async throws -> [FilmDetails],
    fetchRelationshipSummary:
      @escaping @Sendable (_ filmURL: URL) async throws -> FilmRelationshipSummary,
    fetchRelationshipEntities:
      @escaping @Sendable (
        _ filmURL: URL,
        _ relationship: Relationship
      ) async throws -> [RelationshipEntity]
  ) {
    self.setup = setup
    self.importSnapshot = importSnapshot
    self.observeChanges = observeChanges
    self.shutdown = shutdown
    self.fetchFilms = fetchFilms
    self.fetchRelationshipSummary = fetchRelationshipSummary
    self.fetchRelationshipEntities = fetchRelationshipEntities
  }
}

public struct PersistenceConfiguration: Sendable {
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

extension PersistenceService {
  public func films() async throws -> [FilmDetails] {
    try await fetchFilms()
  }

  public func relationshipSummary(
    forFilmWithURL filmURL: URL
  ) async throws -> FilmRelationshipSummary {
    try await fetchRelationshipSummary(filmURL)
  }

  public func relationshipEntities(
    forFilmWithURL filmURL: URL,
    relationship: Relationship
  ) async throws -> [RelationshipEntity] {
    try await fetchRelationshipEntities(filmURL, relationship)
  }

  public struct FilmRelationshipSummary: Sendable, Equatable {
    public let characterCount: Int
    public let planetCount: Int
    public let speciesCount: Int
    public let starshipCount: Int
    public let vehicleCount: Int

    public init(
      characterCount: Int = 0,
      planetCount: Int = 0,
      speciesCount: Int = 0,
      starshipCount: Int = 0,
      vehicleCount: Int = 0
    ) {
      self.characterCount = characterCount
      self.planetCount = planetCount
      self.speciesCount = speciesCount
      self.starshipCount = starshipCount
      self.vehicleCount = vehicleCount
    }

    public static let empty = Self()
  }

  public enum Relationship: CaseIterable, Sendable {
    case characters
    case planets
    case species
    case starships
    case vehicles
  }

  public struct CharacterDetails: Sendable, Equatable, Hashable, Identifiable {
    public let id: URL
    public let name: String
    public let gender: PersonResponse.Gender
    public let birthYear: PersonResponse.BirthYear
    public let height: String
    public let mass: String
    public let hairColors: [ColorDescriptor]
    public let skinColors: [ColorDescriptor]
    public let eyeColors: [ColorDescriptor]
    public let homeworld: PlanetDetails?
    public let species: [SpeciesDetails]
    public let starships: [StarshipDetails]
    public let vehicles: [VehicleDetails]
    public let films: [FilmSummary]

    public init(
      id: URL,
      name: String,
      gender: PersonResponse.Gender,
      birthYear: PersonResponse.BirthYear,
      height: String,
      mass: String,
      hairColors: [ColorDescriptor],
      skinColors: [ColorDescriptor],
      eyeColors: [ColorDescriptor],
      homeworld: PlanetDetails?,
      species: [SpeciesDetails],
      starships: [StarshipDetails],
      vehicles: [VehicleDetails],
      films: [FilmSummary]
    ) {
      self.id = id
      self.name = name
      self.gender = gender
      self.birthYear = birthYear
      self.height = height
      self.mass = mass
      self.hairColors = hairColors
      self.skinColors = skinColors
      self.eyeColors = eyeColors
      self.homeworld = homeworld
      self.species = species
      self.starships = starships
      self.vehicles = vehicles
      self.films = films
    }
  }

  public struct PlanetDetails: Sendable, Equatable, Hashable, Identifiable {
    public let id: URL
    public let name: String
    public let climates: [PlanetResponse.ClimateDescriptor]
    public let population: String
    public let rotationPeriod: String
    public let orbitalPeriod: String
    public let diameter: String
    public let gravityLevels: [PlanetResponse.GravityDescriptor]
    public let terrains: [PlanetResponse.TerrainDescriptor]
    public let surfaceWater: String
    public let films: [FilmSummary]

    public init(
      id: URL,
      name: String,
      climates: [PlanetResponse.ClimateDescriptor],
      population: String,
      rotationPeriod: String,
      orbitalPeriod: String,
      diameter: String,
      gravityLevels: [PlanetResponse.GravityDescriptor],
      terrains: [PlanetResponse.TerrainDescriptor],
      surfaceWater: String,
      films: [FilmSummary]
    ) {
      self.id = id
      self.name = name
      self.climates = climates
      self.population = population
      self.rotationPeriod = rotationPeriod
      self.orbitalPeriod = orbitalPeriod
      self.diameter = diameter
      self.gravityLevels = gravityLevels
      self.terrains = terrains
      self.surfaceWater = surfaceWater
      self.films = films
    }
  }

  public struct SpeciesDetails: Sendable, Equatable, Hashable, Identifiable {
    public let id: URL
    public let name: String
    public let classification: String
    public let designation: String
    public let averageHeight: String
    public let averageLifespan: String
    public let skinColors: [ColorDescriptor]
    public let hairColors: [ColorDescriptor]
    public let eyeColors: [ColorDescriptor]
    public let homeworld: PlanetDetails?
    public let language: String
    public let films: [FilmSummary]

    public init(
      id: URL,
      name: String,
      classification: String,
      designation: String,
      averageHeight: String,
      averageLifespan: String,
      skinColors: [ColorDescriptor],
      hairColors: [ColorDescriptor],
      eyeColors: [ColorDescriptor],
      homeworld: PlanetDetails?,
      language: String,
      films: [FilmSummary]
    ) {
      self.id = id
      self.name = name
      self.classification = classification
      self.designation = designation
      self.averageHeight = averageHeight
      self.averageLifespan = averageLifespan
      self.skinColors = skinColors
      self.hairColors = hairColors
      self.eyeColors = eyeColors
      self.homeworld = homeworld
      self.language = language
      self.films = films
    }
  }

  public struct StarshipDetails: Sendable, Equatable, Hashable, Identifiable {
    public let id: URL
    public let name: String
    public let model: String
    public let manufacturers: [Manufacturer]
    public let costInCredits: String
    public let length: String
    public let maxAtmospheringSpeed: String
    public let crew: String
    public let passengers: String
    public let cargoCapacity: String
    public let consumables: String
    public let hyperdriveRating: String
    public let mglt: String
    public let starshipClass: StarshipResponse.StarshipClass
    public let films: [FilmSummary]

    public init(
      id: URL,
      name: String,
      model: String,
      manufacturers: [Manufacturer],
      costInCredits: String,
      length: String,
      maxAtmospheringSpeed: String,
      crew: String,
      passengers: String,
      cargoCapacity: String,
      consumables: String,
      hyperdriveRating: String,
      mglt: String,
      starshipClass: StarshipResponse.StarshipClass,
      films: [FilmSummary]
    ) {
      self.id = id
      self.name = name
      self.model = model
      self.manufacturers = manufacturers
      self.costInCredits = costInCredits
      self.length = length
      self.maxAtmospheringSpeed = maxAtmospheringSpeed
      self.crew = crew
      self.passengers = passengers
      self.cargoCapacity = cargoCapacity
      self.consumables = consumables
      self.hyperdriveRating = hyperdriveRating
      self.mglt = mglt
      self.starshipClass = starshipClass
      self.films = films
    }
  }

  public struct VehicleDetails: Sendable, Equatable, Hashable, Identifiable {
    public let id: URL
    public let name: String
    public let model: String
    public let vehicleClass: VehicleResponse.VehicleClass
    public let manufacturers: [Manufacturer]
    public let costInCredits: String
    public let length: String
    public let maxAtmospheringSpeed: String
    public let crew: String
    public let passengers: String
    public let cargoCapacity: String
    public let consumables: String
    public let films: [FilmSummary]

    public init(
      id: URL,
      name: String,
      model: String,
      vehicleClass: VehicleResponse.VehicleClass,
      manufacturers: [Manufacturer],
      costInCredits: String,
      length: String,
      maxAtmospheringSpeed: String,
      crew: String,
      passengers: String,
      cargoCapacity: String,
      consumables: String,
      films: [FilmSummary]
    ) {
      self.id = id
      self.name = name
      self.model = model
      self.vehicleClass = vehicleClass
      self.manufacturers = manufacturers
      self.costInCredits = costInCredits
      self.length = length
      self.maxAtmospheringSpeed = maxAtmospheringSpeed
      self.crew = crew
      self.passengers = passengers
      self.cargoCapacity = cargoCapacity
      self.consumables = consumables
      self.films = films
    }
  }

  public struct FilmSummary: Sendable, Equatable, Hashable, Identifiable {
    public let id: URL
    public let title: String
    public let episodeId: Int
    public let releaseDate: Date?

    public init(id: URL, title: String, episodeId: Int, releaseDate: Date?) {
      self.id = id
      self.title = title
      self.episodeId = episodeId
      self.releaseDate = releaseDate
    }
  }

  public enum RelationshipEntity: Sendable, Hashable, Identifiable {
    case character(CharacterDetails)
    case planet(PlanetDetails)
    case species(SpeciesDetails)
    case starship(StarshipDetails)
    case vehicle(VehicleDetails)

    public var id: URL {
      switch self {
      case .character(let details):
        return details.id
      case .planet(let details):
        return details.id
      case .species(let details):
        return details.id
      case .starship(let details):
        return details.id
      case .vehicle(let details):
        return details.id
      }
    }
  }

  public struct FilmDetails: Sendable, Equatable, Hashable, Identifiable {
    public let id: URL
    public let title: String
    public let episodeId: Int
    public let openingCrawl: String
    public let director: String
    public let producers: [String]
    public let releaseDate: Date?
    public let created: Date
    public let edited: Date

    public init(
      id: URL,
      title: String,
      episodeId: Int,
      openingCrawl: String,
      director: String,
      producers: [String],
      releaseDate: Date?,
      created: Date,
      edited: Date
    ) {
      self.id = id
      self.title = title
      self.episodeId = episodeId
      self.openingCrawl = openingCrawl
      self.director = director
      self.producers = producers
      self.releaseDate = releaseDate
      self.created = created
      self.edited = edited
    }
  }

  public struct Snapshot: Sendable {
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

  public struct ChangeBatch: Sendable {
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
