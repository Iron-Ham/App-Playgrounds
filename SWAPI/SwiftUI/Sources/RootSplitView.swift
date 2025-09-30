import API
import Persistence
import SQLiteData
import SwiftUI

struct RootSplitView: View {
  let dataStore: SWAPIDataStore

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

  @State
  private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

  var body: some View {
    NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
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
    }
    .task {
      guard !hasLoadedInitialData else { return }
      await refresh()
    }
    .onAppear {
      preferredCompactColumn = selectedFilm == nil ? .sidebar : .detail
    }
    .onChange(of: selectedFilm) { _, newValue in
      preferredCompactColumn = newValue == nil ? .sidebar : .detail
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
    async let films = Client.films()
    async let people = Client.people()
    async let planets = Client.planets()
    async let species = Client.species()
    async let starships = Client.starships()
    async let vehicles = Client.vehicles()

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
