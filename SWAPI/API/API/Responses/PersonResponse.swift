import Foundation

/// A model representing an individual character returned by the public SWAPI (https://swapi.info).
public struct PersonResponse: Codable, Hashable, Sendable, Identifiable {
  /// Stable identifier equal to the canonical resource ``url``.
  public var id: URL { url }

  /// Human-readable character name (e.g. "Luke Skywalker").
  public let name: String

  /// Raw height string as provided by the API (typically centimeters or "unknown").
  public let height: String

  /// Parsed numeric height in centimeters, omitting any punctuation or whitespace.
  public var heightInCentimeters: Double? {
    Self.metricNumber(from: height)
  }

  /// Parsed numeric height in meters derived from ``heightInCentimeters``.
  public var heightInMeters: Double? {
    guard let centimeters = heightInCentimeters else { return nil }
    return centimeters / 100
  }

  /// Raw mass string as provided by the API (typically kilograms or "unknown").
  public let mass: String

  /// Parsed numeric mass in kilograms, omitting any punctuation or whitespace.
  public var massInKilograms: Double? {
    Self.metricNumber(from: mass)
  }

  /// Raw hair color descriptor string as provided by the API.
  let hairColor: String

  /// Derived hair color descriptors parsed from ``hairColorRawValue``.
  public var hairColors: [ColorDescriptor] {
    ColorDescriptor.descriptors(from: hairColor)
  }

  /// Raw skin color descriptor string as provided by the API.
  let skinColor: String

  /// Derived skin color descriptors parsed from ``skinColorRawValue``.
  public var skinColors: [ColorDescriptor] {
    ColorDescriptor.descriptors(from: skinColor)
  }

  /// Raw eye color descriptor string as provided by the API.
  let eyeColor: String

  /// Derived eye color descriptors parsed from ``eyeColorRawValue``.
  public var eyeColors: [ColorDescriptor] {
    ColorDescriptor.descriptors(from: eyeColor)
  }

  /// Birth year descriptor (e.g. "19BBY").
  public let birthYear: BirthYear

  /// Gender descriptor normalized into an enum.
  public let gender: Gender

  /// Homeworld resource URL.
  public let homeworld: URL

  /// Films in which this character appears.
  public let films: [URL]

  /// Species resources associated with this character.
  public let species: [URL]

  /// Vehicle resources operated by this character.
  public let vehicles: [URL]

  /// Starship resources piloted by this character.
  public let starships: [URL]

  /// Creation timestamp of the resource (ISO-8601, supplied by SWAPI).
  public let created: Date

  /// Last edit timestamp of the resource (ISO-8601, supplied by SWAPI).
  public let edited: Date

  /// Canonical URL to this character resource on the API.
  public let url: URL
}

extension PersonResponse {
  /// Canonical enum representation of SWAPI gender strings.
  @frozen
  public enum Gender: Hashable, Sendable, Codable, CustomStringConvertible {
    case male
    case female
    case hermaphrodite
    case none
    case notApplicable
    case unknown
    case other(String)

    public var rawValue: String {
      switch self {
      case .male: return "male"
      case .female: return "female"
      case .hermaphrodite: return "hermaphrodite"
      case .none: return "none"
      case .notApplicable: return "n/a"
      case .unknown: return "unknown"
      case .other(let value): return value
      }
    }

    /// Human-friendly display string intended for UI presentation.
    public var displayName: String {
      switch self {
      case .male: return "Male"
      case .female: return "Female"
      case .hermaphrodite: return "Hermaphrodite"
      case .none: return "None"
      case .notApplicable: return "Not applicable"
      case .unknown: return "Unknown"
      case .other(let value):
        guard !value.isEmpty else { return "" }
        return value.localizedCapitalized
      }
    }

    public var description: String { displayName }

    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      let rawValue = try container.decode(String.self)
      self = Gender(rawValue: rawValue)
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }

    /// Creates a gender enum from an arbitrary API string, preserving unknown values.
    public init(rawValue: String) {
      switch rawValue.lowercased() {
      case "male": self = .male
      case "female": self = .female
      case "hermaphrodite": self = .hermaphrodite
      case "none": self = .none
      case "n/a": self = .notApplicable
      case "unknown": self = .unknown
      default: self = .other(rawValue)
      }
    }
  }

  /// Canonical representation of the SWAPI ``birth_year`` field supporting BBY/ABY parsing.
  @frozen
  public struct BirthYear: Hashable, Sendable, Codable, CustomStringConvertible {
    /// Galactic era relative to the Battle of Yavin.
    @frozen
    public enum Era: String, Hashable, Sendable, Codable {
      case beforeBattleOfYavin = "BBY"
      case afterBattleOfYavin = "ABY"

      /// The canonical two-letter abbreviation ("BBY" or "ABY").
      public var abbreviation: String { rawValue }
    }

    private static let unknownTokens: Set<String> = ["", "n/a", "none", "unknown"]

    /// Original raw string value returned by the API.
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Parsed absolute year value (always positive) when available.
    public var magnitude: Double? { parsedComponents?.value }

    /// Parsed galactic era relative to the Battle of Yavin when available.
    public var era: Era? { parsedComponents?.era }

    /// Signed year offset relative to the Battle of Yavin (BBY values are negative).
    public var relativeYear: Double? {
      guard let components = parsedComponents else { return nil }
      switch components.era {
      case .beforeBattleOfYavin?: return -components.value
      case .afterBattleOfYavin?: return components.value
      case nil: return components.value
      }
    }

    /// Indicates that the year could not be parsed into a numeric value.
    public var isUnknown: Bool { parsedComponents == nil }

    public var description: String { rawValue }

    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }

    private var parsedComponents: (value: Double, era: Era?)? {
      let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return nil }
      let lowered = trimmed.lowercased()
      if Self.unknownTokens.contains(lowered) { return nil }

      var numericPortion = trimmed
      let era: Era?
      if lowered.hasSuffix("bby") {
        era = .beforeBattleOfYavin
        numericPortion = String(trimmed.dropLast(3))
      } else if lowered.hasSuffix("aby") {
        era = .afterBattleOfYavin
        numericPortion = String(trimmed.dropLast(3))
      } else {
        era = nil
      }

      let normalizedNumber = numericPortion.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let value = Double(normalizedNumber) else { return nil }
      return (value, era)
    }
  }

  /// Decodes an array of people from raw JSON `Data` using the type's internal decoder.
  /// - Parameter data: Raw JSON representing an array of person objects.
  /// - Returns: An array of `PersonResponse` values.
  /// - Throws: Any decoding error encountered while parsing the payload.
  public static func people(from data: Data) throws -> [PersonResponse] {
    try Self.makeDecoder().decode([PersonResponse].self, from: data)
  }

  /// Creates a single `PersonResponse` by decoding the provided JSON `Data`.
  /// - Parameter data: Raw JSON representing one person object.
  /// - Throws: Any decoding error encountered while parsing the payload.
  public init(data: Data) throws {
    self = try Self.makeDecoder().decode(PersonResponse.self, from: data)
  }
}

extension PersonResponse {
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

  private static func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }
}
