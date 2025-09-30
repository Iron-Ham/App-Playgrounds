import Foundation
import SQLiteData
import StructuredQueriesCore

struct InvalidURL: Error {}

@Table
public struct Film: Hashable, Identifiable, Sendable {
	@Column(primaryKey: true)
	public var url: URL
	public var title: String
	public var episodeID: Int
	public var openingCrawl: String
	public var director: String
	public var producerRaw: String
	public var releaseDate: Date?
	public var created: Date
	public var edited: Date

  public var id: String { url.absoluteString }

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
		self.producerRaw = producerNames.joined(separator: ", ")
		self.releaseDate = releaseDate
		self.created = created
		self.edited = edited
	}
}

public extension Film {
	var producerNames: [String] {
		producerRaw
			.split(separator: ",")
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty }
	}
}
