import Observation
import SwiftUI

struct RootSplitView: View {
  @Bindable
  var model: RootSplitViewModel

  var body: some View {
    NavigationSplitView {
      FilmsView(
        films: model.films,
        selection: filmSelection,
        isLoading: model.isLoadingFilms,
        onRefresh: {
          await model.refresh(force: true)
        }
      )
      .overlay {
        if let error = model.filmsError, model.films.isEmpty {
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
      FilmDetailView(model: model.detailModel)
        .environment(\.openFilmDetails) { summary in
          Task { @MainActor in
            if let target = model.films.first(where: { $0.id == summary.id }) {
              model.selectFilm(target)
            } else {
              await model.refresh(force: true)
              if let refreshed = model.films.first(where: { $0.id == summary.id }) {
                model.selectFilm(refreshed)
              }
            }
          }
        }
    }
    .task {
      await model.loadInitialIfNeeded()
    }
  }
}

extension RootSplitView {
  fileprivate var filmSelection: Binding<RootSplitViewModel.Film?> {
    Binding(
      get: { model.selectedFilm },
      set: { selection in
        model.selectFilm(selection)
      }
    )
  }
}
