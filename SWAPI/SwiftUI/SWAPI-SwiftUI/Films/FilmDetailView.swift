import DataStore
import SwiftData
import SwiftUI

struct FilmDetailView: View {
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
