import API
import DataStore
import SwiftData
import SwiftUI

struct RootSplitView: View {
  let dataStore: SWAPIDataStore

  @Environment(\.modelContext)
  private var modelContext

  @Query(sort: \Film.releaseDate, order: .forward)
  private var films: [Film]

  @State
  private var error: Error?

  @State
  private var isLoading: Bool = false

  @State
  private var hasLoadedInitialData: Bool = false

  @State
  private var selectedFilmID: Film.ID?

  var body: some View {
    NavigationSplitView {
      FilmsView(
        films: films,
        selection: $selectedFilmID,
        isLoading: isLoading,
        onRefresh: {
          await refresh(force: true)
        }
      )
    } detail: {
      FilmDetailView(film: selectedFilmBinding)
    }
    .navigationSplitViewStyle(.balanced)
    .loadableState(
      hasLoadedInitialData: hasLoadedInitialData,
      isContentEmpty: films.isEmpty,
      error: error,
      loadingView: {
        VStack {
          Spacer()
          ProgressView()
            .progressViewStyle(.circular)
          Spacer()
        }
      },
      errorView: { error in
        ErrorView(
          errorTitle: "An error has occurred",
          errorDescription: error.localizedDescription,
          action: {
            await refresh(force: true)
          }
        )
      },
      emptyView: {
        ContentUnavailableView {
          Text("No films available")
        }
      }
    )
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

  @MainActor
  private func loadSnapshot() async throws {
    async let filmsResponse = Client.films()
    async let peopleResponse = Client.people()
    async let planetsResponse = Client.planets()
    async let speciesResponse = Client.species()
    async let starshipsResponse = Client.starships()
    async let vehiclesResponse = Client.vehicles()

    let importer = dataStore.makeImporter(context: modelContext)
    try importer.importSnapshot(
      films: try await filmsResponse,
      people: try await peopleResponse,
      planets: try await planetsResponse,
      species: try await speciesResponse,
      starships: try await starshipsResponse,
      vehicles: try await vehiclesResponse
    )
  }
}

extension RootSplitView {
  fileprivate var selectedFilmBinding: Binding<Film?> {
    Binding(
      get: {
        if let selectedFilmID {
          films.first { $0.id == selectedFilmID }
        } else {
          nil
        }
      },
      set: { film in
        selectedFilmID = film?.id
      }
    )
  }

}

#Preview {
  let store = SWAPIDataStorePreview.inMemory()

  return NavigationStack {
    RootSplitView(dataStore: store)
  }
  .modelContainer(store.container)
}
