import Fluent
import Foundation

public final class FilmCharacterPivot: Model, @unchecked Sendable {
  public static let schema = "filmCharacters"

  @ID(key: .id)
  public var id: UUID?

  @Parent(key: "filmUrl")
  public var film: Film

  @Parent(key: "personUrl")
  public var person: Person

  public init() {}

  public init(id: UUID? = nil, filmID: URL, personID: URL) {
    self.id = id
    self.$film.id = filmID
    self.$person.id = personID
  }
}

public final class FilmPlanetPivot: Model, @unchecked Sendable {
  public static let schema = "filmPlanets"

  @ID(key: .id)
  public var id: UUID?

  @Parent(key: "filmUrl")
  public var film: Film

  @Parent(key: "planetUrl")
  public var planet: Planet

  public init() {}

  public init(id: UUID? = nil, filmID: URL, planetID: URL) {
    self.id = id
    self.$film.id = filmID
    self.$planet.id = planetID
  }
}

public final class FilmSpeciesPivot: Model, @unchecked Sendable {
  public static let schema = "filmSpecies"

  @ID(key: .id)
  public var id: UUID?

  @Parent(key: "filmUrl")
  public var film: Film

  @Parent(key: "speciesUrl")
  public var species: Species

  public init() {}

  public init(id: UUID? = nil, filmID: URL, speciesID: URL) {
    self.id = id
    self.$film.id = filmID
    self.$species.id = speciesID
  }
}

public final class FilmStarshipPivot: Model, @unchecked Sendable {
  public static let schema = "filmStarships"

  @ID(key: .id)
  public var id: UUID?

  @Parent(key: "filmUrl")
  public var film: Film

  @Parent(key: "starshipUrl")
  public var starship: Starship

  public init() {}

  public init(id: UUID? = nil, filmID: URL, starshipID: URL) {
    self.id = id
    self.$film.id = filmID
    self.$starship.id = starshipID
  }
}

public final class FilmVehiclePivot: Model, @unchecked Sendable {
  public static let schema = "filmVehicles"

  @ID(key: .id)
  public var id: UUID?

  @Parent(key: "filmUrl")
  public var film: Film

  @Parent(key: "vehicleUrl")
  public var vehicle: Vehicle

  public init() {}

  public init(id: UUID? = nil, filmID: URL, vehicleID: URL) {
    self.id = id
    self.$film.id = filmID
    self.$vehicle.id = vehicleID
  }
}

public final class PersonSpeciesPivot: Model, @unchecked Sendable {
  public static let schema = "personSpecies"

  @ID(key: .id)
  public var id: UUID?

  @Parent(key: "personUrl")
  public var person: Person

  @Parent(key: "speciesUrl")
  public var species: Species

  public init() {}

  public init(id: UUID? = nil, personID: URL, speciesID: URL) {
    self.id = id
    self.$person.id = personID
    self.$species.id = speciesID
  }
}

public final class PersonStarshipPivot: Model, @unchecked Sendable {
  public static let schema = "personStarships"

  @ID(key: .id)
  public var id: UUID?

  @Parent(key: "personUrl")
  public var person: Person

  @Parent(key: "starshipUrl")
  public var starship: Starship

  public init() {}

  public init(id: UUID? = nil, personID: URL, starshipID: URL) {
    self.id = id
    self.$person.id = personID
    self.$starship.id = starshipID
  }
}

public final class PersonVehiclePivot: Model, @unchecked Sendable {
  public static let schema = "personVehicles"

  @ID(key: .id)
  public var id: UUID?

  @Parent(key: "personUrl")
  public var person: Person

  @Parent(key: "vehicleUrl")
  public var vehicle: Vehicle

  public init() {}

  public init(id: UUID? = nil, personID: URL, vehicleID: URL) {
    self.id = id
    self.$person.id = personID
    self.$vehicle.id = vehicleID
  }
}
