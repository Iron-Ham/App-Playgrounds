import Foundation
import SQLiteData

@Table("species")
public struct Species: Hashable, Identifiable, Sendable {
	@Column(primaryKey: true)
	public var url: URL
	public var name: String
	public var classification: String
	public var designation: String
	public var averageHeight: String
	public var averageLifespan: String
	public var skinColors: String
	public var hairColors: String
	public var eyeColors: String
	public var language: String
	public var homeworldURL: URL?
	public var created: Date
	public var edited: Date

	public var id: String { url.absoluteString }

	public init(
		url: URL,
		name: String,
		classification: String,
		designation: String,
		averageHeight: String,
		averageLifespan: String,
		skinColors: String,
		hairColors: String,
		eyeColors: String,
		language: String,
		homeworld: URL?,
		created: Date,
		edited: Date
	) {
		self.url = url
		self.name = name
		self.classification = classification
		self.designation = designation
		self.averageHeight = averageHeight
		self.averageLifespan = averageLifespan
		self.skinColors = skinColors
		self.hairColors = hairColors
		self.eyeColors = eyeColors
		self.language = language
		self.homeworldURL = homeworld.map(URL.init)
		self.created = created
		self.edited = edited
	}
}
