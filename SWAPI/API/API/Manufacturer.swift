import Foundation

/// Represents a starship or vehicle manufacturer with normalized identity semantics.
public struct Manufacturer: Hashable, Sendable, Codable {
  /// Original manufacturer name as provided by the API after trimming white space.
  public let rawName: String

  /// Normalized identifier used for hashing and equality comparisons.
  public let identifier: String

  /// Display-friendly manufacturer name, potentially canonicalized from known variants.
  public let displayName: String

  public init(rawName: String) {
    let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
    self.rawName = trimmed

    let normalization = Manufacturer.normalization(for: trimmed)

    if let canonical = Manufacturer.canonicalManufacturers[normalization.identifier] {
      self.identifier = canonical.identifier
      self.displayName = canonical.displayName
    } else {
      self.identifier = normalization.identifier
      self.displayName = normalization.displayName
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let value = try container.decode(String.self)
    self.init(rawName: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawName)
  }
}

extension Manufacturer {
  public static func == (lhs: Manufacturer, rhs: Manufacturer) -> Bool {
    lhs.identifier == rhs.identifier
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(identifier)
  }
}

extension Manufacturer {
  /// Creates a canonical identifier string for a manufacturer, collapsing well-known suffixes.
  /// - Parameter value: Raw manufacturer value.
  /// - Returns: Lowercased canonical string without corporate suffix variations.
  fileprivate static func normalizedIdentifier(for value: String) -> String {
    normalization(for: value).identifier
  }

  private static func normalization(for value: String) -> (identifier: String, displayName: String)
  {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

    var candidate = trimmed
    var lowercase = candidate.lowercased()

    let suffixes = [", inc.", ", inc", ", incorporated", " inc.", " inc", " incorporated"]
    while let suffix = suffixes.first(where: { lowercase.hasSuffix($0) }) {
      candidate = String(candidate.dropLast(suffix.count)).trimmingCharacters(
        in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",")))
      lowercase = candidate.lowercased()
    }

    let disallowedCharacters = CharacterSet(charactersIn: ".")
    let strippedScalars = lowercase.unicodeScalars.filter { !disallowedCharacters.contains($0) }
    let identifier = String(String.UnicodeScalarView(strippedScalars)).trimmingCharacters(
      in: .whitespacesAndNewlines)

    let display = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
    return (identifier: identifier, displayName: display.isEmpty ? trimmed : display)
  }

  /// Parses a raw manufacturer string into a unique, order-preserving list of ``Manufacturer`` values.
  /// - Parameter raw: Raw comma- and slash-delimited manufacturer string supplied by the API.
  /// - Returns: Array of normalized manufacturers preserving input order but removing duplicates.
  public static func manufacturers(from raw: String) -> [Manufacturer] {
    let slashSeparated = raw.split(separator: "/", omittingEmptySubsequences: false)

    var manufacturers: [Manufacturer] = []
    var seen: Set<String> = []

    for segment in slashSeparated {
      let trimmedSegment = segment.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmedSegment.isEmpty else { continue }

      for name in Self.segmentNames(from: trimmedSegment) {
        let manufacturer = Manufacturer(rawName: name)
        if seen.insert(manufacturer.identifier).inserted {
          manufacturers.append(manufacturer)
        }
      }
    }

    return manufacturers
  }

  private static func segmentNames(from segment: String) -> [String] {
    var components: [String] = []
    var buffer = ""

    let parts = segment.split(separator: ",", omittingEmptySubsequences: false)

    for part in parts {
      let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { continue }

      if buffer.isEmpty {
        buffer = trimmed
      } else if isCorporateSuffix(trimmed) {
        buffer += ", " + trimmed
        continue
      } else {
        components.append(buffer)
        buffer = trimmed
        continue
      }

      if isCorporateSuffix(trimmed) {
        continue
      }
    }

    if !buffer.isEmpty {
      components.append(buffer)
    }

    return components
  }

  private static func isCorporateSuffix(_ value: String) -> Bool {
    switch value.lowercased() {
    case "inc", "inc.", "incorporated":
      return true
    default:
      return false
    }
  }
}

extension Manufacturer {
  private struct CanonicalRecord {
    let identifier: String
    let displayName: String
  }

  private struct CanonicalEntry {
    let displayName: String
    let aliases: [String]

    init(_ displayName: String, aliases: [String] = []) {
      self.displayName = displayName
      self.aliases = aliases
    }
  }

  private static let canonicalEntries: [CanonicalEntry] = [
    CanonicalEntry("Alliance Underground Engineering"),
    CanonicalEntry("Allanteen Six Shipyards"),
    CanonicalEntry("Appazanna Engineering Works"),
    CanonicalEntry("Aratech Repulsor Company"),
    CanonicalEntry("Baktoid Armor Workshop"),
    CanonicalEntry("Baktoid Fleet Ordnance"),
    CanonicalEntry("Bespin Motors"),
    CanonicalEntry("Botajef Shipyards"),
    CanonicalEntry("Colla Designs"),
    CanonicalEntry("Corellia Mining Corporation"),
    CanonicalEntry("Corellian Engineering Corporation"),
    CanonicalEntry("Cygnus Spaceworks", aliases: ["Cyngus Spaceworks"]),
    CanonicalEntry("Desler Gizh Outworld Mobility Corporation"),
    CanonicalEntry("Feethan Ottraw Scalable Assemblies"),
    CanonicalEntry("Fondor Shipyards"),
    CanonicalEntry("Free Dac Volunteers Engineering Corps"),
    CanonicalEntry("Gallofree Yards"),
    CanonicalEntry("Gwori Revolutionary Industries"),
    CanonicalEntry("Haor Chall Engineering"),
    CanonicalEntry("Hoersch-Kessel Drive"),
    CanonicalEntry("Huppla Pasa Tisc Shipwrights Collective"),
    CanonicalEntry("Imperial Department of Military Research"),
    CanonicalEntry("Incom Corporation"),
    CanonicalEntry("Koensayr Manufacturing"),
    CanonicalEntry("Kuat Drive Yards"),
    CanonicalEntry("Kuat Systems Engineering"),
    CanonicalEntry("Mon Calamari Shipyards"),
    CanonicalEntry("Mobquet Swoops and Speeders"),
    CanonicalEntry("Narglatch AirTech Prefabricated Kit"),
    CanonicalEntry("Nubia Star Drives"),
    CanonicalEntry("Otoh Gunga Bongameken Cooperative"),
    CanonicalEntry("Phlac-Arphocc Automata Industries"),
    CanonicalEntry("Razalon"),
    CanonicalEntry("Rendili StarDrive"),
    CanonicalEntry("Republic Sienar Systems"),
    CanonicalEntry("Rothana Heavy Engineering"),
    CanonicalEntry("Sienar Fleet Systems"),
    CanonicalEntry("Slayn & Korpil"),
    CanonicalEntry("SoroSuub Corporation"),
    CanonicalEntry("Techno Union"),
    CanonicalEntry("Theed Palace Space Vessel Engineering Corps"),
    CanonicalEntry("Ubrikkian Industries"),
    CanonicalEntry("Ubrikkian Industries Custom Vehicle Division"),
    CanonicalEntry("Unknown", aliases: ["unknown"]),
    CanonicalEntry("Z-Gomot Ternbuell Guppat Corporation"),
  ]

  private static let canonicalManufacturers: [String: CanonicalRecord] = {
    var records: [String: CanonicalRecord] = [:]

    func insert(_ key: String, record: CanonicalRecord) {
      guard records[key] == nil else { return }
      records[key] = record
    }

    for entry in canonicalEntries {
      let identifier = Manufacturer.normalizedIdentifier(for: entry.displayName)
      let record = CanonicalRecord(identifier: identifier, displayName: entry.displayName)
      insert(identifier, record: record)

      for alias in entry.aliases {
        let aliasIdentifier = Manufacturer.normalizedIdentifier(for: alias)
        insert(aliasIdentifier, record: record)
      }
    }

    return records
  }()
}
