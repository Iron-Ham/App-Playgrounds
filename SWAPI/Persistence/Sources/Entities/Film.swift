import Foundation
import SQLiteData

@Table
public struct Film: Hashable, Identifiable, Sendable {
  @Column(primaryKey: true)
  public var url: URL
  public var title: String
  public var episodeId: Int
  public var openingCrawl: String
  public var director: String
  @Column("producers")
  var producersRaw: String
  public var producers: [String] {
    producersRaw
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }
  public var releaseDate: Date?
  public var created: Date
  public var edited: Date

  public var id: URL { url }

  public init(
    url: URL,
    title: String,
    episodeId: Int,
    openingCrawl: String,
    director: String,
    producers: [String],
    releaseDate: Date?,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.title = title
    self.episodeId = episodeId
    self.openingCrawl = openingCrawl
    self.director = director
    self.producersRaw = producers.joined(separator: ", ")
    self.releaseDate = releaseDate
    self.created = created
    self.edited = edited
  }
}
