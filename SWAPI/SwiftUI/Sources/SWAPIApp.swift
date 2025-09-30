import Persistence
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
      RootSplitView(dataStore: dataStore)
    }
  }
}
