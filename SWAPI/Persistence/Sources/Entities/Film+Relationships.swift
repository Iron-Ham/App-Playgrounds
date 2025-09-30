import Foundation
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
}
