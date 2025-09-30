import Foundation
import SwiftData
import API

@Model
public final class FilmEntity {
  @Attribute(.unique) public var url: URL
  public var title: String
  public var episodeID: Int
  public var openingCrawl: String
  public var director: String
  public var producerNames: [String]
  public var releaseDate: Date?
  public var created: Date
  public var edited: Date

  @Relationship(deleteRule: .nullify)
  public var characters: [PersonEntity] = []

  @Relationship(deleteRule: .nullify)
  public var planets: [PlanetEntity] = []

  @Relationship(deleteRule: .nullify)
  public var starships: [StarshipEntity] = []

  @Relationship(deleteRule: .nullify)
  public var vehicles: [VehicleEntity] = []

  @Relationship(deleteRule: .nullify)
  public var species: [SpeciesEntity] = []

  public init(
    url: URL,
    title: String,
    episodeID: Int,
    openingCrawl: String,
    director: String,
    producerNames: [String],
    releaseDate: Date?,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.title = title
    self.episodeID = episodeID
    self.openingCrawl = openingCrawl
    self.director = director
    self.producerNames = producerNames
    self.releaseDate = releaseDate
    self.created = created
    self.edited = edited
  }

  public func apply(response: FilmResponse) {
    title = response.title
    episodeID = response.episodeId
    openingCrawl = response.openingCrawl
    director = response.director
    producerNames = response.producers
    releaseDate = response.release
    created = response.created
    edited = response.edited
  }

  @Transient
  public var id: URL { url }
}
