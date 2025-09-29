import Foundation
import Testing

@testable import API

@Suite("PlanetResponseTests", .serialized)
struct PlanetResponseTests {
  @Test
  func initialization() throws {
    let tatooine = try PlanetResponse(data: tatooineResponse)
    #expect(tatooine.name == "Tatooine")
    #expect(tatooine.id.absoluteString == "https://swapi.info/api/planets/1")

    #expect(tatooine.rotationPeriod == "23")
    #expect(tatooine.rotationPeriodInHours == 23)

    #expect(tatooine.orbitalPeriod == "304")
    #expect(tatooine.orbitalPeriodInDays == 304)

    #expect(tatooine.diameter == "10465")
    #expect(tatooine.diameterInKilometers == 10465)

    #expect(tatooine.climates.map(\.normalizedValue) == ["arid"])

    #expect(tatooine.gravityLevels.count == 1)
    #expect(tatooine.gravityLevels.first?.standardGravityValue == 1)

    #expect(tatooine.terrains.map(\.normalizedValue) == ["desert"])

    #expect(tatooine.surfaceWater == "1")
    #expect(tatooine.surfaceWaterPercentage == Double(1))

    #expect(tatooine.population == "200000")
    #expect(tatooine.populationCount == 200000)

    #expect(tatooine.residents.count == 10)
    #expect(tatooine.residents.first?.absoluteString == "https://swapi.info/api/people/1")

    #expect(tatooine.films.count == 5)
    #expect(tatooine.films.contains(URL(string: "https://swapi.info/api/films/4")!))

    let isoNoFrac = ISO8601DateFormatter()
    isoNoFrac.formatOptions = [.withInternetDateTime]
    #expect(isoNoFrac.string(from: tatooine.created) == "2014-12-09T13:50:49Z")
    #expect(isoNoFrac.string(from: tatooine.edited) == "2014-12-20T20:58:18Z")
  }
}

private let tatooineResponse = #"""
  {
      "name": "Tatooine",
      "rotation_period": "23",
      "orbital_period": "304",
      "diameter": "10465",
      "climate": "arid",
      "gravity": "1 standard",
      "terrain": "desert",
      "surface_water": "1",
      "population": "200000",
      "residents": [
        "https://swapi.info/api/people/1",
        "https://swapi.info/api/people/2",
        "https://swapi.info/api/people/4",
        "https://swapi.info/api/people/6",
        "https://swapi.info/api/people/7",
        "https://swapi.info/api/people/8",
        "https://swapi.info/api/people/9",
        "https://swapi.info/api/people/11",
        "https://swapi.info/api/people/43",
        "https://swapi.info/api/people/62"
      ],
      "films": [
        "https://swapi.info/api/films/1",
        "https://swapi.info/api/films/3",
        "https://swapi.info/api/films/4",
        "https://swapi.info/api/films/5",
        "https://swapi.info/api/films/6"
      ],
      "created": "2014-12-09T13:50:49.641000Z",
      "edited": "2014-12-20T20:58:18.411000Z",
      "url": "https://swapi.info/api/planets/1"
    }
  """#.data(using: .utf8)!
