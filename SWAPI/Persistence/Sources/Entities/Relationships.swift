import Foundation
import SQLiteData

@Table
public struct FilmCharacter: Hashable, Identifiable, Sendable {
    public var id: UUID
    public var filmURL: URL
    public var personURL: URL

    public init(id: UUID = UUID(), film: URL, person: URL) {
        self.id = id
        self.filmURL = film
        self.personURL = person
    }
}

@Table
public struct FilmPlanet: Hashable, Identifiable, Sendable {
    public var id: UUID
    public var filmURL: URL
    public var planetURL: URL

    public init(id: UUID = UUID(), film: URL, planet: URL) {
        self.id = id
        self.filmURL = film
        self.planetURL = planet
    }
}

@Table("filmSpecies")
public struct FilmSpecies: Hashable, Identifiable, Sendable {
    public var id: UUID
    public var filmURL: URL
    public var speciesURL: URL

    public init(id: UUID = UUID(), film: URL, species: URL) {
        self.id = id
        self.filmURL = film
        self.speciesURL = species
    }
}

@Table
public struct FilmStarship: Hashable, Identifiable, Sendable {
    public var id: UUID
    public var filmURL: URL
    public var starshipURL: URL

    public init(id: UUID = UUID(), film: URL, starship: URL) {
        self.id = id
        self.filmURL = film
        self.starshipURL = starship
    }
}

@Table
public struct FilmVehicle: Hashable, Identifiable, Sendable {
    public var id: UUID
    public var filmURL: URL
    public var vehicleURL: URL

    public init(id: UUID = UUID(), film: URL, vehicle: URL) {
        self.id = id
        self.filmURL = film
        self.vehicleURL = vehicle
    }
}

@Table("personSpecies")
public struct PersonSpecies: Hashable, Identifiable, Sendable {
    public var id: UUID
    public var personURL: URL
    public var speciesURL: URL

    public init(id: UUID = UUID(), person: URL, species: URL) {
        self.id = id
        self.personURL = person
        self.speciesURL = species
    }
}

@Table
public struct PersonStarship: Hashable, Identifiable, Sendable {
    public var id: UUID
    public var personURL: URL
    public var starshipURL: URL

    public init(id: UUID = UUID(), person: URL, starship: URL) {
        self.id = id
        self.personURL = person
        self.starshipURL = starship
    }
}

@Table
public struct PersonVehicle: Hashable, Identifiable, Sendable {
    public var id: UUID
    public var personURL: URL
    public var vehicleURL: URL

    public init(id: UUID = UUID(), person: URL, vehicle: URL) {
        self.id = id
        self.personURL = person
        self.vehicleURL = vehicle
    }
}
