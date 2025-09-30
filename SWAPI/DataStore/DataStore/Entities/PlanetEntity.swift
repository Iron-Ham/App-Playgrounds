import Foundation
import SwiftData
import API

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
