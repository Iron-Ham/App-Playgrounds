import Foundation
import SwiftData
import API

public final class SnapshotImporter {
  public let context: ModelContext

  public init(context: ModelContext) {
    self.context = context
  }

  public func importSnapshot(
    films: [FilmResponse],
    people: [PersonResponse],
    planets: [PlanetResponse],
    species: [SpeciesResponse],
    starships: [StarshipResponse],
    vehicles: [VehicleResponse],
    persist: Bool = true
  ) throws {
    let filmEntities = try upsertFilms(films)
    let planetEntities = try upsertPlanets(planets)
    let speciesEntities = try upsertSpecies(species)
    let starshipEntities = try upsertStarships(starships)
    let vehicleEntities = try upsertVehicles(vehicles)
    let personEntities = try upsertPeople(people)

    linkPeople(people, people: personEntities, planets: planetEntities, films: filmEntities, species: speciesEntities, starships: starshipEntities, vehicles: vehicleEntities)
    linkFilms(films, films: filmEntities, people: personEntities, planets: planetEntities, species: speciesEntities, starships: starshipEntities, vehicles: vehicleEntities)
    linkPlanets(planets, planets: planetEntities, people: personEntities, films: filmEntities)
    linkSpecies(species, species: speciesEntities, people: personEntities, films: filmEntities, planets: planetEntities)
    linkStarships(starships, starships: starshipEntities, people: personEntities, films: filmEntities)
    linkVehicles(vehicles, vehicles: vehicleEntities, people: personEntities, films: filmEntities)

    if persist, context.hasChanges {
      try context.save()
    }
  }

  private func upsertFilms(_ responses: [FilmResponse]) throws -> [URL: FilmEntity] {
    var map: [URL: FilmEntity] = [:]
    for response in responses {
      let entity = try fetchFilm(response.url)
        ?? FilmEntity(
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
      if entity.modelContext == nil {
        context.insert(entity)
      }
      entity.apply(response: response)
      map[entity.url] = entity
    }
    return map
  }

  private func upsertPeople(_ responses: [PersonResponse]) throws -> [URL: PersonEntity] {
    var map: [URL: PersonEntity] = [:]
    for response in responses {
      let entity = try fetchPerson(response.url)
        ?? PersonEntity(
          url: response.url,
          name: response.name,
          heightRaw: response.height,
          massRaw: response.mass,
          heightInCentimeters: response.heightInCentimeters,
          massInKilograms: response.massInKilograms,
          hairColorValues: response.hairColors.map(\.rawValue),
          skinColorValues: response.skinColors.map(\.rawValue),
          eyeColorValues: response.eyeColors.map(\.rawValue),
          birthYearRaw: response.birthYear.rawValue,
          genderRaw: response.gender.rawValue,
          created: response.created,
          edited: response.edited
        )
      if entity.modelContext == nil {
        context.insert(entity)
      }
      entity.apply(response: response)
      map[entity.url] = entity
    }
    return map
  }

  private func upsertPlanets(_ responses: [PlanetResponse]) throws -> [URL: PlanetEntity] {
    var map: [URL: PlanetEntity] = [:]
    for response in responses {
      let entity = try fetchPlanet(response.url)
        ?? PlanetEntity(
          url: response.url,
          name: response.name,
          rotationPeriodRaw: response.rotationPeriod,
          rotationPeriodInHours: response.rotationPeriodInHours,
          orbitalPeriodRaw: response.orbitalPeriod,
          orbitalPeriodInDays: response.orbitalPeriodInDays,
          diameterRaw: response.diameter,
          diameterInKilometers: response.diameterInKilometers,
          climateValues: response.climates.map(\.rawValue),
          gravityValues: response.gravityLevels.map(\.rawValue),
          terrainValues: response.terrains.map(\.rawValue),
          surfaceWaterRaw: response.surfaceWater,
          surfaceWaterPercentage: response.surfaceWaterPercentage,
          populationRaw: response.population,
          populationCount: response.populationCount,
          created: response.created,
          edited: response.edited
        )
      if entity.modelContext == nil {
        context.insert(entity)
      }
      entity.apply(response: response)
      map[entity.url] = entity
    }
    return map
  }

  private func upsertSpecies(_ responses: [SpeciesResponse]) throws -> [URL: SpeciesEntity] {
    var map: [URL: SpeciesEntity] = [:]
    for response in responses {
      let entity = try fetchSpecies(response.url)
        ?? SpeciesEntity(
          url: response.url,
          name: response.name,
          classification: response.classification,
          designation: response.designation,
          averageHeightRaw: response.averageHeight,
          averageHeightInCentimeters: response.averageHeightInCentimeters,
          averageHeightInMeters: response.averageHeightInMeters,
          averageLifespanRaw: response.averageLifespan,
          averageLifespanInYears: response.averageLifespanInYears,
          skinColorValues: response.skinColor.map(\.rawValue),
          hairColorValues: response.hairColor.map(\.rawValue),
          eyeColorValues: response.eyeColor.map(\.rawValue),
          language: response.language,
          created: response.created,
          edited: response.edited
        )
      if entity.modelContext == nil {
        context.insert(entity)
      }
      entity.apply(response: response)
      map[entity.url] = entity
    }
    return map
  }

  private func upsertStarships(_ responses: [StarshipResponse]) throws -> [URL: StarshipEntity] {
    var map: [URL: StarshipEntity] = [:]
    for response in responses {
      let entity = try fetchStarship(response.url)
        ?? StarshipEntity(
          url: response.url,
          name: response.name,
          model: response.model,
          manufacturerValues: response.manufacturers.map(\.rawName),
          costInCreditsRaw: response.costInCredits,
          costInCreditsValue: response.costInCreditsValue,
          lengthRaw: response.length,
          lengthInMeters: response.lengthInMeters,
          maxAtmospheringSpeedRaw: response.maxAtmospheringSpeed,
          maxAtmospheringSpeedValue: response.maxAtmospheringSpeedValue,
          crewRaw: response.crew,
          crewCount: response.crewCount,
          passengersRaw: response.passengers,
          passengerCapacity: response.passengerCapacity,
          cargoCapacityRaw: response.cargoCapacity,
          cargoCapacityInKilograms: response.cargoCapacityInKilograms,
          consumables: response.consumables,
          hyperdriveRatingRaw: response.hyperdriveRating,
          hyperdriveRatingValue: response.hyperdriveRatingValue,
          mgltRaw: response.mglt,
          mgltValue: response.mgltValue,
          starshipClass: response.starshipClass,
          created: response.created,
          edited: response.edited
        )
      if entity.modelContext == nil {
        context.insert(entity)
      }
      entity.apply(response: response)
      map[entity.url] = entity
    }
    return map
  }

  private func upsertVehicles(_ responses: [VehicleResponse]) throws -> [URL: VehicleEntity] {
    var map: [URL: VehicleEntity] = [:]
    for response in responses {
      let entity = try fetchVehicle(response.url)
        ?? VehicleEntity(
          url: response.url,
          name: response.name,
          model: response.model,
          manufacturerValues: response.manufacturers.map(\.rawName),
          costInCreditsRaw: response.costInCredits,
          costInCreditsValue: response.costInCreditsValue,
          lengthRaw: response.length,
          lengthInMeters: response.lengthInMeters,
          maxAtmospheringSpeedRaw: response.maxAtmospheringSpeed,
          maxAtmospheringSpeedValue: response.maxAtmospheringSpeedValue,
          crewRaw: response.crew,
          crewCount: response.crewCount,
          passengersRaw: response.passengers,
          passengerCapacity: response.passengerCapacity,
          cargoCapacityRaw: response.cargoCapacity,
          cargoCapacityInKilograms: response.cargoCapacityInKilograms,
          consumables: response.consumables,
          vehicleClassRaw: response.vehicleClass.rawValue,
          created: response.created,
          edited: response.edited
        )
      if entity.modelContext == nil {
        context.insert(entity)
      }
      entity.apply(response: response)
      map[entity.url] = entity
    }
    return map
  }

  private func fetchFilm(_ url: URL) throws -> FilmEntity? {
    try context.fetch(FetchDescriptor<FilmEntity>(predicate: #Predicate { $0.url == url })).first
  }

  private func fetchPerson(_ url: URL) throws -> PersonEntity? {
    try context.fetch(FetchDescriptor<PersonEntity>(predicate: #Predicate { $0.url == url })).first
  }

  private func fetchPlanet(_ url: URL) throws -> PlanetEntity? {
    try context.fetch(FetchDescriptor<PlanetEntity>(predicate: #Predicate { $0.url == url })).first
  }

  private func fetchSpecies(_ url: URL) throws -> SpeciesEntity? {
    try context.fetch(FetchDescriptor<SpeciesEntity>(predicate: #Predicate { $0.url == url })).first
  }

  private func fetchStarship(_ url: URL) throws -> StarshipEntity? {
    try context.fetch(FetchDescriptor<StarshipEntity>(predicate: #Predicate { $0.url == url })).first
  }

  private func fetchVehicle(_ url: URL) throws -> VehicleEntity? {
    try context.fetch(FetchDescriptor<VehicleEntity>(predicate: #Predicate { $0.url == url })).first
  }

  private func linkPeople(
    _ responses: [PersonResponse],
    people: [URL: PersonEntity],
    planets: [URL: PlanetEntity],
    films: [URL: FilmEntity],
    species: [URL: SpeciesEntity],
    starships: [URL: StarshipEntity],
    vehicles: [URL: VehicleEntity]
  ) {
    for response in responses {
      guard let person = people[response.url] else { continue }
      person.homeworld = planets[response.homeworld]
      person.films = response.films.compactMap { films[$0] }
      person.species = response.species.compactMap { species[$0] }
      person.starships = response.starships.compactMap { starships[$0] }
      person.vehicles = response.vehicles.compactMap { vehicles[$0] }
    }
  }

  private func linkFilms(
    _ responses: [FilmResponse],
    films: [URL: FilmEntity],
    people: [URL: PersonEntity],
    planets: [URL: PlanetEntity],
    species: [URL: SpeciesEntity],
    starships: [URL: StarshipEntity],
    vehicles: [URL: VehicleEntity]
  ) {
    for response in responses {
      guard let film = films[response.url] else { continue }
      film.characters = response.characters.compactMap { people[$0] }
      film.planets = response.planets.compactMap { planets[$0] }
      film.species = response.species.compactMap { species[$0] }
      film.starships = response.starships.compactMap { starships[$0] }
      film.vehicles = response.vehicles.compactMap { vehicles[$0] }
    }
  }

  private func linkPlanets(
    _ responses: [PlanetResponse],
    planets: [URL: PlanetEntity],
    people: [URL: PersonEntity],
    films: [URL: FilmEntity]
  ) {
    for response in responses {
      guard let planet = planets[response.url] else { continue }
      planet.residents = response.residents.compactMap { people[$0] }
      planet.films = response.films.compactMap { films[$0] }
    }
  }

  private func linkSpecies(
    _ responses: [SpeciesResponse],
    species: [URL: SpeciesEntity],
    people: [URL: PersonEntity],
    films: [URL: FilmEntity],
    planets: [URL: PlanetEntity]
  ) {
    for response in responses {
      guard let entity = species[response.url] else { continue }
      entity.people = response.people.compactMap { people[$0] }
      entity.films = response.films.compactMap { films[$0] }
      if let homeworld = response.homeworld {
        entity.homeworld = planets[homeworld]
      } else {
        entity.homeworld = nil
      }
    }
  }

  private func linkStarships(
    _ responses: [StarshipResponse],
    starships: [URL: StarshipEntity],
    people: [URL: PersonEntity],
    films: [URL: FilmEntity]
  ) {
    for response in responses {
      guard let entity = starships[response.url] else { continue }
      entity.pilots = response.pilots.compactMap { people[$0] }
      entity.films = response.films.compactMap { films[$0] }
    }
  }

  private func linkVehicles(
    _ responses: [VehicleResponse],
    vehicles: [URL: VehicleEntity],
    people: [URL: PersonEntity],
    films: [URL: FilmEntity]
  ) {
    for response in responses {
      guard let entity = vehicles[response.url] else { continue }
      entity.pilots = response.pilots.compactMap { people[$0] }
      entity.films = response.films.compactMap { films[$0] }
    }
  }
}
