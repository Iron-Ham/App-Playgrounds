import Dependencies
import Foundation
import GRDB
import SQLiteData
import StructuredQueries

public struct SWAPIDataStore {
  public let database: any DatabaseWriter

  public init(
    path: String? = nil,
    configuration: Configuration = Configuration(),
    setDefaultDatabase: Bool = true
  ) throws {
    var configuration = configuration
    configuration.prepareDatabase { db in
      try SWAPIDataStore.prepare(database: db)
    }
    self.database = try SQLiteData.defaultDatabase(path: path, configuration: configuration)
    try Self.migrator.migrate(database)
    if setDefaultDatabase {
      prepareDependencies {
        $0.defaultDatabase = self.database
      }
    }
  }

  public init(
    database: any DatabaseWriter,
    setDefaultDatabase: Bool = true
  ) throws {
    self.database = database
    try database.write { db in
      try SWAPIDataStore.prepare(database: db)
    }
    try Self.migrator.migrate(database)
    if setDefaultDatabase {
      prepareDependencies {
        $0.defaultDatabase = self.database
      }
    }
  }

  public func makeImporter() -> SnapshotImporter {
    SnapshotImporter(database: database)
  }
}

public enum SWAPIDataStorePreview {
  public static func inMemory() -> SWAPIDataStore {
    var configuration = Configuration()
    configuration.prepareDatabase { db in
      try SWAPIDataStore.prepare(database: db)
    }
    let database = try! DatabaseQueue(configuration: configuration)
    return try! SWAPIDataStore(database: database)
  }
}

extension SWAPIDataStore {
  static let migrator: DatabaseMigrator = {
    var migrator = DatabaseMigrator()
    migrator.registerMigration("Create schema") { db in
      try createSchema(db)
    }
    return migrator
  }()

  static func prepare(database db: Database) throws {
    try db.execute(sql: "PRAGMA foreign_keys = ON")
  }

  static func createSchema(_ db: Database) throws {
    try #sql(
      """
      CREATE TABLE "films" (
        "url" TEXT PRIMARY KEY NOT NULL,
        "title" TEXT NOT NULL,
        "episodeId" INTEGER NOT NULL,
        "openingCrawl" TEXT NOT NULL,
        "director" TEXT NOT NULL,
        "producerRaw" TEXT NOT NULL,
        "releaseDate" TEXT,
        "created" TEXT NOT NULL,
        "edited" TEXT NOT NULL
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE TABLE "planets" (
        "url" TEXT PRIMARY KEY NOT NULL,
        "name" TEXT NOT NULL,
        "rotationPeriod" TEXT NOT NULL,
        "orbitalPeriod" TEXT NOT NULL,
        "diameter" TEXT NOT NULL,
        "climate" TEXT NOT NULL,
        "gravity" TEXT NOT NULL,
        "terrain" TEXT NOT NULL,
        "surfaceWater" TEXT NOT NULL,
        "population" TEXT NOT NULL,
        "created" TEXT NOT NULL,
        "edited" TEXT NOT NULL
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE TABLE "people" (
        "url" TEXT PRIMARY KEY NOT NULL,
        "name" TEXT NOT NULL,
        "height" TEXT NOT NULL,
        "mass" TEXT NOT NULL,
        "hairColor" TEXT NOT NULL,
        "skinColor" TEXT NOT NULL,
        "eyeColor" TEXT NOT NULL,
        "birthYear" TEXT NOT NULL,
        "gender" TEXT NOT NULL,
        "homeworldUrl" TEXT REFERENCES "planets"("url") ON DELETE SET NULL,
        "created" TEXT NOT NULL,
        "edited" TEXT NOT NULL
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE TABLE "species" (
        "url" TEXT PRIMARY KEY NOT NULL,
        "name" TEXT NOT NULL,
        "classification" TEXT NOT NULL,
        "designation" TEXT NOT NULL,
        "averageHeight" TEXT NOT NULL,
        "averageLifespan" TEXT NOT NULL,
        "skinColors" TEXT NOT NULL,
        "hairColors" TEXT NOT NULL,
        "eyeColors" TEXT NOT NULL,
        "language" TEXT NOT NULL,
        "homeworldUrl" TEXT REFERENCES "planets"("url") ON DELETE SET NULL,
        "created" TEXT NOT NULL,
        "edited" TEXT NOT NULL
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE TABLE "starships" (
        "url" TEXT PRIMARY KEY NOT NULL,
        "name" TEXT NOT NULL,
        "model" TEXT NOT NULL,
        "manufacturer" TEXT NOT NULL,
        "costInCredits" TEXT NOT NULL,
        "length" TEXT NOT NULL,
        "maxAtmospheringSpeed" TEXT NOT NULL,
        "crew" TEXT NOT NULL,
        "passengers" TEXT NOT NULL,
        "cargoCapacity" TEXT NOT NULL,
        "consumables" TEXT NOT NULL,
        "hyperdriveRating" TEXT NOT NULL,
        "mglt" TEXT NOT NULL,
        "starshipClass" TEXT NOT NULL,
        "created" TEXT NOT NULL,
        "edited" TEXT NOT NULL
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE TABLE "vehicles" (
        "url" TEXT PRIMARY KEY NOT NULL,
        "name" TEXT NOT NULL,
        "model" TEXT NOT NULL,
        "manufacturer" TEXT NOT NULL,
        "costInCredits" TEXT NOT NULL,
        "length" TEXT NOT NULL,
        "maxAtmospheringSpeed" TEXT NOT NULL,
        "crew" TEXT NOT NULL,
        "passengers" TEXT NOT NULL,
        "cargoCapacity" TEXT NOT NULL,
        "consumables" TEXT NOT NULL,
        "vehicleClass" TEXT NOT NULL,
        "created" TEXT NOT NULL,
        "edited" TEXT NOT NULL
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE TABLE "filmCharacters" (
        "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
        "filmUrl" TEXT NOT NULL REFERENCES "films"("url") ON DELETE CASCADE,
        "personUrl" TEXT NOT NULL REFERENCES "people"("url") ON DELETE CASCADE,
        UNIQUE("filmUrl", "personUrl")
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE TABLE "filmPlanets" (
        "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
        "filmUrl" TEXT NOT NULL REFERENCES "films"("url") ON DELETE CASCADE,
        "planetUrl" TEXT NOT NULL REFERENCES "planets"("url") ON DELETE CASCADE,
        UNIQUE("filmUrl", "planetUrl")
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE TABLE "filmSpecies" (
        "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
        "filmUrl" TEXT NOT NULL REFERENCES "films"("url") ON DELETE CASCADE,
        "speciesUrl" TEXT NOT NULL REFERENCES "species"("url") ON DELETE CASCADE,
        UNIQUE("filmUrl", "speciesUrl")
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE TABLE "filmStarships" (
        "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
        "filmUrl" TEXT NOT NULL REFERENCES "films"("url") ON DELETE CASCADE,
        "starshipUrl" TEXT NOT NULL REFERENCES "starships"("url") ON DELETE CASCADE,
        UNIQUE("filmUrl", "starshipUrl")
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE TABLE "filmVehicles" (
        "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
        "filmUrl" TEXT NOT NULL REFERENCES "films"("url") ON DELETE CASCADE,
        "vehicleUrl" TEXT NOT NULL REFERENCES "vehicles"("url") ON DELETE CASCADE,
        UNIQUE("filmUrl", "vehicleUrl")
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE TABLE "personSpecies" (
        "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
        "personUrl" TEXT NOT NULL REFERENCES "people"("url") ON DELETE CASCADE,
        "speciesUrl" TEXT NOT NULL REFERENCES "species"("url") ON DELETE CASCADE,
        UNIQUE("personUrl", "speciesUrl")
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE TABLE "personStarships" (
        "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
        "personUrl" TEXT NOT NULL REFERENCES "people"("url") ON DELETE CASCADE,
        "starshipUrl" TEXT NOT NULL REFERENCES "starships"("url") ON DELETE CASCADE,
        UNIQUE("personUrl", "starshipUrl")
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE TABLE "personVehicles" (
        "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
        "personUrl" TEXT NOT NULL REFERENCES "people"("url") ON DELETE CASCADE,
        "vehicleUrl" TEXT NOT NULL REFERENCES "vehicles"("url") ON DELETE CASCADE,
        UNIQUE("personUrl", "vehicleUrl")
      ) STRICT
      """
    ).execute(db)

    try #sql(
      """
      CREATE INDEX "idxPeopleHomeworld" ON "people"("homeworldUrl")
      """
    ).execute(db)

    try #sql(
      """
      CREATE INDEX "idxSpeciesHomeworld" ON "species"("homeworldUrl")
      """
    ).execute(db)
  }
}
