import Foundation

/// A model representing a single planet returned by the public SWAPI (https://swapi.info).
public struct PlanetResponse: Codable, Hashable, Sendable, Identifiable {
  /// Stable identifier equal to the canonical resource ``url``.
  public var id: URL { url }

  /// Human-readable planet name (e.g. "Tatooine").
  public let name: String

  /// Raw rotation period string as provided by the API (typically hours or "unknown").
  public let rotationPeriod: String

  /// Parsed rotation period in hours when the raw value is numeric.
  public var rotationPeriodInHours: Int? {
    Self.intNumber(from: rotationPeriod)
  }

  /// Raw orbital period string as provided by the API (typically days or "unknown").
  public let orbitalPeriod: String

  /// Parsed orbital period in days when the raw value is numeric.
  public var orbitalPeriodInDays: Int? {
    Self.intNumber(from: orbitalPeriod)
  }

  /// Raw diameter string as provided by the API (typically kilometers or "unknown").
  public let diameter: String

  /// Parsed diameter in kilometers when the raw value is numeric.
  public var diameterInKilometers: Int? {
    Self.intNumber(from: diameter)
  }

  /// Raw climate descriptor string as provided by the API.
  private let climate: String

  /// Parsed climate descriptors derived from ``climateDescription``.
  public var climates: [ClimateDescriptor] {
    ClimateDescriptor.descriptors(from: climate)
  }

  /// Raw gravity descriptor string as provided by the API.
  private let gravity: String

  /// Parsed gravity descriptors derived from ``gravityDescription``.
  public var gravityLevels: [GravityDescriptor] {
    GravityDescriptor.descriptors(from: gravity)
  }

  /// Raw terrain descriptor string as provided by the API.
  private let terrain: String

  /// Parsed terrain descriptors derived from ``terrainDescription``.
  public var terrains: [TerrainDescriptor] {
    TerrainDescriptor.descriptors(from: terrain)
  }

  /// Raw surface water percentage string as provided by the API.
  public let surfaceWater: String

  /// Parsed surface water percentage (0-100) when the raw value is numeric.
  public var surfaceWaterPercentage: Double? {
    Self.metricNumber(from: surfaceWater)
  }

  /// Raw population string as provided by the API.
  public let population: String

  /// Parsed population count as an integer when the raw value is numeric.
  public var populationCount: Int? {
    Self.intNumber(from: population)
  }

  /// Resource URLs representing known residents of this planet.
  public let residents: [URL]

  /// Resource URLs for films featuring this planet.
  public let films: [URL]

  /// Creation timestamp of the resource (ISO-8601, supplied by SWAPI).
  public let created: Date

  /// Last edit timestamp of the resource (ISO-8601, supplied by SWAPI).
  public let edited: Date

  /// Canonical URL to this planet resource on the API.
  public let url: URL
}

extension PlanetResponse {
  /// Decodes an array of planets from raw JSON `Data` using the type's internal decoder.
  /// - Parameter data: Raw JSON representing an array of planet objects.
  /// - Returns: An array of `PlanetResponse` values.
  /// - Throws: Any decoding error encountered while parsing the payload.
  public static func planets(from data: Data) throws -> [PlanetResponse] {
    try Self.decoder.decode([PlanetResponse].self, from: data)
  }

  /// Creates a single `PlanetResponse` by decoding the provided JSON `Data`.
  /// - Parameter data: Raw JSON representing one planet object.
  /// - Throws: Any decoding error encountered while parsing the payload.
  public init(data: Data) throws {
    self = try Self.decoder.decode(PlanetResponse.self, from: data)
  }
}

extension PlanetResponse {
  /// A single climate descriptor token parsed from SWAPI climate fields.
  @frozen
  public struct ClimateDescriptor: Hashable, Sendable, Codable, CustomStringConvertible {
    private static let notApplicableTokens: Set<String> = ["n/a", "none", "unknown"]

    /// Original descriptor token trimmed for leading and trailing whitespace.
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Lowercased descriptor value for case-insensitive comparisons.
    public var normalizedValue: String { rawValue.lowercased() }

    /// Human-friendly display string intended for UI presentation.
    public var displayName: String {
      guard !rawValue.isEmpty else { return "" }
      return rawValue.localizedCapitalized
    }

    /// Indicates that this descriptor conveys an absence of data (e.g. "n/a").
    public var isNotApplicable: Bool {
      Self.notApplicableTokens.contains(normalizedValue)
    }

    public var description: String { rawValue }

    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }

    fileprivate static func descriptors(from rawList: String) -> [ClimateDescriptor] {
      let segments =
        rawList
        .split(separator: ",")
        .map { ClimateDescriptor(rawValue: String($0)) }
        .filter { !$0.rawValue.isEmpty }
      if segments.count == 1, segments.first?.isNotApplicable == true {
        return []
      }
      return segments
    }
  }

  /// A single terrain descriptor token parsed from SWAPI terrain fields.
  @frozen
  public struct TerrainDescriptor: Hashable, Sendable, Codable, CustomStringConvertible {
    private static let notApplicableTokens: Set<String> = ["n/a", "none", "unknown"]

    /// Original descriptor token trimmed for leading and trailing whitespace.
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Lowercased descriptor value for case-insensitive comparisons.
    public var normalizedValue: String { rawValue.lowercased() }

    /// Human-friendly display string intended for UI presentation.
    public var displayName: String {
      guard !rawValue.isEmpty else { return "" }
      return rawValue.localizedCapitalized
    }

    /// Indicates that this descriptor conveys an absence of data (e.g. "n/a").
    public var isNotApplicable: Bool {
      Self.notApplicableTokens.contains(normalizedValue)
    }

    public var description: String { rawValue }

    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }

    fileprivate static func descriptors(from rawList: String) -> [TerrainDescriptor] {
      let segments =
        rawList
        .split(separator: ",")
        .map { TerrainDescriptor(rawValue: String($0)) }
        .filter { !$0.rawValue.isEmpty }
      if segments.count == 1, segments.first?.isNotApplicable == true {
        return []
      }
      return segments
    }
  }

  /// A single gravity descriptor token parsed from SWAPI gravity fields.
  @frozen
  public struct GravityDescriptor: Hashable, Sendable, Codable, CustomStringConvertible {
    private static let notApplicableTokens: Set<String> = ["n/a", "none", "unknown"]

    /// Original descriptor token trimmed for leading and trailing whitespace.
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Lowercased descriptor value for case-insensitive comparisons.
    public var normalizedValue: String { rawValue.lowercased() }

    /// Human-friendly display string intended for UI presentation.
    public var displayName: String {
      guard !rawValue.isEmpty else { return "" }
      return rawValue.localizedCapitalized
    }

    /// Indicates that this descriptor conveys an absence of data (e.g. "n/a").
    public var isNotApplicable: Bool {
      Self.notApplicableTokens.contains(normalizedValue)
    }

    /// Parsed numeric approximation of the gravity in standard G units, when present.
    public var standardGravityValue: Double? {
      PlanetResponse.metricNumber(from: rawValue)
    }

    public var description: String { rawValue }

    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }

    fileprivate static func descriptors(from rawList: String) -> [GravityDescriptor] {
      let segments =
        rawList
        .split(separator: ",")
        .map { GravityDescriptor(rawValue: String($0)) }
        .filter { !$0.rawValue.isEmpty }
      if segments.count == 1, segments.first?.isNotApplicable == true {
        return []
      }
      return segments
    }
  }

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
