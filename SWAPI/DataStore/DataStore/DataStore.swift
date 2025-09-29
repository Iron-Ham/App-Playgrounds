import Foundation
import SwiftData

public struct SWAPIDataStore {
	public let container: ModelContainer

	public init(configuration: ModelConfiguration = ModelConfiguration()) throws {
		container = try ModelContainer(
			for: FilmEntity.self,
			PersonEntity.self,
			PlanetEntity.self,
			SpeciesEntity.self,
			StarshipEntity.self,
			VehicleEntity.self,
			configurations: configuration
		)
	}

	public func makeContext() -> ModelContext {
		ModelContext(container)
	}

	public func makeImporter(context: ModelContext? = nil) -> SnapshotImporter {
		let context = context ?? ModelContext(container)
		return SnapshotImporter(context: context)
	}
}

public enum SWAPIDataStorePreview {
	public static func inMemory() -> SWAPIDataStore {
		let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
		return try! SWAPIDataStore(configuration: configuration)
	}
}

