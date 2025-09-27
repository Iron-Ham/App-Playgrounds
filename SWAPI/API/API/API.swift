import Foundation
import Playgrounds

public enum SWAPIClient {
  private static let filmURL = URL(string: "https://swapi.info/api/films")!
  private static let peopleURL = URL(string: "https://swapi.info/api/people")!

  public static func films() async throws -> [FilmResponse] {
    let (data, _) = try await URLSession.shared.data(from: Self.filmURL)
    return try FilmResponse.films(from: data)
  }
}

#Playground {
  do {
    _ = try await SWAPIClient.films()
  } catch {
    print(String(describing: error))
  }
}
