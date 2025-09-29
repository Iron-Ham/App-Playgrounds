import Foundation
import Testing

@testable import API

@Suite("VehicleResponseTests", .serialized)
struct VehicleResponseTests {
  @Test
  func initialization() throws {
    let snowspeeder = try VehicleResponse(data: snowspeederResponse)

    #expect(snowspeeder.name == "Snowspeeder")
    #expect(snowspeeder.model == "t-47 airspeeder")
    #expect(snowspeeder.id == URL(string: "https://swapi.info/api/vehicles/14")!)

    #expect(snowspeeder.manufacturers.map(\.displayName) == ["Incom Corporation"])

    #expect(snowspeeder.costInCredits == "unknown")
    #expect(snowspeeder.costInCreditsValue == nil)

    #expect(snowspeeder.length == "4.5")
    let length = try #require(snowspeeder.lengthInMeters)
    #expect((length - 4.5).magnitude < 0.0001)

    #expect(snowspeeder.maxAtmospheringSpeed == "650")
    #expect(snowspeeder.maxAtmospheringSpeedValue == 650)

    #expect(snowspeeder.crew == "2")
    #expect(snowspeeder.crewCount == 2)

    #expect(snowspeeder.passengers == "0")
    #expect(snowspeeder.passengerCapacity == 0)

    #expect(snowspeeder.cargoCapacity == "10")
    #expect(snowspeeder.cargoCapacityInKilograms == 10)

    #expect(snowspeeder.consumables == "none")

    #expect(snowspeeder.vehicleClass == .airspeeder)
    #expect(snowspeeder.vehicleClass.displayName == "Airspeeder")

    #expect(snowspeeder.pilots.count == 2)
    #expect(snowspeeder.pilots.first?.absoluteString == "https://swapi.info/api/people/18")

    #expect(snowspeeder.films.count == 1)
    #expect(snowspeeder.films.contains(URL(string: "https://swapi.info/api/films/2")!))

    let isoNoFrac = ISO8601DateFormatter()
    isoNoFrac.formatOptions = [.withInternetDateTime]
    #expect(isoNoFrac.string(from: snowspeeder.created) == "2014-12-15T12:22:12Z")
    #expect(isoNoFrac.string(from: snowspeeder.edited) == "2014-12-20T21:30:21Z")
  }

  @Test
  func arrayDecodingAndNormalization() throws {
    let vehicles = try VehicleResponse.vehicles(from: sampleVehiclesResponse)
    #expect(vehicles.count == 2)

    let atst = try #require(vehicles.first)
    let hoverPod = try #require(vehicles.last)

    #expect(atst.name == "AT-ST")
    #expect(atst.vehicleClass == .walker)
    #expect(
      atst.manufacturers.map(\.displayName) == [
        "Kuat Drive Yards", "Imperial Department of Military Research",
      ])
    #expect(atst.costInCredits == "unknown")
    #expect(atst.costInCreditsValue == nil)
    #expect(atst.lengthInMeters == 4.5)
    #expect(atst.maxAtmospheringSpeedValue == 90)
    #expect(atst.crewCount == 2)
    #expect(atst.passengerCapacity == 0)
    #expect(atst.cargoCapacityInKilograms == 200)
    #expect(atst.pilots.isEmpty)
    #expect(atst.films.count == 2)

    #expect(hoverPod.name == "Ubrikkian 9000 Z001 landspeeder")
    #expect(hoverPod.vehicleClass == .other("hover pod"))
    #expect(hoverPod.vehicleClass.displayName == "Hover Pod")
    #expect(
      hoverPod.manufacturers.map(\.displayName) == [
        "Ubrikkian Industries", "Lerrimore Engineering",
      ])
    #expect(hoverPod.costInCreditsValue == 120_000)
    let hoverLength = try #require(hoverPod.lengthInMeters)
    #expect((hoverLength - 36.8).magnitude < 0.0001)
    #expect(hoverPod.maxAtmospheringSpeedValue == 950)
    #expect(hoverPod.crewCount == 2)
    #expect(hoverPod.passengerCapacity == 18)
    #expect(hoverPod.cargoCapacityInKilograms == 1_600)
    #expect(hoverPod.consumables == "2 months")
    #expect(hoverPod.pilots.count == 1)
    #expect(hoverPod.pilots.first?.absoluteString == "https://swapi.info/api/people/1")
    #expect(hoverPod.films.count == 1)

    let isoNoFrac = ISO8601DateFormatter()
    isoNoFrac.formatOptions = [.withInternetDateTime]
    #expect(isoNoFrac.string(from: atst.created) == "2014-12-18T11:46:25Z")
    #expect(isoNoFrac.string(from: atst.edited) == "2014-12-20T21:30:21Z")
    #expect(isoNoFrac.string(from: hoverPod.created) == "2014-12-20T10:12:00Z")
    #expect(isoNoFrac.string(from: hoverPod.edited) == "2014-12-20T21:30:21Z")
  }

  @Test
  func vehicleClassNormalization() {
    let withSpace = VehicleResponse.VehicleClass(rawValue: "air speeder")
    #expect(withSpace == .airspeeder)
    #expect(withSpace.displayName == "Airspeeder")
    #expect(withSpace.rawValue == "airspeeder")

    let canonical = VehicleResponse.VehicleClass(rawValue: "airspeeder")
    #expect(canonical == .airspeeder)
  }

  @Test
  func manufacturerDeduplication() throws {
    let vehicle = try VehicleResponse(data: manufacturerDeduplicationResponse)

    let names = vehicle.manufacturers.map(\.displayName)
    #expect(
      names == [
        "Cygnus Spaceworks",
        "Kuat Drive Yards",
      ])

    let identifiers = Set(vehicle.manufacturers.map(\.identifier))
    #expect(
      identifiers
        == Set([
          "cygnus spaceworks",
          "kuat drive yards",
        ]))
  }

  @Test
  func canonicalManufacturerLookups() {
    let raw =
      "Mon Calamari shipyards, Cyngus Spaceworks / Nubia Star Drives, Incorporated, Gallofree Yards, Inc."
    let manufacturers = Manufacturer.manufacturers(from: raw)

    #expect(
      manufacturers.map(\.displayName) == [
        "Mon Calamari Shipyards",
        "Cygnus Spaceworks",
        "Nubia Star Drives",
        "Gallofree Yards",
      ])

    #expect(
      Set(manufacturers.map(\.identifier))
        == Set([
          "mon calamari shipyards",
          "cygnus spaceworks",
          "nubia star drives",
          "gallofree yards",
        ]))
  }
}

private let snowspeederResponse = #"""
  {
    "name": "Snowspeeder",
    "model": "t-47 airspeeder",
    "manufacturer": "Incom corporation",
    "cost_in_credits": "unknown",
    "length": "4.5",
    "max_atmosphering_speed": "650",
    "crew": "2",
    "passengers": "0",
    "cargo_capacity": "10",
    "consumables": "none",
    "vehicle_class": "airspeeder",
    "pilots": [
      "https://swapi.info/api/people/18",
      "https://swapi.info/api/people/19"
    ],
    "films": [
      "https://swapi.info/api/films/2"
    ],
    "created": "2014-12-15T12:22:12Z",
    "edited": "2014-12-20T21:30:21Z",
    "url": "https://swapi.info/api/vehicles/14"
  }
  """#.data(using: .utf8)!

private let sampleVehiclesResponse = #"""
  [
    {
      "name": "AT-ST",
      "model": "All Terrain Scout Transport",
      "manufacturer": "Kuat Drive Yards, Imperial Department of Military Research",
      "cost_in_credits": "unknown",
      "length": "4.5",
      "max_atmosphering_speed": "90",
      "crew": "2",
      "passengers": "0",
      "cargo_capacity": "200",
      "consumables": "none",
      "vehicle_class": "walker",
      "pilots": [],
      "films": [
        "https://swapi.info/api/films/2",
        "https://swapi.info/api/films/3"
      ],
      "created": "2014-12-18T11:46:25Z",
      "edited": "2014-12-20T21:30:21Z",
      "url": "https://swapi.info/api/vehicles/15"
    },
    {
      "name": "Ubrikkian 9000 Z001 landspeeder",
      "model": "Luxury Landspeeder",
      "manufacturer": "Ubrikkian Industries, Lerrimore Engineering",
      "cost_in_credits": "120,000",
      "length": "36.8",
      "max_atmosphering_speed": "950",
      "crew": "2",
      "passengers": "18",
      "cargo_capacity": "1,600",
      "consumables": "2 months",
      "vehicle_class": "hover pod",
      "pilots": [
        "https://swapi.info/api/people/1"
      ],
      "films": [
        "https://swapi.info/api/films/6"
      ],
      "created": "2014-12-20T10:12:00Z",
      "edited": "2014-12-20T21:30:21Z",
      "url": "https://swapi.info/api/vehicles/42"
    }
  ]
  """#.data(using: .utf8)!

private let manufacturerDeduplicationResponse = #"""
  {
    "name": "Cygnus transport",
    "model": "Custom Transport",
    "manufacturer": "Cygnus Spaceworks, Incorporated, Cygnus Spaceworks / Kuat Drive Yards",
    "cost_in_credits": "unknown",
    "length": "18.5",
    "max_atmosphering_speed": "2000",
    "crew": "5",
    "passengers": "16",
    "cargo_capacity": "50000",
    "consumables": "56 days",
    "vehicle_class": "transport",
    "pilots": [],
    "films": [],
    "created": "2014-12-20T19:48:40.409000Z",
    "edited": "2014-12-20T21:23:49.944000Z",
    "url": "https://swapi.info/api/vehicles/61"
  }
  """#.data(using: .utf8)!
