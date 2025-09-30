import Foundation

/// A model representing a single starship returned by the public SWAPI (https://swapi.info).
public struct StarshipResponse: Codable, Hashable, Sendable, Identifiable {
  /// Stable identifier equal to the canonical resource ``url``.
  public var id: URL { url }

  /// Human-readable starship name (e.g. "Millennium Falcon").
  public let name: String

  /// Manufacturer-provided model designation (e.g. "YT-1300 light freighter").
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

  /// Raw starship length string (typically meters or "unknown").
  public let length: String

  /// Parsed starship length in meters when the raw value is numeric.
  public var lengthInMeters: Double? {
    Self.metricNumber(from: length)
  }

  /// Raw maximum atmospheric speed string (typically in km/h or "unknown").
  public let maxAtmospheringSpeed: String

  /// Parsed maximum atmospheric speed as an integer when available.
  public var maxAtmospheringSpeedValue: Int? {
    Self.intNumber(from: maxAtmospheringSpeed)
  }

  /// Raw crew count string (e.g. "342,953", "unknown").
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

  /// Raw hyperdrive rating string (typically a decimal value or "unknown").
  public let hyperdriveRating: String

  /// Parsed hyperdrive rating as a floating-point value when the raw value is numeric.
  public var hyperdriveRatingValue: Double? {
    Self.metricNumber(from: hyperdriveRating)
  }

  /// Raw MGLT (Megalight per hour) string.
  public let mglt: String

  /// Parsed MGLT value as an integer when the raw value is numeric.
  public var mgltValue: Int? {
    Self.intNumber(from: mglt)
  }

  /// Raw starship class string as supplied by the API.
  private let starshipClassRawValue: String

  /// Canonical starship class enum derived from the API string.
  public var starshipClass: StarshipClass {
    StarshipClass(rawValue: starshipClassRawValue)
  }

  /// Resource URLs representing pilots known to operate this starship.
  public let pilots: [URL]

  /// Resource URLs for films featuring this starship.
  public let films: [URL]

  /// Creation timestamp of the resource (ISO-8601, supplied by SWAPI).
  public let created: Date

  /// Last edit timestamp of the resource (ISO-8601, supplied by SWAPI).
  public let edited: Date

  /// Canonical URL to this starship resource on the API.
  public let url: URL

  private enum CodingKeys: String, CodingKey {
    case name
    case model
    case manufacturer
    case costInCredits
    case length
    case maxAtmospheringSpeed
    case crew
    case passengers
    case cargoCapacity
    case consumables
    case hyperdriveRating
    case mglt = "MGLT"
    case starshipClassRawValue = "starshipClass"
    case pilots
    case films
    case created
    case edited
    case url
  }
}

extension StarshipResponse {
  /// Canonical enum representation of SWAPI starship class strings.
  @frozen
  public enum StarshipClass: Hashable, Sendable, Codable, CustomStringConvertible {
    case assaultShip
    case assaultStarfighter
    case capitalShip
    case corvette
    case cruiser
    case deepSpaceMobileBattlestation
    case diplomaticBarge
    case droidControlShip
    case escortShip
    case freighter
    case landingCraft
    case lightFreighter
    case mediumTransport
    case patrolCraft
    case spaceCruiser
    case spaceTransport
    case starCruiser
    case starDestroyer
    case starDreadnought
    case starfighter
    case transport
    case yacht
    case other(String)

    /// Original API string representation of the starship class.
    public var rawValue: String {
      switch self {
      case .assaultShip: return "assault ship"
      case .assaultStarfighter: return "assault starfighter"
      case .capitalShip: return "capital ship"
      case .corvette: return "corvette"
      case .cruiser: return "cruiser"
      case .deepSpaceMobileBattlestation: return "deep space mobile battlestation"
      case .diplomaticBarge: return "diplomatic barge"
      case .droidControlShip: return "droid control ship"
      case .escortShip: return "escort ship"
      case .freighter: return "freighter"
      case .landingCraft: return "landing craft"
      case .lightFreighter: return "light freighter"
      case .mediumTransport: return "medium transport"
      case .patrolCraft: return "patrol craft"
      case .spaceCruiser: return "space cruiser"
      case .spaceTransport: return "space transport"
      case .starCruiser: return "star cruiser"
      case .starDestroyer: return "star destroyer"
      case .starDreadnought: return "star dreadnought"
      case .starfighter: return "starfighter"
      case .transport: return "transport"
      case .yacht: return "yacht"
      case .other(let value): return value
      }
    }

    /// Human-friendly display name intended for UI presentation.
    public var displayName: String {
      switch self {
      case .assaultShip: return "Assault Ship"
      case .assaultStarfighter: return "Assault Starfighter"
      case .capitalShip: return "Capital Ship"
      case .corvette: return "Corvette"
      case .cruiser: return "Cruiser"
      case .deepSpaceMobileBattlestation: return "Deep Space Mobile Battlestation"
      case .diplomaticBarge: return "Diplomatic Barge"
      case .droidControlShip: return "Droid Control Ship"
      case .escortShip: return "Escort Ship"
      case .freighter: return "Freighter"
      case .landingCraft: return "Landing Craft"
      case .lightFreighter: return "Light Freighter"
      case .mediumTransport: return "Medium Transport"
      case .patrolCraft: return "Patrol Craft"
      case .spaceCruiser: return "Space Cruiser"
      case .spaceTransport: return "Space Transport"
      case .starCruiser: return "Star Cruiser"
      case .starDestroyer: return "Star Destroyer"
      case .starDreadnought: return "Star Dreadnought"
      case .starfighter: return "Starfighter"
      case .transport: return "Transport"
      case .yacht: return "Yacht"
      case .other(let value):
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return trimmed.localizedCapitalized
      }
    }

    public var description: String { displayName }

    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      let rawValue = try container.decode(String.self)
      self = StarshipClass(rawValue: rawValue)
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }

    /// Creates a starship class enum from an arbitrary API string, preserving unknown values.
    public init(rawValue: String) {
      let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
      let normalized = trimmed.lowercased()
      switch normalized {
      case "assault ship": self = .assaultShip
      case "assault starfighter": self = .assaultStarfighter
      case "capital ship": self = .capitalShip
      case "corvette": self = .corvette
      case "cruiser": self = .cruiser
      case "deep space mobile battlestation": self = .deepSpaceMobileBattlestation
      case "diplomatic barge": self = .diplomaticBarge
      case "droid control ship": self = .droidControlShip
      case "escort ship": self = .escortShip
      case "freighter": self = .freighter
      case "landing craft": self = .landingCraft
      case "light freighter": self = .lightFreighter
      case "medium transport": self = .mediumTransport
      case "patrol craft": self = .patrolCraft
      case "space cruiser": self = .spaceCruiser
      case "space transport": self = .spaceTransport
      case "star cruiser": self = .starCruiser
      case "star destroyer": self = .starDestroyer
      case "star dreadnought": self = .starDreadnought
      case "starfighter": self = .starfighter
      case "assault star fighter": self = .assaultStarfighter
      case "transport": self = .transport
      case "yacht": self = .yacht
      default:
        self = .other(trimmed)
      }
    }
  }
}

extension StarshipResponse {
  /// Decodes an array of starships from raw JSON `Data` using the type's internal decoder.
  /// - Parameter data: Raw JSON representing an array of starship objects.
  /// - Returns: An array of `StarshipResponse` values.
  /// - Throws: Any decoding error encountered while parsing the payload.
  public static func starships(from data: Data) throws -> [StarshipResponse] {
    try Self.makeDecoder().decode([StarshipResponse].self, from: data)
  }

  /// Creates a single `StarshipResponse` by decoding the provided JSON `Data`.
  /// - Parameter data: Raw JSON representing one starship object.
  /// - Throws: Any decoding error encountered while parsing the payload.
  public init(data: Data) throws {
    self = try Self.makeDecoder().decode(StarshipResponse.self, from: data)
  }
}

extension StarshipResponse {
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

  private static func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }
}
