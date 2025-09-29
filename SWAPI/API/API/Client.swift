import Foundation
import Playgrounds

public enum Client {
  private static let filmsURL = URL(string: "https://swapi.info/api/films")!
  private static let peopleURL = URL(string: "https://swapi.info/api/people")!
  private static let planetsURL = URL(string: "https://swapi.info/api/planets")!
  private static let speciesURL = URL(string: "https://swapi.info/api/species")!
  private static let vehiclesURL = URL(string: "https://swapi.info/api/vehicles")!
  private static let starshipsURL = URL(string: "https://swapi.info/api/starships")!

  private static let sessionStore = SessionStore()

  public static func films() async throws -> [FilmResponse] {
    try await fetch(Self.filmsURL, decode: FilmResponse.films(from:))
  }

  public static func film(url: URL) async throws -> FilmResponse {
    try await fetch(url, decode: FilmResponse.init(data:))
  }

  public static func people() async throws -> [PersonResponse] {
    try await fetch(Self.peopleURL, decode: PersonResponse.people(from:))
  }

  public static func person(url: URL) async throws -> PersonResponse {
    try await fetch(url, decode: PersonResponse.init(data:))
  }

  public static func planets() async throws -> [PlanetResponse] {
    try await fetch(Self.planetsURL, decode: PlanetResponse.planets(from:))
  }

  public static func planet(url: URL) async throws -> PlanetResponse {
    try await fetch(url, decode: PlanetResponse.init(data:))
  }

  public static func species() async throws -> [SpeciesResponse] {
    try await fetch(Self.speciesURL, decode: SpeciesResponse.species(from:))
  }

  public static func species(url: URL) async throws -> SpeciesResponse {
    try await fetch(url, decode: SpeciesResponse.init(data:))
  }

  public static func vehicles() async throws -> [VehicleResponse] {
    try await fetch(Self.vehiclesURL, decode: VehicleResponse.vehicles(from:))
  }

  public static func vehicle(url: URL) async throws -> VehicleResponse {
    try await fetch(url, decode: VehicleResponse.init(data:))
  }

  public static func starships() async throws -> [StarshipResponse] {
    try await fetch(Self.starshipsURL, decode: StarshipResponse.starships(from:))
  }

  public static func starship(url: URL) async throws -> StarshipResponse {
    try await fetch(url, decode: StarshipResponse.init(data:))
  }

  private static func fetch<T: Sendable>(
    _ url: URL,
    decode: @Sendable (Data) throws -> T
  ) async throws -> T {
    let (data, _) = try await sessionStore.data(from: url)
    return try decode(data)
  }
}

extension Client {
  #if DEBUG
    internal static func withSessionOverride<T>(
      _ session: URLSession,
      operation: () async throws -> T
    ) async rethrows -> T {
      try await sessionStore.withSessionOverride(session, operation: operation)
    }
  #endif
}

extension Client {
  private static func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.default
    configuration.httpMaximumConnectionsPerHost = max(
      configuration.httpMaximumConnectionsPerHost, 8)
    configuration.waitsForConnectivity = true
    return URLSession(configuration: configuration)
  }

  private actor SessionStore {
    private var session: URLSession = Client.makeSession()

    func data(from url: URL) async throws -> (Data, URLResponse) {
      try await session.data(from: url)
    }

    #if DEBUG
      func withSessionOverride<T>(
        _ session: URLSession,
        operation: () async throws -> T
      ) async rethrows -> T {
        let previous = self.session
        self.session = session
        defer { self.session = previous }
        return try await operation()
      }
    #endif
  }
}
