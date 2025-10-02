import Dependencies
import FluentPersistence
import Foundation
import SwiftUI

struct FilmDetailView: View {
  @Binding
  var film: Film?
  @Dependency(\.persistenceService)
  var persistenceService: FluentPersistenceService

  @Dependency(\.configurePersistence)
  var configurePersistence: @Sendable () async throws -> Void

  @State
  private var relationshipSummaryState = RelationshipSummaryState()
  @State
  var relationshipSummaryError: Error?
  @State
  var relationshipItems: [Relationship: RelationshipItemsState] =
    Self.defaultRelationshipState
  @State
  var expandedRelationships: Set<Relationship> = []
  @State
  var relationshipNavigationPath: [RelationshipEntity] = []
  @State
  var lastLoadedFilmID: Film.ID?
  @State
  var isPresentingOpeningCrawl = false

  static let defaultRelationshipState: [Relationship: RelationshipItemsState] =
    Dictionary(
      uniqueKeysWithValues: Relationship.allCases.map { relationship in
        (relationship, .idle)
      })

  static let relationshipRowInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

  static let expandedRowsTransition: AnyTransition = .asymmetric(
    insertion: .move(edge: .top).combined(with: .opacity),
    removal: .move(edge: .top).combined(with: .opacity)
  )

  var body: some View {
    Group {
      if let film {
        NavigationStack(path: $relationshipNavigationPath) {
          detailContent(for: film, summary: relationshipSummaryState.summary)
        }
        .navigationDestination(for: RelationshipEntity.self) { entity in
          RelationshipDestinationPlaceholder(entity: entity)
        }
        .id(film.id)
        .task(id: film) {
          await loadRelationships(for: film)
        }
        .onChange(of: film) {
          Task {
            await loadRelationships(for: film)
          }
        }
        .overlay(alignment: .bottomLeading) {
          if let error = relationshipSummaryError {
            relationshipErrorBanner(error)
          }
        }
        #if os(macOS)
          .sheet(isPresented: $isPresentingOpeningCrawl) {
            openingCrawlExperience(for: film)
          }
        #else
          .fullScreenCover(isPresented: $isPresentingOpeningCrawl) {
            openingCrawlExperience(for: film)
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

      Section {
        Button {
          isPresentingOpeningCrawl = true
        } label: {
          OpeningCrawlCallout()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View the Star Wars style opening crawl")
        .accessibilityHint("Presents the opening crawl with animated Star Wars styling")
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
    let filmID = film.id
    let isNewFilm = lastLoadedFilmID != filmID

    do {
      try await configurePersistence()
    } catch {
      await MainActor.run {
        relationshipSummaryError = error
      }
      return
    }

    await MainActor.run {
      relationshipSummaryError = nil
      if isNewFilm {
        relationshipSummaryState.summary = .empty
        relationshipItems = Self.defaultRelationshipState
        expandedRelationships.removeAll()
        relationshipNavigationPath.removeAll()
        isPresentingOpeningCrawl = false
      }
      lastLoadedFilmID = filmID
    }

    guard !Task.isCancelled else { return }
    do {
      let summary = try await persistenceService.relationshipSummary(forFilmWithURL: filmID)
      guard !Task.isCancelled else { return }
      await MainActor.run {
        relationshipSummaryState.summary = summary
        relationshipSummaryError = nil
      }
    } catch is CancellationError {
      return
    } catch {
      guard !Task.isCancelled else {
        return
      }
      await MainActor.run {
        relationshipSummaryError = error
      }
    }
  }
}

#Preview {
  @Previewable
  @State
  var film: Film? = .preview

  let previewFilm = Film.preview

  let previewService = FluentPersistenceService(
    setup: { _ in },
    importSnapshot: { _ in },
    observeChanges: { AsyncStream { _ in } },
    shutdown: {},
    fetchFilms: { [previewFilm] },
    fetchRelationshipSummary: { _ in .empty },
    fetchRelationshipEntities: { _, _ in [] as [FluentPersistenceService.RelationshipEntity] }
  )

  withDependencies {
    $0.persistenceService = previewService
    $0.configurePersistence = {}
  } operation: {
    NavigationStack {
      FilmDetailView(film: $film)
    }
  }
}

extension Film {
  fileprivate static let preview = Self(
    id: URL(string: "https://swapi.dev/api/films/1/")!,
    title: "A New Hope",
    episodeId: 4,
    openingCrawl: "It is a period of civil war...",
    director: "George Lucas",
    producers: ["Gary Kurtz", "Rick McCallum"],
    releaseDate: Date(timeIntervalSince1970: 236_102_400),
    created: Date(timeIntervalSince1970: 236_102_400),
    edited: Date(timeIntervalSince1970: 236_102_400)
  )
}
