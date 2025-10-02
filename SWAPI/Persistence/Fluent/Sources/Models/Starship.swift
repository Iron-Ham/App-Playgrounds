import API
import Fluent
import Foundation

public final class Starship: Model, @unchecked Sendable {
  public static let schema = "starships"

  @ID(custom: "url", generatedBy: .user)
  public var id: URL?

  @Field(key: "name")
  public var name: String

  @Field(key: "model")
  public var model: String

  @Field(key: "manufacturers")
  private var manufacturersRaw: String

  @Field(key: "costInCredits")
  public var costInCredits: String

  @Field(key: "length")
  public var length: String

  @Field(key: "maxAtmospheringSpeed")
  public var maxAtmospheringSpeed: String

  @Field(key: "crew")
  public var crew: String

  @Field(key: "passengers")
  public var passengers: String

  @Field(key: "cargoCapacity")
  public var cargoCapacity: String

  @Field(key: "consumables")
  public var consumables: String

  @Field(key: "hyperdriveRating")
  public var hyperdriveRating: String

  @Field(key: "mglt")
  public var mglt: String

  @Field(key: "starshipClass")
  private var starshipClassRaw: String

  @Field(key: "created")
  public var created: Date

  @Field(key: "edited")
  public var edited: Date

  @Siblings(through: FilmStarshipPivot.self, from: \.$starship, to: \.$film)
  public var films: [Film]

  @Siblings(through: PersonStarshipPivot.self, from: \.$starship, to: \.$person)
  public var pilots: [Person]

  public var url: URL {
    get {
      guard let id else {
        fatalError("Attempted to access Starship.url before the record had an assigned URL")
      }
      return id
    }
    set { id = newValue }
  }

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

  public init() {
    self.name = ""
    self.model = ""
    self.manufacturersRaw = ""
    self.costInCredits = ""
    self.length = ""
    self.maxAtmospheringSpeed = ""
    self.crew = ""
    self.passengers = ""
    self.cargoCapacity = ""
    self.consumables = ""
    self.hyperdriveRating = ""
    self.mglt = ""
    self.starshipClassRaw = ""
    self.created = .now
    self.edited = .now
  }

  public convenience init(from response: StarshipResponse) {
    self.init(
      url: response.url,
      name: response.name,
      model: response.model,
      manufacturers: response.manufacturers,
      costInCredits: response.costInCredits,
      length: response.length,
      maxAtmospheringSpeed: response.maxAtmospheringSpeed,
      crew: response.crew,
      passengers: response.passengers,
      cargoCapacity: response.cargoCapacity,
      consumables: response.consumables,
      hyperdriveRating: response.hyperdriveRating,
      mglt: response.mglt,
      starshipClass: response.starshipClass,
      created: response.created,
      edited: response.edited
    )
  }

  public convenience init(
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
    self.init()
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

  private static func joinedManufacturerRaw(from manufacturers: [Manufacturer]) -> String {
    manufacturers
      .map(\.rawName)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: ",")
  }
}
