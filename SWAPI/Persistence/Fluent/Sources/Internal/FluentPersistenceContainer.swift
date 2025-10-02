import API
import Fluent
import FluentSQLiteDriver
import Foundation
import Logging
import NIO

@MainActor
final class FluentPersistenceContainer {
  private struct ConfigurationState {
    var sqliteConfiguration: SQLiteConfiguration
    var loggingLevel: Logger.Level
  }

  let databases: Databases
  let migrations: Migrations
  private let databaseID: DatabaseID
  private let eventLoopGroup: any EventLoopGroup
  private let threadPool: NIOThreadPool
  private var logger = Logger(label: "dev.iron-ham.FluentPersistence")

  private var migrator: Migrator?
  private var configuration: ConfigurationState?

  private let changeStreamContinuation:
    AsyncStream<FluentPersistenceService.ChangeBatch>.Continuation

  let changeStream: AsyncStream<FluentPersistenceService.ChangeBatch>

  init(eventLoopGroup: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)) {
    self.eventLoopGroup = eventLoopGroup
    self.threadPool = NIOThreadPool(numberOfThreads: 2)
    self.threadPool.start()
    self.databases = Databases(threadPool: threadPool, on: eventLoopGroup)
    self.migrations = Migrations()
    self.databaseID = .sqlite

    var continuation: AsyncStream<FluentPersistenceService.ChangeBatch>.Continuation!
    self.changeStream = AsyncStream { continuation = $0 }
    self.changeStreamContinuation = continuation

    self.changeStreamContinuation.onTermination = { [weak self] _ in
      self?.changeStreamContinuation.finish()
    }
  }

  deinit {
    changeStreamContinuation.finish()
  }

  func configure(_ configuration: FluentPersistenceConfiguration) async throws {
    guard self.configuration == nil else {
      throw FluentPersistenceError.databaseAlreadyConfigured
    }

    logger.logLevel = configuration.loggingLevel

    let sqliteConfiguration: SQLiteConfiguration
    switch configuration.storage {
    case .file(let url):
      let fileURL = url.standardizedFileURL
      let directoryURL = fileURL.deletingLastPathComponent()
      try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
      #if swift(>=6.0)
        sqliteConfiguration = .file(fileURL.path(percentEncoded: false))
      #else
        sqliteConfiguration = .file(fileURL.path)
      #endif
    case .inMemory(let identifier):
      sqliteConfiguration = .init(storage: .memory(identifier: identifier))
    }

    databases.use(
      .sqlite(sqliteConfiguration, sqlLogLevel: configuration.loggingLevel),
      as: databaseID,
      isDefault: true
    )

    migrations.add(CreateSWAPISchema(), to: databaseID)

    logger.log(level: configuration.loggingLevel, "Running Fluent migrations")
    let migrator = Migrator(
      databases: databases, migrations: migrations, logger: logger, on: eventLoopGroup.next())
    self.migrator = migrator

    try await migrator.setupIfNeeded().value()
    try await migrator.prepareBatch().value()

    self.configuration = ConfigurationState(
      sqliteConfiguration: sqliteConfiguration,
      loggingLevel: configuration.loggingLevel
    )
  }

  func importSnapshot(_ snapshot: FluentPersistenceService.Snapshot) async throws {
    guard configuration != nil else {
      throw FluentPersistenceError.databaseNotConfigured
    }

    guard
      let database = databases.database(
        databaseID,
        logger: logger,
        on: eventLoopGroup.next()
      )
    else {
      throw FluentPersistenceError.databaseUnavailable
    }

    try await runInTransaction(on: database) { transaction in
      try await self.clearExistingData(on: transaction)
      try await self.seedEntities(from: snapshot, on: transaction)
      try await self.seedRelationships(from: snapshot, on: transaction)
    }

    emitChanges(for: snapshot)
  }

  func observeChanges() -> AsyncStream<FluentPersistenceService.ChangeBatch> {
    changeStream
  }

  func filmsOrderedByReleaseDate() async throws -> [FluentPersistenceService.FilmDetails] {
    try await withDatabase { database in
      try await Film.query(on: database)
        .sort(\.$releaseDate, .ascending)
        .sort(\.$episodeID, .ascending)
        .sort(\.$title, .ascending)
        .all()
        .map { film in
          FluentPersistenceService.FilmDetails(
            id: film.url,
            title: film.title,
            episodeId: film.episodeID,
            openingCrawl: film.openingCrawl,
            director: film.director,
            producers: film.producers,
            releaseDate: film.releaseDate,
            created: film.created,
            edited: film.edited
          )
        }
    }
  }

  func relationshipSummary(
    forFilmWithURL filmURL: URL
  ) async throws -> FluentPersistenceService.FilmRelationshipSummary {
    try await withDatabase { database in
      return FluentPersistenceService.FilmRelationshipSummary(
        characterCount: try await FilmCharacterPivot.query(on: database)
          .filter(\.$film.$id == filmURL)
          .count(),
        planetCount: try await FilmPlanetPivot.query(on: database)
          .filter(\.$film.$id == filmURL)
          .count(),
        speciesCount: try await FilmSpeciesPivot.query(on: database)
          .filter(\.$film.$id == filmURL)
          .count(),
        starshipCount: try await FilmStarshipPivot.query(on: database)
          .filter(\.$film.$id == filmURL)
          .count(),
        vehicleCount: try await FilmVehiclePivot.query(on: database)
          .filter(\.$film.$id == filmURL)
          .count()
      )
    }
  }

  func relationshipEntities(
    forFilmWithURL filmURL: URL,
    relationship: FluentPersistenceService.Relationship
  ) async throws -> [FluentPersistenceService.RelationshipEntity] {
    try await withDatabase { database in
      guard let film = try await Film.find(filmURL, on: database) else { return [] }
      switch relationship {
      case .characters:
        let people = try await film.$characters
          .query(on: database)
          .sort(\.$name, .ascending)
          .all()
        return people.map { person in
          .character(
            .init(
              id: person.url,
              name: person.name,
              gender: person.gender,
              birthYear: person.birthYear
            )
          )
        }

      case .planets:
        let planets = try await film.$planets
          .query(on: database)
          .sort(\.$name, .ascending)
          .all()
        return planets.map { planet in
          .planet(
            .init(
              id: planet.url,
              name: planet.name,
              climates: planet.climates,
              population: planet.population
            )
          )
        }

      case .species:
        let species = try await film.$species
          .query(on: database)
          .sort(\.$name, .ascending)
          .all()
        return species.map { species in
          .species(
            .init(
              id: species.url,
              name: species.name,
              classification: species.classification,
              language: species.language
            )
          )
        }

      case .starships:
        let starships = try await film.$starships
          .query(on: database)
          .sort(\.$name, .ascending)
          .all()
        return starships.map { starship in
          .starship(
            .init(
              id: starship.url,
              name: starship.name,
              model: starship.model,
              starshipClass: starship.starshipClass
            )
          )
        }

      case .vehicles:
        let vehicles = try await film.$vehicles
          .query(on: database)
          .sort(\.$name, .ascending)
          .all()
        return vehicles.map { vehicle in
          .vehicle(
            .init(
              id: vehicle.url,
              name: vehicle.name,
              model: vehicle.model,
              vehicleClass: vehicle.vehicleClass
            )
          )
        }
      }
    }
  }

  func shutdown() async throws {
    changeStreamContinuation.finish()
    await databases.shutdownAsync()
    try await threadPool.shutdownGracefully()
    try await eventLoopGroup.shutdownGracefully()
    migrator = nil
    configuration = nil
  }
}

extension FluentPersistenceContainer {
  private func emitChanges(for snapshot: FluentPersistenceService.Snapshot) {
    let changedEntities: [FluentPersistenceService.ChangeBatch.Entity] = [
      snapshot.films.isEmpty ? nil : .film,
      snapshot.planets.isEmpty ? nil : .planet,
      snapshot.people.isEmpty ? nil : .person,
      snapshot.species.isEmpty ? nil : .species,
      snapshot.starships.isEmpty ? nil : .starship,
      snapshot.vehicles.isEmpty ? nil : .vehicle,
    ].compactMap { $0 }

    if !changedEntities.isEmpty {
      changeStreamContinuation.yield(
        .init(entities: changedEntities)
      )
    }
  }

  private func clearExistingData(on database: any Database) async throws {
    try await FilmCharacterPivot.query(on: database).delete()
    try await FilmPlanetPivot.query(on: database).delete()
    try await FilmSpeciesPivot.query(on: database).delete()
    try await FilmStarshipPivot.query(on: database).delete()
    try await FilmVehiclePivot.query(on: database).delete()
    try await PersonSpeciesPivot.query(on: database).delete()
    try await PersonStarshipPivot.query(on: database).delete()
    try await PersonVehiclePivot.query(on: database).delete()

    try await Film.query(on: database).delete()
    try await Planet.query(on: database).delete()
    try await Person.query(on: database).delete()
    try await Species.query(on: database).delete()
    try await Starship.query(on: database).delete()
    try await Vehicle.query(on: database).delete()
  }

  private func seedEntities(
    from snapshot: FluentPersistenceService.Snapshot, on database: any Database
  ) async throws {
    for film in snapshot.films {
      try await Film(from: film).create(on: database)
    }

    for planet in snapshot.planets {
      try await Planet(from: planet).create(on: database)
    }

    for species in snapshot.species {
      try await Species(from: species).create(on: database)
    }

    for person in snapshot.people {
      try await Person(from: person).create(on: database)
    }

    for starship in snapshot.starships {
      try await Starship(from: starship).create(on: database)
    }

    for vehicle in snapshot.vehicles {
      try await Vehicle(from: vehicle).create(on: database)
    }
  }

  private func seedRelationships(
    from snapshot: FluentPersistenceService.Snapshot, on database: any Database
  ) async throws {
    for film in snapshot.films {
      try await attachRelationships(for: film, on: database)
    }

    for person in snapshot.people {
      try await attachRelationships(for: person, on: database)
    }

    for species in snapshot.species {
      try await attachRelationships(for: species, on: database)
    }

    for starship in snapshot.starships {
      try await attachRelationships(for: starship, on: database)
    }

    for vehicle in snapshot.vehicles {
      try await attachRelationships(for: vehicle, on: database)
    }
  }

  private func attachRelationships(for film: FilmResponse, on database: any Database) async throws {
    guard let filmModel = try await Film.find(film.url, on: database) else { return }

    if !film.characters.isEmpty {
      let people = try await Person.query(on: database).filter(\.$id ~~ film.characters).all()
      try await filmModel.$characters.attach(people, on: database)
    }

    if !film.planets.isEmpty {
      let planets = try await Planet.query(on: database).filter(\.$id ~~ film.planets).all()
      try await filmModel.$planets.attach(planets, on: database)
    }

    if !film.species.isEmpty {
      let species = try await Species.query(on: database).filter(\.$id ~~ film.species).all()
      try await filmModel.$species.attach(species, on: database)
    }

    if !film.starships.isEmpty {
      let starships = try await Starship.query(on: database).filter(\.$id ~~ film.starships).all()
      try await filmModel.$starships.attach(starships, on: database)
    }

    if !film.vehicles.isEmpty {
      let vehicles = try await Vehicle.query(on: database).filter(\.$id ~~ film.vehicles).all()
      try await filmModel.$vehicles.attach(vehicles, on: database)
    }
  }

  private func attachRelationships(
    for person: PersonResponse, on database: any Database
  ) async throws {
    guard let personModel = try await Person.find(person.url, on: database) else { return }

    if !person.species.isEmpty {
      let species = try await Species.query(on: database).filter(\.$id ~~ person.species).all()
      try await personModel.$species.attach(species, on: database)
    }

    if !person.starships.isEmpty {
      let starships = try await Starship.query(on: database).filter(\.$id ~~ person.starships).all()
      try await personModel.$starships.attach(starships, on: database)
    }

    if !person.vehicles.isEmpty {
      let vehicles = try await Vehicle.query(on: database).filter(\.$id ~~ person.vehicles).all()
      try await personModel.$vehicles.attach(vehicles, on: database)
    }
  }

  private func attachRelationships(
    for species: SpeciesResponse, on database: any Database
  ) async throws {
    guard let speciesModel = try await Species.find(species.url, on: database) else { return }

    if let homeworld = species.homeworld {
      speciesModel.$homeworld.id = homeworld
      try await speciesModel.save(on: database)
    }
  }

  private func attachRelationships(
    for starship: StarshipResponse, on database: any Database
  ) async throws {
    guard let starshipModel = try await Starship.find(starship.url, on: database) else { return }

    if !starship.pilots.isEmpty {
      let pilots = try await Person.query(on: database).filter(\.$id ~~ starship.pilots).all()
      try await starshipModel.$pilots.attach(pilots, on: database)
    }
  }

  private func attachRelationships(
    for vehicle: VehicleResponse, on database: any Database
  ) async throws {
    guard let vehicleModel = try await Vehicle.find(vehicle.url, on: database) else { return }

    if !vehicle.pilots.isEmpty {
      let pilots = try await Person.query(on: database).filter(\.$id ~~ vehicle.pilots).all()
      try await vehicleModel.$pilots.attach(pilots, on: database)
    }
  }
}

enum FluentPersistenceError: Error {
  case databaseNotConfigured
  case databaseAlreadyConfigured
  case databaseUnavailable
}

extension FluentPersistenceContainer {
  fileprivate func withDatabase<T>(
    _ operation: @escaping @Sendable (any Database) async throws -> T
  ) async throws -> T {
    guard configuration != nil else {
      throw FluentPersistenceError.databaseNotConfigured
    }

    guard
      let database = databases.database(
        databaseID,
        logger: logger,
        on: eventLoopGroup.next()
      )
    else {
      throw FluentPersistenceError.databaseUnavailable
    }

    return try await operation(database)
  }

  fileprivate func runInTransaction(
    on database: any Database, _ body: @escaping @Sendable (any Database) async throws -> Void
  ) async throws {
    try await database.transaction { transaction in
      transaction.eventLoop.makeFutureWithTask {
        try await body(transaction)
      }
    }.value()
  }
}

extension EventLoopFuture where Value: Sendable {
  fileprivate func value() async throws -> Value {
    try await withCheckedThrowingContinuation { continuation in
      self.whenComplete { result in
        switch result {
        case .success(let value):
          continuation.resume(returning: value)
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
}
