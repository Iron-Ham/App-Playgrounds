import Foundation
import SwiftData
import API

@Model
public final class PersonEntity {
  @Attribute(.unique) public var url: URL
  public var name: String
  public var heightRaw: String
  public var massRaw: String
  public var heightInCentimeters: Double?
  public var massInKilograms: Double?
  public var hairColorValues: [String]
  public var skinColorValues: [String]
  public var eyeColorValues: [String]
  public var birthYearRaw: String
  public var genderRaw: String
  public var created: Date
  public var edited: Date

  @Relationship(deleteRule: .nullify, inverse: \PlanetEntity.residents)
  public var homeworld: PlanetEntity?

  @Relationship(deleteRule: .nullify, inverse: \FilmEntity.characters)
  public var films: [FilmEntity] = []

  @Relationship(deleteRule: .nullify)
  public var species: [SpeciesEntity] = []

  @Relationship(deleteRule: .nullify)
  public var vehicles: [VehicleEntity] = []

  @Relationship(deleteRule: .nullify)
  public var starships: [StarshipEntity] = []

  public init(
    url: URL,
    name: String,
    heightRaw: String,
    massRaw: String,
    heightInCentimeters: Double?,
    massInKilograms: Double?,
    hairColorValues: [String],
    skinColorValues: [String],
    eyeColorValues: [String],
    birthYearRaw: String,
    genderRaw: String,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.name = name
    self.heightRaw = heightRaw
    self.massRaw = massRaw
    self.heightInCentimeters = heightInCentimeters
    self.massInKilograms = massInKilograms
    self.hairColorValues = hairColorValues
    self.skinColorValues = skinColorValues
    self.eyeColorValues = eyeColorValues
    self.birthYearRaw = birthYearRaw
    self.genderRaw = genderRaw
    self.created = created
    self.edited = edited
  }

  public func apply(response: PersonResponse) {
    name = response.name
    heightRaw = response.height
    massRaw = response.mass
    heightInCentimeters = response.heightInCentimeters
    massInKilograms = response.massInKilograms
    hairColorValues = response.hairColors.map(\.rawValue)
    skinColorValues = response.skinColors.map(\.rawValue)
    eyeColorValues = response.eyeColors.map(\.rawValue)
    birthYearRaw = response.birthYear.rawValue
    genderRaw = response.gender.rawValue
    created = response.created
    edited = response.edited
  }

  @Transient
  public var id: URL { url }

  @Transient
  public var hairColors: [ColorDescriptor] {
    get { hairColorValues.map { ColorDescriptor(rawValue: $0) } }
    set { hairColorValues = newValue.map(\.rawValue) }
  }

  @Transient
  public var skinColors: [ColorDescriptor] {
    get { skinColorValues.map { ColorDescriptor(rawValue: $0) } }
    set { skinColorValues = newValue.map(\.rawValue) }
  }

  @Transient
  public var eyeColors: [ColorDescriptor] {
    get { eyeColorValues.map { ColorDescriptor(rawValue: $0) } }
    set { eyeColorValues = newValue.map(\.rawValue) }
  }

  @Transient
  public var birthYear: PersonResponse.BirthYear {
    get { PersonResponse.BirthYear(rawValue: birthYearRaw) }
    set { birthYearRaw = newValue.rawValue }
  }

  @Transient
  public var gender: PersonResponse.Gender {
    get { PersonResponse.Gender(rawValue: genderRaw) }
    set { genderRaw = newValue.rawValue }
  }
}
