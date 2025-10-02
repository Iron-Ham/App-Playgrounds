#if canImport(Persistence)
  import Persistence
  import Foundation
  import Observation
  import SwiftUI

  struct FilmDetailView: View {
    @Bindable
    var model: FilmDetailModel
    @State
    private var isPresentingOpeningCrawl = false

    static let relationshipRowInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

    static let expandedRowsTransition: AnyTransition = .asymmetric(
      insertion: .move(edge: .top).combined(with: .opacity),
      removal: .move(edge: .top).combined(with: .opacity)
    )

    var body: some View {
      Group {
        if let film = model.film {
          NavigationStack(path: $model.navigationPath) {
            detailContent(for: film, summary: model.summary)
          }
          .navigationDestination(for: RelationshipDetailScreens.Screen.self) { screen in
            RelationshipDetailScreens.makeView(for: screen)
          }
          .id(film.id)
          .overlay(alignment: .bottomLeading) {
            if let error = model.summaryError {
              relationshipErrorBanner(error)
            }
          }
          .onChange(of: film.id) {
            closeOpeningCrawl()
          }
          .onDisappear {
            closeOpeningCrawl()
          }
          #if !os(macOS)
            .fullScreenCover(isPresented: $isPresentingOpeningCrawl) {
              openingCrawlExperience(for: film) {
                isPresentingOpeningCrawl = false
              }
            }
          #endif
        } else {
          ContentUnavailableView {
            Label("Select a film", systemImage: "film")
          }
        }
      }
    }

    private func detailContent(
      for film: Film,
      summary: RelationshipSummary
    ) -> some View {
      List {
        Section {
          headerSection(for: film)
        }

        Section {
          Button {
            presentOpeningCrawl(for: film)
          } label: {
            OpeningCrawlCallout()
          }
          .buttonStyle(.plain)
          .accessibilityLabel("View the Star Wars style opening crawl")
          .accessibilityHint("Presents the opening crawl with animated Star Wars styling")
          .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 16, trailing: 0))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
        } header: {
          Text("Opening Crawl")
            .font(.headline)
            .textCase(nil)
        }

        Section {
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
        } header: {
          Text("Release Information")
            .font(.headline)
            .textCase(nil)
        }

        Section {
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
        } header: {
          Text("Production Team")
            .font(.headline)
            .textCase(nil)
        }

        relationshipSections(for: film, summary: summary)
      }
      .listStyle(.inset)
      .navigationTitle(film.title)
      #if os(iOS) || os(tvOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
    }

    @MainActor
    private func presentOpeningCrawl(for film: Film) {
      #if os(macOS)
        OpeningCrawlFullScreenPresenter.shared.present(
          content: openingCrawlContent(for: film)
        ) {
          isPresentingOpeningCrawl = false
        }
        isPresentingOpeningCrawl = true
      #else
        isPresentingOpeningCrawl = true
      #endif
    }

    @MainActor
    private func closeOpeningCrawl() {
      #if os(macOS)
        OpeningCrawlFullScreenPresenter.shared.dismiss()
      #endif
      isPresentingOpeningCrawl = false
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

    private func headerSection(for film: Film) -> some View {
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
      .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }
  }

  #Preview {
    NavigationStack {
      FilmDetailView(model: FilmDetailModel.preview())
    }
  }
#endif
