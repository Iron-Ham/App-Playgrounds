import Foundation
import SwiftData
import API

@Model
public final class VehicleEntity {
  @Attribute(.unique) public var url: URL
  public var name: String
  public var model: String
  public var manufacturerValues: [String]
  public var costInCreditsRaw: String
  public var costInCreditsValue: Int?
  public var lengthRaw: String
  public var lengthInMeters: Double?
  public var maxAtmospheringSpeedRaw: String
  public var maxAtmospheringSpeedValue: Int?
  public var crewRaw: String
  public var crewCount: Int?
  public var passengersRaw: String
  public var passengerCapacity: Int?
  public var cargoCapacityRaw: String
  public var cargoCapacityInKilograms: Int?
  public var consumables: String
  public var vehicleClassRaw: String
  public var created: Date
  public var edited: Date

  @Relationship(deleteRule: .nullify, inverse: \PersonEntity.vehicles)
  public var pilots: [PersonEntity] = []

  @Relationship(deleteRule: .nullify, inverse: \FilmEntity.vehicles)
  public var films: [FilmEntity] = []

  public init(
    url: URL,
    name: String,
    model: String,
    manufacturerValues: [String],
    costInCreditsRaw: String,
    costInCreditsValue: Int?,
    lengthRaw: String,
    lengthInMeters: Double?,
    maxAtmospheringSpeedRaw: String,
    maxAtmospheringSpeedValue: Int?,
    crewRaw: String,
    crewCount: Int?,
    passengersRaw: String,
    passengerCapacity: Int?,
    cargoCapacityRaw: String,
    cargoCapacityInKilograms: Int?,
    consumables: String,
    vehicleClassRaw: String,
    created: Date,
    edited: Date
  ) {
    self.url = url
    self.name = name
    self.model = model
    self.manufacturerValues = manufacturerValues
    self.costInCreditsRaw = costInCreditsRaw
    self.costInCreditsValue = costInCreditsValue
    self.lengthRaw = lengthRaw
    self.lengthInMeters = lengthInMeters
    self.maxAtmospheringSpeedRaw = maxAtmospheringSpeedRaw
    self.maxAtmospheringSpeedValue = maxAtmospheringSpeedValue
    self.crewRaw = crewRaw
    self.crewCount = crewCount
    self.passengersRaw = passengersRaw
    self.passengerCapacity = passengerCapacity
    self.cargoCapacityRaw = cargoCapacityRaw
    self.cargoCapacityInKilograms = cargoCapacityInKilograms
    self.consumables = consumables
    self.vehicleClassRaw = vehicleClassRaw
    self.created = created
    self.edited = edited
  }

  public func apply(response: VehicleResponse) {
    name = response.name
    model = response.model
    manufacturerValues = response.manufacturers.map(\.rawName)
    costInCreditsRaw = response.costInCredits
    costInCreditsValue = response.costInCreditsValue
    lengthRaw = response.length
    lengthInMeters = response.lengthInMeters
    maxAtmospheringSpeedRaw = response.maxAtmospheringSpeed
    maxAtmospheringSpeedValue = response.maxAtmospheringSpeedValue
    crewRaw = response.crew
    crewCount = response.crewCount
    passengersRaw = response.passengers
    passengerCapacity = response.passengerCapacity
    cargoCapacityRaw = response.cargoCapacity
    cargoCapacityInKilograms = response.cargoCapacityInKilograms
    consumables = response.consumables
    vehicleClassRaw = response.vehicleClass.rawValue
    created = response.created
    edited = response.edited
  }

  @Transient
  public var id: URL { url }

  @Transient
  public var vehicleClass: VehicleResponse.VehicleClass {
    get { VehicleResponse.VehicleClass(rawValue: vehicleClassRaw) }
    set { vehicleClassRaw = newValue.rawValue }
  }

  @Transient
  public var manufacturers: [Manufacturer] {
    get { manufacturerValues.map { Manufacturer(rawName: $0) } }
    set { manufacturerValues = newValue.map(\.rawName) }
  }
}
