import Foundation

/// A model representing a single Star Wars film returned by the public SWAPI (https://swapi.info).
public struct FilmResponse: Codable, Hashable, Sendable, Identifiable {
  /// Stable identifier equal to the canonical resource ``url``.
  public var id: URL { url }

  /// Human‑readable film title (e.g. "A New Hope").
  public let title: String

  /// Numeric episode identifier in release / saga order, used as the model `id`.
  public let episodeId: Int

  /// Full opening crawl text as provided by the API. Newlines and spacing are preserved.
  public let openingCrawl: String

  /// Primary credited director for the film.
  public let director: String

  /// Raw producer field from the API (comma‑separated). Not public; prefer `producers`.
  let producer: String

  /// Parsed list of individual producer names derived from the raw comma‑separated `producer` string.
  /// Whitespace (including newlines) around each name is trimmed.
  public var producers: [String] {
    producer
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
  }

  /// Raw release date string from the API (format `yyyy-MM-dd`).
  private let releaseDate: String

  /// Parsed ``Date`` representation of the film's release date (format `yyyy-MM-dd`).
  /// Returns `nil` if the date string is invalid or the formatter fails.
  public var release: Date? {
    FilmResponse.releaseDateFormatter.date(from: releaseDate)
  }

  /// Resource URLs for character endpoints appearing in this film.
  public let characters: [URL]

  /// Resource URLs for planet endpoints featured in this film.
  public let planets: [URL]

  /// Resource URLs for starship endpoints featured in this film.
  public let starships: [URL]

  /// Resource URLs for vehicle endpoints featured in this film.
  public let vehicles: [URL]

  /// Resource URLs for species endpoints featured in this film.
  public let species: [URL]

  /// Creation timestamp of this film resource (ISO‑8601, supplied by SWAPI).
  public let created: Date

  /// Last edit timestamp of this film resource (ISO‑8601, supplied by SWAPI).
  public let edited: Date

  /// Canonical URL to this film resource on the API.
  public let url: URL
}

extension FilmResponse {
  /// Decodes an array of films from raw JSON `Data` using the type's internal decoder.
  /// - Parameter data: Raw JSON representing an array of film objects.
  /// - Returns: An array of `FilmResponse` values.
  /// - Throws: Any decoding error encountered while parsing the payload.
  public static func films(from data: Data) throws -> [FilmResponse] {
    try Self.decoder.decode([FilmResponse].self, from: data)
  }

  /// Creates a single `FilmResponse` by decoding the provided JSON `Data`.
  /// - Parameter data: Raw JSON representing one film object.
  /// - Throws: Any decoding error encountered while parsing the payload.
  public init(data: Data) throws {
    self = try Self.decoder.decode(FilmResponse.self, from: data)
  }
}

extension FilmResponse {
  private nonisolated static let releaseDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter
  }()

  private static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()
}
