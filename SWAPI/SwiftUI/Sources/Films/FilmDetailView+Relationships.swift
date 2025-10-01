import Foundation
import Persistence
import SwiftUI

extension FilmDetailView {
  @ViewBuilder
  func relationshipSections(
    for film: Film,
    summary: SWAPIDataStore.FilmRelationshipSummary
  ) -> some View {
    let relationships = Array(SWAPIDataStore.Relationship.allCases.enumerated())
    Section {
      ForEach(relationships, id: \.element) { index, relationship in
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
      }
    } header: {
      Text("Featured In This Film")
        .font(.headline)
        .textCase(nil)
    }
  }

  @ViewBuilder
  func relationshipExpandedRows(
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
  func toggleRelationshipExpansion(
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
  func navigateToRelationshipEntity(_ entity: RelationshipEntity) {
    guard relationshipNavigationPath != [entity] else { return }
    withAnimation(.easeInOut(duration: 0.18)) {
      relationshipNavigationPath = [entity]
    }
  }

  func loadRelationshipItems(
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
  func shouldStartLoading(
    _ relationship: SWAPIDataStore.Relationship,
    forceReload: Bool
  ) -> Bool {
    let state = relationshipItems[relationship] ?? .idle
    if forceReload { return true }
    if state.isLoading || state.isLoaded { return false }
    return true
  }

  func fetchEntities(
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

  enum RelationshipItemsState: Equatable {
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

  enum RelationshipEntity: Identifiable, Hashable {
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
  }
}

extension FilmDetailView {
  struct RelationshipSummaryRow: View {
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

  struct RelationshipItemRow: View {
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

  struct RelationshipThumbnail: View {
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

  struct RelationshipDestinationPlaceholder: View {
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

  struct RelationshipBadge: View {
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
}
