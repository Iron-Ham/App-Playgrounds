import API
import Fluent
import Foundation

public final class Film: Model, @unchecked Sendable {
  public static let schema = "films"

  @ID(custom: "url", generatedBy: .user)
  public var id: URL?

  @Field(key: "title")
  public var title: String

  @Field(key: "episodeId")
  public var episodeID: Int

  @Field(key: "openingCrawl")
  public var openingCrawl: String

  @Field(key: "director")
  public var director: String

  @Field(key: "producers")
  private var producersRaw: String

  @OptionalField(key: "releaseDate")
  public var releaseDate: Date?

  @Field(key: "created")
  public var created: Date

  @Field(key: "edited")
  public var edited: Date

  @Siblings(through: FilmCharacterPivot.self, from: \.$film, to: \.$person)
  public var characters: [Person]

  @Siblings(through: FilmPlanetPivot.self, from: \.$film, to: \.$planet)
  public var planets: [Planet]

  @Siblings(through: FilmSpeciesPivot.self, from: \.$film, to: \.$species)
  public var species: [Species]

  @Siblings(through: FilmStarshipPivot.self, from: \.$film, to: \.$starship)
  public var starships: [Starship]

  @Siblings(through: FilmVehiclePivot.self, from: \.$film, to: \.$vehicle)
  public var vehicles: [Vehicle]

  public var url: URL {
    get {
      guard let id else {
        fatalError("Attempted to access Film.url before the record had an assigned URL")
      }
      return id
    }
    set { id = newValue }
  }

  public var producers: [String] {
    producersRaw
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  public init() {
    self.title = ""
    self.episodeID = 0
    self.openingCrawl = ""
    self.director = ""
    self.producersRaw = ""
    self.created = .now
    self.edited = .now
  }

  public convenience init(
    url: URL,
    title: String,
    episodeID: Int,
    openingCrawl: String,
    director: String,
    producers: [String],
    releaseDate: Date?,
    created: Date,
    edited: Date
  ) {
    self.init()
  self.url = url
    self.title = title
    self.episodeID = episodeID
    self.openingCrawl = openingCrawl
    self.director = director
    self.producersRaw = Self.joinedProducers(from: producers)
    self.releaseDate = releaseDate
    self.created = created
    self.edited = edited
  }

  public convenience init(from response: FilmResponse) {
    self.init(
      url: response.url,
      title: response.title,
      episodeID: response.episodeId,
      openingCrawl: response.openingCrawl,
      director: response.director,
      producers: response.producers,
      releaseDate: response.release,
      created: response.created,
      edited: response.edited
    )
  }
}

extension Film {
  private static func joinedProducers(from producers: [String]) -> String {
    producers
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: ", ")
  }
}
