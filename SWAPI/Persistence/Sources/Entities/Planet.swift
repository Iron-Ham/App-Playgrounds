import API
import Foundation
import SQLiteData

@Table
public struct Planet: Hashable, Identifiable, Sendable {
  @Column(primaryKey: true)
  public var url: URL
  public var name: String
  public var rotationPeriod: String
  public var orbitalPeriod: String
  public var diameter: String
  @Column("climates")
  private var climatesRaw: String
  @Column("gravityLevels")
  private var gravityLevelsRaw: String
  @Column("terrains")
  private var terrainsRaw: String
  public var surfaceWater: String
  public var population: String
  public var created: Date
  public var edited: Date

  public var id: URL { url }

  public var climates: [PlanetResponse.ClimateDescriptor] {
    get { PlanetResponse.ClimateDescriptor.descriptors(from: climatesRaw) }
    set { climatesRaw = Self.joinedRawValues(from: newValue.map(\.rawValue)) }
  }

  public var gravityLevels: [PlanetResponse.GravityDescriptor] {
    get { Self.gravityDescriptors(from: gravityLevelsRaw) }
    set { gravityLevelsRaw = Self.joinedRawValues(from: newValue.map(\.rawValue)) }
  }

  public var terrains: [PlanetResponse.TerrainDescriptor] {
    get { PlanetResponse.TerrainDescriptor.descriptors(from: terrainsRaw) }
    set { terrainsRaw = Self.joinedRawValues(from: newValue.map(\.rawValue)) }
  }

  public var rotationPeriodInHours: Int? { Self.intNumber(from: rotationPeriod) }
  public var orbitalPeriodInDays: Int? { Self.intNumber(from: orbitalPeriod) }
  public var diameterInKilometers: Int? { Self.intNumber(from: diameter) }
  public var surfaceWaterPercentage: Double? { Self.metricNumber(from: surfaceWater) }
  public var populationCount: Int? { Self.intNumber(from: population) }

  public init(
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
    self.url = url
    self.name = name
    self.rotationPeriod = rotationPeriod
    self.orbitalPeriod = orbitalPeriod
    self.diameter = diameter
    self.climatesRaw = Self.joinedRawValues(from: climates.map(\.rawValue))
    self.gravityLevelsRaw = Self.joinedRawValues(from: gravityLevels.map(\.rawValue))
    self.terrainsRaw = Self.joinedRawValues(from: terrains.map(\.rawValue))
    self.surfaceWater = surfaceWater
    self.population = population
    self.created = created
    self.edited = edited
  }
}

extension Planet {
  fileprivate static func metricNumber(from rawValue: String) -> Double? {
    let filtered = rawValue.compactMap { character -> Character? in
      if character.isNumber || character == "." || character == "-" { return character }
      return nil
    }

    guard !filtered.isEmpty else { return nil }
    return Double(String(filtered))
  }

  fileprivate static func intNumber(from rawValue: String) -> Int? {
    guard let value = metricNumber(from: rawValue) else { return nil }
    guard value.isFinite, value.truncatingRemainder(dividingBy: 1) == 0 else { return nil }
    return Int(value)
  }

  fileprivate static func joinedRawValues(from rawValues: [String]) -> String {
    rawValues
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: ",")
  }

  fileprivate static func gravityDescriptors(
    from rawList: String
  ) -> [PlanetResponse.GravityDescriptor] {
    let segments =
      rawList
      .split(separator: ",")
      .map { PlanetResponse.GravityDescriptor(rawValue: String($0)) }
      .filter { !$0.rawValue.isEmpty }

    if segments.count == 1, segments.first?.isNotApplicable == true {
      return []
    }

    return segments
  }
}
