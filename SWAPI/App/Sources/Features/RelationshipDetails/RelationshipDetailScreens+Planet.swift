#if canImport(Persistence)
  import API
  import Persistence
  import SwiftUI

  extension RelationshipDetailScreens {
    struct PlanetDetailView: View {
      let screen: Screen
      let details: PersistenceService.PlanetDetails

      var body: some View {
        RelationshipDetailContainer(
          title: details.name,
          subtitle: climateSubtitle,
          iconName: screen.iconName,
          gradient: screen.accentGradient
        ) {
          RelationshipDetailSection(
            title: String(localized: "Environment"), iconName: "globe.asia.australia"
          ) {
            RelationshipDetailRow(
              label: String(localized: "Primary climate"), value: climateSummary,
              systemImage: "sun.max")
            RelationshipDetailRow(
              label: String(localized: "Terrains"), value: terrainSummary,
              systemImage: "map")
            RelationshipDetailRow(
              label: String(localized: "Gravity"), value: gravitySummary,
              systemImage: "arrow.up.and.down.circle")
            RelationshipDetailRow(
              label: String(localized: "Surface water"), value: surfaceWaterSummary,
              systemImage: "drop.fill")
            RelationshipDetailRow(
              label: String(localized: "Population"), value: populationSummary,
              systemImage: "person.3")
          }

          RelationshipDetailSection(
            title: String(localized: "Astronomical metrics"), iconName: "clock.arrow.circlepath"
          ) {
            RelationshipDetailRow(
              label: String(localized: "Rotation period"), value: rotationSummary,
              systemImage: "arrow.triangle.2.circlepath")
            RelationshipDetailRow(
              label: String(localized: "Orbital period"), value: orbitalSummary,
              systemImage: "globe.europe.africa")
            RelationshipDetailRow(
              label: String(localized: "Diameter"), value: diameterSummary,
              systemImage: "ruler")
          }

          if !details.films.isEmpty {
            RelationshipDetailSection(
              title: String(localized: "Featured films"), iconName: "film"
            ) {
              ForEach(details.films) { film in
                RelationshipDetailFilmRow(film: film)
              }
            }
          }

          RelationshipDetailSection(
            title: String(localized: "Canonical reference"), iconName: "link"
          ) {
            RelationshipDetailLinkRow(label: String(localized: "API resource"), url: details.id)
          }

          RelationshipDetailCallout(
            text: String(
              localized:
                "Notable settlements, cultural notes, and trade lanes are shipping in a future update."
            )
          )
        }
      }

      private var climateSubtitle: String? {
        guard !details.climates.isEmpty else { return nil }
        return RelationshipDetailFormatter.list(details.climates.map(\.displayName))
      }

      private var climateSummary: String {
        guard !details.climates.isEmpty else {
          return RelationshipDetailFormatter.notDocumentedDisplay
        }
        return RelationshipDetailFormatter.list(details.climates.map(\.displayName))
      }

      private var terrainSummary: String {
        RelationshipDetailFormatter.list(details.terrains.map(\.displayName))
      }

      private var gravitySummary: String {
        RelationshipDetailFormatter.list(details.gravityLevels.map(\.displayName))
      }

      private var surfaceWaterSummary: String {
        RelationshipDetailFormatter.percentage(details.surfaceWater)
      }

      private var populationSummary: String {
        RelationshipDetailFormatter.population(details.population)
      }

      private var rotationSummary: String {
        RelationshipDetailFormatter.measurement(
          details.rotationPeriod, unit: String(localized: "hours"))
      }

      private var orbitalSummary: String {
        RelationshipDetailFormatter.measurement(
          details.orbitalPeriod, unit: String(localized: "days"))
      }

      private var diameterSummary: String {
        RelationshipDetailFormatter.measurement(details.diameter, unit: String(localized: "km"))
      }
    }
  }
#endif
