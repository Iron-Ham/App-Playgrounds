import DataStore
import SwiftData
import SwiftUI

@main
struct SWAPIApp: App {
  private let dataStore: SWAPIDataStore

  init() {
    do {
      dataStore = try SWAPIDataStore()
    } catch {
      fatalError("Failed to create data store: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        RootSplitView(dataStore: dataStore)
      }
    }
    .modelContainer(dataStore.container)
  }
}
