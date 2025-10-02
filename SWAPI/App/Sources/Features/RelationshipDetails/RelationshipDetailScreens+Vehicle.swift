#if canImport(Persistence)
  import API
  import Persistence
  import SwiftUI

  extension RelationshipDetailScreens {
    struct VehicleDetailView: View {
      let screen: Screen
      let details: PersistenceService.VehicleDetails

      var body: some View {
        RelationshipDetailContainer(
          title: details.name,
          subtitle: details.model,
          iconName: screen.iconName,
          gradient: screen.accentGradient
        ) {
          RelationshipDetailSection(
            title: String(localized: "Specifications"), iconName: "speedometer"
          ) {
            RelationshipDetailRow(
              label: String(localized: "Model"), value: details.model, systemImage: "ruler")
            RelationshipDetailRow(
              label: String(localized: "Vehicle class"), value: details.vehicleClass.displayName,
              systemImage: "car")
          }

          RelationshipDetailSection(
            title: String(localized: "Canonical reference"), iconName: "link"
          ) {
            RelationshipDetailLinkRow(label: String(localized: "API resource"), url: details.id)
          }

          RelationshipDetailCallout(
            text: String(
              localized:
                "Performance envelopes, crew complements, and manufacturer histories are on the roadmap."
            )
          )
        }
      }
    }
  }
#endif
