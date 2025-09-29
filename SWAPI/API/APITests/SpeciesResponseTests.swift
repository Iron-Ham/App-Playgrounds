import Foundation
import Testing

@testable import API

@Suite("SpeciesResponseTests", .serialized)
struct SpeciesResponseTests {
  @Test
  func initialization() throws {
    let human = try SpeciesResponse(data: humanSpeciesResponse)
    #expect(human.name == "Human")
    #expect(human.id == URL(string: "https://swapi.info/api/species/1")!)
    #expect(human.classification == "mammal")
    #expect(human.designation == "sentient")
    #expect(human.averageHeight == "180")
    let heightCentimeters = try #require(human.averageHeightInCentimeters)
    #expect(heightCentimeters == 180)
    let heightMeters = try #require(human.averageHeightInMeters)
    #expect((heightMeters - 1.8).magnitude < 0.0001)
    #expect(human.averageLifespan == "120")
    #expect(human.averageLifespanInYears == 120)
    #expect(human.hairColor.map(\.rawValue) == ["blonde", "brown", "black", "red"])
    #expect(human.skinColor.map(\.rawValue) == ["caucasian", "black", "asian", "hispanic"])
    #expect(human.eyeColor.map(\.rawValue) == ["brown", "blue", "green", "hazel", "grey", "amber"])
    let homeworld = try #require(human.homeworld)
    #expect(homeworld.absoluteString == "https://swapi.info/api/planets/9")
    #expect(human.language == "Galactic Basic")
    #expect(human.people.count == 4)
    #expect(human.films.count == 6)
    let isoNoFrac = ISO8601DateFormatter()
    isoNoFrac.formatOptions = [.withInternetDateTime]
    #expect(isoNoFrac.string(from: human.created) == "2014-12-10T13:52:11Z")
    #expect(isoNoFrac.string(from: human.edited) == "2014-12-20T21:36:42Z")
  }

  @Test
  func arrayDecodingAndMetricParsing() throws {
    let species = try SpeciesResponse.species(from: sampleSpeciesArrayResponse)
    #expect(species.count == 2)
    let human = try #require(species.first)
    let droid = try #require(species.last)

    #expect(human.name == "Human")
    #expect(droid.name == "Droid")
    #expect(droid.classification == "artificial")
    #expect(droid.designation == "sentient")
    #expect(droid.averageHeight == "n/a")
    #expect(droid.averageHeightInCentimeters == nil)
    #expect(droid.averageHeightInMeters == nil)
    #expect(droid.averageLifespan == "indefinite")
    #expect(droid.averageLifespanInYears == nil)
    #expect(droid.homeworld == nil)
    #expect(droid.language == "n/a")
    #expect(droid.people.count == 4)
    #expect(droid.films.count == 6)
    #expect(droid.hairColor.isEmpty)
    #expect(droid.skinColor.isEmpty)
    #expect(droid.eyeColor.isEmpty)
  }

  #if canImport(SwiftUI)
    @Test
    func colorDescriptorAlias() {
      let descriptors = ColorDescriptor.descriptors(from: "orange, amber")
      #expect(descriptors.count == 2)
      #expect(descriptors.map(\.displayName) == ["Orange", "Amber"])
    }
  #endif
}

private let humanSpeciesResponse = #"""
  {
    "name": "Human",
    "classification": "mammal",
    "designation": "sentient",
    "average_height": "180",
    "skin_colors": "caucasian, black, asian, hispanic",
    "hair_colors": "blonde, brown, black, red",
    "eye_colors": "brown, blue, green, hazel, grey, amber",
    "average_lifespan": "120",
    "homeworld": "https://swapi.info/api/planets/9",
    "language": "Galactic Basic",
    "people": [
      "https://swapi.info/api/people/66",
      "https://swapi.info/api/people/67",
      "https://swapi.info/api/people/68",
      "https://swapi.info/api/people/74"
    ],
    "films": [
      "https://swapi.info/api/films/1",
      "https://swapi.info/api/films/2",
      "https://swapi.info/api/films/3",
      "https://swapi.info/api/films/4",
      "https://swapi.info/api/films/5",
      "https://swapi.info/api/films/6"
    ],
    "created": "2014-12-10T13:52:11.567000Z",
    "edited": "2014-12-20T21:36:42.136000Z",
    "url": "https://swapi.info/api/species/1"
  }
  """#.data(using: .utf8)!

private let sampleSpeciesArrayResponse = #"""
  [
    {
      "name": "Human",
      "classification": "mammal",
      "designation": "sentient",
      "average_height": "180",
      "skin_colors": "caucasian, black, asian, hispanic",
      "hair_colors": "blonde, brown, black, red",
      "eye_colors": "brown, blue, green, hazel, grey, amber",
      "average_lifespan": "120",
      "homeworld": "https://swapi.info/api/planets/9",
      "language": "Galactic Basic",
      "people": [
        "https://swapi.info/api/people/66",
        "https://swapi.info/api/people/67",
        "https://swapi.info/api/people/68",
        "https://swapi.info/api/people/74"
      ],
      "films": [
        "https://swapi.info/api/films/1",
        "https://swapi.info/api/films/2",
        "https://swapi.info/api/films/3",
        "https://swapi.info/api/films/4",
        "https://swapi.info/api/films/5",
        "https://swapi.info/api/films/6"
      ],
      "created": "2014-12-10T13:52:11.567000Z",
      "edited": "2014-12-20T21:36:42.136000Z",
      "url": "https://swapi.info/api/species/1"
    },
    {
      "name": "Droid",
      "classification": "artificial",
      "designation": "sentient",
      "average_height": "n/a",
      "skin_colors": "n/a",
      "hair_colors": "n/a",
      "eye_colors": "n/a",
      "average_lifespan": "indefinite",
      "homeworld": null,
      "language": "n/a",
      "people": [
        "https://swapi.info/api/people/2",
        "https://swapi.info/api/people/3",
        "https://swapi.info/api/people/8",
        "https://swapi.info/api/people/23"
      ],
      "films": [
        "https://swapi.info/api/films/1",
        "https://swapi.info/api/films/2",
        "https://swapi.info/api/films/3",
        "https://swapi.info/api/films/4",
        "https://swapi.info/api/films/5",
        "https://swapi.info/api/films/6"
      ],
      "created": "2014-12-10T15:16:16.259000Z",
      "edited": "2014-12-20T21:36:42.139000Z",
      "url": "https://swapi.info/api/species/2"
    }
  ]
  """#.data(using: .utf8)!
