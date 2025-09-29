import Foundation
import Testing

@testable import API

@Suite("StarshipResponseTests", .serialized)
struct StarshipResponseTests {
  @Test
  func initialization() throws {
    let falcon = try StarshipResponse(data: millenniumFalconResponse)

    #expect(falcon.name == "Millennium Falcon")
    #expect(falcon.model == "YT-1300 light freighter")
    #expect(falcon.id == URL(string: "https://swapi.info/api/starships/10")!)

    #expect(falcon.manufacturers.map(\.displayName) == ["Corellian Engineering Corporation"])

    #expect(falcon.costInCredits == "100000")
    #expect(falcon.costInCreditsValue == 100_000)

    #expect(falcon.length == "34.37")
    let length = try #require(falcon.lengthInMeters)
    #expect((length - 34.37).magnitude < 0.0001)

    #expect(falcon.maxAtmospheringSpeed == "1050")
    #expect(falcon.maxAtmospheringSpeedValue == 1050)

    #expect(falcon.crew == "4")
    #expect(falcon.crewCount == 4)

    #expect(falcon.passengers == "6")
    #expect(falcon.passengerCapacity == 6)

    #expect(falcon.cargoCapacity == "100000")
    #expect(falcon.cargoCapacityInKilograms == 100_000)

    #expect(falcon.consumables == "2 months")

    #expect(falcon.hyperdriveRating == "0.5")
    let hyperdrive = try #require(falcon.hyperdriveRatingValue)
    #expect((hyperdrive - 0.5).magnitude < 0.0001)

    #expect(falcon.mglt == "75")
    #expect(falcon.mgltValue == 75)

    #expect(falcon.starshipClass == "Light freighter")

    #expect(falcon.pilots.count == 4)
    #expect(falcon.pilots.contains(URL(string: "https://swapi.info/api/people/13")!))

    #expect(falcon.films.count == 3)
    #expect(falcon.films.contains(URL(string: "https://swapi.info/api/films/2")!))

    let isoNoFrac = ISO8601DateFormatter()
    isoNoFrac.formatOptions = [.withInternetDateTime]
    #expect(isoNoFrac.string(from: falcon.created) == "2014-12-10T16:59:45Z")
    #expect(isoNoFrac.string(from: falcon.edited) == "2014-12-20T21:23:49Z")
  }

  @Test
  func arrayDecodingAndNumericParsing() throws {
    let starships = try StarshipResponse.starships(from: sampleStarshipsResponse)
    #expect(starships.count == 2)

    let starDestroyer = try #require(starships.first)
    let executor = try #require(starships.last)

    #expect(starDestroyer.name == "Star Destroyer")
    #expect(starDestroyer.model == "Imperial I-class Star Destroyer")
    #expect(starDestroyer.manufacturers.map(\.displayName) == ["Kuat Drive Yards"])
    #expect(starDestroyer.costInCreditsValue == 150_000_000)
    let destroyerLength = try #require(starDestroyer.lengthInMeters)
    #expect((destroyerLength - 1_600).magnitude < 0.0001)
    #expect(starDestroyer.maxAtmospheringSpeedValue == 975)
    #expect(starDestroyer.crewCount == 47_060)
    #expect(starDestroyer.passengerCapacity == nil)
    #expect(starDestroyer.cargoCapacityInKilograms == 36_000_000)
    #expect(starDestroyer.hyperdriveRatingValue == 2.0)
    #expect(starDestroyer.mgltValue == 60)
    #expect(starDestroyer.pilots.isEmpty)
    #expect(starDestroyer.films.count == 3)

    #expect(executor.name == "Executor")
    #expect(executor.manufacturers.map(\.displayName) == ["Kuat Drive Yards", "Fondor Shipyards"])
    #expect(executor.costInCreditsValue == 1_143_350_000)
    let executorLength = try #require(executor.lengthInMeters)
    #expect((executorLength - 19_000).magnitude < 0.0001)
    #expect(executor.maxAtmospheringSpeedValue == nil)
    #expect(executor.crewCount == 279_144)
    #expect(executor.passengerCapacity == 38_000)
    #expect(executor.cargoCapacityInKilograms == 250_000_000)
    #expect(executor.hyperdriveRatingValue == 2.0)
    #expect(executor.mgltValue == 40)
    #expect(executor.films.count == 2)

    let isoNoFrac = ISO8601DateFormatter()
    isoNoFrac.formatOptions = [.withInternetDateTime]
    #expect(isoNoFrac.string(from: starDestroyer.created) == "2014-12-10T15:08:19Z")
    #expect(isoNoFrac.string(from: starDestroyer.edited) == "2014-12-20T21:23:49Z")
    #expect(isoNoFrac.string(from: executor.created) == "2014-12-15T12:31:42Z")
    #expect(isoNoFrac.string(from: executor.edited) == "2014-12-20T21:23:49Z")
  }

  @Test
  func manufacturerNormalization() throws {
    let starship = try StarshipResponse(data: manufacturerNormalizationResponse)

    let names = starship.manufacturers.map(\.displayName)
    #expect(
      names == [
        "Theed Palace Space Vessel Engineering Corps",
        "Nubia Star Drives",
      ])

    let identifiers = Set(starship.manufacturers.map(\.identifier))
    #expect(
      identifiers
        == Set([
          "theed palace space vessel engineering corps",
          "nubia star drives",
        ]))
  }
}

private let millenniumFalconResponse = #"""
  {
    "name": "Millennium Falcon",
    "model": "YT-1300 light freighter",
    "manufacturer": "Corellian Engineering Corporation",
    "cost_in_credits": "100000",
    "length": "34.37",
    "max_atmosphering_speed": "1050",
    "crew": "4",
    "passengers": "6",
    "cargo_capacity": "100000",
    "consumables": "2 months",
    "hyperdrive_rating": "0.5",
    "MGLT": "75",
    "starship_class": "Light freighter",
    "pilots": [
      "https://swapi.info/api/people/13",
      "https://swapi.info/api/people/14",
      "https://swapi.info/api/people/25",
      "https://swapi.info/api/people/31"
    ],
    "films": [
      "https://swapi.info/api/films/1",
      "https://swapi.info/api/films/2",
      "https://swapi.info/api/films/3"
    ],
    "created": "2014-12-10T16:59:45.094000Z",
    "edited": "2014-12-20T21:23:49.880000Z",
    "url": "https://swapi.info/api/starships/10"
  }
  """#.data(using: .utf8)!

private let sampleStarshipsResponse = #"""
  [
    {
      "name": "Star Destroyer",
      "model": "Imperial I-class Star Destroyer",
      "manufacturer": "Kuat Drive Yards",
      "cost_in_credits": "150000000",
      "length": "1,600",
      "max_atmosphering_speed": "975",
      "crew": "47,060",
      "passengers": "n/a",
      "cargo_capacity": "36000000",
      "consumables": "2 years",
      "hyperdrive_rating": "2.0",
      "MGLT": "60",
      "starship_class": "Star Destroyer",
      "pilots": [],
      "films": [
        "https://swapi.info/api/films/1",
        "https://swapi.info/api/films/2",
        "https://swapi.info/api/films/3"
      ],
      "created": "2014-12-10T15:08:19.848000Z",
      "edited": "2014-12-20T21:23:49.870000Z",
      "url": "https://swapi.info/api/starships/3"
    },
    {
      "name": "Executor",
      "model": "Executor-class star dreadnought",
      "manufacturer": "Kuat Drive Yards, Fondor Shipyards",
      "cost_in_credits": "1143350000",
      "length": "19000",
      "max_atmosphering_speed": "n/a",
      "crew": "279,144",
      "passengers": "38000",
      "cargo_capacity": "250000000",
      "consumables": "6 years",
      "hyperdrive_rating": "2.0",
      "MGLT": "40",
      "starship_class": "Star dreadnought",
      "pilots": [],
      "films": [
        "https://swapi.info/api/films/2",
        "https://swapi.info/api/films/3"
      ],
      "created": "2014-12-15T12:31:42.547000Z",
      "edited": "2014-12-20T21:23:49.893000Z",
      "url": "https://swapi.info/api/starships/15"
    }
  ]
  """#.data(using: .utf8)!

private let manufacturerNormalizationResponse = #"""
  {
    "name": "Naboo star skiff",
    "model": "J-type star skiff",
    "manufacturer": "Theed Palace Space Vessel Engineering Corps/Nubia Star Drives, Incorporated, Nubia Star Drives",
    "cost_in_credits": "unknown",
    "length": "29.2",
    "max_atmosphering_speed": "1050",
    "crew": "3",
    "passengers": "3",
    "cargo_capacity": "unknown",
    "consumables": "unknown",
    "hyperdrive_rating": "0.5",
    "MGLT": "unknown",
    "starship_class": "yacht",
    "pilots": [],
    "films": [],
    "created": "2014-12-20T19:55:15.396000Z",
    "edited": "2014-12-20T21:23:49.948000Z",
    "url": "https://swapi.info/api/starships/64"
  }
  """#.data(using: .utf8)!
