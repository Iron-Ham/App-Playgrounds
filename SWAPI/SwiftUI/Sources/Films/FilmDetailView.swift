import Dependencies
import Foundation
import Persistence
import SwiftUI

struct FilmDetailView: View {
  @Binding
  var film: Film?
  @Dependency(\.dataStore)
  private var dataStore: SWAPIDataStore

  @State
  private var relationshipSummary: SWAPIDataStore.FilmRelationshipSummary = .empty

  @State
  private var relationshipSummaryError: Error?

  @State
  private var relationshipItems: [SWAPIDataStore.Relationship: RelationshipItemsState] =
    Self.defaultRelationshipState

  @State
  private var expandedRelationships: Set<SWAPIDataStore.Relationship> = []

  @State
  private var relationshipNavigationPath: [RelationshipEntity] = []

  @State
  private var lastLoadedFilmID: Film.ID?

  @State
  private var isPresentingOpeningCrawl = false

  private static let defaultRelationshipState:
    [SWAPIDataStore.Relationship: RelationshipItemsState] =
      Dictionary(
        uniqueKeysWithValues: SWAPIDataStore.Relationship.allCases.map { relationship in
          (relationship, .idle)
        })

  private static let relationshipRowInsets = EdgeInsets(
    top: 8, leading: 16, bottom: 8, trailing: 16)

  private static let expandedRowsTransition: AnyTransition = .asymmetric(
    insertion: .move(edge: .top).combined(with: .opacity),
    removal: .move(edge: .top).combined(with: .opacity)
  )

  var body: some View {
    Group {
      if let film {
        NavigationStack(path: $relationshipNavigationPath) {
          detailContent(for: film, summary: relationshipSummary)
        }
        .navigationDestination(for: RelationshipEntity.self) { entity in
          RelationshipDestinationPlaceholder(entity: entity)
        }
        .id(film.url)
        .task(id: film) {
          await loadRelationships(for: film)
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

  @ViewBuilder
  private func openingCrawlExperience(for film: Film) -> some View {
    OpeningCrawlView(
      content: .init(
        title: film.title,
        episodeNumber: film.episodeId,
        openingText: film.openingCrawl
      )
    )
    .environment(\.colorScheme, .dark)
  }

  private func detailContent(
    for film: Film,
    summary: SWAPIDataStore.FilmRelationshipSummary
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
    //    .listStyle(.grouped)
    .navigationTitle(film.title)
    #if os(iOS) || os(tvOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }

  @ViewBuilder
  private func relationshipSections(
    for film: Film,
    summary: SWAPIDataStore.FilmRelationshipSummary
  ) -> some View {
    let relationships = Array(SWAPIDataStore.Relationship.allCases.enumerated())
    ForEach(relationships, id: \.element) { index, relationship in
      Section {
        let isExpanded = expandedRelationships.contains(relationship)
        Button {
          toggleRelationshipExpansion(for: relationship, film: film)
        } label: {
          RelationshipSummaryRow(
            relationship: relationship,
            summaryText: summary.localizedCount(for: relationship),
            isExpanded: isExpanded
          )
          .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .listRowInsets(Self.relationshipRowInsets)
        .contentShape(Rectangle())

        if isExpanded {
          relationshipExpandedRows(for: relationship, film: film)
            .transition(Self.expandedRowsTransition)
        }
      } header: {
        if index == 0 {
          Text("Featured In This Film")
            .font(.headline)
            .textCase(nil)
        }
      }
      .animation(.easeInOut(duration: 0.22), value: expandedRelationships)
      .animation(
        .easeInOut(duration: 0.22),
        value: relationshipItems[relationship, default: .idle].animationID
      )
    }
  }

  @ViewBuilder
  private func relationshipExpandedRows(
    for relationship: SWAPIDataStore.Relationship,
    film: Film
  ) -> some View {
    let state = relationshipItems[relationship, default: .idle]

    Group {
      switch state {
      case .idle:
        Text("Expand to load details.")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .listRowInsets(Self.relationshipRowInsets)

      case .loading:
        HStack(spacing: 12) {
          ProgressView()
          Text("Fetching \(relationship.displayTitle.lowercased()).")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowInsets(Self.relationshipRowInsets)

      case .loaded(let entities):
        if entities.isEmpty {
          Text("No \(relationship.emptyDescription) recorded for this film.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(Self.relationshipRowInsets)
        } else {
          ForEach(entities) { entity in
            Button {
              navigateToRelationshipEntity(entity)
            } label: {
              RelationshipItemRow(entity: entity)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .listRowInsets(Self.relationshipRowInsets)
            .transition(Self.expandedRowsTransition)
          }
        }

      case .failed(let message):
        VStack(alignment: .leading, spacing: 10) {
          Label {
            Text("We couldn't load the latest \(relationship.emptyDescription).")
              .font(.footnote)
            Text(message)
              .font(.caption)
              .foregroundStyle(.secondary)
          } icon: {
            Image(systemName: "exclamationmark.triangle")
              .foregroundStyle(.orange)
          }

          Button("Retry") {
            Task {
              await loadRelationshipItems(for: relationship, film: film, forceReload: true)
            }
          }
          .buttonStyle(.borderedProminent)
          .tint(relationship.accentColor)
          .font(.footnote)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .listRowInsets(Self.relationshipRowInsets)
      }
    }
    .animation(.easeInOut(duration: 0.22), value: state.animationID)
  }

  @MainActor
  private func toggleRelationshipExpansion(
    for relationship: SWAPIDataStore.Relationship,
    film: Film
  ) {
    if expandedRelationships.contains(relationship) {
      withAnimation(.easeInOut(duration: 0.18)) {
        _ = expandedRelationships.remove(relationship)
      }
    } else {
      withAnimation(.easeInOut(duration: 0.18)) {
        _ = expandedRelationships.insert(relationship)
      }

      Task {
        await loadRelationshipItems(for: relationship, film: film)
      }
    }
  }

  @MainActor
  private func navigateToRelationshipEntity(_ entity: RelationshipEntity) {
    guard relationshipNavigationPath != [entity] else { return }
    withAnimation(.easeInOut(duration: 0.18)) {
      relationshipNavigationPath = [entity]
    }
  }

  private func loadRelationshipItems(
    for relationship: SWAPIDataStore.Relationship,
    film: Film,
    forceReload: Bool = false
  ) async {
    guard shouldStartLoading(relationship, forceReload: forceReload) else { return }

    await MainActor.run {
      relationshipItems[relationship] = .loading
    }

    guard !Task.isCancelled else { return }

    let filmURL = film.url
    let dataStore = self.dataStore
    let fetchTask = Task(priority: .userInitiated) { () throws -> [RelationshipEntity] in
      try fetchEntities(for: relationship, filmURL: filmURL, dataStore: dataStore)
    }

    do {
      let entities = try await fetchTask.value
      guard !Task.isCancelled else { return }
      await MainActor.run {
        relationshipItems[relationship] = .loaded(entities)
      }
    } catch is CancellationError {
      fetchTask.cancel()
    } catch {
      guard !Task.isCancelled else {
        fetchTask.cancel()
        return
      }
      await MainActor.run {
        relationshipItems[relationship] = .failed(error.localizedDescription)
      }
    }
  }

  @MainActor
  private func shouldStartLoading(
    _ relationship: SWAPIDataStore.Relationship,
    forceReload: Bool
  ) -> Bool {
    let state = relationshipItems[relationship] ?? .idle
    if forceReload { return true }
    if state.isLoading || state.isLoaded { return false }
    return true
  }

  private func fetchEntities(
    for relationship: SWAPIDataStore.Relationship,
    filmURL: Film.ID,
    dataStore: SWAPIDataStore
  ) throws -> [RelationshipEntity] {
    switch relationship {
    case .characters:
      return try dataStore.characters(forFilmWithURL: filmURL).map(RelationshipEntity.character)
    case .planets:
      return try dataStore.planets(forFilmWithURL: filmURL).map(RelationshipEntity.planet)
    case .species:
      return try dataStore.species(forFilmWithURL: filmURL).map(RelationshipEntity.species)
    case .starships:
      return try dataStore.starships(forFilmWithURL: filmURL).map(RelationshipEntity.starship)
    case .vehicles:
      return try dataStore.vehicles(forFilmWithURL: filmURL).map(RelationshipEntity.vehicle)
    }
  }

  fileprivate enum RelationshipItemsState: Equatable {
    case idle
    case loading
    case loaded([RelationshipEntity])
    case failed(String)

    var isLoading: Bool {
      if case .loading = self { return true }
      return false
    }

    var isLoaded: Bool {
      if case .loaded = self { return true }
      return false
    }

    var animationID: Int {
      switch self {
      case .idle: 0
      case .loading: 1
      case .loaded(let entities): 2 + entities.count
      case .failed: 3
      }
    }
  }

  fileprivate enum RelationshipEntity: Identifiable, Hashable {
    case character(SWAPIDataStore.CharacterDetails)
    case planet(SWAPIDataStore.PlanetDetails)
    case species(SWAPIDataStore.SpeciesDetails)
    case starship(SWAPIDataStore.StarshipDetails)
    case vehicle(SWAPIDataStore.VehicleDetails)

    var id: String {
      switch self {
      case .character(let details): return details.id.absoluteString
      case .planet(let details): return details.id.absoluteString
      case .species(let details): return details.id.absoluteString
      case .starship(let details): return details.id.absoluteString
      case .vehicle(let details): return details.id.absoluteString
      }
    }

    var title: String {
      switch self {
      case .character(let details): return details.name
      case .planet(let details): return details.name
      case .species(let details): return details.name
      case .starship(let details): return details.name
      case .vehicle(let details): return details.name
      }
    }

    var subtitle: String? {
      switch self {
      case .character(let details):
        return joinedDescription([
          details.gender.displayName,
          details.birthYear.rawValue,
        ])

      case .planet(let details):
        let population: String? = {
          let trimmed = details.population.trimmingCharacters(in: .whitespacesAndNewlines)
          guard !trimmed.isEmpty, trimmed.lowercased() != "unknown" else { return nil }
          return "Population \(trimmed.capitalized)"
        }()

        let climates = details.climates
          .map(\.displayName)
          .filter { !$0.isEmpty }

        let climateSummary =
          climates.isEmpty
          ? nil
          : "Climate \(ListFormatter.localizedString(byJoining: climates))"

        return joinedDescription([population, climateSummary])

      case .species(let details):
        return joinedDescription([
          details.classification.localizedCapitalized,
          details.language.localizedCapitalized,
        ])

      case .starship(let details):
        return joinedDescription([
          details.model,
          details.starshipClass.displayName,
        ])

      case .vehicle(let details):
        return joinedDescription([
          details.model,
          details.vehicleClass.displayName,
        ])
      }
    }

    var relationship: SWAPIDataStore.Relationship {
      switch self {
      case .character: .characters
      case .planet: .planets
      case .species: .species
      case .starship: .starships
      case .vehicle: .vehicles
      }
    }

    var iconName: String { relationship.iconName }

    var placeholderTitle: String {
      switch relationship {
      case .characters:
        return "Character details coming soon"
      case .planets:
        return "Planet profile coming soon"
      case .species:
        return "Species encyclopedia coming soon"
      case .starships:
        return "Starship hangar coming soon"
      case .vehicles:
        return "Vehicle bay coming soon"
      }
    }

    var placeholderDescription: String {
      switch relationship {
      case .characters:
        return "We're building rich biographies for every hero and villain in the saga."
      case .planets:
        return "Detailed planetary data, maps, and lore will land in a future release."
      case .species:
        return "Species spotlights will highlight cultures, traits, and homeworlds soon."
      case .starships:
        return "Deck plans and performance stats are on the flight deck for a later update."
      case .vehicles:
        return "Specs and operational history will roll out in an upcoming build."
      }
    }

    private func joinedDescription(_ components: [String?]) -> String? {
      let values = components.compactMap { component -> String? in
        guard let component else { return nil }
        let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
      }
      guard !values.isEmpty else { return nil }
      return values.joined(separator: " • ")
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
  }

  private struct RelationshipSummaryRow: View {
    let relationship: SWAPIDataStore.Relationship
    let summaryText: String
    let isExpanded: Bool

    var body: some View {
      HStack(spacing: 12) {
        RelationshipBadge(relationship: relationship)
        VStack(alignment: .leading, spacing: 2) {
          Text(relationship.displayTitle)
            .font(.headline)
            .foregroundStyle(.primary)
          Text(summaryText)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Image(systemName: "chevron.down")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
          .rotationEffect(isExpanded ? .degrees(180) : .degrees(0))
          .animation(.easeInOut(duration: 0.18), value: isExpanded)
      }
      .contentShape(Rectangle())
    }
  }

  private struct RelationshipItemRow: View {
    let entity: RelationshipEntity

    var body: some View {
      HStack(spacing: 12) {
        RelationshipThumbnail(entity: entity)
        VStack(alignment: .leading, spacing: 3) {
          Text(entity.title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
          if let subtitle = entity.subtitle {
            Text(subtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        Spacer(minLength: 0)
      }
      .contentShape(Rectangle())
    }
  }

  private struct RelationshipThumbnail: View {
    let entity: RelationshipEntity
    var size: CGFloat = 40

    var body: some View {
      RoundedRectangle(cornerRadius: size / 4, style: .continuous)
        .fill(entity.relationship.accentGradient)
        .frame(width: size, height: size)
        .overlay {
          Image(systemName: entity.iconName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
        }
        .shadow(color: entity.relationship.accentColor.opacity(0.18), radius: 4, x: 0, y: 2)
        .accessibilityHidden(true)
    }
  }

  private struct RelationshipDestinationPlaceholder: View {
    let entity: RelationshipEntity

    var body: some View {
      RelationshipDetailPlaceholder(
        title: entity.title,
        iconName: entity.iconName,
        accentGradient: entity.relationship.accentGradient,
        headline: entity.placeholderTitle,
        message: entity.placeholderDescription
      )
    }
  }

  private struct RelationshipDisclosureCell<DetailContent: View>: View {
    let relationship: SWAPIDataStore.Relationship
    let summaryText: String
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder
    let detailContent: () -> DetailContent

    var body: some View {
      VStack(spacing: 0) {
        Button(action: onToggle) {
          RelationshipSummaryRow(
            relationship: relationship,
            summaryText: summaryText,
            isExpanded: isExpanded
          )
          .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())

        if isExpanded {
          Divider()
            .padding(.leading, 56)

          detailContent()
            .padding(.top, 12)
            .transition(
              .move(edge: .top)
                .combined(with: .opacity)
            )
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .animation(.easeInOut(duration: 0.18), value: isExpanded)
    }
  }

  private struct RelationshipBadge: View {
    let relationship: SWAPIDataStore.Relationship

    var body: some View {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(relationship.accentGradient)
        .frame(width: 44, height: 44)
        .overlay {
          Image(systemName: relationship.iconName)
            .font(.title3)
            .foregroundStyle(.white)
        }
        .shadow(color: relationship.accentColor.opacity(0.16), radius: 4, x: 0, y: 2)
        .accessibilityHidden(true)
    }
  }

  private struct OpeningCrawlCallout: View {
    @Environment(\.colorScheme)
    private var colorScheme

    var body: some View {
      ZStack {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .fill(.ultraThinMaterial)
          .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
              .strokeBorder(Color.yellow.opacity(0.45), lineWidth: 1.5)
              .blendMode(.screen)
          }
          .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.2), radius: 14, y: 10)

        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack")
              .symbolRenderingMode(.hierarchical)
              .font(.system(size: 32, weight: .semibold))
              .foregroundStyle(
                LinearGradient(
                  colors: [Color.yellow, Color.orange.opacity(0.9)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .shadow(color: Color.yellow.opacity(0.4), radius: 12, y: 6)

            VStack(alignment: .leading, spacing: 4) {
              Text("Experience the crawl")
                .font(.headline)
                .foregroundStyle(Color.primary)

              Text("Watch the animated intro exactly how it appears on screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
          }

          HStack(spacing: 8) {
            Spacer()
            Text("Launch cinematic crawl")
              .font(.footnote.weight(.semibold))
              .textCase(.uppercase)
              .tracking(1.2)
              .foregroundStyle(Color.yellow)
            Image(systemName: "chevron.right")
              .font(.footnote.weight(.bold))
              .foregroundStyle(Color.yellow.opacity(0.9))
          }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
      }
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
      .padding(.vertical, 6)
    }
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
    let filmURL = film.url
    let dataStore = self.dataStore
    let isNewFilm = lastLoadedFilmID != filmURL

    await MainActor.run {
      relationshipSummaryError = nil
      if isNewFilm {
        relationshipSummary = .empty
        relationshipItems = Self.defaultRelationshipState
        expandedRelationships.removeAll()
        relationshipNavigationPath.removeAll()
        isPresentingOpeningCrawl = false
      }
      lastLoadedFilmID = filmURL
    }

    guard !Task.isCancelled else { return }

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

extension SWAPIDataStore.FilmRelationshipSummary {
  fileprivate static let empty = Self(
    characterCount: 0,
    planetCount: 0,
    speciesCount: 0,
    starshipCount: 0,
    vehicleCount: 0
  )

  fileprivate func localizedCount(_ key: CountKey) -> String {
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

  fileprivate func localizedCount(for relationship: SWAPIDataStore.Relationship) -> String {
    switch relationship {
    case .characters:
      localizedCount(.characters)
    case .planets:
      localizedCount(.planets)
    case .species:
      localizedCount(.species)
    case .starships:
      localizedCount(.starships)
    case .vehicles:
      localizedCount(.vehicles)
    }
  }

  fileprivate enum CountKey: String {
    case characters = "characters-count"
    case planets = "planets-count"
    case species = "species-count"
    case starships = "starships-count"
    case vehicles = "vehicles-count"
  }
}

extension SWAPIDataStore.Relationship {
  fileprivate var displayTitle: String {
    switch self {
    case .characters: "Characters"
    case .planets: "Planets"
    case .species: "Species"
    case .starships: "Starships"
    case .vehicles: "Vehicles"
    }
  }

  fileprivate var iconName: String {
    switch self {
    case .characters: "person.3"
    case .planets: "globe.europe.africa"
    case .species: "leaf"
    case .starships: "airplane"
    case .vehicles: "car"
    }
  }

  fileprivate var accentColor: Color {
    switch self {
    case .characters: Color.blue
    case .planets: Color.teal
    case .species: Color.green
    case .starships: Color.purple
    case .vehicles: Color.orange
    }
  }

  fileprivate var accentGradient: LinearGradient {
    LinearGradient(
      colors: [accentColor.opacity(0.75), accentColor],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  fileprivate var emptyDescription: String {
    displayTitle.lowercased()
  }
}

extension Film {
  fileprivate var releaseDateLongText: String? {
    releaseDate?.formatted(date: .long, time: .omitted)
  }

  fileprivate var releaseDateDisplayText: String {
    releaseDateLongText ?? "Release date unavailable"
  }

  fileprivate var producersListText: String {
    guard !producers.isEmpty else { return "No producers listed" }
    return ListFormatter.localizedString(byJoining: producers)
  }

  fileprivate var openingCrawlAccessibilityLabel: String {
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
  @Previewable
  @State
  var film: Film? = Film(
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

  withDependencies {
    $0.dataStore = SWAPIDataStorePreview.inMemory()
  } operation: {
    NavigationStack {
      FilmDetailView(film: $film)
    }
  }
}
