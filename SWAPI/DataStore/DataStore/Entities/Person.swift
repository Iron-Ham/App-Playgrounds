import Foundation
import SQLiteData

@Table("people")
public struct Person: Hashable, Identifiable, Sendable {
	@Column(primaryKey: true)
	public var url: URL
	public var name: String
	public var height: String
	public var mass: String
	public var hairColor: String
	public var skinColor: String
	public var eyeColor: String
	public var birthYear: String
	public var gender: String
	public var homeworldURL: URL?
	public var created: Date
	public var edited: Date

	public var id: String { url.absoluteString }

	public init(
		url: URL,
		name: String,
		height: String,
		mass: String,
		hairColor: String,
		skinColor: String,
		eyeColor: String,
		birthYear: String,
		gender: String,
		homeworld: URL?,
		created: Date,
		edited: Date
	) {
		self.url = url
		self.name = name
		self.height = height
		self.mass = mass
		self.hairColor = hairColor
		self.skinColor = skinColor
		self.eyeColor = eyeColor
		self.birthYear = birthYear
		self.gender = gender
		self.homeworldURL = homeworld.map(URL.init)
		self.created = created
		self.edited = edited
	}
}
