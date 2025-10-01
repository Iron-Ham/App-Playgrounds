import API
import Foundation
import GRDB
import SQLiteData
import StructuredQueries

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
      switch relationship {
      case .characters:
        try relatedURLs(
          FilmCharacter.self,
          filmURLColumn: \.filmURL,
          valueColumn: \.personURL,
          filmURL: filmURL,
          db: db
        )
      case .planets:
        try relatedURLs(
          FilmPlanet.self,
          filmURLColumn: \.filmURL,
          valueColumn: \.planetURL,
          filmURL: filmURL,
          db: db
        )
      case .species:
        try relatedURLs(
          FilmSpecies.self,
          filmURLColumn: \.filmURL,
          valueColumn: \.speciesURL,
          filmURL: filmURL,
          db: db
        )
      case .starships:
        try relatedURLs(
          FilmStarship.self,
          filmURLColumn: \.filmURL,
          valueColumn: \.starshipURL,
          filmURL: filmURL,
          db: db
        )
      case .vehicles:
        try relatedURLs(
          FilmVehicle.self,
          filmURLColumn: \.filmURL,
          valueColumn: \.vehicleURL,
          filmURL: filmURL,
          db: db
        )
      }
    }
  }

  private func relationshipCount(
    forFilmWithURL filmURL: Film.ID,
    _ relationship: Relationship
  ) throws -> Int {
    try database.read { db in
      switch relationship {
      case .characters:
        try countRelationships(
          FilmCharacter.self,
          filmURLColumn: \.filmURL,
          filmURL: filmURL,
          db: db
        )
      case .planets:
        try countRelationships(
          FilmPlanet.self,
          filmURLColumn: \.filmURL,
          filmURL: filmURL,
          db: db
        )
      case .species:
        try countRelationships(
          FilmSpecies.self,
          filmURLColumn: \.filmURL,
          filmURL: filmURL,
          db: db
        )
      case .starships:
        try countRelationships(
          FilmStarship.self,
          filmURLColumn: \.filmURL,
          filmURL: filmURL,
          db: db
        )
      case .vehicles:
        try countRelationships(
          FilmVehicle.self,
          filmURLColumn: \.filmURL,
          filmURL: filmURL,
          db: db
        )
      }
    }
  }

  private func countRelationships<RelationshipTable, FilmURLColumn>(
    _ table: RelationshipTable.Type,
    filmURLColumn: KeyPath<RelationshipTable.TableColumns, FilmURLColumn>,
    filmURL: Film.ID,
    db: Database
  ) throws -> Int
  where
    RelationshipTable: StructuredQueries.Table,
    FilmURLColumn: QueryExpression,
    FilmURLColumn.QueryValue == URL
  {
    try table
      .where { columns in
        columns[keyPath: filmURLColumn] == filmURL
      }
      .select { _ in AggregateFunction<Int>.count() }
      .fetchOne(db) ?? 0
  }

  private func relatedURLs<RelationshipTable, FilmURLColumn, ValueColumn>(
    _ table: RelationshipTable.Type,
    filmURLColumn: KeyPath<RelationshipTable.TableColumns, FilmURLColumn>,
    valueColumn: KeyPath<RelationshipTable.TableColumns, ValueColumn>,
    filmURL: Film.ID,
    db: Database
  ) throws -> [URL]
  where
    RelationshipTable: StructuredQueries.Table,
    FilmURLColumn: QueryExpression,
    FilmURLColumn.QueryValue == URL,
    ValueColumn: QueryExpression,
    ValueColumn.QueryValue == URL
  {
    try table
      .where { columns in
        columns[keyPath: filmURLColumn] == filmURL
      }
      .select(valueColumn)
      .fetchAll(db)
  }

  public enum Relationship: CaseIterable, Sendable {
    case characters
    case planets
    case species
    case starships
    case vehicles
  }

  public func characters(for film: Film) throws -> [CharacterDetails] {
    try characters(forFilmWithURL: film.url)
  }

  public func characters(forFilmWithURL filmURL: Film.ID) throws -> [CharacterDetails] {
    try database.read { db in
      let rows =
        try Person
        .order { $0.name.collate(.nocase) }
        .join(
          FilmCharacter
            .where { $0.filmURL == filmURL }
        ) { $0.url == $1.personURL }
        .selectStar()
        .fetchAll(db)

      return rows.map { person, _ in
        CharacterDetails(
          id: person.url,
          name: person.name,
          gender: person.gender,
          birthYear: person.birthYear
        )
      }
    }
  }

  public func planets(for film: Film) throws -> [PlanetDetails] {
    try planets(forFilmWithURL: film.url)
  }

  public func planets(forFilmWithURL filmURL: Film.ID) throws -> [PlanetDetails] {
    try database.read { db in
      let rows =
        try Planet
        .order { $0.name.collate(.nocase) }
        .join(
          FilmPlanet
            .where { $0.filmURL == filmURL }
        ) { $0.url == $1.planetURL }
        .selectStar()
        .fetchAll(db)

      return rows.map { planet, _ in
        PlanetDetails(
          id: planet.url,
          name: planet.name,
          climates: planet.climates,
          population: planet.population
        )
      }
    }
  }

  public func species(for film: Film) throws -> [SpeciesDetails] {
    try species(forFilmWithURL: film.url)
  }

  public func species(forFilmWithURL filmURL: Film.ID) throws -> [SpeciesDetails] {
    try database.read { db in
      let rows =
        try Species
        .order { $0.name.collate(.nocase) }
        .join(
          FilmSpecies
            .where { $0.filmURL == filmURL }
        ) { $0.url == $1.speciesURL }
        .selectStar()
        .fetchAll(db)

      return rows.map { species, _ in
        SpeciesDetails(
          id: species.url,
          name: species.name,
          classification: species.classification,
          language: species.language
        )
      }
    }
  }

  public func starships(for film: Film) throws -> [StarshipDetails] {
    try starships(forFilmWithURL: film.url)
  }

  public func starships(forFilmWithURL filmURL: Film.ID) throws -> [StarshipDetails] {
    try database.read { db in
      let rows =
        try Starship
        .order { $0.name.collate(.nocase) }
        .join(
          FilmStarship
            .where { $0.filmURL == filmURL }
        ) { $0.url == $1.starshipURL }
        .selectStar()
        .fetchAll(db)

      return rows.map { starship, _ in
        StarshipDetails(
          id: starship.url,
          name: starship.name,
          model: starship.model,
          starshipClass: starship.starshipClass
        )
      }
    }
  }

  public func vehicles(for film: Film) throws -> [VehicleDetails] {
    try vehicles(forFilmWithURL: film.url)
  }

  public func vehicles(forFilmWithURL filmURL: Film.ID) throws -> [VehicleDetails] {
    try database.read { db in
      let rows =
        try Vehicle
        .order { $0.name.collate(.nocase) }
        .join(
          FilmVehicle
            .where { $0.filmURL == filmURL }
        ) { $0.url == $1.vehicleURL }
        .selectStar()
        .fetchAll(db)

      return rows.map { vehicle, _ in
        VehicleDetails(
          id: vehicle.url,
          name: vehicle.name,
          model: vehicle.model,
          vehicleClass: vehicle.vehicleClass
        )
      }
    }
  }
}
