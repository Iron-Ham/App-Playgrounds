#if canImport(Persistence)
  import API
  import Persistence
  import SwiftUI

  extension RelationshipDetailScreens {
    struct SpeciesDetailView: View {
      let screen: Screen
      let details: PersistenceService.SpeciesDetails

      var body: some View {
        RelationshipDetailContainer(
          title: details.name,
          subtitle: subtitle,
          iconName: screen.iconName,
          gradient: screen.accentGradient
        ) {
          RelationshipDetailSection(
            title: String(localized: "Biology"), iconName: "cross.case.fill"
          ) {
            RelationshipDetailRow(
              label: String(localized: "Classification"), value: classificationDisplay,
              systemImage: "square.grid.2x2")
            RelationshipDetailRow(
              label: String(localized: "Designation"), value: designationDisplay,
              systemImage: "person.3")
            RelationshipDetailRow(
              label: String(localized: "Average height"), value: averageHeightDisplay,
              systemImage: "ruler")
            RelationshipDetailRow(
              label: String(localized: "Average lifespan"), value: averageLifespanDisplay,
              systemImage: "hourglass")
          }

          RelationshipDetailSection(
            title: String(localized: "Appearance"), iconName: "paintpalette"
          ) {
            RelationshipDetailRow(
              label: String(localized: "Skin"), value: skinColorDisplay,
              systemImage: "paintbrush")
            RelationshipDetailRow(
              label: String(localized: "Hair"), value: hairColorDisplay,
              systemImage: "comb")
            RelationshipDetailRow(
              label: String(localized: "Eyes"), value: eyeColorDisplay,
              systemImage: "eye")
          }

          RelationshipDetailSection(
            title: String(localized: "Origins & language"), iconName: "globe"
          ) {
            if let homeworld = details.homeworld {
              RelationshipDetailNavigationRow(
                title: homeworld.name,
                subtitle: RelationshipDetailFormatter.planetSummary(for: homeworld),
                iconName: "globe",
                destination: .planet(homeworld)
              )
            } else {
              RelationshipDetailRow(
                label: String(localized: "Homeworld"),
                value: RelationshipDetailFormatter.unknownDisplay,
                systemImage: "globe")
            }

            RelationshipDetailRow(
              label: String(localized: "Language"), value: languageDisplay,
              systemImage: "character.book.closed")
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
                "Cultural rituals, notable representatives, and origin timelines are coming soon."
            )
          )
        }
      }

      private var subtitle: String? {
        RelationshipDetailFormatter.joinedLine([
          RelationshipDetailFormatter.titleCased(details.classification),
          RelationshipDetailFormatter.titleCased(details.language),
        ])
      }

      private var classificationDisplay: String {
        RelationshipDetailFormatter.displayOrFallback(details.classification)
      }

      private var designationDisplay: String {
        RelationshipDetailFormatter.displayOrFallback(details.designation)
      }

      private var averageHeightDisplay: String {
        RelationshipDetailFormatter.measurement(
          details.averageHeight, unit: String(localized: "cm"))
      }

      private var averageLifespanDisplay: String {
        RelationshipDetailFormatter.duration(
          details.averageLifespan, unit: String(localized: "years"))
      }

      private var skinColorDisplay: String {
        RelationshipDetailFormatter.colorSummary(details.skinColors)
      }

      private var hairColorDisplay: String {
        RelationshipDetailFormatter.colorSummary(details.hairColors)
      }

      private var eyeColorDisplay: String {
        RelationshipDetailFormatter.colorSummary(details.eyeColors)
      }

      private var languageDisplay: String {
        RelationshipDetailFormatter.displayOrFallback(details.language)
      }
    }
  }
#endif
