import API
import Persistence
import SQLiteData
import SwiftUI

struct RootSplitView: View {
  let dataStore: SWAPIDataStore
  let client: Client

  @FetchAll(Film.order(by: \.releaseDate))
  private var films

  @State
  private var error: Error?

  @State
  private var isLoading: Bool = false

  @State
  private var hasLoadedInitialData: Bool = false

  @State
  private var selectedFilm: Film?

  init(dataStore: SWAPIDataStore, client: Client = .init()) {
    self.dataStore = dataStore
    self.client = client
  }

  var body: some View {
    NavigationSplitView {
      FilmsView(
        films: films,
        selection: $selectedFilm,
        isLoading: isLoading,
        onRefresh: {
          await refresh(force: true)
        }
      )
    } detail: {
      FilmDetailView(film: $selectedFilm, dataStore: dataStore)
        .redacted(if: isLoading)
        .allowsHitTesting(!isLoading)
    }
    .task {
      guard !hasLoadedInitialData else { return }
      await refresh()
    }
  }
}

extension RootSplitView {
  @MainActor
  private func refresh(force: Bool = false) async {
    if isLoading { return }
    if hasLoadedInitialData, !force, !films.isEmpty { return }

    isLoading = true
    defer {
      isLoading = false
      hasLoadedInitialData = true
    }

    do {
      try await loadSnapshot()
      error = nil
    } catch {
      guard !Task.isCancelled else { return }
      self.error = error
    }
  }

  private func loadSnapshot() async throws {
    let snapshot = try await fetchSnapshot()
    try Task.checkCancellation()
    try await importSnapshot(snapshot)
  }

  private func fetchSnapshot() async throws -> SnapshotPayload {
    let client = self.client
    async let films = client.films()
    async let people = client.people()
    async let planets = client.planets()
    async let species = client.species()
    async let starships = client.starships()
    async let vehicles = client.vehicles()

    return SnapshotPayload(
      films: try await films,
      people: try await people,
      planets: try await planets,
      species: try await species,
      starships: try await starships,
      vehicles: try await vehicles
    )
  }

  private func importSnapshot(_ snapshot: SnapshotPayload) async throws {
    try await Task(priority: .userInitiated) {
      let importer = dataStore.makeImporter()
      try importer.importSnapshot(
        films: snapshot.films,
        people: snapshot.people,
        planets: snapshot.planets,
        species: snapshot.species,
        starships: snapshot.starships,
        vehicles: snapshot.vehicles
      )
    }
    .value
  }
}

private struct SnapshotPayload: Sendable {
  let films: [FilmResponse]
  let people: [PersonResponse]
  let planets: [PlanetResponse]
  let species: [SpeciesResponse]
  let starships: [StarshipResponse]
  let vehicles: [VehicleResponse]
}

#Preview {
  let store = SWAPIDataStorePreview.inMemory()

  return NavigationStack {
    RootSplitView(dataStore: store)
  }
}
