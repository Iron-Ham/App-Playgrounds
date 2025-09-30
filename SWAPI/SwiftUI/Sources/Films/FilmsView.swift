import Persistence
import SwiftUI

struct FilmsView: View {
  let films: [Film]

  @Binding
  var selection: Film?

  let isLoading: Bool

  let onRefresh: () async -> Void

  var body: some View {
    List(selection: $selection) {
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
      await onRefresh()
    }
    .overlay(alignment: .bottom) {
      if isLoading {
        ProgressView()
          .progressViewStyle(.circular)
          .padding()
      }
    }
  }
}

private struct CellView: View {
  let film: Film

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
      onRefresh: {
}
    )
  }
}
