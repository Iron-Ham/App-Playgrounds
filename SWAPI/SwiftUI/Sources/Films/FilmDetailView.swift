import Foundation
import Persistence
import SwiftUI

struct FilmDetailView: View {
  @Binding var film: Film?
  let dataStore: SWAPIDataStore

  @State
  private var relationshipSummary: SWAPIDataStore.FilmRelationshipSummary = .empty

  @State
  private var relationshipSummaryError: Error?

  var body: some View {
    Group {
      if let film {
        detailContent(for: film, summary: relationshipSummary)
          .task(id: film) {
            await loadRelationships(for: film)
          }
          .overlay(alignment: .bottomLeading) {
            if let error = relationshipSummaryError {
              relationshipErrorBanner(error)
            }
          }
      } else {
        ContentUnavailableView {
          Label("Select a film", systemImage: "film")
        }
      }
    }
  }

  private func detailContent(
    for film: Film,
    summary: SWAPIDataStore.FilmRelationshipSummary
  ) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          Text(film.title)
            .font(.largeTitle)
            .fontWeight(.bold)

          if let releaseDateText = film.releaseDateLongText {
            Text(releaseDateText)
              .font(.headline)
              .foregroundStyle(.secondary)
          }

          Text("Episode \(film.episodeId)")
            .font(.title3)
            .foregroundStyle(.secondary)
        }

        Divider()

        VStack(alignment: .leading, spacing: 12) {
          Text("Release Information")
            .font(.headline)

          InfoRow(
            title: "Episode number",
            value: "Episode \(film.episodeId)",
            iconName: "rectangle.3.offgrid",
            iconDescription: "Icon representing the episode number"
          )

          InfoRow(
            title: "Release date",
            value: film.releaseDateDisplayText,
            iconName: "calendar.circle",
            iconDescription: "Calendar icon denoting the release date"
          )
        }

        Divider()

        VStack(alignment: .leading, spacing: 12) {
          Text("Production Team")
            .font(.headline)

          InfoRow(
            title: "Director",
            value: film.director,
            iconName: "person.crop.rectangle",
            iconDescription: "Person icon indicating the director"
          )

          InfoRow(
            title: "Producers",
            value: film.producersListText,
            iconName: "person.2",
            iconDescription: "People icon indicating the producers"
          )
        }

        Divider()

        VStack(alignment: .leading, spacing: 12) {
          Text("Featured In This Film")
            .font(.headline)

          InfoRow(
            title: "Characters",
            value: summary.localizedCount(.characters),
            iconName: "person.3",
            iconDescription: "Icon representing the number of characters"
          )

          InfoRow(
            title: "Planets",
            value: summary.localizedCount(.planets),
            iconName: "globe.europe.africa",
            iconDescription: "Globe icon representing planets"
          )

          InfoRow(
            title: "Species",
            value: summary.localizedCount(.species),
            iconName: "leaf",
            iconDescription: "Leaf icon representing species"
          )

          InfoRow(
            title: "Starships",
            value: summary.localizedCount(.starships),
            iconName: "airplane",
            iconDescription: "Airplane icon representing starships"
          )

          InfoRow(
            title: "Vehicles",
            value: summary.localizedCount(.vehicles),
            iconName: "car",
            iconDescription: "Car icon representing vehicles"
          )
        }

        Divider()

        VStack(alignment: .leading, spacing: 12) {
          Text("Opening Crawl")
            .font(.headline)

          Text(film.openingCrawl)
            .foregroundStyle(.primary)
            .accessibilityLabel(film.openingCrawlAccessibilityLabel)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
    }
    .navigationTitle(film.title)
#if os(iOS) || os(tvOS)
    .navigationBarTitleDisplayMode(.inline)
#endif
  }

  @ViewBuilder
  private func relationshipErrorBanner(_ error: Error) -> some View {
    Label {
      Text("Some relationship data couldn't be loaded. Showing the latest known values.")
        .font(.footnote)
      Text(error.localizedDescription)
        .font(.footnote)
        .foregroundStyle(.secondary)
    } icon: {
      Image(systemName: "exclamationmark.triangle")
    }
    .padding(8)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    .padding()
    .accessibilityElement(children: .combine)
  }

  private func loadRelationships(for film: Film) async {
    await MainActor.run {
      relationshipSummary = .empty
      relationshipSummaryError = nil
    }

    guard !Task.isCancelled else { return }

    let filmURL = film.url
    let summaryTask = Task.detached(priority: .userInitiated) {
      try dataStore.relationshipSummary(forFilmWithURL: filmURL)
    }

    do {
      let summary = try await summaryTask.value
      guard !Task.isCancelled else { return }
      await MainActor.run {
        relationshipSummary = summary
        relationshipSummaryError = nil
      }
    } catch is CancellationError {
      summaryTask.cancel()
      // Ignore cancellations triggered by SwiftUI refreshing the task.
    } catch {
      guard !Task.isCancelled else {
        summaryTask.cancel()
        return
      }
      await MainActor.run {
        relationshipSummaryError = error
      }
    }
  }
}

private extension SWAPIDataStore.FilmRelationshipSummary {
  static let empty = Self(
    characterCount: 0,
    planetCount: 0,
    speciesCount: 0,
    starshipCount: 0,
    vehicleCount: 0
  )

  func localizedCount(_ key: CountKey) -> String {
    let count: Int = {
      switch key {
      case .characters: characterCount
      case .planets: planetCount
      case .species: speciesCount
      case .starships: starshipCount
      case .vehicles: vehicleCount
      }
    }()

    let format = NSLocalizedString(
      key.rawValue,
      tableName: "FilmDetail",
      bundle: .main,
      value: "%d",
      comment: "Pluralized count for \(key.rawValue)"
    )
    return String.localizedStringWithFormat(format, count)
  }

  enum CountKey: String {
    case characters = "characters-count"
    case planets = "planets-count"
    case species = "species-count"
    case starships = "starships-count"
    case vehicles = "vehicles-count"
  }
}

private extension Film {
  var releaseDateLongText: String? {
    releaseDate?.formatted(date: .long, time: .omitted)
  }

  var releaseDateDisplayText: String {
    releaseDateLongText ?? "Release date unavailable"
  }

  var producersListText: String {
    guard !producers.isEmpty else { return "No producers listed" }
    return ListFormatter.localizedString(byJoining: producers)
  }

  var openingCrawlAccessibilityLabel: String {
    String(localized: "Opening crawl: \(openingCrawl)")
  }
}

private struct InfoRow: View {
  let title: String
  let value: String
  let iconName: String
  let iconDescription: String

  var body: some View {
    Label {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.caption)
          .foregroundStyle(.secondary)

        Text(value)
          .font(.body)
          .foregroundStyle(.primary)
      }
    } icon: {
      Image(systemName: iconName)
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(.tint)
        .accessibilityHidden(true)
    }
    .accessibilityLabel("\(title): \(value)")
    .accessibilityHint(iconDescription)
    .accessibilityElement(children: .combine)
  }
}

#Preview {
  @Previewable @State var film: Film? = Film(
    url: URL(string: "https://swapi.dev/api/films/1/")!,
    title: "A New Hope",
    episodeId: 4,
    openingCrawl: "It is a period of civil war...",
    director: "George Lucas",
    producers: ["Gary Kurtz", "Rick McCallum"],
    releaseDate: Date(timeIntervalSince1970: 236_102_400),
    created: Date(timeIntervalSince1970: 236_102_400),
    edited: Date(timeIntervalSince1970: 236_102_400)
  )

  let dataStore = SWAPIDataStorePreview.inMemory()

  NavigationStack {
    FilmDetailView(film: $film, dataStore: dataStore)
  }
}
