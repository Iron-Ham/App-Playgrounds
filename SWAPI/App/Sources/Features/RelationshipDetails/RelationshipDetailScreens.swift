#if canImport(Persistence)
  import API
  import Persistence
  import SwiftUI

  /// Shared namespace for the dedicated relationship detail experiences presented from a film.
  enum RelationshipDetailScreens {
    enum Screen: Hashable {
      case character(PersistenceService.CharacterDetails)
      case planet(PersistenceService.PlanetDetails)
      case species(PersistenceService.SpeciesDetails)
      case starship(PersistenceService.StarshipDetails)
      case vehicle(PersistenceService.VehicleDetails)
      case film(PersistenceService.FilmSummary)

      init(entity: PersistenceService.RelationshipEntity) {
        switch entity {
        case .character(let details):
          self = .character(details)
        case .planet(let details):
          self = .planet(details)
        case .species(let details):
          self = .species(details)
        case .starship(let details):
          self = .starship(details)
        case .vehicle(let details):
          self = .vehicle(details)
        }
      }

      var iconName: String {
        switch self {
        case .character:
          return PersistenceService.Relationship.characters.iconName
        case .planet:
          return PersistenceService.Relationship.planets.iconName
        case .species:
          return PersistenceService.Relationship.species.iconName
        case .starship:
          return PersistenceService.Relationship.starships.iconName
        case .vehicle:
          return PersistenceService.Relationship.vehicles.iconName
        case .film:
          return "film"
        }
      }

      var accentGradient: LinearGradient {
        switch self {
        case .character:
          return PersistenceService.Relationship.characters.accentGradient
        case .planet:
          return PersistenceService.Relationship.planets.accentGradient
        case .species:
          return PersistenceService.Relationship.species.accentGradient
        case .starship:
          return PersistenceService.Relationship.starships.accentGradient
        case .vehicle:
          return PersistenceService.Relationship.vehicles.accentGradient
        case .film:
          return LinearGradient(
            colors: [Color.orange.opacity(0.85), Color.pink.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        }
      }
    }

    @ViewBuilder
    static func makeView(for screen: Screen) -> some View {
      switch screen {
      case .character(let details):
        CharacterDetailView(screen: screen, details: details)
      case .planet(let details):
        PlanetDetailView(screen: screen, details: details)
      case .species(let details):
        SpeciesDetailView(screen: screen, details: details)
      case .starship(let details):
        StarshipDetailView(screen: screen, details: details)
      case .vehicle(let details):
        VehicleDetailView(screen: screen, details: details)
      case .film(let summary):
        FilmSummaryDetailView(screen: screen, film: summary)
      }
    }
  }
#endif
