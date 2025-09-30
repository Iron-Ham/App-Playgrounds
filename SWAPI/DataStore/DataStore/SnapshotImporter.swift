import API
import Foundation
import GRDB
import SQLiteData
import StructuredQueriesCore

public struct SnapshotImporter {
  private let database: any DatabaseWriter

  public init(database: any DatabaseWriter) {
    self.database = database
  }

  public func importSnapshot(
    films: [FilmResponse],
    people: [PersonResponse],
    planets: [PlanetResponse],
    species: [SpeciesResponse],
    starships: [StarshipResponse],
    vehicles: [VehicleResponse]
  ) throws {
    try database.write { db in
      try clearExistingData(db)
      try importPlanets(planets, db: db)
      try importSpecies(species, db: db)
      try importFilms(films, db: db)
      try importPeople(people, db: db)
      try importStarships(starships, db: db)
      try importVehicles(vehicles, db: db)
      try importRelationships(
        films: films,
        people: people,
        planets: planets,
        species: species,
        starships: starships,
        vehicles: vehicles,
        db: db
      )
    }
  }

  private func importFilms(_ films: [FilmResponse], db: Database) throws {
    guard !films.isEmpty else { return }
    try db.seed {
      for film in films {
        Film(from: film)
      }
    }
  }

  private func importPlanets(_ planets: [PlanetResponse], db: Database) throws {
    guard !planets.isEmpty else { return }
    try db.seed {
      for planet in planets {
        Planet(from: planet)
      }
    }
  }

  private func importPeople(_ people: [PersonResponse], db: Database) throws {
    guard !people.isEmpty else { return }
    try db.seed {
      for person in people {
        Person(from: person)
      }
    }
  }

  private func importSpecies(_ species: [SpeciesResponse], db: Database) throws {
    guard !species.isEmpty else { return }
    try db.seed {
      for species in species {
        Species(from: species)
      }
    }
  }

  private func importStarships(_ starships: [StarshipResponse], db: Database) throws {
    guard !starships.isEmpty else { return }
    try db.seed {
      for starship in starships {
        Starship(from: starship)
      }
    }
  }

  private func importVehicles(_ vehicles: [VehicleResponse], db: Database) throws {
    guard !vehicles.isEmpty else { return }
    try db.seed {
      for vehicle in vehicles {
        Vehicle(from: vehicle)
      }
    }
  }

  private func importRelationships(
    films: [FilmResponse],
    people: [PersonResponse],
    planets: [PlanetResponse],
    species: [SpeciesResponse],
    starships: [StarshipResponse],
    vehicles: [VehicleResponse],
    db: Database
  ) throws {
    try seed(
      films.flatMap { film in
        film.characters.map { FilmCharacter(film: film.url, person: $0) }
      },
      db: db
    )

    try seed(
      films.flatMap { film in
        film.planets.map { FilmPlanet(film: film.url, planet: $0) }
      },
      db: db
    )

    try seed(
      films.flatMap { film in
        film.species.map { FilmSpecies(film: film.url, species: $0) }
      },
      db: db
    )

    try seed(
      films.flatMap { film in
        film.starships.map { FilmStarship(film: film.url, starship: $0) }
      },
      db: db
    )

    try seed(
      films.flatMap { film in
        film.vehicles.map { FilmVehicle(film: film.url, vehicle: $0) }
      },
      db: db
    )

    try seed(
      people.flatMap { person in
        person.species.map { PersonSpecies(person: person.url, species: $0) }
      },
      db: db
    )

    try seed(
      starships.flatMap { starship in
        starship.pilots.map { PersonStarship(person: $0, starship: starship.url) }
      },
      db: db
    )

    try seed(
      vehicles.flatMap { vehicle in
        vehicle.pilots.map { PersonVehicle(person: $0, vehicle: vehicle.url) }
      },
      db: db
    )
  }
}

extension SnapshotImporter {
  fileprivate func clearExistingData(_ db: Database) throws {
    let relationshipTables = [
      "filmCharacters",
      "filmPlanets",
      "filmSpecies",
      "filmStarships",
      "filmVehicles",
      "personSpecies",
      "personStarships",
      "personVehicles",
    ]

    let entityTables = [
      "films",
      "people",
      "planets",
      "species",
      "starships",
      "vehicles",
    ]

    for table in relationshipTables + entityTables {
      try db.execute(sql: "DELETE FROM \"\(table)\"")
    }
  }

  fileprivate func seed<Record>(
    _ records: [Record],
    db: Database
  ) throws where Record: StructuredQueriesCore.Table {
    guard !records.isEmpty else { return }
    try db.seed {
      for record in records {
        record
      }
    }
  }
}

extension Film {
  fileprivate init(from response: FilmResponse) {
    self.init(
      url: response.url,
      title: response.title,
      episodeID: response.episodeId,
      openingCrawl: response.openingCrawl,
      director: response.director,
      producerNames: response.producers,
      releaseDate: response.release,
      created: response.created,
      edited: response.edited
    )
  }
}

extension Planet {
  fileprivate init(from response: PlanetResponse) {
    self.init(
      url: response.url,
      name: response.name,
      rotationPeriod: response.rotationPeriod,
      orbitalPeriod: response.orbitalPeriod,
      diameter: response.diameter,
      climate: response.climates.map(\.displayName).joined(separator: ", "),
      gravity: response.gravityLevels.map(\.description).joined(separator: ", "),
      terrain: response.terrains.map(\.displayName).joined(separator: ", "),
      surfaceWater: response.surfaceWater,
      population: response.population,
      created: response.created,
      edited: response.edited
    )
  }
}

extension Person {
  fileprivate init(from response: PersonResponse) {
    self.init(
      url: response.url,
      name: response.name,
      height: response.height,
      mass: response.mass,
      hairColor: response.hairColors.map(\.displayName).joined(separator: ", "),
      skinColor: response.skinColors.map(\.displayName).joined(separator: ", "),
      eyeColor: response.eyeColors.map(\.displayName).joined(separator: ", "),
      birthYear: response.birthYear.rawValue,
      gender: response.gender.rawValue,
      homeworld: response.homeworld,
      created: response.created,
      edited: response.edited
    )
  }
}

extension Species {
  fileprivate init(from response: SpeciesResponse) {
    self.init(
      url: response.url,
      name: response.name,
      classification: response.classification,
      designation: response.designation,
      averageHeight: response.averageHeight,
      averageLifespan: response.averageLifespan,
      skinColors: response.skinColor.map(\.displayName).joined(separator: ", "),
      hairColors: response.hairColor.map(\.displayName).joined(separator: ", "),
      eyeColors: response.eyeColor.map(\.displayName).joined(separator: ", "),
      language: response.language,
      homeworld: response.homeworld,
      created: response.created,
      edited: response.edited
    )
  }
}

extension Starship {
  fileprivate init(from response: StarshipResponse) {
    self.init(
      url: response.url,
      name: response.name,
      model: response.model,
      manufacturer: response.manufacturers.map(\.displayName).joined(separator: ", "),
      costInCredits: response.costInCredits,
      length: response.length,
      maxAtmospheringSpeed: response.maxAtmospheringSpeed,
      crew: response.crew,
      passengers: response.passengers,
      cargoCapacity: response.cargoCapacity,
      consumables: response.consumables,
      hyperdriveRating: response.hyperdriveRating,
      mglt: response.mglt,
      starshipClass: response.starshipClass.displayName,
      created: response.created,
      edited: response.edited
    )
  }
}

extension Vehicle {
  fileprivate init(from response: VehicleResponse) {
    self.init(
      url: response.url,
      name: response.name,
      model: response.model,
      manufacturer: response.manufacturers.map(\.displayName).joined(separator: ", "),
      costInCredits: response.costInCredits,
      length: response.length,
      maxAtmospheringSpeed: response.maxAtmospheringSpeed,
      crew: response.crew,
      passengers: response.passengers,
      cargoCapacity: response.cargoCapacity,
      consumables: response.consumables,
      vehicleClass: response.vehicleClass.displayName,
      created: response.created,
      edited: response.edited
    )
  }
}
