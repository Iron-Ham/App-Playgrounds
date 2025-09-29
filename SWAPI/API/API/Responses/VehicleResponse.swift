import Foundation

/// A model representing a single vehicle returned by the public SWAPI (https://swapi.info).
public struct VehicleResponse: Codable, Hashable, Sendable, Identifiable {
  /// Stable identifier equal to the canonical resource ``url``.
  public var id: URL { url }

  /// Human-readable vehicle name (e.g. "Snowspeeder").
  public let name: String

  /// Manufacturer-provided model designation (e.g. "t-47 airspeeder").
  public let model: String

  /// Raw comma-separated manufacturer string as supplied by the API.
  let manufacturer: String

  /// Parsed list of manufacturers derived from the raw comma or slash-delimited ``manufacturer`` string.
  public var manufacturers: [Manufacturer] {
    Manufacturer.manufacturers(from: manufacturer)
  }

  /// Raw acquisition cost string (typically in credits or "unknown").
  public let costInCredits: String

  /// Parsed acquisition cost as an integer number of credits when available.
  public var costInCreditsValue: Int? {
    Self.intNumber(from: costInCredits)
  }

  /// Raw vehicle length string (typically meters or "unknown").
  public let length: String

  /// Parsed vehicle length in meters when the raw value is numeric.
  public var lengthInMeters: Double? {
    Self.metricNumber(from: length)
  }

  /// Raw maximum atmospheric speed string (typically in km/h or "unknown").
  public let maxAtmospheringSpeed: String

  /// Parsed maximum atmospheric speed as an integer when available.
  public var maxAtmospheringSpeedValue: Int? {
    Self.intNumber(from: maxAtmospheringSpeed)
  }

  /// Raw crew count string (e.g. "1", "unknown").
  public let crew: String

  /// Parsed crew count as an integer when the raw value is numeric.
  public var crewCount: Int? {
    Self.intNumber(from: crew)
  }

  /// Raw passenger capacity string (e.g. "6", "unknown").
  public let passengers: String

  /// Parsed passenger capacity as an integer when the raw value is numeric.
  public var passengerCapacity: Int? {
    Self.intNumber(from: passengers)
  }

  /// Raw cargo capacity string (typically kilograms or "unknown").
  public let cargoCapacity: String

  /// Parsed cargo capacity as an integer number of kilograms when the raw value is numeric.
  public var cargoCapacityInKilograms: Int? {
    Self.intNumber(from: cargoCapacity)
  }

  /// Consumables description (e.g. "2 months").
  public let consumables: String

  /// Canonical vehicle class enum derived from the API string.
  public let vehicleClass: VehicleClass

  /// Resource URLs representing pilots known to operate this vehicle.
  public let pilots: [URL]

  /// Resource URLs for films featuring this vehicle.
  public let films: [URL]

  /// Creation timestamp of the resource (ISO-8601, supplied by SWAPI).
  public let created: Date

  /// Last edit timestamp of the resource (ISO-8601, supplied by SWAPI).
  public let edited: Date

  /// Canonical URL to this vehicle resource on the API.
  public let url: URL
}

extension VehicleResponse {
  /// Canonical enum representation of SWAPI vehicle class strings.
  @frozen
  public enum VehicleClass: Hashable, Sendable, Codable, CustomStringConvertible {
    case airspeeder
    case assaultWalker
    case droidStarfighter
    case droidTank
    case fireSuppressionShip
    case gunship
    case landingCraft
    case repulsorcraft
    case repulsorcraftCargoSkiff
    case sailBarge
    case spacePlanetaryBomber
    case speeder
    case starfighter
    case submarine
    case transport
    case walker
    case wheeled
    case wheeledWalker
    case other(String)

    /// Original API string representation of the vehicle class.
    public var rawValue: String {
      switch self {
      case .airspeeder: return "airspeeder"
      case .assaultWalker: return "assault walker"
      case .droidStarfighter: return "droid starfighter"
      case .droidTank: return "droid tank"
      case .fireSuppressionShip: return "fire suppression ship"
      case .gunship: return "gunship"
      case .landingCraft: return "landing craft"
      case .repulsorcraft: return "repulsorcraft"
      case .repulsorcraftCargoSkiff: return "repulsorcraft cargo skiff"
      case .sailBarge: return "sail barge"
      case .spacePlanetaryBomber: return "space/planetary bomber"
      case .speeder: return "speeder"
      case .starfighter: return "starfighter"
      case .submarine: return "submarine"
      case .transport: return "transport"
      case .walker: return "walker"
      case .wheeled: return "wheeled"
      case .wheeledWalker: return "wheeled walker"
      case .other(let value): return value
      }
    }

    /// Human-friendly display name intended for UI presentation.
    public var displayName: String {
      switch self {
      case .airspeeder: return "Airspeeder"
      case .assaultWalker: return "Assault Walker"
      case .droidStarfighter: return "Droid Starfighter"
      case .droidTank: return "Droid Tank"
      case .fireSuppressionShip: return "Fire Suppression Ship"
      case .gunship: return "Gunship"
      case .landingCraft: return "Landing Craft"
      case .repulsorcraft: return "Repulsorcraft"
      case .repulsorcraftCargoSkiff: return "Repulsorcraft Cargo Skiff"
      case .sailBarge: return "Sail Barge"
      case .spacePlanetaryBomber: return "Space/Planetary Bomber"
      case .speeder: return "Speeder"
      case .starfighter: return "Starfighter"
      case .submarine: return "Submarine"
      case .transport: return "Transport"
      case .walker: return "Walker"
      case .wheeled: return "Wheeled"
      case .wheeledWalker: return "Wheeled Walker"
      case .other(let value):
        guard !value.isEmpty else { return "" }
        return value.localizedCapitalized
      }
    }

    public var description: String { displayName }

    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      let rawValue = try container.decode(String.self)
      self = VehicleClass(rawValue: rawValue)
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }

    /// Creates a vehicle class enum from an arbitrary API string, preserving unknown values.
    public init(rawValue: String) {
      switch rawValue.lowercased() {
      case "air speeder", "airspeeder": self = .airspeeder
      case "assault walker": self = .assaultWalker
      case "droid starfighter": self = .droidStarfighter
      case "droid tank": self = .droidTank
      case "fire suppression ship": self = .fireSuppressionShip
      case "gunship": self = .gunship
      case "landing craft": self = .landingCraft
      case "repulsorcraft": self = .repulsorcraft
      case "repulsorcraft cargo skiff": self = .repulsorcraftCargoSkiff
      case "sail barge": self = .sailBarge
      case "space/planetary bomber": self = .spacePlanetaryBomber
      case "speeder": self = .speeder
      case "starfighter": self = .starfighter
      case "submarine": self = .submarine
      case "transport": self = .transport
      case "walker": self = .walker
      case "wheeled": self = .wheeled
      case "wheeled walker": self = .wheeledWalker
      default: self = .other(rawValue)
      }
    }
  }

  /// Decodes an array of vehicles from raw JSON `Data` using the type's internal decoder.
  /// - Parameter data: Raw JSON representing an array of vehicle objects.
  /// - Returns: An array of `VehicleResponse` values.
  /// - Throws: Any decoding error encountered while parsing the payload.
  public static func vehicles(from data: Data) throws -> [VehicleResponse] {
    try Self.decoder.decode([VehicleResponse].self, from: data)
  }

  /// Creates a single `VehicleResponse` by decoding the provided JSON `Data`.
  /// - Parameter data: Raw JSON representing one vehicle object.
  /// - Throws: Any decoding error encountered while parsing the payload.
  public init(data: Data) throws {
    self = try Self.decoder.decode(VehicleResponse.self, from: data)
  }
}

extension VehicleResponse {
  /// Attempts to parse a numeric value from the supplied raw string, preserving decimal points
  /// and minus signs but stripping any other non-numeric characters (e.g. commas, units).
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

  private static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()
}
