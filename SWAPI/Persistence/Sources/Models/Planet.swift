import API
import Fluent
import Foundation

public final class Planet: Model, @unchecked Sendable {
  public static let schema = "planets"

  @ID(custom: "url", generatedBy: .user)
  public var id: URL?

  @Field(key: "name")
  public var name: String

  @Field(key: "rotationPeriod")
  public var rotationPeriod: String

  @Field(key: "orbitalPeriod")
  public var orbitalPeriod: String

  @Field(key: "diameter")
  public var diameter: String

  @Field(key: "climates")
  private var climatesRaw: String

  @Field(key: "gravityLevels")
  private var gravityLevelsRaw: String

  @Field(key: "terrains")
  private var terrainsRaw: String

  @Field(key: "surfaceWater")
  public var surfaceWater: String

  @Field(key: "population")
  public var population: String

  @Field(key: "created")
  public var created: Date

  @Field(key: "edited")
  public var edited: Date

  @Children(for: \.$homeworld)
  public var residents: [Person]

  @Siblings(through: FilmPlanetPivot.self, from: \.$planet, to: \.$film)
  public var films: [Film]

  public var url: URL {
    get {
      guard let id else {
        fatalError("Attempted to access Planet.url before the record had an assigned URL")
      }
      return id
    }
    set { id = newValue }
  }

  public var climates: [PlanetResponse.ClimateDescriptor] {
    get { PlanetResponse.ClimateDescriptor.descriptors(from: climatesRaw) }
    set { climatesRaw = Self.joinedDescriptors(from: newValue.map(\.rawValue)) }
  }

  public var gravityLevels: [PlanetResponse.GravityDescriptor] {
    get { PlanetResponse.GravityDescriptor.descriptors(from: gravityLevelsRaw) }
    set { gravityLevelsRaw = Self.joinedDescriptors(from: newValue.map(\.rawValue)) }
  }

  public var terrains: [PlanetResponse.TerrainDescriptor] {
    get { PlanetResponse.TerrainDescriptor.descriptors(from: terrainsRaw) }
    set { terrainsRaw = Self.joinedDescriptors(from: newValue.map(\.rawValue)) }
  }

  public var rotationPeriodInHours: Int? { Self.intNumber(from: rotationPeriod) }
  public var orbitalPeriodInDays: Int? { Self.intNumber(from: orbitalPeriod) }
  public var diameterInKilometers: Int? { Self.intNumber(from: diameter) }
  public var surfaceWaterPercentage: Double? { Self.metricNumber(from: surfaceWater) }
  public var populationCount: Int? { Self.intNumber(from: population) }

  public init() {
    self.name = ""
    self.rotationPeriod = ""
    self.orbitalPeriod = ""
    self.diameter = ""
    self.climatesRaw = ""
    self.gravityLevelsRaw = ""
    self.terrainsRaw = ""
    self.surfaceWater = ""
    self.population = ""
    self.created = .now
    self.edited = .now
  }

  public convenience init(from response: PlanetResponse) {
    self.init(
      url: response.url,
      name: response.name,
      rotationPeriod: response.rotationPeriod,
      orbitalPeriod: response.orbitalPeriod,
      diameter: response.diameter,
      climates: response.climates,
      gravityLevels: response.gravityLevels,
      terrains: response.terrains,
      surfaceWater: response.surfaceWater,
      population: response.population,
      created: response.created,
      edited: response.edited
    )
  }

  public convenience init(
    url: URL,
    name: String,
    rotationPeriod: String,
    orbitalPeriod: String,
    diameter: String,
    climates: [PlanetResponse.ClimateDescriptor],
    gravityLevels: [PlanetResponse.GravityDescriptor],
    terrains: [PlanetResponse.TerrainDescriptor],
    surfaceWater: String,
    population: String,
    created: Date,
    edited: Date
  ) {
    self.init()
    self.url = url
    self.name = name
    self.rotationPeriod = rotationPeriod
    self.orbitalPeriod = orbitalPeriod
    self.diameter = diameter
    self.climatesRaw = Self.joinedDescriptors(from: climates.map(\.rawValue))
    self.gravityLevelsRaw = Self.joinedDescriptors(from: gravityLevels.map(\.rawValue))
    self.terrainsRaw = Self.joinedDescriptors(from: terrains.map(\.rawValue))
    self.surfaceWater = surfaceWater
    self.population = population
    self.created = created
    self.edited = edited
  }
}

extension Planet {
  private static func metricNumber(from rawValue: String) -> Double? {
    let filtered = rawValue.compactMap { character -> Character? in
      if character.isNumber || character == "." || character == "-" { return character }
      return nil
    }

    guard !filtered.isEmpty else { return nil }
    return Double(String(filtered))
  }

  private static func intNumber(from rawValue: String) -> Int? {
    guard let value = metricNumber(from: rawValue) else { return nil }
    guard value.isFinite, value.truncatingRemainder(dividingBy: 1) == 0 else { return nil }
    return Int(value)
  }

  private static func joinedDescriptors(from rawValues: [String]) -> String {
    rawValues
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: ",")
  }
}
