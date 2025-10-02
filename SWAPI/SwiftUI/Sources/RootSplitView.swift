import SwiftUI

struct RootSplitView: View {
  @ObservedObject
  var model: RootSplitViewModel

  var body: some View {
    NavigationSplitView {
      FilmsView(
        films: model.films,
        selection: filmSelection,
        isLoading: model.isLoading,
        onRefresh: {
          await model.refresh(force: true)
        }
      )
      .overlay {
        if let error = model.error, model.films.isEmpty {
          VStack {
            Spacer()
            ErrorView(
              errorTitle: "Couldn’t refresh Star Wars data",
              errorDescription: error.localizedDescription,
              action: {
                await model.refresh(force: true)
              }
            )
            .padding()
          }
        }
      }
    } detail: {
      FilmDetailView(
        film: filmSelection
      )
      .redacted(if: model.isLoading)
      .allowsHitTesting(!model.isLoading)
    }
    .task {
      await model.loadInitialIfNeeded()
    }
  }
}

extension RootSplitView {
  fileprivate var filmSelection: Binding<PersistenceCoordinator.Film?> {
    Binding(
      get: { model.selectedFilm },
      set: { selection in
        model.selectedFilm = selection
      }
    )
  }
}
