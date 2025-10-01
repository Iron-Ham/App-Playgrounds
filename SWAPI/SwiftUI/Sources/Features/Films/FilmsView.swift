import SQLiteDataPersistence
import SwiftUI

struct FilmsView: View {
  let films: [Film]

  @Binding
  var selection: Film?

  let isLoading: Bool

  let onRefresh: () async -> Void

  private static let placeholderRows = Array(0..<6)

  var body: some View {
    List(selection: $selection) {
      Section {
        if isLoading, films.isEmpty {
          ForEach(Self.placeholderRows, id: \.self) { _ in
            CellView(film: nil)
          }
        } else {
          ForEach(films) { film in
            CellView(film: film)
              .tag(film)
          }
        }
      } header: {
        Text("All films")
      }
    }
    .listStyle(.sidebar)
    .navigationTitle("Star Wars")
    .refreshable {
      await onRefresh()
    }
    .redacted(if: isLoading)
    .allowsHitTesting(!isLoading)
  }
}

private struct CellView: View {
  let film: Film?

  private var episodeNumber: String {
    film.flatMap({ "Episode \($0.episodeId)" }) ?? .placeholder(length: 10)
  }

  private var releaseDateText: String {
    film?.releaseDate?.formatted(date: .abbreviated, time: .omitted) ?? .placeholder(length: 20)
  }

  private var filmTitle: String {
    film?.title ?? .placeholder(length: 12)
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(episodeNumber)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Text(filmTitle)
        .font(.body)
        .foregroundStyle(.primary)

      Text(releaseDateText)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }.redacted(if: film == nil)
  }
}

#Preview {
  NavigationStack {
    FilmsView(
      films: [
        Film(
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
      ],
      selection: .constant(nil),
      isLoading: false,
      onRefresh: {}
    )
  }
}
