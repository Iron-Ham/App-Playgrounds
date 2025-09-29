import Foundation
import SwiftData
import Testing
@testable import DataStore
import API

struct DataStoreTests {
    private let iso8601 = ISO8601DateFormatter()

    @Test func snapshotImporterRoundsTripRelationships() throws {
        let created = iso8601.string(from: Date(timeIntervalSince1970: 1_704_000_000))
        let edited = iso8601.string(from: Date(timeIntervalSince1970: 1_704_360_000))

        let filmURL = URL(string: "https://swapi.info/api/films/1/")!
        let personURL = URL(string: "https://swapi.info/api/people/1/")!
        let planetURL = URL(string: "https://swapi.info/api/planets/1/")!
        let speciesURL = URL(string: "https://swapi.info/api/species/1/")!
        let starshipURL = URL(string: "https://swapi.info/api/starships/1/")!
        let vehicleURL = URL(string: "https://swapi.info/api/vehicles/1/")!

        let film = try FilmResponse(data: makeJSON([
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

        let person = try PersonResponse(data: makeJSON([
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

        let planet = try PlanetResponse(data: makeJSON([
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

        let species = try SpeciesResponse(data: makeJSON([
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

        let starship = try StarshipResponse(data: makeJSON([
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

        let vehicle = try VehicleResponse(data: makeJSON([
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

        let context = importer.context
        let peopleEntities = try context.fetch(FetchDescriptor<PersonEntity>())
        let filmsEntities = try context.fetch(FetchDescriptor<FilmEntity>())
        let planetsEntities = try context.fetch(FetchDescriptor<PlanetEntity>())
        let speciesEntities = try context.fetch(FetchDescriptor<SpeciesEntity>())
        let starshipsEntities = try context.fetch(FetchDescriptor<StarshipEntity>())
        let vehiclesEntities = try context.fetch(FetchDescriptor<VehicleEntity>())

        let persistedPerson = try #require(peopleEntities.first)
        #expect(persistedPerson.homeworld?.name == "Tatooine")
        #expect(persistedPerson.films.count == 1)
        #expect(persistedPerson.species.count == 1)
        #expect(persistedPerson.starships.count == 1)
        #expect(persistedPerson.vehicles.count == 1)

        let persistedFilm = try #require(filmsEntities.first)
        #expect(persistedFilm.characters.first?.name == "Luke Skywalker")
        #expect(persistedFilm.planets.first?.name == "Tatooine")
        #expect(persistedFilm.species.first?.name == "Human")
        #expect(persistedFilm.starships.first?.name == "X-wing")
        #expect(persistedFilm.vehicles.first?.name == "Snowspeeder")

        let persistedPlanet = try #require(planetsEntities.first)
        #expect(persistedPlanet.residents.count == 1)
        #expect(persistedPlanet.films.count == 1)

        let persistedSpecies = try #require(speciesEntities.first)
        #expect(persistedSpecies.people.count == 1)
        #expect(persistedSpecies.homeworld?.name == "Tatooine")

        let persistedStarship = try #require(starshipsEntities.first)
        #expect(persistedStarship.pilots.count == 1)

        let persistedVehicle = try #require(vehiclesEntities.first)
        #expect(persistedVehicle.pilots.count == 1)
    }

    private func makeJSON(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object)
    }
}
