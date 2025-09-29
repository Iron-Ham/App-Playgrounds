import API
import DataStore
import SwiftData
import SwiftUI

struct ContentView: View {
  let dataStore: SWAPIDataStore

  @Environment(\.modelContext)
  private var modelContext

  @Query(sort: \FilmEntity.releaseDate, order: .reverse)
  private var films: [FilmEntity]

  @State
  private var error: Error?

  @State
  private var isLoading: Bool = false

  @State
  private var hasLoadedInitialData: Bool = false

  @State
  private var selectedFilmID: FilmEntity.ID?

  var body: some View {
    Group {
      if !hasLoadedInitialData {
        VStack {
          Spacer()
          ProgressView()
            .progressViewStyle(.circular)
          Spacer()
        }
      } else if let error, films.isEmpty {
        ErrorView(
          errorTitle: "An error has occurred",
          errorDescription: error.localizedDescription,
          action: {
            await refresh(force: true)
          }
        )
      } else if films.isEmpty {
        ContentUnavailableView {
          Text("No films available")
        }
      } else {
        NavigationSplitView {
          List(selection: $selectedFilmID) {
            Section {
              ForEach(films) { film in
                CellView(film: film)
                  .tag(film.id)
              }
            } header: {
              Text("All films")
            }
          }
          .listStyle(.sidebar)
          .navigationTitle("Star Wars")
          .refreshable {
            await refresh(force: true)
          }
          .overlay(alignment: .bottom) {
            if isLoading {
              ProgressView()
                .progressViewStyle(.circular)
                .padding()
            }
          }
        } detail: {
          if let film = selectedFilm {
            FilmDetailView(film: film)
          } else {
            ContentUnavailableView {
              Label("Select a film", systemImage: "film")
            }
          }
        }
        .navigationSplitViewStyle(.balanced)
      }
    }
    .task {
      guard !hasLoadedInitialData else { return }
      await refresh()
    }
  }
}

private struct CellView: View {
  let film: FilmEntity

  var body: some View {
    VStack(alignment: .leading) {
      if let releaseDate = film.releaseDate?.formatted(date: .abbreviated, time: .omitted) {
        Text(releaseDate)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Text(film.title)
        .font(.title2)
        .foregroundStyle(.primary)
    }
  }
}

private struct FilmDetailView: View {
  let film: FilmEntity

  private var releaseDateText: String? {
    film.releaseDate?.formatted(date: .long, time: .omitted)
  }

  private var producerText: String? {
    guard !film.producerNames.isEmpty else { return nil }
    return ListFormatter.localizedString(byJoining: film.producerNames)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          Text(film.title)
            .font(.largeTitle)
            .fontWeight(.bold)

          if let releaseDateText {
            Text(releaseDateText)
              .font(.headline)
              .foregroundStyle(.secondary)
          }

          Text("Episode \(film.episodeID)")
            .font(.title3)
            .foregroundStyle(.secondary)
        }

        Divider()

        VStack(alignment: .leading, spacing: 12) {
          Label(film.director, systemImage: "megaphone")
            .font(.body.weight(.medium))
            .foregroundStyle(.primary)

          if let producerText {
            Label(producerText, systemImage: "person.2")
              .foregroundStyle(.primary)
          }
        }

        Divider()

        VStack(alignment: .leading, spacing: 12) {
          Text("Opening Crawl")
            .font(.headline)

          Text(film.openingCrawl)
            .foregroundStyle(.primary)
            .accessibilityLabel("Opening crawl: \(film.openingCrawl)")
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
    }
    .navigationTitle(film.title)
    .navigationBarTitleDisplayMode(.inline)
    .background(Color(.systemGroupedBackground))
  }
}

extension ContentView {
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

private extension ContentView {
  var selectedFilm: FilmEntity? {
    if let selectedFilmID {
      films.first { $0.id == selectedFilmID }
    } else {
      nil
    }
  }
}

#Preview {
  let store = SWAPIDataStorePreview.inMemory()

  return NavigationStack {
    ContentView(dataStore: store)
  }
  .modelContainer(store.container)
}
