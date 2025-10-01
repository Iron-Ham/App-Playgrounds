import Fluent
import Foundation

public struct CreateSWAPISchema: AsyncMigration {
  public init() {}

  public func prepare(on database: any Database) async throws {
    try await createFilms(on: database)
    try await createPlanets(on: database)
    try await createSpecies(on: database)
    try await createPeople(on: database)
    try await createStarships(on: database)
    try await createVehicles(on: database)
    try await createFilmCharacterPivot(on: database)
    try await createFilmPlanetPivot(on: database)
    try await createFilmSpeciesPivot(on: database)
    try await createFilmStarshipPivot(on: database)
    try await createFilmVehiclePivot(on: database)
    try await createPersonSpeciesPivot(on: database)
    try await createPersonStarshipPivot(on: database)
    try await createPersonVehiclePivot(on: database)
  }

  public func revert(on database: any Database) async throws {
    try await database.schema(PersonVehiclePivot.schema).delete()
    try await database.schema(PersonStarshipPivot.schema).delete()
    try await database.schema(PersonSpeciesPivot.schema).delete()
    try await database.schema(FilmVehiclePivot.schema).delete()
    try await database.schema(FilmStarshipPivot.schema).delete()
    try await database.schema(FilmSpeciesPivot.schema).delete()
    try await database.schema(FilmPlanetPivot.schema).delete()
    try await database.schema(FilmCharacterPivot.schema).delete()
    try await database.schema(Vehicle.schema).delete()
    try await database.schema(Starship.schema).delete()
    try await database.schema(Person.schema).delete()
    try await database.schema(Species.schema).delete()
    try await database.schema(Planet.schema).delete()
    try await database.schema(Film.schema).delete()
  }
}

private extension CreateSWAPISchema {
  func createFilms(on database: any Database) async throws {
    try await database.schema(Film.schema)
      .field("url", .string, .identifier(auto: false))
      .field("title", .string, .required)
      .field("episodeId", .int, .required)
      .field("openingCrawl", .string, .required)
      .field("director", .string, .required)
      .field("producers", .string, .required)
      .field("releaseDate", .datetime)
      .field("created", .datetime, .required)
      .field("edited", .datetime, .required)
      .create()
  }

  func createPlanets(on database: any Database) async throws {
    try await database.schema(Planet.schema)
      .field("url", .string, .identifier(auto: false))
      .field("name", .string, .required)
      .field("rotationPeriod", .string, .required)
      .field("orbitalPeriod", .string, .required)
      .field("diameter", .string, .required)
      .field("climates", .string, .required)
      .field("gravityLevels", .string, .required)
      .field("terrains", .string, .required)
      .field("surfaceWater", .string, .required)
      .field("population", .string, .required)
      .field("created", .datetime, .required)
      .field("edited", .datetime, .required)
      .create()
  }

  func createSpecies(on database: any Database) async throws {
    try await database.schema(Species.schema)
      .field("url", .string, .identifier(auto: false))
      .field("name", .string, .required)
      .field("classification", .string, .required)
      .field("designation", .string, .required)
      .field("averageHeight", .string, .required)
      .field("averageLifespan", .string, .required)
      .field("skinColors", .string, .required)
      .field("hairColors", .string, .required)
      .field("eyeColors", .string, .required)
      .field("homeworldUrl", .string, .references(Planet.schema, "url", onDelete: .setNull))
      .field("language", .string, .required)
      .field("created", .datetime, .required)
      .field("edited", .datetime, .required)
      .create()
  }

  func createPeople(on database: any Database) async throws {
    try await database.schema(Person.schema)
      .field("url", .string, .identifier(auto: false))
      .field("name", .string, .required)
      .field("height", .string, .required)
      .field("mass", .string, .required)
      .field("hairColors", .string, .required)
      .field("skinColors", .string, .required)
      .field("eyeColors", .string, .required)
      .field("birthYear", .string, .required)
      .field("gender", .string, .required)
      .field("homeworldUrl", .string, .references(Planet.schema, "url", onDelete: .setNull))
      .field("created", .datetime, .required)
      .field("edited", .datetime, .required)
      .create()
  }

  func createStarships(on database: any Database) async throws {
    try await database.schema(Starship.schema)
      .field("url", .string, .identifier(auto: false))
      .field("name", .string, .required)
      .field("model", .string, .required)
      .field("manufacturers", .string, .required)
      .field("costInCredits", .string, .required)
      .field("length", .string, .required)
      .field("maxAtmospheringSpeed", .string, .required)
      .field("crew", .string, .required)
      .field("passengers", .string, .required)
      .field("cargoCapacity", .string, .required)
      .field("consumables", .string, .required)
      .field("hyperdriveRating", .string, .required)
      .field("mglt", .string, .required)
      .field("starshipClass", .string, .required)
      .field("created", .datetime, .required)
      .field("edited", .datetime, .required)
      .create()
  }

  func createVehicles(on database: any Database) async throws {
    try await database.schema(Vehicle.schema)
      .field("url", .string, .identifier(auto: false))
      .field("name", .string, .required)
      .field("model", .string, .required)
      .field("manufacturers", .string, .required)
      .field("costInCredits", .string, .required)
      .field("length", .string, .required)
      .field("maxAtmospheringSpeed", .string, .required)
      .field("crew", .string, .required)
      .field("passengers", .string, .required)
      .field("cargoCapacity", .string, .required)
      .field("consumables", .string, .required)
      .field("vehicleClass", .string, .required)
      .field("created", .datetime, .required)
      .field("edited", .datetime, .required)
      .create()
  }

  func createFilmCharacterPivot(on database: any Database) async throws {
    try await database.schema(FilmCharacterPivot.schema)
      .id()
      .field("filmUrl", .string, .required, .references(Film.schema, "url", onDelete: .cascade))
      .field("personUrl", .string, .required, .references(Person.schema, "url", onDelete: .cascade))
      .unique(on: "filmUrl", "personUrl")
      .create()
  }

  func createFilmPlanetPivot(on database: any Database) async throws {
    try await database.schema(FilmPlanetPivot.schema)
      .id()
      .field("filmUrl", .string, .required, .references(Film.schema, "url", onDelete: .cascade))
      .field("planetUrl", .string, .required, .references(Planet.schema, "url", onDelete: .cascade))
      .unique(on: "filmUrl", "planetUrl")
      .create()
  }

  func createFilmSpeciesPivot(on database: any Database) async throws {
    try await database.schema(FilmSpeciesPivot.schema)
      .id()
      .field("filmUrl", .string, .required, .references(Film.schema, "url", onDelete: .cascade))
      .field("speciesUrl", .string, .required, .references(Species.schema, "url", onDelete: .cascade))
      .unique(on: "filmUrl", "speciesUrl")
      .create()
  }

  func createFilmStarshipPivot(on database: any Database) async throws {
    try await database.schema(FilmStarshipPivot.schema)
      .id()
      .field("filmUrl", .string, .required, .references(Film.schema, "url", onDelete: .cascade))
      .field("starshipUrl", .string, .required, .references(Starship.schema, "url", onDelete: .cascade))
      .unique(on: "filmUrl", "starshipUrl")
      .create()
  }

  func createFilmVehiclePivot(on database: any Database) async throws {
    try await database.schema(FilmVehiclePivot.schema)
      .id()
      .field("filmUrl", .string, .required, .references(Film.schema, "url", onDelete: .cascade))
      .field("vehicleUrl", .string, .required, .references(Vehicle.schema, "url", onDelete: .cascade))
      .unique(on: "filmUrl", "vehicleUrl")
      .create()
  }

  func createPersonSpeciesPivot(on database: any Database) async throws {
    try await database.schema(PersonSpeciesPivot.schema)
      .id()
      .field("personUrl", .string, .required, .references(Person.schema, "url", onDelete: .cascade))
      .field("speciesUrl", .string, .required, .references(Species.schema, "url", onDelete: .cascade))
      .unique(on: "personUrl", "speciesUrl")
      .create()
  }

  func createPersonStarshipPivot(on database: any Database) async throws {
    try await database.schema(PersonStarshipPivot.schema)
      .id()
      .field("personUrl", .string, .required, .references(Person.schema, "url", onDelete: .cascade))
      .field("starshipUrl", .string, .required, .references(Starship.schema, "url", onDelete: .cascade))
      .unique(on: "personUrl", "starshipUrl")
      .create()
  }

  func createPersonVehiclePivot(on database: any Database) async throws {
    try await database.schema(PersonVehiclePivot.schema)
      .id()
      .field("personUrl", .string, .required, .references(Person.schema, "url", onDelete: .cascade))
      .field("vehicleUrl", .string, .required, .references(Vehicle.schema, "url", onDelete: .cascade))
      .unique(on: "personUrl", "vehicleUrl")
      .create()
  }
}
