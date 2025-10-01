import Dependencies

extension SWAPIDataStore: DependencyKey {
  public static let liveValue: SWAPIDataStore = {
    do {
      return try SWAPIDataStore()
    } catch {
      fatalError("Failed to create live SWAPIDataStore: \(error)")
    }
  }()

  public static let testValue: SWAPIDataStore = SWAPIDataStorePreview.inMemory()
  public static let previewValue: SWAPIDataStore = SWAPIDataStorePreview.inMemory()
}

extension DependencyValues {
  public var dataStore: SWAPIDataStore {
    get { self[SWAPIDataStore.self] }
    set { self[SWAPIDataStore.self] = newValue }
  }
}
