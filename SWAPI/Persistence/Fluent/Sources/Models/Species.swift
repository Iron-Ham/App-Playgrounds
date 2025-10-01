import API
import Fluent
import Foundation

public final class Species: Model, @unchecked Sendable {
  public static let schema = "species"

  @ID(custom: "url", generatedBy: .user)
  public var id: URL?

  @Field(key: "name")
  public var name: String

  @Field(key: "classification")
  public var classification: String

  @Field(key: "designation")
  public var designation: String

  @Field(key: "averageHeight")
  public var averageHeight: String

  @Field(key: "averageLifespan")
  public var averageLifespan: String

  @Field(key: "skinColors")
  private var skinColorsRaw: String

  @Field(key: "hairColors")
  private var hairColorsRaw: String

  @Field(key: "eyeColors")
  private var eyeColorsRaw: String

  @OptionalParent(key: "homeworldUrl")
  public var homeworld: Planet?

  @Field(key: "language")
  public var language: String

  @Field(key: "created")
  public var created: Date

  @Field(key: "edited")
  public var edited: Date

  @Siblings(through: FilmSpeciesPivot.self, from: \.$species, to: \.$film)
  public var films: [Film]

  @Siblings(through: PersonSpeciesPivot.self, from: \.$species, to: \.$person)
  public var members: [Person]

  public var url: URL {
    get {
      guard let id else {
        fatalError("Attempted to access Species.url before the record had an assigned URL")
      }
      return id
    }
    set { id = newValue }
  }

  public var skinColor: [ColorDescriptor] {
    get { ColorDescriptor.descriptors(from: skinColorsRaw) }
    set { skinColorsRaw = Self.joinedColorRaw(from: newValue) }
  }

  public var hairColor: [ColorDescriptor] {
    get { ColorDescriptor.descriptors(from: hairColorsRaw) }
    set { hairColorsRaw = Self.joinedColorRaw(from: newValue) }
  }

  public var eyeColor: [ColorDescriptor] {
    get { ColorDescriptor.descriptors(from: eyeColorsRaw) }
    set { eyeColorsRaw = Self.joinedColorRaw(from: newValue) }
  }

  public var averageHeightInCentimeters: Double? { Self.metricNumber(from: averageHeight) }
  public var averageHeightInMeters: Double? {
    guard let centimeters = averageHeightInCentimeters else { return nil }
    return centimeters / 100
  }
  public var averageLifespanInYears: Double? { Self.metricNumber(from: averageLifespan) }

  public init() {
    self.name = ""
    self.classification = ""
    self.designation = ""
    self.averageHeight = ""
    self.averageLifespan = ""
    self.skinColorsRaw = ""
    self.hairColorsRaw = ""
    self.eyeColorsRaw = ""
    self.language = ""
    self.created = .now
    self.edited = .now
  }

  public convenience init(from response: SpeciesResponse) {
    self.init(
      url: response.url,
      name: response.name,
      classification: response.classification,
      designation: response.designation,
      averageHeight: response.averageHeight,
      averageLifespan: response.averageLifespan,
      skinColor: response.skinColor,
      hairColor: response.hairColor,
      eyeColor: response.eyeColor,
      homeworld: response.homeworld,
      language: response.language,
      created: response.created,
      edited: response.edited
    )
  }

  public convenience init(
    url: URL,
    name: String,
    classification: String,
    designation: String,
    averageHeight: String,
    averageLifespan: String,
    skinColor: [ColorDescriptor],
    hairColor: [ColorDescriptor],
    eyeColor: [ColorDescriptor],
    homeworld: URL?,
    language: String,
    created: Date,
    edited: Date
  ) {
    self.init()
  self.url = url
    self.name = name
    self.classification = classification
    self.designation = designation
    self.averageHeight = averageHeight
    self.averageLifespan = averageLifespan
    self.skinColorsRaw = Self.joinedColorRaw(from: skinColor)
    self.hairColorsRaw = Self.joinedColorRaw(from: hairColor)
    self.eyeColorsRaw = Self.joinedColorRaw(from: eyeColor)
    self.$homeworld.id = homeworld
    self.language = language
    self.created = created
    self.edited = edited
  }
}

extension Species {
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
