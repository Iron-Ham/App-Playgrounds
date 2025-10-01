import API
import Foundation
import GRDB
import SQLiteData

extension SWAPIDataStore {
  public struct FilmRelationshipSummary: Sendable, Equatable {
    public let characterCount: Int
    public let planetCount: Int
    public let speciesCount: Int
    public let starshipCount: Int
    public let vehicleCount: Int

    public init(
      characterCount: Int,
      planetCount: Int,
      speciesCount: Int,
      starshipCount: Int,
      vehicleCount: Int
    ) {
      self.characterCount = characterCount
      self.planetCount = planetCount
      self.speciesCount = speciesCount
      self.starshipCount = starshipCount
      self.vehicleCount = vehicleCount
    }
  }

  public struct CharacterDetails: Sendable, Equatable {
    public let id: URL
    public let name: String
    public let gender: PersonResponse.Gender
    public let birthYear: PersonResponse.BirthYear
  }

  public struct PlanetDetails: Sendable, Equatable {
    public let id: URL
    public let name: String
    public let climates: [PlanetResponse.ClimateDescriptor]
    public let population: String
  }

  public struct SpeciesDetails: Sendable, Equatable {
    public let id: URL
    public let name: String
    public let classification: String
    public let language: String
  }

  public struct StarshipDetails: Sendable, Equatable {
    public let id: URL
    public let name: String
    public let model: String
    public let starshipClass: StarshipResponse.StarshipClass
  }

  public struct VehicleDetails: Sendable, Equatable {
    public let id: URL
    public let name: String
    public let model: String
    public let vehicleClass: VehicleResponse.VehicleClass
  }

  public func relationshipSummary(for film: Film) throws -> FilmRelationshipSummary {
    try relationshipSummary(forFilmWithURL: film.url)
  }

  public func relationshipSummary(forFilmWithURL filmURL: Film.ID) throws -> FilmRelationshipSummary
  {
    try FilmRelationshipSummary(
      characterCount: relationshipCount(forFilmWithURL: filmURL, .characters),
      planetCount: relationshipCount(forFilmWithURL: filmURL, .planets),
      speciesCount: relationshipCount(forFilmWithURL: filmURL, .species),
      starshipCount: relationshipCount(forFilmWithURL: filmURL, .starships),
      vehicleCount: relationshipCount(forFilmWithURL: filmURL, .vehicles)
    )
  }

  public func relationshipURLs(
    for film: Film,
    _ relationship: Relationship
  ) throws -> [URL] {
    try relationshipURLs(forFilmWithURL: film.url, relationship)
  }

  public func relationshipURLs(
    forFilmWithURL filmURL: Film.ID,
    _ relationship: Relationship
  ) throws -> [URL] {
    try database.read { db in
      let identifiers = try String.fetchAll(
        db,
        sql:
          "SELECT \"\(relationship.valueColumn)\" FROM \"\(relationship.tableName)\" WHERE \"filmUrl\" = ?",
        arguments: [filmURL.absoluteString]
      )
      return identifiers.compactMap(URL.init(string:))
    }
  }

  private func relationshipCount(
    forFilmWithURL filmURL: Film.ID,
    _ relationship: Relationship
  ) throws -> Int {
    try database.read { db in
      try Int.fetchOne(
        db,
        sql: "SELECT COUNT(*) FROM \"\(relationship.tableName)\" WHERE \"filmUrl\" = ?",
        arguments: [filmURL.absoluteString]
      ) ?? 0
    }
  }

  public enum Relationship: CaseIterable, Sendable {
    case characters
    case planets
    case species
    case starships
    case vehicles

    var tableName: String {
      switch self {
      case .characters: "filmCharacters"
      case .planets: "filmPlanets"
      case .species: "filmSpecies"
      case .starships: "filmStarships"
      case .vehicles: "filmVehicles"
      }
    }

    var valueColumn: String {
      switch self {
      case .characters: "personUrl"
      case .planets: "planetUrl"
      case .species: "speciesUrl"
      case .starships: "starshipUrl"
      case .vehicles: "vehicleUrl"
      }
    }
  }

  public func characters(for film: Film) throws -> [CharacterDetails] {
    try characters(forFilmWithURL: film.url)
  }

  public func characters(forFilmWithURL filmURL: Film.ID) throws -> [CharacterDetails] {
    try database.read { db in
      let rows = try Row.fetchAll(
        db,
        sql:
          """
          SELECT people.*
          FROM people
          INNER JOIN filmCharacters ON filmCharacters.personUrl = people.url
          WHERE filmCharacters.filmUrl = ?
          ORDER BY people.name COLLATE NOCASE
          """,
        arguments: [filmURL.absoluteString]
      )
      return rows.compactMap { row in
        guard
          let urlString: String = row["url"],
          let url = URL(string: urlString),
          let name: String = row["name"],
          let genderRaw: String = row["gender"],
          let birthYearRaw: String = row["birthYear"]
        else { return nil }

        return CharacterDetails(
          id: url,
          name: name,
          gender: PersonResponse.Gender(rawValue: genderRaw),
          birthYear: PersonResponse.BirthYear(rawValue: birthYearRaw)
        )
      }
    }
  }

  public func planets(for film: Film) throws -> [PlanetDetails] {
    try planets(forFilmWithURL: film.url)
  }

  public func planets(forFilmWithURL filmURL: Film.ID) throws -> [PlanetDetails] {
    try database.read { db in
      let rows = try Row.fetchAll(
        db,
        sql:
          """
          SELECT planets.*
          FROM planets
          INNER JOIN filmPlanets ON filmPlanets.planetUrl = planets.url
          WHERE filmPlanets.filmUrl = ?
          ORDER BY planets.name COLLATE NOCASE
          """,
        arguments: [filmURL.absoluteString]
      )
      return rows.compactMap { row in
        guard
          let urlString: String = row["url"],
          let url = URL(string: urlString),
          let name: String = row["name"],
          let climatesRaw: String = row["climates"],
          let population: String = row["population"]
        else { return nil }

        return PlanetDetails(
          id: url,
          name: name,
          climates: PlanetResponse.ClimateDescriptor.descriptors(from: climatesRaw),
          population: population
        )
      }
    }
  }

  public func species(for film: Film) throws -> [SpeciesDetails] {
    try species(forFilmWithURL: film.url)
  }

  public func species(forFilmWithURL filmURL: Film.ID) throws -> [SpeciesDetails] {
    try database.read { db in
      let rows = try Row.fetchAll(
        db,
        sql:
          """
          SELECT species.*
          FROM species
          INNER JOIN filmSpecies ON filmSpecies.speciesUrl = species.url
          WHERE filmSpecies.filmUrl = ?
          ORDER BY species.name COLLATE NOCASE
          """,
        arguments: [filmURL.absoluteString]
      )
      return rows.compactMap { row in
        guard
          let urlString: String = row["url"],
          let url = URL(string: urlString),
          let name: String = row["name"],
          let classification: String = row["classification"],
          let language: String = row["language"]
        else { return nil }

        return SpeciesDetails(
          id: url,
          name: name,
          classification: classification,
          language: language
        )
      }
    }
  }

  public func starships(for film: Film) throws -> [StarshipDetails] {
    try starships(forFilmWithURL: film.url)
  }

  public func starships(forFilmWithURL filmURL: Film.ID) throws -> [StarshipDetails] {
    try database.read { db in
      let rows = try Row.fetchAll(
        db,
        sql:
          """
          SELECT starships.*
          FROM starships
          INNER JOIN filmStarships ON filmStarships.starshipUrl = starships.url
          WHERE filmStarships.filmUrl = ?
          ORDER BY starships.name COLLATE NOCASE
          """,
        arguments: [filmURL.absoluteString]
      )
      return rows.compactMap { row in
        guard
          let urlString: String = row["url"],
          let url = URL(string: urlString),
          let name: String = row["name"],
          let model: String = row["model"],
          let classRaw: String = row["starshipClass"]
        else { return nil }

        return StarshipDetails(
          id: url,
          name: name,
          model: model,
          starshipClass: StarshipResponse.StarshipClass(rawValue: classRaw)
        )
      }
    }
  }

  public func vehicles(for film: Film) throws -> [VehicleDetails] {
    try vehicles(forFilmWithURL: film.url)
  }

  public func vehicles(forFilmWithURL filmURL: Film.ID) throws -> [VehicleDetails] {
    try database.read { db in
      let rows = try Row.fetchAll(
        db,
        sql:
          """
          SELECT vehicles.*
          FROM vehicles
          INNER JOIN filmVehicles ON filmVehicles.vehicleUrl = vehicles.url
          WHERE filmVehicles.filmUrl = ?
          ORDER BY vehicles.name COLLATE NOCASE
          """,
        arguments: [filmURL.absoluteString]
      )
      return rows.compactMap { row in
        guard
          let urlString: String = row["url"],
          let url = URL(string: urlString),
          let name: String = row["name"],
          let model: String = row["model"],
          let classRaw: String = row["vehicleClass"]
        else { return nil }

        return VehicleDetails(
          id: url,
          name: name,
          model: model,
          vehicleClass: VehicleResponse.VehicleClass(rawValue: classRaw)
        )
      }
    }
  }
}
