import Foundation

#if canImport(SwiftUI)
  import SwiftUI
#endif

/// A single color descriptor token parsed from SWAPI appearance fields.
@frozen
public struct ColorDescriptor: Hashable, Sendable, Codable, CustomStringConvertible {
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
    ColorDescriptor.notApplicableTokens.contains(normalizedValue)
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

  static func descriptors(from rawList: String) -> [ColorDescriptor] {
    let segments =
      rawList
      .split(separator: ",")
      .map { ColorDescriptor(rawValue: String($0)) }
      .filter { !$0.rawValue.isEmpty }
    if segments.count == 1, segments.first?.isNotApplicable == true {
      return []
    }
    return segments
  }

  static func isNotApplicable(list rawList: String) -> Bool {
    let segments =
      rawList
      .split(separator: ",")
      .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    guard segments.count == 1, let first = segments.first else { return false }
    return notApplicableTokens.contains(first.lowercased())
  }

  static func normalizedValues(from rawList: String) -> [String] {
    descriptors(from: rawList).map(\.normalizedValue)
  }

  #if canImport(SwiftUI)
    /// Attempts to provide a representative SwiftUI color for the descriptor.
    public var color: Color? {
      guard !isNotApplicable else { return nil }
      if let direct = Self.namedColors[normalizedValue] {
        return direct
      }

      let components =
        normalizedValue
        .replacingOccurrences(of: "-", with: " ")
        .replacingOccurrences(of: "/", with: " ")
        .split(whereSeparator: { !$0.isLetter })

      for component in components {
        if let match = Self.namedColors[String(component)] {
          return match
        }
      }

      return nil
    }

    private static func makeColor(_ red: Double, _ green: Double, _ blue: Double) -> Color {
      Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }

    private static let namedColors: [String: Color] = [
      "amber": ColorDescriptor.makeColor(0.99, 0.75, 0.24),
      "auburn": ColorDescriptor.makeColor(0.65, 0.32, 0.17),
      "black": .black,
      "blond": ColorDescriptor.makeColor(0.97, 0.91, 0.72),
      "blue": .blue,
      "blue-gray": ColorDescriptor.makeColor(0.44, 0.61, 0.73),
      "bronze": ColorDescriptor.makeColor(0.80, 0.58, 0.24),
      "brown": ColorDescriptor.makeColor(0.55, 0.36, 0.20),
      "brown mottle": ColorDescriptor.makeColor(0.42, 0.29, 0.20),
      "dark": ColorDescriptor.makeColor(0.25, 0.22, 0.19),
      "fair": ColorDescriptor.makeColor(0.96, 0.89, 0.80),
      "gold": ColorDescriptor.makeColor(0.85, 0.65, 0.13),
      "green": .green,
      "green-tan": ColorDescriptor.makeColor(0.69, 0.67, 0.46),
      "grey": ColorDescriptor.makeColor(0.60, 0.60, 0.60),
      "gray": ColorDescriptor.makeColor(0.60, 0.60, 0.60),
      "hazel": ColorDescriptor.makeColor(0.56, 0.47, 0.34),
      "light": ColorDescriptor.makeColor(0.88, 0.82, 0.72),
      "magenta": ColorDescriptor.makeColor(0.89, 0.13, 0.49),
      "metal": ColorDescriptor.makeColor(0.69, 0.69, 0.72),
      "orange": .orange,
      "pink": ColorDescriptor.makeColor(0.95, 0.75, 0.80),
      "purple": ColorDescriptor.makeColor(0.65, 0.33, 0.80),
      "red": .red,
      "sand": ColorDescriptor.makeColor(0.87, 0.77, 0.58),
      "silver": ColorDescriptor.makeColor(0.75, 0.75, 0.78),
      "tan": ColorDescriptor.makeColor(0.82, 0.70, 0.55),
      "teal": ColorDescriptor.makeColor(0.00, 0.50, 0.50),
      "white": .white,
      "yellow": .yellow,
    ]
  #endif
}
