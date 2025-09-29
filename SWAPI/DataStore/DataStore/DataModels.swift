import Foundation
import SwiftData
import API

@Model
public final class FilmEntity {
  @Attribute(.unique) public var url: URL
  public var title: String
  public var episodeID: Int
  public var openingCrawl: String
  public var director: String
  public var producerNames: [String]
  public var releaseDate: Date?
  public var created: Date
  public var edited: Date

  @Relationship(deleteRule: .nullify)
  public var characters: [PersonEntity] = []

  @Relationship(deleteRule: .nullify)
  public var planets: [PlanetEntity] = []

  @Relationship(deleteRule: .nullify)
  public var starships: [StarshipEntity] = []

  @Relationship(deleteRule: .nullify)
  public var vehicles: [VehicleEntity] = []

  @Relationship(deleteRule: .nullify)
  public var species: [SpeciesEntity] = []

  public init(
    url: URL,
    title: String,
    episodeID: Int,
    openingCrawl: String,
    director: String,
    producerNames: [String],
    releaseDate: Date?,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.title = title
    self.episodeID = episodeID
    self.openingCrawl = openingCrawl
    self.director = director
    self.producerNames = producerNames
    self.releaseDate = releaseDate
    self.created = created
    self.edited = edited
  }

  public func apply(response: FilmResponse) {
    title = response.title
    episodeID = response.episodeId
    openingCrawl = response.openingCrawl
    director = response.director
    producerNames = response.producers
    releaseDate = response.release
    created = response.created
    edited = response.edited
  }

  @Transient
  public var id: URL { url }
}

@Model
public final class PersonEntity {
  @Attribute(.unique) public var url: URL
  public var name: String
  public var heightRaw: String
  public var massRaw: String
  public var heightInCentimeters: Double?
  public var massInKilograms: Double?
  public var hairColorValues: [String]
  public var skinColorValues: [String]
  public var eyeColorValues: [String]
  public var birthYearRaw: String
  public var genderRaw: String
  public var created: Date
  public var edited: Date

  @Relationship(deleteRule: .nullify, inverse: \PlanetEntity.residents)
  public var homeworld: PlanetEntity?

  @Relationship(deleteRule: .nullify, inverse: \FilmEntity.characters)
  public var films: [FilmEntity] = []

  @Relationship(deleteRule: .nullify)
  public var species: [SpeciesEntity] = []

  @Relationship(deleteRule: .nullify)
  public var vehicles: [VehicleEntity] = []

  @Relationship(deleteRule: .nullify)
  public var starships: [StarshipEntity] = []

  public init(
    url: URL,
    name: String,
    heightRaw: String,
    massRaw: String,
    heightInCentimeters: Double?,
    massInKilograms: Double?,
    hairColorValues: [String],
    skinColorValues: [String],
    eyeColorValues: [String],
    birthYearRaw: String,
    genderRaw: String,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.name = name
    self.heightRaw = heightRaw
    self.massRaw = massRaw
    self.heightInCentimeters = heightInCentimeters
    self.massInKilograms = massInKilograms
    self.hairColorValues = hairColorValues
    self.skinColorValues = skinColorValues
    self.eyeColorValues = eyeColorValues
    self.birthYearRaw = birthYearRaw
    self.genderRaw = genderRaw
    self.created = created
    self.edited = edited
  }

  public func apply(response: PersonResponse) {
    name = response.name
    heightRaw = response.height
    massRaw = response.mass
    heightInCentimeters = response.heightInCentimeters
    massInKilograms = response.massInKilograms
    hairColorValues = response.hairColors.map(\.rawValue)
    skinColorValues = response.skinColors.map(\.rawValue)
    eyeColorValues = response.eyeColors.map(\.rawValue)
    birthYearRaw = response.birthYear.rawValue
    genderRaw = response.gender.rawValue
    created = response.created
    edited = response.edited
  }

  @Transient
  public var id: URL { url }

  @Transient
  public var hairColors: [ColorDescriptor] {
    get { hairColorValues.map { ColorDescriptor(rawValue: $0) } }
    set { hairColorValues = newValue.map(\.rawValue) }
  }

  @Transient
  public var skinColors: [ColorDescriptor] {
    get { skinColorValues.map { ColorDescriptor(rawValue: $0) } }
    set { skinColorValues = newValue.map(\.rawValue) }
  }

  @Transient
  public var eyeColors: [ColorDescriptor] {
    get { eyeColorValues.map { ColorDescriptor(rawValue: $0) } }
    set { eyeColorValues = newValue.map(\.rawValue) }
  }

  @Transient
  public var birthYear: PersonResponse.BirthYear {
    get { PersonResponse.BirthYear(rawValue: birthYearRaw) }
    set { birthYearRaw = newValue.rawValue }
  }

  @Transient
  public var gender: PersonResponse.Gender {
    get { PersonResponse.Gender(rawValue: genderRaw) }
    set { genderRaw = newValue.rawValue }
  }
}

@Model
public final class PlanetEntity {
  @Attribute(.unique) public var url: URL
  public var name: String
  public var rotationPeriodRaw: String
  public var rotationPeriodInHours: Int?
  public var orbitalPeriodRaw: String
  public var orbitalPeriodInDays: Int?
  public var diameterRaw: String
  public var diameterInKilometers: Int?
  public var climateValues: [String]
  public var gravityValues: [String]
  public var terrainValues: [String]
  public var surfaceWaterRaw: String
  public var surfaceWaterPercentage: Double?
  public var populationRaw: String
  public var populationCount: Int?
  public var created: Date
  public var edited: Date

  @Relationship(deleteRule: .nullify)
  public var residents: [PersonEntity] = []

  @Relationship(deleteRule: .nullify, inverse: \FilmEntity.planets)
  public var films: [FilmEntity] = []

  @Relationship(deleteRule: .nullify)
  public var nativeSpecies: [SpeciesEntity] = []

  public init(
    url: URL,
    name: String,
    rotationPeriodRaw: String,
    rotationPeriodInHours: Int?,
    orbitalPeriodRaw: String,
    orbitalPeriodInDays: Int?,
    diameterRaw: String,
    diameterInKilometers: Int?,
    climateValues: [String],
    gravityValues: [String],
    terrainValues: [String],
    surfaceWaterRaw: String,
    surfaceWaterPercentage: Double?,
    populationRaw: String,
    populationCount: Int?,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.name = name
    self.rotationPeriodRaw = rotationPeriodRaw
    self.rotationPeriodInHours = rotationPeriodInHours
    self.orbitalPeriodRaw = orbitalPeriodRaw
    self.orbitalPeriodInDays = orbitalPeriodInDays
    self.diameterRaw = diameterRaw
    self.diameterInKilometers = diameterInKilometers
    self.climateValues = climateValues
    self.gravityValues = gravityValues
    self.terrainValues = terrainValues
    self.surfaceWaterRaw = surfaceWaterRaw
    self.surfaceWaterPercentage = surfaceWaterPercentage
    self.populationRaw = populationRaw
    self.populationCount = populationCount
    self.created = created
    self.edited = edited
  }

  public func apply(response: PlanetResponse) {
    name = response.name
    rotationPeriodRaw = response.rotationPeriod
    rotationPeriodInHours = response.rotationPeriodInHours
    orbitalPeriodRaw = response.orbitalPeriod
    orbitalPeriodInDays = response.orbitalPeriodInDays
    diameterRaw = response.diameter
    diameterInKilometers = response.diameterInKilometers
    climateValues = response.climates.map(\.rawValue)
    gravityValues = response.gravityLevels.map(\.rawValue)
    terrainValues = response.terrains.map(\.rawValue)
    surfaceWaterRaw = response.surfaceWater
    surfaceWaterPercentage = response.surfaceWaterPercentage
    populationRaw = response.population
    populationCount = response.populationCount
    created = response.created
    edited = response.edited
  }

  @Transient
  public var id: URL { url }

  @Transient
  public var climates: [PlanetResponse.ClimateDescriptor] {
    get { climateValues.map { PlanetResponse.ClimateDescriptor(rawValue: $0) } }
    set { climateValues = newValue.map(\.rawValue) }
  }

  @Transient
  public var gravities: [PlanetResponse.GravityDescriptor] {
    get { gravityValues.map { PlanetResponse.GravityDescriptor(rawValue: $0) } }
    set { gravityValues = newValue.map(\.rawValue) }
  }

  @Transient
  public var terrains: [PlanetResponse.TerrainDescriptor] {
    get { terrainValues.map { PlanetResponse.TerrainDescriptor(rawValue: $0) } }
    set { terrainValues = newValue.map(\.rawValue) }
  }
}

@Model
public final class SpeciesEntity {
  @Attribute(.unique) public var url: URL
  public var name: String
  public var classification: String
  public var designation: String
  public var averageHeightRaw: String
  public var averageHeightInCentimeters: Double?
  public var averageHeightInMeters: Double?
  public var averageLifespanRaw: String
  public var averageLifespanInYears: Double?
  public var skinColorValues: [String]
  public var hairColorValues: [String]
  public var eyeColorValues: [String]
  public var language: String
  public var created: Date
  public var edited: Date

  @Relationship(deleteRule: .nullify, inverse: \PersonEntity.species)
  public var people: [PersonEntity] = []

  @Relationship(deleteRule: .nullify, inverse: \FilmEntity.species)
  public var films: [FilmEntity] = []

  @Relationship(deleteRule: .nullify, inverse: \PlanetEntity.nativeSpecies)
  public var homeworld: PlanetEntity?

  public init(
    url: URL,
    name: String,
    classification: String,
    designation: String,
    averageHeightRaw: String,
    averageHeightInCentimeters: Double?,
    averageHeightInMeters: Double?,
    averageLifespanRaw: String,
    averageLifespanInYears: Double?,
    skinColorValues: [String],
    hairColorValues: [String],
    eyeColorValues: [String],
    language: String,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.name = name
    self.classification = classification
    self.designation = designation
    self.averageHeightRaw = averageHeightRaw
    self.averageHeightInCentimeters = averageHeightInCentimeters
    self.averageHeightInMeters = averageHeightInMeters
    self.averageLifespanRaw = averageLifespanRaw
    self.averageLifespanInYears = averageLifespanInYears
    self.skinColorValues = skinColorValues
    self.hairColorValues = hairColorValues
    self.eyeColorValues = eyeColorValues
    self.language = language
    self.created = created
    self.edited = edited
  }

  public func apply(response: SpeciesResponse) {
    name = response.name
    classification = response.classification
    designation = response.designation
    averageHeightRaw = response.averageHeight
    averageHeightInCentimeters = response.averageHeightInCentimeters
    averageHeightInMeters = response.averageHeightInMeters
    averageLifespanRaw = response.averageLifespan
    averageLifespanInYears = response.averageLifespanInYears
    skinColorValues = response.skinColor.map(\.rawValue)
    hairColorValues = response.hairColor.map(\.rawValue)
    eyeColorValues = response.eyeColor.map(\.rawValue)
    language = response.language
    created = response.created
    edited = response.edited
  }

  @Transient
  public var id: URL { url }

  @Transient
  public var skinColors: [ColorDescriptor] {
    get { skinColorValues.map { ColorDescriptor(rawValue: $0) } }
    set { skinColorValues = newValue.map(\.rawValue) }
  }

  @Transient
  public var hairColors: [ColorDescriptor] {
    get { hairColorValues.map { ColorDescriptor(rawValue: $0) } }
    set { hairColorValues = newValue.map(\.rawValue) }
  }

  @Transient
  public var eyeColors: [ColorDescriptor] {
    get { eyeColorValues.map { ColorDescriptor(rawValue: $0) } }
    set { eyeColorValues = newValue.map(\.rawValue) }
  }
}

@Model
public final class StarshipEntity {
  @Attribute(.unique) public var url: URL
  public var name: String
  public var model: String
  public var manufacturerValues: [String]
  public var costInCreditsRaw: String
  public var costInCreditsValue: Int?
  public var lengthRaw: String
  public var lengthInMeters: Double?
  public var maxAtmospheringSpeedRaw: String
  public var maxAtmospheringSpeedValue: Int?
  public var crewRaw: String
  public var crewCount: Int?
  public var passengersRaw: String
  public var passengerCapacity: Int?
  public var cargoCapacityRaw: String
  public var cargoCapacityInKilograms: Int?
  public var consumables: String
  public var hyperdriveRatingRaw: String
  public var hyperdriveRatingValue: Double?
  public var mgltRaw: String
  public var mgltValue: Int?
  public var starshipClass: String
  public var created: Date
  public var edited: Date

  @Relationship(deleteRule: .nullify, inverse: \PersonEntity.starships)
  public var pilots: [PersonEntity] = []

  @Relationship(deleteRule: .nullify, inverse: \FilmEntity.starships)
  public var films: [FilmEntity] = []

  public init(
    url: URL,
    name: String,
    model: String,
    manufacturerValues: [String],
    costInCreditsRaw: String,
    costInCreditsValue: Int?,
    lengthRaw: String,
    lengthInMeters: Double?,
    maxAtmospheringSpeedRaw: String,
    maxAtmospheringSpeedValue: Int?,
    crewRaw: String,
    crewCount: Int?,
    passengersRaw: String,
    passengerCapacity: Int?,
    cargoCapacityRaw: String,
    cargoCapacityInKilograms: Int?,
    consumables: String,
    hyperdriveRatingRaw: String,
    hyperdriveRatingValue: Double?,
    mgltRaw: String,
    mgltValue: Int?,
    starshipClass: String,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.name = name
    self.model = model
    self.manufacturerValues = manufacturerValues
    self.costInCreditsRaw = costInCreditsRaw
    self.costInCreditsValue = costInCreditsValue
    self.lengthRaw = lengthRaw
    self.lengthInMeters = lengthInMeters
    self.maxAtmospheringSpeedRaw = maxAtmospheringSpeedRaw
    self.maxAtmospheringSpeedValue = maxAtmospheringSpeedValue
    self.crewRaw = crewRaw
    self.crewCount = crewCount
    self.passengersRaw = passengersRaw
    self.passengerCapacity = passengerCapacity
    self.cargoCapacityRaw = cargoCapacityRaw
    self.cargoCapacityInKilograms = cargoCapacityInKilograms
    self.consumables = consumables
    self.hyperdriveRatingRaw = hyperdriveRatingRaw
    self.hyperdriveRatingValue = hyperdriveRatingValue
    self.mgltRaw = mgltRaw
    self.mgltValue = mgltValue
    self.starshipClass = starshipClass
    self.created = created
    self.edited = edited
  }

  public func apply(response: StarshipResponse) {
    name = response.name
    model = response.model
    manufacturerValues = response.manufacturers.map(\.rawName)
    costInCreditsRaw = response.costInCredits
    costInCreditsValue = response.costInCreditsValue
    lengthRaw = response.length
    lengthInMeters = response.lengthInMeters
    maxAtmospheringSpeedRaw = response.maxAtmospheringSpeed
    maxAtmospheringSpeedValue = response.maxAtmospheringSpeedValue
    crewRaw = response.crew
    crewCount = response.crewCount
    passengersRaw = response.passengers
    passengerCapacity = response.passengerCapacity
    cargoCapacityRaw = response.cargoCapacity
    cargoCapacityInKilograms = response.cargoCapacityInKilograms
    consumables = response.consumables
    hyperdriveRatingRaw = response.hyperdriveRating
    hyperdriveRatingValue = response.hyperdriveRatingValue
    mgltRaw = response.mglt
    mgltValue = response.mgltValue
    starshipClass = response.starshipClass
    created = response.created
    edited = response.edited
  }

  @Transient
  public var id: URL { url }

  @Transient
  public var manufacturers: [Manufacturer] {
    get { manufacturerValues.map { Manufacturer(rawName: $0) } }
    set { manufacturerValues = newValue.map(\.rawName) }
  }
}

@Model
public final class VehicleEntity {
  @Attribute(.unique) public var url: URL
  public var name: String
  public var model: String
  public var manufacturerValues: [String]
  public var costInCreditsRaw: String
  public var costInCreditsValue: Int?
  public var lengthRaw: String
  public var lengthInMeters: Double?
  public var maxAtmospheringSpeedRaw: String
  public var maxAtmospheringSpeedValue: Int?
  public var crewRaw: String
  public var crewCount: Int?
  public var passengersRaw: String
  public var passengerCapacity: Int?
  public var cargoCapacityRaw: String
  public var cargoCapacityInKilograms: Int?
  public var consumables: String
  public var vehicleClassRaw: String
  public var created: Date
  public var edited: Date

  @Relationship(deleteRule: .nullify, inverse: \PersonEntity.vehicles)
  public var pilots: [PersonEntity] = []

  @Relationship(deleteRule: .nullify, inverse: \FilmEntity.vehicles)
  public var films: [FilmEntity] = []

  public init(
    url: URL,
    name: String,
    model: String,
    manufacturerValues: [String],
    costInCreditsRaw: String,
    costInCreditsValue: Int?,
    lengthRaw: String,
    lengthInMeters: Double?,
    maxAtmospheringSpeedRaw: String,
    maxAtmospheringSpeedValue: Int?,
    crewRaw: String,
    crewCount: Int?,
    passengersRaw: String,
    passengerCapacity: Int?,
    cargoCapacityRaw: String,
    cargoCapacityInKilograms: Int?,
    consumables: String,
    vehicleClassRaw: String,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.name = name
    self.model = model
    self.manufacturerValues = manufacturerValues
    self.costInCreditsRaw = costInCreditsRaw
    self.costInCreditsValue = costInCreditsValue
    self.lengthRaw = lengthRaw
    self.lengthInMeters = lengthInMeters
    self.maxAtmospheringSpeedRaw = maxAtmospheringSpeedRaw
    self.maxAtmospheringSpeedValue = maxAtmospheringSpeedValue
    self.crewRaw = crewRaw
    self.crewCount = crewCount
    self.passengersRaw = passengersRaw
    self.passengerCapacity = passengerCapacity
    self.cargoCapacityRaw = cargoCapacityRaw
    self.cargoCapacityInKilograms = cargoCapacityInKilograms
    self.consumables = consumables
    self.vehicleClassRaw = vehicleClassRaw
    self.created = created
    self.edited = edited
  }

  public func apply(response: VehicleResponse) {
    name = response.name
    model = response.model
    manufacturerValues = response.manufacturers.map(\.rawName)
    costInCreditsRaw = response.costInCredits
    costInCreditsValue = response.costInCreditsValue
    lengthRaw = response.length
    lengthInMeters = response.lengthInMeters
    maxAtmospheringSpeedRaw = response.maxAtmospheringSpeed
    maxAtmospheringSpeedValue = response.maxAtmospheringSpeedValue
    crewRaw = response.crew
    crewCount = response.crewCount
    passengersRaw = response.passengers
    passengerCapacity = response.passengerCapacity
    cargoCapacityRaw = response.cargoCapacity
    cargoCapacityInKilograms = response.cargoCapacityInKilograms
    consumables = response.consumables
    vehicleClassRaw = response.vehicleClass.rawValue
    created = response.created
    edited = response.edited
  }

  @Transient
  public var id: URL { url }

  @Transient
  public var vehicleClass: VehicleResponse.VehicleClass {
    get { VehicleResponse.VehicleClass(rawValue: vehicleClassRaw) }
    set { vehicleClassRaw = newValue.rawValue }
  }

  @Transient
  public var manufacturers: [Manufacturer] {
    get { manufacturerValues.map { Manufacturer(rawName: $0) } }
    set { manufacturerValues = newValue.map(\.rawName) }
  }
}
