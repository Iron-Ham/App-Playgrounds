import API
import Foundation
import SQLiteData

@Table("people")
public struct Person: Hashable, Identifiable, Sendable {
  @Column(primaryKey: true)
  public var url: URL
  public var name: String
  public var height: String
  public var mass: String
  @Column("hairColors")
  private var hairColorsRaw: String
  @Column("skinColors")
  private var skinColorsRaw: String
  @Column("eyeColors")
  private var eyeColorsRaw: String
  @Column("birthYear")
  private var birthYearRaw: String
  @Column("gender")
  private var genderRaw: String
  @Column("homeworldUrl")
  public var homeworldUrl: URL?
  public var created: Date
  public var edited: Date

  public var id: URL { url }

  public var birthYear: PersonResponse.BirthYear {
    get { PersonResponse.BirthYear(rawValue: birthYearRaw) }
    set { birthYearRaw = newValue.rawValue }
  }

  public var gender: PersonResponse.Gender {
    get { PersonResponse.Gender(rawValue: genderRaw) }
    set { genderRaw = newValue.rawValue }
  }

  public var hairColors: [ColorDescriptor] {
    get { ColorDescriptor.descriptors(from: hairColorsRaw) }
    set { hairColorsRaw = newValue.map(\.rawValue).joined(separator: ",") }
  }

  public var skinColors: [ColorDescriptor] {
    get { ColorDescriptor.descriptors(from: skinColorsRaw) }
    set { skinColorsRaw = newValue.map(\.rawValue).joined(separator: ",") }
  }

  public var eyeColors: [ColorDescriptor] {
    get { ColorDescriptor.descriptors(from: eyeColorsRaw) }
    set { eyeColorsRaw = newValue.map(\.rawValue).joined(separator: ",") }
  }

  public var heightInCentimeters: Double? { Self.metricNumber(from: height) }
  public var heightInMeters: Double? {
    guard let centimeters = heightInCentimeters else { return nil }
    return centimeters / 100
  }

  public var massInKilograms: Double? { Self.metricNumber(from: mass) }

  public init(
    url: URL,
    name: String,
    height: String,
    mass: String,
    hairColors: [ColorDescriptor],
    skinColors: [ColorDescriptor],
    eyeColors: [ColorDescriptor],
    birthYear: PersonResponse.BirthYear,
    gender: PersonResponse.Gender,
    homeworld: URL?,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.name = name
    self.height = height
    self.mass = mass
    self.hairColorsRaw = hairColors.map(\.rawValue).joined(separator: ",")
    self.skinColorsRaw = skinColors.map(\.rawValue).joined(separator: ",")
    self.eyeColorsRaw = eyeColors.map(\.rawValue).joined(separator: ",")
    self.birthYearRaw = birthYear.rawValue
    self.genderRaw = gender.rawValue
    self.homeworldUrl = homeworld
    self.created = created
    self.edited = edited
  }
}

extension Person {
  fileprivate static func metricNumber(from rawValue: String) -> Double? {
    let filtered = rawValue.compactMap { character -> Character? in
      if character.isNumber || character == "." || character == "-" { return character }
      return nil
    }

    guard !filtered.isEmpty else { return nil }
    return Double(String(filtered))
  }
}
