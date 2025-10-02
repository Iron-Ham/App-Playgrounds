import API
import Fluent
import FluentSQLiteDriver
import Foundation
import Logging
import NIO

@MainActor
final class PersistenceContainer {
  private struct ConfigurationState {
    var sqliteConfiguration: SQLiteConfiguration
    var loggingLevel: Logger.Level
  }

  let databases: Databases
  let migrations: Migrations
  private let databaseID: DatabaseID
  private let eventLoopGroup: any EventLoopGroup
  private let threadPool: NIOThreadPool
  private var logger = Logger(label: "dev.iron-ham.Persistence")

  private var migrator: Migrator?
  private var configuration: ConfigurationState?

  private let changeStreamContinuation: AsyncStream<PersistenceService.ChangeBatch>.Continuation

  let changeStream: AsyncStream<PersistenceService.ChangeBatch>

  init(eventLoopGroup: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)) {
    self.eventLoopGroup = eventLoopGroup
    self.threadPool = NIOThreadPool(numberOfThreads: 2)
    self.threadPool.start()
    self.databases = Databases(threadPool: threadPool, on: eventLoopGroup)
    self.migrations = Migrations()
    self.databaseID = .sqlite

    var continuation: AsyncStream<PersistenceService.ChangeBatch>.Continuation!
    self.changeStream = AsyncStream { continuation = $0 }
    self.changeStreamContinuation = continuation

    self.changeStreamContinuation.onTermination = { [weak self] _ in
      self?.changeStreamContinuation.finish()
    }
  }

  deinit {
    changeStreamContinuation.finish()
  }

  func configure(_ configuration: PersistenceConfiguration) async throws {
    guard self.configuration == nil else {
      throw PersistenceError.databaseAlreadyConfigured
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

  func importSnapshot(_ snapshot: PersistenceService.Snapshot) async throws {
    guard configuration != nil else {
      throw PersistenceError.databaseNotConfigured
    }

    guard
      let database = databases.database(
        databaseID,
        logger: logger,
        on: eventLoopGroup.next()
      )
    else {
      throw PersistenceError.databaseUnavailable
    }

    try await runInTransaction(on: database) { transaction in
      try await self.clearExistingData(on: transaction)
      try await self.seedEntities(from: snapshot, on: transaction)
      try await self.seedRelationships(from: snapshot, on: transaction)
    }

    emitChanges(for: snapshot)
  }

  func observeChanges() -> AsyncStream<PersistenceService.ChangeBatch> {
    changeStream
  }

  func filmsOrderedByReleaseDate() async throws -> [PersistenceService.FilmDetails] {
    try await withDatabase { database in
      try await Film.query(on: database)
        .sort(\.$releaseDate, .ascending)
        .sort(\.$episodeID, .ascending)
        .sort(\.$title, .ascending)
        .all()
        .map { film in
          PersistenceService.FilmDetails(
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
  ) async throws -> PersistenceService.FilmRelationshipSummary {
    try await withDatabase { database in
      return PersistenceService.FilmRelationshipSummary(
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
    relationship: PersistenceService.Relationship
  ) async throws -> [PersistenceService.RelationshipEntity] {
    try await withDatabase { database in
      guard let film = try await Film.find(filmURL, on: database) else { return [] }
      switch relationship {
      case .characters:
        let people = try await film.$characters
          .query(on: database)
          .with(\.$homeworld)
          .with(\.$species) { species in
            species
              .with(\.$homeworld)
              .with(\.$films)
          }
          .with(\.$starships)
          .with(\.$vehicles)
          .with(\.$films)
          .sort(\.$name, .ascending)
          .all()
        return people.map { person in
          .character(
            Self.characterDetails(from: person)
          )
        }

      case .planets:
        let planets = try await film.$planets
          .query(on: database)
          .sort(\.$name, .ascending)
          .all()
        return planets.map { planet in
          .planet(
            Self.planetDetails(from: planet)
          )
        }

      case .species:
        let species = try await film.$species
          .query(on: database)
          .with(\.$homeworld)
          .with(\.$films)
          .sort(\.$name, .ascending)
          .all()
        return species.map { species in
          .species(
            Self.speciesDetails(from: species)
          )
        }

      case .starships:
        let starships = try await film.$starships
          .query(on: database)
          .sort(\.$name, .ascending)
          .all()
        return starships.map { starship in
          .starship(
            Self.starshipDetails(from: starship)
          )
        }

      case .vehicles:
        let vehicles = try await film.$vehicles
          .query(on: database)
          .sort(\.$name, .ascending)
          .all()
        return vehicles.map { vehicle in
          .vehicle(
            Self.vehicleDetails(from: vehicle)
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

extension PersistenceContainer {
  private func emitChanges(for snapshot: PersistenceService.Snapshot) {
    let changedEntities: [PersistenceService.ChangeBatch.Entity] = [
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
    from snapshot: PersistenceService.Snapshot, on database: any Database
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
    from snapshot: PersistenceService.Snapshot, on database: any Database
  ) async throws {
    var attachedPersonSpecies: Set<RelationshipPair> = []
    var attachedPersonStarships: Set<RelationshipPair> = []
    var attachedPersonVehicles: Set<RelationshipPair> = []

    for film in snapshot.films {
      try await attachRelationships(for: film, on: database)
    }

    for person in snapshot.people {
      try await attachRelationships(
        for: person,
        on: database,
        attachedSpecies: &attachedPersonSpecies,
        attachedStarships: &attachedPersonStarships,
        attachedVehicles: &attachedPersonVehicles
      )
    }

    for species in snapshot.species {
      try await attachRelationships(for: species, on: database)
    }

    for starship in snapshot.starships {
      try await attachRelationships(
        for: starship,
        on: database,
        attachedPilots: &attachedPersonStarships
      )
    }

    for vehicle in snapshot.vehicles {
      try await attachRelationships(
        for: vehicle,
        on: database,
        attachedPilots: &attachedPersonVehicles
      )
    }
  }

  private func attachRelationships(for film: FilmResponse, on database: any Database) async throws {
    guard let filmModel = try await Film.find(film.url, on: database) else { return }

    let characterIDs = uniqueOrderedURLs(film.characters)
    if !characterIDs.isEmpty {
      let people = try await Person.query(on: database).filter(\.$id ~~ characterIDs).all()
      try await filmModel.$characters.attach(people, on: database)
    }

    let planetIDs = uniqueOrderedURLs(film.planets)
    if !planetIDs.isEmpty {
      let planets = try await Planet.query(on: database).filter(\.$id ~~ planetIDs).all()
      try await filmModel.$planets.attach(planets, on: database)
    }

    let speciesIDs = uniqueOrderedURLs(film.species)
    if !speciesIDs.isEmpty {
      let species = try await Species.query(on: database).filter(\.$id ~~ speciesIDs).all()
      try await filmModel.$species.attach(species, on: database)
    }

    let starshipIDs = uniqueOrderedURLs(film.starships)
    if !starshipIDs.isEmpty {
      let starships = try await Starship.query(on: database).filter(\.$id ~~ starshipIDs).all()
      try await filmModel.$starships.attach(starships, on: database)
    }

    let vehicleIDs = uniqueOrderedURLs(film.vehicles)
    if !vehicleIDs.isEmpty {
      let vehicles = try await Vehicle.query(on: database).filter(\.$id ~~ vehicleIDs).all()
      try await filmModel.$vehicles.attach(vehicles, on: database)
    }
  }

  private func attachRelationships(
    for person: PersonResponse,
    on database: any Database,
    attachedSpecies: inout Set<RelationshipPair>,
    attachedStarships: inout Set<RelationshipPair>,
    attachedVehicles: inout Set<RelationshipPair>
  ) async throws {
    guard let personModel = try await Person.find(person.url, on: database) else { return }

    let speciesIDs = uniqueOrderedURLs(person.species)
    if !speciesIDs.isEmpty {
      let species = try await Species.query(on: database).filter(\.$id ~~ speciesIDs).all()
      let newSpecies = species.filter { species in
        let pair = RelationshipPair(first: person.url, second: species.url)
        return attachedSpecies.insert(pair).inserted
      }
      if !newSpecies.isEmpty {
        try await personModel.$species.attach(newSpecies, on: database)
      }
    }

    let starshipIDs = uniqueOrderedURLs(person.starships)
    if !starshipIDs.isEmpty {
      let starships = try await Starship.query(on: database).filter(\.$id ~~ starshipIDs).all()
      let newStarships = starships.filter { starship in
        let pair = RelationshipPair(first: person.url, second: starship.url)
        return attachedStarships.insert(pair).inserted
      }
      if !newStarships.isEmpty {
        try await personModel.$starships.attach(newStarships, on: database)
      }
    }

    let vehicleIDs = uniqueOrderedURLs(person.vehicles)
    if !vehicleIDs.isEmpty {
      let vehicles = try await Vehicle.query(on: database).filter(\.$id ~~ vehicleIDs).all()
      let newVehicles = vehicles.filter { vehicle in
        let pair = RelationshipPair(first: person.url, second: vehicle.url)
        return attachedVehicles.insert(pair).inserted
      }
      if !newVehicles.isEmpty {
        try await personModel.$vehicles.attach(newVehicles, on: database)
      }
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
    for starship: StarshipResponse,
    on database: any Database,
    attachedPilots: inout Set<RelationshipPair>
  ) async throws {
    guard let starshipModel = try await Starship.find(starship.url, on: database) else { return }

    let pilotIDs = uniqueOrderedURLs(starship.pilots)
    guard !pilotIDs.isEmpty else { return }

    let pendingPilotIDs = pilotIDs.filter { pilotURL in
      let pair = RelationshipPair(first: pilotURL, second: starship.url)
      return !attachedPilots.contains(pair)
    }

    guard !pendingPilotIDs.isEmpty else { return }

    let pilots = try await Person.query(on: database).filter(\.$id ~~ pendingPilotIDs).all()
    let pilotsToAttach = pilots.filter { pilot in
      let pair = RelationshipPair(first: pilot.url, second: starship.url)
      return attachedPilots.insert(pair).inserted
    }

    if !pilotsToAttach.isEmpty {
      try await starshipModel.$pilots.attach(pilotsToAttach, on: database)
    }
  }

  private func attachRelationships(
    for vehicle: VehicleResponse,
    on database: any Database,
    attachedPilots: inout Set<RelationshipPair>
  ) async throws {
    guard let vehicleModel = try await Vehicle.find(vehicle.url, on: database) else { return }

    let pilotIDs = uniqueOrderedURLs(vehicle.pilots)
    guard !pilotIDs.isEmpty else { return }

    let pendingPilotIDs = pilotIDs.filter { pilotURL in
      let pair = RelationshipPair(first: pilotURL, second: vehicle.url)
      return !attachedPilots.contains(pair)
    }

    guard !pendingPilotIDs.isEmpty else { return }

    let pilots = try await Person.query(on: database).filter(\.$id ~~ pendingPilotIDs).all()
    let pilotsToAttach = pilots.filter { pilot in
      let pair = RelationshipPair(first: pilot.url, second: vehicle.url)
      return attachedPilots.insert(pair).inserted
    }

    if !pilotsToAttach.isEmpty {
      try await vehicleModel.$pilots.attach(pilotsToAttach, on: database)
    }
  }
}

private func uniqueOrderedURLs(_ urls: [URL]) -> [URL] {
  var seen: Set<URL> = []
  var ordered: [URL] = []

  for url in urls where seen.insert(url).inserted {
    ordered.append(url)
  }

  return ordered
}

private struct RelationshipPair: Hashable {
  let first: URL
  let second: URL
}

enum PersistenceError: Error {
  case databaseNotConfigured
  case databaseAlreadyConfigured
  case databaseUnavailable
}

extension PersistenceContainer {
  fileprivate nonisolated static func characterDetails(
    from person: Person
  )
    -> PersistenceService.CharacterDetails
  {
    let homeworld: PersistenceService.PlanetDetails?
    if let homeworldModel = person.$homeworld.value, let planet = homeworldModel {
      homeworld = Self.planetDetails(from: planet)
    } else {
      homeworld = nil
    }

    let speciesDetailsList = person.species
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
      .map { Self.speciesDetails(from: $0) }

    let starshipDetailList = person.starships
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
      .map { Self.starshipDetails(from: $0) }

    let vehicleDetailList = person.vehicles
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
      .map { Self.vehicleDetails(from: $0) }

    let filmSummariesList = Self.filmSummaries(from: person.films)

    return .init(
      id: person.url,
      name: person.name,
      gender: person.gender,
      birthYear: person.birthYear,
      height: person.height,
      mass: person.mass,
      hairColors: person.hairColors,
      skinColors: person.skinColors,
      eyeColors: person.eyeColors,
      homeworld: homeworld,
      species: speciesDetailsList,
      starships: starshipDetailList,
      vehicles: vehicleDetailList,
      films: filmSummariesList
    )
  }

  fileprivate nonisolated static func planetDetails(
    from planet: Planet
  )
    -> PersistenceService.PlanetDetails
  {
    .init(
      id: planet.url,
      name: planet.name,
      climates: planet.climates,
      population: planet.population,
      rotationPeriod: planet.rotationPeriod,
      orbitalPeriod: planet.orbitalPeriod,
      diameter: planet.diameter,
      gravityLevels: planet.gravityLevels,
      terrains: planet.terrains,
      surfaceWater: planet.surfaceWater
    )
  }

  fileprivate nonisolated static func speciesDetails(
    from species: Species
  )
    -> PersistenceService.SpeciesDetails
  {
    let homeworld: PersistenceService.PlanetDetails?
    if let homeworldModel = species.$homeworld.value, let planet = homeworldModel {
      homeworld = Self.planetDetails(from: planet)
    } else {
      homeworld = nil
    }
    let films = Self.filmSummaries(from: species.films)

    return .init(
      id: species.url,
      name: species.name,
      classification: species.classification,
      designation: species.designation,
      averageHeight: species.averageHeight,
      averageLifespan: species.averageLifespan,
      skinColors: species.skinColor,
      hairColors: species.hairColor,
      eyeColors: species.eyeColor,
      homeworld: homeworld,
      language: species.language,
      films: films
    )
  }

  fileprivate nonisolated static func starshipDetails(
    from starship: Starship
  )
    -> PersistenceService.StarshipDetails
  {
    .init(
      id: starship.url,
      name: starship.name,
      model: starship.model,
      starshipClass: starship.starshipClass
    )
  }

  fileprivate nonisolated static func vehicleDetails(
    from vehicle: Vehicle
  )
    -> PersistenceService.VehicleDetails
  {
    .init(
      id: vehicle.url,
      name: vehicle.name,
      model: vehicle.model,
      vehicleClass: vehicle.vehicleClass
    )
  }

  fileprivate nonisolated static func filmSummaries(
    from films: [Film]
  ) -> [PersistenceService.FilmSummary] {
    films
      .sorted { Self.filmSort(lhs: $0, rhs: $1) }
      .map { Self.filmSummary(from: $0) }
  }

  fileprivate nonisolated static func filmSummary(
    from film: Film
  ) -> PersistenceService.FilmSummary {
    .init(
      id: film.url,
      title: film.title,
      episodeId: film.episodeID,
      releaseDate: film.releaseDate
    )
  }

  fileprivate nonisolated static func filmSort(lhs: Film, rhs: Film) -> Bool {
    switch (lhs.releaseDate, rhs.releaseDate) {
    case (let lhsDate?, let rhsDate?) where lhsDate != rhsDate:
      return lhsDate < rhsDate
    case (nil, .some):
      return false
    case (.some, nil):
      return true
    default:
      break
    }

    if lhs.episodeID != rhs.episodeID {
      return lhs.episodeID < rhs.episodeID
    }

    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
  }
}

extension PersistenceContainer {
  fileprivate func withDatabase<T>(
    _ operation: @escaping @Sendable (any Database) async throws -> T
  ) async throws -> T {
    guard configuration != nil else {
      throw PersistenceError.databaseNotConfigured
    }

    guard
      let database = databases.database(
        databaseID,
        logger: logger,
        on: eventLoopGroup.next()
      )
    else {
      throw PersistenceError.databaseUnavailable
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
