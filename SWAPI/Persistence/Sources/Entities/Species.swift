import API
import Foundation
import SQLiteData

@Table("species")
public struct Species: Hashable, Identifiable, Sendable {
  @Column(primaryKey: true)
  public var url: URL
  public var name: String
  public var classification: String
  public var designation: String
  public var averageHeight: String
  public var averageLifespan: String
  @Column("skinColors")
  private var skinColorsRaw: String
  @Column("hairColors")
  private var hairColorsRaw: String
  @Column("eyeColors")
  private var eyeColorsRaw: String
  public var language: String
  @Column("homeworldUrl")
  private var homeworldStorage: URL?
  public var created: Date
  public var edited: Date

  public var id: URL { url }

  public var skinColors: [ColorDescriptor] {
    get { ColorDescriptor.descriptors(from: skinColorsRaw) }
    set { skinColorsRaw = Self.joinedRawValues(from: newValue.map(\.rawValue)) }
  }

  public var hairColors: [ColorDescriptor] {
    get { ColorDescriptor.descriptors(from: hairColorsRaw) }
    set { hairColorsRaw = Self.joinedRawValues(from: newValue.map(\.rawValue)) }
  }

  public var eyeColors: [ColorDescriptor] {
    get { ColorDescriptor.descriptors(from: eyeColorsRaw) }
    set { eyeColorsRaw = Self.joinedRawValues(from: newValue.map(\.rawValue)) }
  }

  public var homeworld: URL? {
    get { homeworldStorage }
    set { homeworldStorage = newValue }
  }

  public var homeworldURL: URL? { homeworld }

  public var averageHeightInCentimeters: Double? { Self.metricNumber(from: averageHeight) }
  public var averageHeightInMeters: Double? {
    guard let centimeters = averageHeightInCentimeters else { return nil }
    return centimeters / 100
  }

  public var averageLifespanInYears: Double? { Self.metricNumber(from: averageLifespan) }

  public init(
    url: URL,
    name: String,
    classification: String,
    designation: String,
    averageHeight: String,
    averageLifespan: String,
    skinColors: [ColorDescriptor],
    hairColors: [ColorDescriptor],
    eyeColors: [ColorDescriptor],
    language: String,
    homeworld: URL?,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.name = name
    self.classification = classification
    self.designation = designation
    self.averageHeight = averageHeight
    self.averageLifespan = averageLifespan
    self.skinColorsRaw = Self.joinedRawValues(from: skinColors.map(\.rawValue))
    self.hairColorsRaw = Self.joinedRawValues(from: hairColors.map(\.rawValue))
    self.eyeColorsRaw = Self.joinedRawValues(from: eyeColors.map(\.rawValue))
    self.language = language
    self.homeworldStorage = homeworld
    self.created = created
    self.edited = edited
  }
}

extension Species {
  fileprivate static func metricNumber(from rawValue: String) -> Double? {
    let filtered = rawValue.compactMap { character -> Character? in
      if character.isNumber || character == "." || character == "-" { return character }
      return nil
    }

    guard !filtered.isEmpty else { return nil }
    return Double(String(filtered))
  }

  fileprivate static func joinedRawValues(from rawValues: [String]) -> String {
    rawValues
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: ",")
  }
}
