import Foundation
import SQLiteData

@Table
public struct Planet: Hashable, Identifiable, Sendable {
	@Column(primaryKey: true)
	public var url: URL
	public var name: String
	public var rotationPeriod: String
	public var orbitalPeriod: String
	public var diameter: String
	public var climate: String
	public var gravity: String
	public var terrain: String
	public var surfaceWater: String
	public var population: String
	public var created: Date
	public var edited: Date

	public var id: String { url.absoluteString }

	public init(
		url: URL,
		name: String,
		rotationPeriod: String,
		orbitalPeriod: String,
		diameter: String,
		climate: String,
		gravity: String,
		terrain: String,
		surfaceWater: String,
		population: String,
		created: Date,
		edited: Date
	) {
		self.url = url
		self.name = name
		self.rotationPeriod = rotationPeriod
		self.orbitalPeriod = orbitalPeriod
		self.diameter = diameter
		self.climate = climate
		self.gravity = gravity
		self.terrain = terrain
		self.surfaceWater = surfaceWater
		self.population = population
		self.created = created
		self.edited = edited
	}
}
