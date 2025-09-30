import API
import Foundation
import SQLiteData

@Table
public struct Starship: Hashable, Identifiable, Sendable {
  @Column(primaryKey: true)
  public var url: URL
  public var name: String
  public var model: String
  @Column("manufacturers")
  private var manufacturersRaw: String
  public var costInCredits: String
  public var length: String
  public var maxAtmospheringSpeed: String
  public var crew: String
  public var passengers: String
  public var cargoCapacity: String
  public var consumables: String
  public var hyperdriveRating: String
  public var mglt: String
  @Column("starshipClass")
  private var starshipClassRaw: String
  public var created: Date
  public var edited: Date

  public var id: String { url.absoluteString }

  public var manufacturers: [Manufacturer] {
    get { Manufacturer.manufacturers(from: manufacturersRaw) }
    set { manufacturersRaw = Self.joinedManufacturerRaw(from: newValue) }
  }

  public var starshipClass: StarshipResponse.StarshipClass {
    get { StarshipResponse.StarshipClass(rawValue: starshipClassRaw) }
    set { starshipClassRaw = newValue.rawValue }
  }

  public var costInCreditsValue: Int? { Self.intNumber(from: costInCredits) }
  public var lengthInMeters: Double? { Self.metricNumber(from: length) }
  public var maxAtmospheringSpeedValue: Int? { Self.intNumber(from: maxAtmospheringSpeed) }
  public var crewCount: Int? { Self.intNumber(from: crew) }
  public var passengerCapacity: Int? { Self.intNumber(from: passengers) }
  public var cargoCapacityInKilograms: Int? { Self.intNumber(from: cargoCapacity) }
  public var hyperdriveRatingValue: Double? { Self.metricNumber(from: hyperdriveRating) }
  public var mgltValue: Int? { Self.intNumber(from: mglt) }

  public init(
    url: URL,
    name: String,
    model: String,
    manufacturers: [Manufacturer],
    costInCredits: String,
    length: String,
    maxAtmospheringSpeed: String,
    crew: String,
    passengers: String,
    cargoCapacity: String,
    consumables: String,
    hyperdriveRating: String,
    mglt: String,
    starshipClass: StarshipResponse.StarshipClass,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.name = name
    self.model = model
    self.manufacturersRaw = Self.joinedManufacturerRaw(from: manufacturers)
    self.costInCredits = costInCredits
    self.length = length
    self.maxAtmospheringSpeed = maxAtmospheringSpeed
    self.crew = crew
    self.passengers = passengers
    self.cargoCapacity = cargoCapacity
    self.consumables = consumables
    self.hyperdriveRating = hyperdriveRating
    self.mglt = mglt
    self.starshipClassRaw = starshipClass.rawValue
    self.created = created
    self.edited = edited
  }
}

extension Starship {
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

  fileprivate static func joinedManufacturerRaw(from manufacturers: [Manufacturer]) -> String {
    manufacturers
      .map(\.rawName)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: ",")
  }
}
