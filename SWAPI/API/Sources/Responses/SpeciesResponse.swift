import Foundation

/// A model representing a single species returned by the public SWAPI (https://swapi.info).
public struct SpeciesResponse: Codable, Hashable, Sendable, Identifiable {
  /// Stable identifier equal to the canonical resource ``url``.
  public var id: URL { url }

  /// Human-readable species name (e.g. "Human").
  public let name: String

  /// Taxonomic classification string supplied by the API (e.g. "mammal").
  public let classification: String

  /// Designation string (e.g. "sentient"), preserved verbatim from the API.
  public let designation: String

  /// Raw average height string as provided by the API (typically centimeters or "unknown").
  public let averageHeight: String

  /// Parsed numeric average height in centimeters, omitting punctuation or whitespace.
  public var averageHeightInCentimeters: Double? {
    Self.metricNumber(from: averageHeight)
  }

  /// Parsed numeric average height in meters derived from ``averageHeightInCentimeters``.
  public var averageHeightInMeters: Double? {
    guard let centimeters = averageHeightInCentimeters else { return nil }
    return centimeters / 100
  }

  /// Raw average lifespan string as provided by the API.
  public let averageLifespan: String

  /// Parsed numeric average lifespan in years when available.
  public var averageLifespanInYears: Double? {
    Self.metricNumber(from: averageLifespan)
  }

  /// Raw skin color descriptor string as provided by the API.
  let skinColors: String

  /// Derived skin color descriptors parsed from ``skinColorsRawValue``.
  public var skinColor: [ColorDescriptor] {
    ColorDescriptor.descriptors(from: skinColors)
  }

  /// Raw hair color descriptor string as provided by the API.
  let hairColors: String

  /// Derived hair color descriptors parsed from ``hairColorsRawValue``.
  public var hairColor: [ColorDescriptor] {
    ColorDescriptor.descriptors(from: hairColors)
  }

  /// Raw eye color descriptor string as provided by the API.
  let eyeColors: String

  /// Derived eye color descriptors parsed from ``eyeColorsRawValue``.
  public var eyeColor: [ColorDescriptor] {
    ColorDescriptor.descriptors(from: eyeColors)
  }

  /// Primary homeworld resource, if known. `nil` when no planet is associated.
  public let homeworld: URL?

  /// Primary language descriptor supplied by the API.
  public let language: String

  /// Resource URLs representing characters that belong to this species.
  public let people: [URL]

  /// Resource URLs for films featuring this species.
  public let films: [URL]

  /// Creation timestamp of the resource (ISO-8601, supplied by SWAPI).
  public let created: Date

  /// Last edit timestamp of the resource (ISO-8601, supplied by SWAPI).
  public let edited: Date

  /// Canonical URL to this species resource on the API.
  public let url: URL
}

extension SpeciesResponse {
  /// Decodes an array of species from raw JSON `Data` using the type's internal decoder.
  /// - Parameter data: Raw JSON representing an array of species objects.
  /// - Returns: An array of `SpeciesResponse` values.
  /// - Throws: Any decoding error encountered while parsing the payload.
  public static func species(from data: Data) throws -> [SpeciesResponse] {
    try Self.makeDecoder().decode([SpeciesResponse].self, from: data)
  }

  /// Creates a single `SpeciesResponse` by decoding the provided JSON `Data`.
  /// - Parameter data: Raw JSON representing one species object.
  /// - Throws: Any decoding error encountered while parsing the payload.
  public init(data: Data) throws {
    self = try Self.makeDecoder().decode(SpeciesResponse.self, from: data)
  }
}

extension SpeciesResponse {
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
