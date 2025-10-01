import API
import Dependencies
import SQLiteDataPersistence
import SwiftUI

@main
struct SWAPIApp: App {
  private let dataStore: SWAPIDataStore
  private let client: Client

  init() {
    client = Client()
    do {
      dataStore = try SWAPIDataStore()
      prepareDependencies {
        $0.client = client
        $0.dataStore = dataStore
      }
    } catch {
      fatalError("Failed to create data store: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      RootSplitView()
    }
  }
}
