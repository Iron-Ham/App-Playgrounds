import Foundation
import SQLiteData

@Table
public struct Vehicle: Hashable, Identifiable, Sendable {
  @Column(primaryKey: true)
  public var url: URL
  public var name: String
  public var model: String
  public var manufacturer: String
  public var costInCredits: String
  public var length: String
  public var maxAtmospheringSpeed: String
  public var crew: String
  public var passengers: String
  public var cargoCapacity: String
  public var consumables: String
  public var vehicleClass: String
  public var created: Date
  public var edited: Date

  public var id: String { url.absoluteString }

  public init(
    url: URL,
    name: String,
    model: String,
    manufacturer: String,
    costInCredits: String,
    length: String,
    maxAtmospheringSpeed: String,
    crew: String,
    passengers: String,
    cargoCapacity: String,
    consumables: String,
    vehicleClass: String,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.name = name
    self.model = model
    self.manufacturer = manufacturer
    self.costInCredits = costInCredits
    self.length = length
    self.maxAtmospheringSpeed = maxAtmospheringSpeed
    self.crew = crew
    self.passengers = passengers
    self.cargoCapacity = cargoCapacity
    self.consumables = consumables
    self.vehicleClass = vehicleClass
    self.created = created
    self.edited = edited
  }
}
