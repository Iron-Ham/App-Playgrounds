import API
import Foundation
import GRDB
import Testing

@testable import SQLiteDataPersistence

struct PersistenceTests {
  private let iso8601 = ISO8601DateFormatter()

  @Test("import snapshot populates entities and relationships")
  func importSnapshot_populatesEntitiesAndRelationships() throws {
    let created = iso8601.string(from: Date(timeIntervalSince1970: 1_704_000_000))
    let edited = iso8601.string(from: Date(timeIntervalSince1970: 1_704_360_000))

    let filmURL = URL(string: "https://swapi.info/api/films/1/")!
    let personURL = URL(string: "https://swapi.info/api/people/1/")!
    let planetURL = URL(string: "https://swapi.info/api/planets/1/")!
    let speciesURL = URL(string: "https://swapi.info/api/species/1/")!
    let starshipURL = URL(string: "https://swapi.info/api/starships/1/")!
    let vehicleURL = URL(string: "https://swapi.info/api/vehicles/1/")!

    let film = try FilmResponse(
      data: makeJSON([
        "title": "A New Hope",
        "episode_id": 4,
        "opening_crawl": "It is a period of civil war...",
        "director": "George Lucas",
        "producer": "Gary Kurtz, Rick McCallum",
        "release_date": "1977-05-25",
        "characters": [personURL.absoluteString],
        "planets": [planetURL.absoluteString],
        "starships": [starshipURL.absoluteString],
        "vehicles": [vehicleURL.absoluteString],
        "species": [speciesURL.absoluteString],
        "created": created,
        "edited": edited,
        "url": filmURL.absoluteString,
      ]))

    let person = try PersonResponse(
      data: makeJSON([
        "name": "Luke Skywalker",
        "height": "172",
        "mass": "77",
        "hair_color": "blond",
        "skin_color": "fair",
        "eye_color": "blue",
        "birth_year": "19BBY",
        "gender": "male",
        "homeworld": planetURL.absoluteString,
        "films": [filmURL.absoluteString],
        "species": [speciesURL.absoluteString],
        "vehicles": [vehicleURL.absoluteString],
        "starships": [starshipURL.absoluteString],
        "created": created,
        "edited": edited,
        "url": personURL.absoluteString,
      ]))

    let planet = try PlanetResponse(
      data: makeJSON([
        "name": "Tatooine",
        "rotation_period": "23",
        "orbital_period": "304",
        "diameter": "10465",
        "climate": "arid",
        "gravity": "1 standard",
        "terrain": "desert",
        "surface_water": "1",
        "population": "200000",
        "residents": [personURL.absoluteString],
        "films": [filmURL.absoluteString],
        "created": created,
        "edited": edited,
        "url": planetURL.absoluteString,
      ]))

    let species = try SpeciesResponse(
      data: makeJSON([
        "name": "Human",
        "classification": "mammal",
        "designation": "sentient",
        "average_height": "180",
        "average_lifespan": "120",
        "skin_colors": "fair",
        "hair_colors": "blond",
        "eye_colors": "blue",
        "homeworld": planetURL.absoluteString,
        "language": "Galactic Basic",
        "people": [personURL.absoluteString],
        "films": [filmURL.absoluteString],
        "created": created,
        "edited": edited,
        "url": speciesURL.absoluteString,
      ]))

    let starship = try StarshipResponse(
      data: makeJSON([
        "name": "X-wing",
        "model": "T-65 X-wing",
        "manufacturer": "Incom Corporation",
        "cost_in_credits": "149999",
        "length": "12.5",
        "max_atmosphering_speed": "1050",
        "crew": "1",
        "passengers": "0",
        "cargo_capacity": "110",
        "consumables": "1 week",
        "hyperdrive_rating": "1.0",
        "MGLT": "100",
        "starship_class": "Starfighter",
        "pilots": [personURL.absoluteString],
        "films": [filmURL.absoluteString],
        "created": created,
        "edited": edited,
        "url": starshipURL.absoluteString,
      ]))

    let vehicle = try VehicleResponse(
      data: makeJSON([
        "name": "Snowspeeder",
        "model": "t-47 airspeeder",
        "manufacturer": "Incom Corporation",
        "cost_in_credits": "unknown",
        "length": "4.5",
        "max_atmosphering_speed": "650",
        "crew": "2",
        "passengers": "0",
        "cargo_capacity": "10",
        "consumables": "none",
        "vehicle_class": "airspeeder",
        "pilots": [personURL.absoluteString],
        "films": [filmURL.absoluteString],
        "created": created,
        "edited": edited,
        "url": vehicleURL.absoluteString,
      ]))

    let store = SWAPIDataStorePreview.inMemory()
    let importer = store.makeImporter()
    try importer.importSnapshot(
      films: [film],
      people: [person],
      planets: [planet],
      species: [species],
      starships: [starship],
      vehicles: [vehicle]
    )

    try store.database.read { db in
      let filmRow = try Row.fetchOne(
        db,
        sql: "SELECT title, episodeId, director, producers, releaseDate FROM films WHERE url = ?",
        arguments: [filmURL.absoluteString]
      )
      #expect(filmRow?["title"] == "A New Hope")
      #expect(filmRow?["episodeId"] == 4)
      #expect(filmRow?["director"] == "George Lucas")
      #expect(filmRow?["producers"] == "Gary Kurtz, Rick McCallum")
      #expect(filmRow?["releaseDate"] != nil)

      let personRow = try Row.fetchOne(
        db,
        sql: "SELECT homeworldUrl FROM people WHERE url = ?",
        arguments: [personURL.absoluteString]
      )
      #expect(personRow?["homeworldUrl"] == planetURL.absoluteString)

      let speciesRow = try Row.fetchOne(
        db,
        sql: "SELECT homeworldUrl FROM species WHERE url = ?",
        arguments: [speciesURL.absoluteString]
      )
      #expect(speciesRow?["homeworldUrl"] == planetURL.absoluteString)

      #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM planets") == 1)
      #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM starships") == 1)
      #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM vehicles") == 1)

      #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM filmCharacters") == 1)
      #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM filmPlanets") == 1)
      #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM filmSpecies") == 1)
      #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM filmStarships") == 1)
      #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM filmVehicles") == 1)
      #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM personSpecies") == 1)
      #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM personStarships") == 1)
      #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM personVehicles") == 1)
    }

    let summary = try store.relationshipSummary(forFilmWithURL: filmURL)
    #expect(summary.characterCount == 1)
    #expect(summary.planetCount == 1)
    #expect(summary.speciesCount == 1)
    #expect(summary.starshipCount == 1)
    #expect(summary.vehicleCount == 1)

    let characterURLs = try store.relationshipURLs(forFilmWithURL: filmURL, .characters)
    #expect(characterURLs == [personURL])

    let characters = try store.characters(forFilmWithURL: filmURL)
    #expect(characters.map(\.name) == ["Luke Skywalker"])

    let planets = try store.planets(forFilmWithURL: filmURL)
    #expect(planets.map(\.name) == ["Tatooine"])

    let speciesCollection = try store.species(forFilmWithURL: filmURL)
    #expect(speciesCollection.map(\.name) == ["Human"])

    let starships = try store.starships(forFilmWithURL: filmURL)
    #expect(starships.map(\.name) == ["X-wing"])

    let vehiclesCollection = try store.vehicles(forFilmWithURL: filmURL)
    #expect(vehiclesCollection.map(\.name) == ["Snowspeeder"])
  }

  @Test("import snapshot clears existing data before reimport")
  func importSnapshot_clearsExistingDataBeforeReimport() throws {
    let created = iso8601.string(from: Date(timeIntervalSince1970: 1_705_000_000))
    let edited = iso8601.string(from: Date(timeIntervalSince1970: 1_705_360_000))

    let firstFilmURL = URL(string: "https://swapi.info/api/films/1/")!
    let secondFilmURL = URL(string: "https://swapi.info/api/films/2/")!

    let baseFilmPayload: [String: Any] = [
      "opening_crawl": "Test crawl",
      "director": "Director",
      "producer": "Producer",
      "release_date": "1980-05-21",
      "characters": [],
      "planets": [],
      "starships": [],
      "vehicles": [],
      "species": [],
      "created": created,
      "edited": edited,
    ]

    let firstFilm = try FilmResponse(
      data: makeJSON(
        baseFilmPayload.merging([
          "title": "Film One",
          "episode_id": 4,
          "url": firstFilmURL.absoluteString,
        ]) { _, new in new }))

    let secondFilm = try FilmResponse(
      data: makeJSON(
        baseFilmPayload.merging([
          "title": "Film Two",
          "episode_id": 5,
          "url": secondFilmURL.absoluteString,
        ]) { _, new in new }))

    let store = SWAPIDataStorePreview.inMemory()
    let importer = store.makeImporter()

    try importer.importSnapshot(
      films: [firstFilm],
      people: [],
      planets: [],
      species: [],
      starships: [],
      vehicles: []
    )

    try importer.importSnapshot(
      films: [secondFilm],
      people: [],
      planets: [],
      species: [],
      starships: [],
      vehicles: []
    )

    try store.database.read { db in
      #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM films") == 1)
      let remainingURL: String? = try String.fetchOne(
        db,
        sql: "SELECT url FROM films LIMIT 1"
      )
      #expect(remainingURL == secondFilmURL.absoluteString)
    }
  }

  private func makeJSON(_ object: [String: Any]) throws -> Data {
    try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
  }
}
