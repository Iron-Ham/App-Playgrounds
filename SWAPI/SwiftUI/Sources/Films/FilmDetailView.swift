import Foundation
import Persistence
import SwiftUI

struct FilmDetailView: View {
  @Binding var film: Film?

  var body: some View {
    Group {
      if let film {
        detailContent(for: film)
      } else {
        ContentUnavailableView {
          Label("Select a film", systemImage: "film")
        }
      }
    }
  }

  private func detailContent(for film: Film) -> some View {
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
            value: film.characterCountDescription,
            iconName: "person.3",
            iconDescription: "Icon representing the number of characters"
          )

          InfoRow(
            title: "Planets",
            value: film.planetCountDescription,
            iconName: "globe.europe.africa",
            iconDescription: "Globe icon representing planets"
          )

          InfoRow(
            title: "Species",
            value: film.speciesCountDescription,
            iconName: "leaf",
            iconDescription: "Leaf icon representing species"
          )

          InfoRow(
            title: "Starships",
            value: film.starshipCountDescription,
            iconName: "airplane",
            iconDescription: "Airplane icon representing starships"
          )

          InfoRow(
            title: "Vehicles",
            value: film.vehicleCountDescription,
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
    .navigationBarTitleDisplayMode(.inline)
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

  var characterCountDescription: String {
    localizedCount(.characters, count: characters.count)
  }

  var planetCountDescription: String {
    localizedCount(.planets, count: planets.count)
  }

  var speciesCountDescription: String {
    localizedCount(.species, count: species.count)
  }

  var starshipCountDescription: String {
    localizedCount(.starships, count: starships.count)
  }

  var vehicleCountDescription: String {
    localizedCount(.vehicles, count: vehicles.count)
  }

  var openingCrawlAccessibilityLabel: String {
    String(localized: "Opening crawl: \(openingCrawl)")
  }

  private func localizedCount(_ key: CountKey, count: Int) -> String {
    let format = NSLocalizedString(
      key.rawValue,
      tableName: "FilmDetail",
      bundle: .main,
      value: "%d",
      comment: "Pluralized count for \(key.rawValue)"
    )
    return String.localizedStringWithFormat(format, count)
  }

  private enum CountKey: String {
    case characters = "characters-count"
    case planets = "planets-count"
    case species = "species-count"
    case starships = "starships-count"
    case vehicles = "vehicles-count"
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
  let film = Film(
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

  return NavigationStack {
    FilmDetailView(film: .constant(Optional(film)))
  }
}
