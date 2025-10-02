#if canImport(Persistence)
  import API
  import Persistence
  import SwiftUI

  extension RelationshipDetailScreens {
    struct StarshipDetailView: View {
      let screen: Screen
      let details: PersistenceService.StarshipDetails

      var body: some View {
        RelationshipDetailContainer(
          title: details.name,
          subtitle: details.model,
          iconName: screen.iconName,
          gradient: screen.accentGradient
        ) {
          RelationshipDetailSection(
            title: String(localized: "Specifications"), iconName: "wrench.and.screwdriver"
          ) {
            RelationshipDetailRow(
              label: String(localized: "Model"), value: details.model,
              systemImage: "barcode.viewfinder")
            RelationshipDetailRow(
              label: String(localized: "Starship class"), value: details.starshipClass.displayName,
              systemImage: "airplane")
          }

          RelationshipDetailSection(
            title: String(localized: "Canonical reference"), iconName: "link"
          ) {
            RelationshipDetailLinkRow(label: String(localized: "API resource"), url: details.id)
          }

          RelationshipDetailCallout(
            text: String(
              localized:
                "Deck layouts, crew manifests, and performance metrics are planned for upcoming drops."
            )
          )
        }
      }
    }
  }
#endif
