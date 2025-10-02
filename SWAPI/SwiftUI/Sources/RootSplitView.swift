import API
import Dependencies
import FluentPersistence
import SwiftUI

struct RootSplitView: View {
  @Dependency(\.client)
  private var client: Client

  @Dependency(\.persistenceService)
  private var persistenceService: FluentPersistenceService

  @Dependency(\.configurePersistence)
  private var configurePersistence: @Sendable () async throws -> Void

  @State
  private var films: [Film] = []

  @State
  private var error: Error?

  @State
  private var isLoading: Bool = false

  @State
  private var hasLoadedInitialData: Bool = false

  @State
  private var selectedFilm: Film?

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
      FilmDetailView(film: $selectedFilm)
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
      try await configurePersistence()
      let snapshot = try await fetchSnapshot()
      try Task.checkCancellation()
      try await importSnapshot(snapshot)
      let fetchedFilms = try await persistenceService.films()
      updateFilms(with: fetchedFilms)
      error = nil
    } catch {
      guard !Task.isCancelled else { return }
      self.error = error
    }
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
    try await persistenceService.importSnapshot(
      .init(
        films: snapshot.films,
        people: snapshot.people,
        planets: snapshot.planets,
        species: snapshot.species,
        starships: snapshot.starships,
        vehicles: snapshot.vehicles
      )
    )
  }

  @MainActor
  private func updateFilms(with newFilms: [Film]) {
    let currentSelectionID = selectedFilm?.id
    films = newFilms

    if let currentSelectionID,
      let matchingFilm = newFilms.first(where: { $0.id == currentSelectionID })
    {
      selectedFilm = matchingFilm
    } else if let firstFilm = newFilms.first {
      selectedFilm = firstFilm
    } else {
      selectedFilm = nil
    }
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
