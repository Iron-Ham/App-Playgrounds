import Foundation
import Persistence
import SwiftUI

@Observable
final class RelationshipSummaryState {
  var summary: SWAPIDataStore.FilmRelationshipSummary = .empty
}

extension SWAPIDataStore.FilmRelationshipSummary {
  static let empty = Self(
    characterCount: 0,
    planetCount: 0,
    speciesCount: 0,
    starshipCount: 0,
    vehicleCount: 0
  )

  func localizedCount(_ key: CountKey) -> String {
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

  func localizedCount(for relationship: SWAPIDataStore.Relationship) -> String {
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

  enum CountKey: String {
    case characters = "characters-count"
    case planets = "planets-count"
    case species = "species-count"
    case starships = "starships-count"
    case vehicles = "vehicles-count"
  }
}

extension SWAPIDataStore.Relationship {
  var displayTitle: String {
    switch self {
    case .characters: "Characters"
    case .planets: "Planets"
    case .species: "Species"
    case .starships: "Starships"
    case .vehicles: "Vehicles"
    }
  }

  var iconName: String {
    switch self {
    case .characters: "person.3"
    case .planets: "globe.europe.africa"
    case .species: "leaf"
    case .starships: "airplane"
    case .vehicles: "car"
    }
  }

  var accentColor: Color {
    switch self {
    case .characters: Color.blue
    case .planets: Color.teal
    case .species: Color.green
    case .starships: Color.purple
    case .vehicles: Color.orange
    }
  }

  var accentGradient: LinearGradient {
    LinearGradient(
      colors: [accentColor.opacity(0.75), accentColor],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  var emptyDescription: String {
    displayTitle.lowercased()
  }
}

extension Film {
  var releaseDateLongText: String? {
    releaseDate?.formatted(date: .long, time: .omitted)
  }

  var releaseDateDisplayText: String {
    releaseDateLongText ?? "Release date unavailable"
  }

  var producersListText: String {
    guard !producers.isEmpty else { return "No producers listed" }
    return ListFormatter.localizedString(byJoining: producers)
  }

  var openingCrawlAccessibilityLabel: String {
    String(localized: "Opening crawl: \(openingCrawl)")
  }
}

struct InfoRow: View {
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
