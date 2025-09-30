import Foundation
import Testing

@testable import API

@Suite("ClientConcurrencyTests", .serialized)
struct ClientConcurrencyTests {
  @Test
  func listEndpointsHandleConcurrentRequests() async throws {
    SWAPIURLProtocolStub.removeAll()
    SWAPIURLProtocolStub.stub(url: peopleCollectionURL, data: StubData.peopleCollection)
    SWAPIURLProtocolStub.stub(url: planetsCollectionURL, data: StubData.planetsCollection)
    SWAPIURLProtocolStub.stub(url: speciesCollectionURL, data: StubData.speciesCollection)
    SWAPIURLProtocolStub.stub(url: vehiclesCollectionURL, data: StubData.vehiclesCollection)
    SWAPIURLProtocolStub.stub(url: starshipsCollectionURL, data: StubData.starshipsCollection)
    SWAPIURLProtocolStub.stub(url: filmsCollectionURL, data: StubData.filmsCollection)

    try await Client.withSessionOverride(makeStubSession()) {
      async let people = Client.people()
      async let planets = Client.planets()
      async let species = Client.species()
      async let vehicles = Client.vehicles()
      async let starships = Client.starships()
      async let films = Client.films()

      let (
        peopleResult,
        planetsResult,
        speciesResult,
        vehiclesResult,
        starshipsResult,
        filmsResult
      ) = try await (people, planets, species, vehicles, starships, films)

      let person = try #require(peopleResult.first)
      #expect(person.name == "Luke Skywalker")

      let planet = try #require(planetsResult.first)
      #expect(planet.name == "Tatooine")
      #expect(planet.terrains.first?.rawValue == "desert")

      let speciesValue = try #require(speciesResult.first)
      #expect(speciesValue.name == "Human")

      let vehicle = try #require(vehiclesResult.first)
      #expect(vehicle.name == "Snowspeeder")
      #expect(vehicle.manufacturers.first?.displayName == "Incom Corporation")

      let starship = try #require(starshipsResult.first)
      #expect(starship.name == "Millennium Falcon")
      #expect(starship.hyperdriveRatingValue == 0.5)

      let film = try #require(filmsResult.first)
      #expect(film.title == "A New Hope")
      let gregorian = Calendar(identifier: .gregorian)
      #expect(
        film.release
          == gregorian
          .date(from: DateComponents(year: 1977, month: 5, day: 25))
      )
    }
  }

  @Test
  func repeatedRequestsAreThreadSafe() async throws {
    SWAPIURLProtocolStub.removeAll()
    SWAPIURLProtocolStub.stub(url: peopleCollectionURL, data: StubData.peopleCollection)
    try await Client.withSessionOverride(makeStubSession()) {
      let results = try await withThrowingTaskGroup(of: [PersonResponse].self) {
        group -> [[PersonResponse]] in
        for _ in 0..<12 {
          group.addTask {
            try await Client.people()
          }
        }

        var allResults: [[PersonResponse]] = []
        for try await value in group {
          allResults.append(value)
        }
        return allResults
      }

      #expect(results.count == 12)
      #expect(results.allSatisfy { $0.count == 1 })
      #expect(results.allSatisfy { $0.first?.name == "Luke Skywalker" })
    }
  }
}

private let peopleCollectionURL = URL(string: "https://swapi.info/api/people")!
private let planetsCollectionURL = URL(string: "https://swapi.info/api/planets")!
private let speciesCollectionURL = URL(string: "https://swapi.info/api/species")!
private let vehiclesCollectionURL = URL(string: "https://swapi.info/api/vehicles")!
private let starshipsCollectionURL = URL(string: "https://swapi.info/api/starships")!
private let filmsCollectionURL = URL(string: "https://swapi.info/api/films")!

private final class SWAPIURLProtocolStub: URLProtocol {
  private struct Stub {
    let statusCode: Int
    let headers: [String: String]
    let data: Data
  }

  nonisolated(unsafe) private static var stubs: [URL: Stub] = [:]
  private static let lock = NSLock()

  static func stub(
    url: URL, data: Data, statusCode: Int = 200,
    headers: [String: String] = ["Content-Type": "application/json"]
  ) {
    lock.lock()
    stubs[url] = Stub(statusCode: statusCode, headers: headers, data: data)
    lock.unlock()
  }

  static func removeAll() {
    lock.lock()
    stubs.removeAll()
    lock.unlock()
  }

  private static func stub(for url: URL) -> Stub? {
    lock.lock()
    let value = stubs[url]
    lock.unlock()
    return value
  }

  override class func canInit(with request: URLRequest) -> Bool {
    guard let url = request.url else { return false }
    return stub(for: url) != nil
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let url = request.url else {
      client?.urlProtocol(self, didFailWithError: URLError(.badURL))
      return
    }

    guard let stub = Self.stub(for: url) else {
      client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
      return
    }

    if let response = HTTPURLResponse(
      url: url,
      statusCode: stub.statusCode,
      httpVersion: "HTTP/1.1",
      headerFields: stub.headers
    ) {
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    }

    client?.urlProtocol(self, didLoad: stub.data)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}

private func makeStubSession() -> URLSession {
  let configuration = URLSessionConfiguration.ephemeral
  configuration.protocolClasses = [SWAPIURLProtocolStub.self]
  configuration.waitsForConnectivity = false
  configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
  return URLSession(configuration: configuration)
}

private enum StubData {
  static let peopleCollection = Data(
    #"""
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
        "films": ["https://swapi.info/api/films/1"],
        "species": [],
        "vehicles": ["https://swapi.info/api/vehicles/14"],
        "starships": ["https://swapi.info/api/starships/12"],
        "created": "2014-12-09T13:50:51Z",
        "edited": "2014-12-20T21:17:56Z",
        "url": "https://swapi.info/api/people/1"
      }
    ]
    """#.utf8)

  static let planetsCollection = Data(
    #"""
    [
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
        "residents": ["https://swapi.info/api/people/1"],
        "films": ["https://swapi.info/api/films/1"],
        "created": "2014-12-09T13:50:49Z",
        "edited": "2014-12-20T20:58:18Z",
        "url": "https://swapi.info/api/planets/1"
      }
    ]
    """#.utf8)

  static let speciesCollection = Data(
    #"""
    [
      {
        "name": "Human",
        "classification": "mammal",
        "designation": "sentient",
        "average_height": "180",
        "average_lifespan": "120",
        "skin_colors": "caucasian, black, asian, hispanic",
        "hair_colors": "blond, brown, black, red",
        "eye_colors": "brown, blue, green, hazel, grey, amber",
        "homeworld": "https://swapi.info/api/planets/9",
        "language": "Galactic Basic",
        "people": ["https://swapi.info/api/people/1"],
        "films": ["https://swapi.info/api/films/1"],
        "created": "2014-12-10T13:52:11Z",
        "edited": "2014-12-20T21:36:42Z",
        "url": "https://swapi.info/api/species/1"
      }
    ]
    """#.utf8)

  static let vehiclesCollection = Data(
    #"""
    [
      {
        "name": "Snowspeeder",
        "model": "t-47 airspeeder",
        "manufacturer": "Incom Corporation",
        "cost_in_credits": "Unknown",
        "length": "4.5",
        "max_atmosphering_speed": "650",
        "crew": "2",
        "passengers": "0",
        "cargo_capacity": "10",
        "consumables": "none",
        "vehicle_class": "airspeeder",
        "pilots": ["https://swapi.info/api/people/1"],
        "films": ["https://swapi.info/api/films/2"],
        "created": "2014-12-15T12:22:12Z",
        "edited": "2014-12-20T21:30:21Z",
        "url": "https://swapi.info/api/vehicles/14"
      }
    ]
    """#.utf8)

  static let starshipsCollection = Data(
    #"""
    [
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
        "pilots": ["https://swapi.info/api/people/13"],
        "films": ["https://swapi.info/api/films/2"],
        "created": "2014-12-10T16:59:45Z",
        "edited": "2014-12-20T21:23:49Z",
        "url": "https://swapi.info/api/starships/10"
      }
    ]
    """#.utf8)

  static let filmsCollection = Data(
    #"""
    [
      {
        "title": "A New Hope",
        "episode_id": 4,
        "opening_crawl": "It is a period of civil war...",
        "director": "George Lucas",
        "producer": "Gary Kurtz, Rick McCallum",
        "release_date": "1977-05-25",
        "characters": ["https://swapi.info/api/people/1"],
        "planets": ["https://swapi.info/api/planets/1"],
        "starships": ["https://swapi.info/api/starships/10"],
        "vehicles": ["https://swapi.info/api/vehicles/14"],
        "species": ["https://swapi.info/api/species/1"],
        "created": "2014-12-10T14:23:31.880000Z",
        "edited": "2014-12-20T19:49:45.256000Z",
        "url": "https://swapi.info/api/films/1"
      }
    ]
    """#.utf8)
}
