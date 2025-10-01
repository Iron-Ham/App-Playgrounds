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

  private static let defaultRelationshipState:
    [SWAPIDataStore.Relationship: RelationshipItemsState] =
      Dictionary(
        uniqueKeysWithValues: SWAPIDataStore.Relationship.allCases.map { relationship in
          (relationship, .idle)
        })

  var body: some View {
    Group {
      if let film {
        detailContent(for: film, summary: relationshipSummary)
          .task(id: film) {
            await loadRelationships(for: film)
          }
          .overlay(alignment: .bottomLeading) {
            if let error = relationshipSummaryError {
              relationshipErrorBanner(error)
            }
          }
      } else {
        ContentUnavailableView {
          Label("Select a film", systemImage: "film")
        }
      }
    }
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

      featuredSection(for: film, summary: summary)

      Section {
        Text(film.openingCrawl)
          .foregroundStyle(.primary)
          .accessibilityLabel(film.openingCrawlAccessibilityLabel)
          .frame(maxWidth: .infinity, alignment: .leading)
      } header: {
        Text("Opening Crawl")
          .font(.headline)
          .textCase(nil)
      }
    }
    .navigationTitle(film.title)
    #if os(iOS) || os(tvOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }

  @ViewBuilder
  private func featuredSection(
    for film: Film,
    summary: SWAPIDataStore.FilmRelationshipSummary
  ) -> some View {
    Section {
      ForEach(SWAPIDataStore.Relationship.allCases, id: \.self) { relationship in
        relationshipDisclosureRow(
          for: relationship,
          film: film,
          summary: summary
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
      }
    } header: {
      Text("Featured In This Film")
        .font(.headline)
        .textCase(nil)
    }
  }

  @ViewBuilder
  private func relationshipDisclosureRow(
    for relationship: SWAPIDataStore.Relationship,
    film: Film,
    summary: SWAPIDataStore.FilmRelationshipSummary
  ) -> some View {
    let binding = expansionBinding(for: relationship, film: film)

    DisclosureGroup(isExpanded: binding) {
      relationshipDetailContent(for: relationship, film: film)
        .padding(.top, 6)
    } label: {
      RelationshipSummaryRow(
        relationship: relationship,
        summaryText: summary.localizedCount(for: relationship)
      )
    }
    .animation(.easeInOut(duration: 0.18), value: binding.wrappedValue)
  }

  private func expansionBinding(
    for relationship: SWAPIDataStore.Relationship,
    film: Film
  ) -> Binding<Bool> {
    Binding {
      expandedRelationships.contains(relationship)
    } set: { isExpanded in
      if isExpanded {
        expandedRelationships.insert(relationship)
        Task {
          await loadRelationshipItems(for: relationship, film: film)
        }
      } else {
        expandedRelationships.remove(relationship)
      }
    }
  }

  @ViewBuilder
  private func relationshipDetailContent(
    for relationship: SWAPIDataStore.Relationship,
    film: Film
  ) -> some View {
    switch relationshipItems[relationship, default: .idle] {
    case .idle:
      VStack(alignment: .leading, spacing: 8) {
        Text("Expand to load details.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

    case .loading:
      HStack(spacing: 12) {
        ProgressView()
        Text("Fetching \(relationship.displayTitle.lowercased()).")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

    case .loaded(let entities):
      if entities.isEmpty {
        Text("No \(relationship.emptyDescription) recorded for this film.")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(Array(entities.enumerated()), id: \.element.id) { index, entity in
            RelationshipItemRow(entity: entity)
              .padding(.vertical, 6)

            if index < entities.count - 1 {
              Divider()
                .padding(.leading, 56)
            }
          }
        }
        .padding(.top, 4)
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
    }
  }

  private func loadRelationshipItems(
    for relationship: SWAPIDataStore.Relationship,
    film: Film,
    forceReload: Bool = false
  ) async {
    guard await shouldStartLoading(relationship, forceReload: forceReload) else { return }

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
  }

  fileprivate enum RelationshipEntity: Identifiable, Equatable {
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
  }

  private struct RelationshipSummaryRow: View {
    let relationship: SWAPIDataStore.Relationship
    let summaryText: String

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
      }
      .contentShape(Rectangle())
    }
  }

  private struct RelationshipItemRow: View {
    let entity: RelationshipEntity

    var body: some View {
      NavigationLink {
        RelationshipDestinationPlaceholder(entity: entity)
      } label: {
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
      }
      .accessibilityElement(children: .combine)
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
    await MainActor.run {
      relationshipSummary = .empty
      relationshipSummaryError = nil
      relationshipItems = Self.defaultRelationshipState
      expandedRelationships.removeAll()
    }

    guard !Task.isCancelled else { return }

    let filmURL = film.url
    let dataStore = self.dataStore
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
