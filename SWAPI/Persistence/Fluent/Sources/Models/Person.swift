import API
import Fluent
import Foundation

public final class Person: Model, @unchecked Sendable {
  public static let schema = "people"

  @ID(custom: "url", generatedBy: .user)
  public var id: URL?

  @Field(key: "name")
  public var name: String

  @Field(key: "height")
  public var height: String

  @Field(key: "mass")
  public var mass: String

  @Field(key: "hairColors")
  private var hairColorsRaw: String

  @Field(key: "skinColors")
  private var skinColorsRaw: String

  @Field(key: "eyeColors")
  private var eyeColorsRaw: String

  @Field(key: "birthYear")
  private var birthYearRaw: String

  @Field(key: "gender")
  private var genderRaw: String

  @OptionalParent(key: "homeworldUrl")
  public var homeworld: Planet?

  @Field(key: "created")
  public var created: Date

  @Field(key: "edited")
  public var edited: Date

  @Siblings(through: FilmCharacterPivot.self, from: \.$person, to: \.$film)
  public var films: [Film]

  @Siblings(through: PersonSpeciesPivot.self, from: \.$person, to: \.$species)
  public var species: [Species]

  @Siblings(through: PersonStarshipPivot.self, from: \.$person, to: \.$starship)
  public var starships: [Starship]

  @Siblings(through: PersonVehiclePivot.self, from: \.$person, to: \.$vehicle)
  public var vehicles: [Vehicle]

  public var url: URL {
    get {
      guard let id else {
        fatalError("Attempted to access Person.url before the record had an assigned URL")
      }
      return id
    }
    set { id = newValue }
  }

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
    set { hairColorsRaw = Self.joinedColorRaw(from: newValue) }
  }

  public var skinColors: [ColorDescriptor] {
    get { ColorDescriptor.descriptors(from: skinColorsRaw) }
    set { skinColorsRaw = Self.joinedColorRaw(from: newValue) }
  }

  public var eyeColors: [ColorDescriptor] {
    get { ColorDescriptor.descriptors(from: eyeColorsRaw) }
    set { eyeColorsRaw = Self.joinedColorRaw(from: newValue) }
  }

  public var heightInCentimeters: Double? { Self.metricNumber(from: height) }
  public var heightInMeters: Double? {
    guard let centimeters = heightInCentimeters else { return nil }
    return centimeters / 100
  }
  public var massInKilograms: Double? { Self.metricNumber(from: mass) }

  public init() {
    self.name = ""
    self.height = ""
    self.mass = ""
    self.hairColorsRaw = ""
    self.skinColorsRaw = ""
    self.eyeColorsRaw = ""
    self.birthYearRaw = ""
    self.genderRaw = ""
    self.created = .now
    self.edited = .now
  }

  public convenience init(from response: PersonResponse) {
    self.init(
      url: response.url,
      name: response.name,
      height: response.height,
      mass: response.mass,
      hairColors: response.hairColors,
      skinColors: response.skinColors,
      eyeColors: response.eyeColors,
      birthYear: response.birthYear,
      gender: response.gender,
      homeworld: response.homeworld,
      created: response.created,
      edited: response.edited
    )
  }

  public convenience init(
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
    self.init()
  self.url = url
    self.name = name
    self.height = height
    self.mass = mass
    self.hairColorsRaw = Self.joinedColorRaw(from: hairColors)
    self.skinColorsRaw = Self.joinedColorRaw(from: skinColors)
    self.eyeColorsRaw = Self.joinedColorRaw(from: eyeColors)
    self.birthYearRaw = birthYear.rawValue
    self.genderRaw = gender.rawValue
    self.$homeworld.id = homeworld
    self.created = created
    self.edited = edited
  }
}

extension Person {
  private static func metricNumber(from rawValue: String) -> Double? {
    let filtered = rawValue.compactMap { character -> Character? in
      if character.isNumber || character == "." || character == "-" { return character }
      return nil
    }

    guard !filtered.isEmpty else { return nil }
    return Double(String(filtered))
  }

  private static func joinedColorRaw(from descriptors: [ColorDescriptor]) -> String {
    descriptors
      .map(\.rawValue)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: ",")
  }
}
