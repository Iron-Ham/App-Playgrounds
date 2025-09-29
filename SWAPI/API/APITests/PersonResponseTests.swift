import Foundation
import Testing

@testable import API

#if canImport(SwiftUI)
  import SwiftUI
#endif

@Suite("PersonResponseTests", .serialized)
struct PersonResponseTests {
  @Test
  func initialization() throws {
    let luke = try PersonResponse(data: lukeSkywalkerResponse)
    #expect(luke.name == "Luke Skywalker")
    #expect(luke.id == URL(string: "https://swapi.info/api/people/1")!)
    #expect(luke.height == "172")
    #expect(luke.mass == "77")
    #expect(luke.heightInCentimeters == 172)
    let heightMeters = try #require(luke.heightInMeters)
    #expect((heightMeters - 1.72).magnitude < 0.0001)
    #expect(luke.massInKilograms == 77)
    #expect(luke.hairColors.map(\.rawValue) == ["blond"])
    #expect(!luke.hairColors.isEmpty)
    #expect(luke.skinColors.map(\.rawValue) == ["fair"])
    #expect(!luke.skinColors.isEmpty)
    #expect(luke.eyeColors.map(\.rawValue) == ["blue"])
    #expect(!luke.eyeColors.isEmpty)
    #expect(luke.birthYear.rawValue == "19BBY")
    #expect(luke.birthYear.era == .beforeBattleOfYavin)
    #expect(luke.birthYear.magnitude == 19)
    #expect(luke.birthYear.relativeYear == -19)
    #expect(!luke.birthYear.isUnknown)
    #expect(luke.gender == .male)
    #expect(luke.gender.rawValue == "male")
    #expect(luke.gender.displayName == "Male")
    #expect(luke.homeworld.absoluteString == "https://swapi.info/api/planets/1")
    #expect(luke.films.count == 2)
    #expect(luke.vehicles.count == 1)
    #expect(luke.starships.count == 1)
    #expect(luke.species.isEmpty)
    let isoNoFrac = ISO8601DateFormatter()
    isoNoFrac.formatOptions = [.withInternetDateTime]
    #expect(isoNoFrac.string(from: luke.created) == "2014-12-09T13:50:51Z")
    #expect(isoNoFrac.string(from: luke.edited) == "2014-12-20T21:17:56Z")
  }

  @Test
  func arrayDecodingAndNumericCleanup() throws {
    let people = try PersonResponse.people(from: samplePeopleResponse)
    #expect(people.count == 2)
    let luke = try #require(people.first)
    #expect(luke.name == "Luke Skywalker")
    let jabba = try #require(people.last)
    #expect(jabba.name == "Jabba Desilijic Tiure")
    #expect(jabba.mass == "1,358")
    #expect(jabba.massInKilograms == 1_358)
    #expect(jabba.heightInCentimeters == 175)
    #expect(jabba.heightInMeters == 1.75)
    #expect(jabba.hairColors.isEmpty)
    #expect(jabba.skinColors.map(\.rawValue) == ["green-tan", "brown"])
    #expect(jabba.birthYear.rawValue == "600BBY")
    #expect(jabba.birthYear.magnitude == 600)
    #expect(jabba.birthYear.era == .beforeBattleOfYavin)
    #expect(jabba.films.count == 2)
    #expect(jabba.gender == .hermaphrodite)
    #expect(jabba.gender.rawValue == "hermaphrodite")
    #expect(jabba.gender.displayName == "Hermaphrodite")
  }

  @Test
  func genderNormalization() throws {
    let r2d2 = try PersonResponse(data: r2D2Response)
    #expect(r2d2.gender == .notApplicable)
    #expect(r2d2.gender.rawValue == "n/a")
    #expect(r2d2.gender.displayName == "Not applicable")
    #expect(r2d2.hairColors.isEmpty)
    #expect(r2d2.skinColors.map(\.rawValue) == ["white", "blue"])
    #expect(r2d2.eyeColors.map(\.rawValue) == ["red"])
    #expect(r2d2.birthYear.magnitude == 33)
    #expect(r2d2.birthYear.era == .beforeBattleOfYavin)

    let custom = try PersonResponse(data: customGenderResponse)
    #expect(custom.gender == .other("fungus"))
    #expect(custom.gender.rawValue == "fungus")
    #expect(custom.gender.displayName == "Fungus")
    #expect(custom.hairColors.map(\.rawValue) == ["spores"])
    #expect(custom.birthYear.rawValue == "unknown")
    #expect(custom.birthYear.isUnknown)
  }

  #if canImport(SwiftUI)
    @Test
    func colorDescriptorMapping() {
      let blond = ColorDescriptor(rawValue: "blond")
      let blueGray = ColorDescriptor(rawValue: "blue-gray")
      let spores = ColorDescriptor(rawValue: "spores")
      let notApplicable = ColorDescriptor(rawValue: "n/a")

      #expect(blond.color != nil)
      #expect(blueGray.color != nil)
      #expect(spores.color == nil)
      #expect(notApplicable.color == nil)
    }
  #endif
}

private let lukeSkywalkerResponse = #"""
  {
    "name": "Luke Skywalker",
    "height": "172",
    "mass": "77",
    "hair_color": "blond",
    "skin_color": "fair",
    "eye_color": "blue",
    "birth_year": "19BBY",
    "gender": "male",
    "homeworld": "https://swapi.info/api/planets/1",
    "films": [
      "https://swapi.info/api/films/1",
      "https://swapi.info/api/films/2"
    ],
    "species": [],
    "vehicles": [
      "https://swapi.info/api/vehicles/14"
    ],
    "starships": [
      "https://swapi.info/api/starships/12"
    ],
    "created": "2014-12-09T13:50:51.644000Z",
    "edited": "2014-12-20T21:17:56.891000Z",
    "url": "https://swapi.info/api/people/1"
  }
  """#.data(using: .utf8)!

private let r2D2Response = #"""
  {
    "name": "R2-D2",
    "height": "96",
    "mass": "32",
    "hair_color": "n/a",
    "skin_color": "white, blue",
    "eye_color": "red",
    "birth_year": "33BBY",
    "gender": "n/a",
    "homeworld": "https://swapi.info/api/planets/8",
    "films": [],
    "species": ["https://swapi.info/api/species/2"],
    "vehicles": [],
    "starships": [],
    "created": "2014-12-10T15:11:50.376000Z",
    "edited": "2014-12-20T21:17:50.311000Z",
    "url": "https://swapi.info/api/people/3"
  }
  """#.data(using: .utf8)!

private let customGenderResponse = #"""
  {
    "name": "Borg Fungus",
    "height": "100",
    "mass": "20",
    "hair_color": "spores",
    "skin_color": "green",
    "eye_color": "amber",
    "birth_year": "unknown",
    "gender": "fungus",
    "homeworld": "https://swapi.info/api/planets/99",
    "films": [],
    "species": [],
    "vehicles": [],
    "starships": [],
    "created": "2014-12-19T17:57:41.191000Z",
    "edited": "2014-12-20T21:17:50.401000Z",
    "url": "https://swapi.info/api/people/103"
  }
  """#.data(using: .utf8)!

private let samplePeopleResponse = #"""
  [
    {
      "name": "Luke Skywalker",
      "height": "172",
      "mass": "77",
      "hair_color": "blond",
      "skin_color": "fair",
      "eye_color": "blue",
      "birth_year": "19BBY",
      "gender": "male",
      "homeworld": "https://swapi.info/api/planets/1",
      "films": [
        "https://swapi.info/api/films/1",
        "https://swapi.info/api/films/2"
      ],
      "species": [],
      "vehicles": [
        "https://swapi.info/api/vehicles/14"
      ],
      "starships": [
        "https://swapi.info/api/starships/12"
      ],
      "created": "2014-12-09T13:50:51.644000Z",
      "edited": "2014-12-20T21:17:56.891000Z",
      "url": "https://swapi.info/api/people/1"
    },
    {
      "name": "Jabba Desilijic Tiure",
      "height": "175",
      "mass": "1,358",
      "hair_color": "n/a",
      "skin_color": "green-tan, brown",
      "eye_color": "orange",
      "birth_year": "600BBY",
      "gender": "hermaphrodite",
      "homeworld": "https://swapi.info/api/planets/24",
      "films": [
        "https://swapi.info/api/films/3",
        "https://swapi.info/api/films/4"
      ],
      "species": [
        "https://swapi.info/api/species/5"
      ],
      "vehicles": [],
      "starships": [],
      "created": "2014-12-10T17:11:31.638000Z",
      "edited": "2014-12-20T21:17:50.338000Z",
      "url": "https://swapi.info/api/people/16"
    }
  ]
  """#.data(using: .utf8)!
