import Foundation
import SwiftData
import API

@Model
public final class SpeciesEntity {
  @Attribute(.unique) public var url: URL
  public var name: String
  public var classification: String
  public var designation: String
  public var averageHeightRaw: String
  public var averageHeightInCentimeters: Double?
  public var averageHeightInMeters: Double?
  public var averageLifespanRaw: String
  public var averageLifespanInYears: Double?
  public var skinColorValues: [String]
  public var hairColorValues: [String]
  public var eyeColorValues: [String]
  public var language: String
  public var created: Date
  public var edited: Date

  @Relationship(deleteRule: .nullify, inverse: \PersonEntity.species)
  public var people: [PersonEntity] = []

  @Relationship(deleteRule: .nullify, inverse: \FilmEntity.species)
  public var films: [FilmEntity] = []

  @Relationship(deleteRule: .nullify, inverse: \PlanetEntity.nativeSpecies)
  public var homeworld: PlanetEntity?

  public init(
    url: URL,
    name: String,
    classification: String,
    designation: String,
    averageHeightRaw: String,
    averageHeightInCentimeters: Double?,
    averageHeightInMeters: Double?,
    averageLifespanRaw: String,
    averageLifespanInYears: Double?,
    skinColorValues: [String],
    hairColorValues: [String],
    eyeColorValues: [String],
    language: String,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.name = name
    self.classification = classification
    self.designation = designation
    self.averageHeightRaw = averageHeightRaw
    self.averageHeightInCentimeters = averageHeightInCentimeters
    self.averageHeightInMeters = averageHeightInMeters
    self.averageLifespanRaw = averageLifespanRaw
    self.averageLifespanInYears = averageLifespanInYears
    self.skinColorValues = skinColorValues
    self.hairColorValues = hairColorValues
    self.eyeColorValues = eyeColorValues
    self.language = language
    self.created = created
    self.edited = edited
  }

  public func apply(response: SpeciesResponse) {
    name = response.name
    classification = response.classification
    designation = response.designation
    averageHeightRaw = response.averageHeight
    averageHeightInCentimeters = response.averageHeightInCentimeters
    averageHeightInMeters = response.averageHeightInMeters
    averageLifespanRaw = response.averageLifespan
    averageLifespanInYears = response.averageLifespanInYears
    skinColorValues = response.skinColor.map(\.rawValue)
    hairColorValues = response.hairColor.map(\.rawValue)
    eyeColorValues = response.eyeColor.map(\.rawValue)
    language = response.language
    created = response.created
    edited = response.edited
  }

  @Transient
  public var id: URL { url }

  @Transient
  public var skinColors: [ColorDescriptor] {
    get { skinColorValues.map { ColorDescriptor(rawValue: $0) } }
    set { skinColorValues = newValue.map(\.rawValue) }
  }

  @Transient
  public var hairColors: [ColorDescriptor] {
    get { hairColorValues.map { ColorDescriptor(rawValue: $0) } }
    set { hairColorValues = newValue.map(\.rawValue) }
  }

  @Transient
  public var eyeColors: [ColorDescriptor] {
    get { eyeColorValues.map { ColorDescriptor(rawValue: $0) } }
    set { eyeColorValues = newValue.map(\.rawValue) }
  }
}
