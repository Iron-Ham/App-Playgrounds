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

      var relationship: PersistenceService.Relationship {
        switch self {
        case .character:
          return .characters
        case .planet:
          return .planets
        case .species:
          return .species
        case .starship:
          return .starships
        case .vehicle:
          return .vehicles
        }
      }

      var iconName: String { relationship.iconName }

      var accentGradient: LinearGradient { relationship.accentGradient }
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
      }
    }
  }
#endif
