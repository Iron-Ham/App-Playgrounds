import Foundation
import Playgrounds

public enum Client {
  private static let filmsURL = URL(string: "https://swapi.info/api/films")!
  private static let peopleURL = URL(string: "https://swapi.info/api/people")!
  private static let planetsURL = URL(string: "https://swapi.info/api/planets")!
  private static let speciesURL = URL(string: "https://swapi.info/api/species")!
  private static let vehiclesURL = URL(string: "https://swapi.info/api/vehicles")!
  private static let starshipsURL = URL(string: "https://swapi.info/api/starships")!

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

  private static func fetch<T>(_ url: URL, decode: (Data) throws -> T) async throws -> T {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try decode(data)
  }
}
