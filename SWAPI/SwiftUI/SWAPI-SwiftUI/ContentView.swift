import API
import SwiftUI

struct ContentView: View {
  @State var films: [FilmResponse] = []
  @State var error: Error?
  @State var isLoading: Bool = true

  private func fetch() async {
    do {
      films = try await SWAPIClient.films()
      isLoading = false
      error = nil
    } catch {
      self.error = error
    }
  }

  var body: some View {
    Group {
      if isLoading {
        VStack {
          Spacer()
          ProgressView()
            .progressViewStyle(.circular)
          Spacer()
        }
      } else if let error {
        ErrorView(
          errorTitle: "An error has occurred",
          errorDescription: error.localizedDescription,
          action: {
            await fetch()
          }
        )
      }

      if let error {
        ContentUnavailableView(
          "An error has occurred",
          image: "x.circle",
          description: Text(error.localizedDescription)
        )
      } else {
        Group {
          if films.isEmpty {
            ContentUnavailableView {
              Text("No films available")
            }
          } else {
            List {
              Section {
                ForEach(films) { film in
                  CellView(film: film)
                }
              } header: {
                Text("All films")
              }
            }
          }
        }.task {
          await fetch()
        }
      }
    }.navigationTitle("Star Wars")
  }
}

private struct CellView: View {
  let film: FilmResponse

  var body: some View {
    VStack(alignment: .leading) {
      if let releaseDate = film.release?.formatted(date: .abbreviated, time: .omitted) {
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
    ContentView()
  }
}
