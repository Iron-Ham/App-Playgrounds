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
          subtitle: subtitle,
          iconName: screen.iconName,
          gradient: screen.accentGradient
        ) {
          RelationshipDetailSection(
            title: String(localized: "Manufacturing & registry"), iconName: "speedometer"
          ) {
            RelationshipDetailRow(
              label: String(localized: "Primary manufacturer"), value: manufacturerDisplay,
              systemImage: "building.2")
            RelationshipDetailRow(
              label: String(localized: "Model"), value: modelDisplay,
              systemImage: "barcode.viewfinder")
            RelationshipDetailRow(
              label: String(localized: "Vehicle class"), value: details.vehicleClass.displayName,
              systemImage: "car")
            RelationshipDetailRow(
              label: String(localized: "Cost"), value: costDisplay,
              systemImage: "banknote")
            RelationshipDetailRow(
              label: String(localized: "Crew"), value: crewDisplay,
              systemImage: "person.2")
            RelationshipDetailRow(
              label: String(localized: "Passengers"), value: passengersDisplay,
              systemImage: "person.3")
          }

          RelationshipDetailSection(
            title: String(localized: "Performance"), iconName: "gauge"
          ) {
            RelationshipDetailRow(
              label: String(localized: "Length"), value: lengthDisplay,
              systemImage: "ruler")
            RelationshipDetailRow(
              label: String(localized: "Max atmosphering speed"), value: maxSpeedDisplay,
              systemImage: "wind")
            RelationshipDetailRow(
              label: String(localized: "Cargo capacity"), value: cargoDisplay,
              systemImage: "shippingbox")
            RelationshipDetailRow(
              label: String(localized: "Consumables"), value: consumablesDisplay,
              systemImage: "cup.and.saucer")
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
                "Production variants, upgrade paths, and battlefield reports are coming soon."
            )
          )
        }
      }

      private var subtitle: String? {
        var components: [String] = []
        if let manufacturer = RelationshipDetailFormatter.primaryManufacturer(details.manufacturers)
        {
          components.append(manufacturer)
        }

        let trimmedModel = details.model.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedModel.isEmpty {
          components.append(trimmedModel)
        }

        return components.isEmpty ? nil : components.joined(separator: " • ")
      }

      private var manufacturerDisplay: String {
        RelationshipDetailFormatter.manufacturers(details.manufacturers)
      }

      private var modelDisplay: String {
        RelationshipDetailFormatter.displayOrFallback(details.model)
      }

      private var costDisplay: String {
        RelationshipDetailFormatter.credits(details.costInCredits)
      }

      private var crewDisplay: String {
        RelationshipDetailFormatter.displayOrFallback(details.crew)
      }

      private var passengersDisplay: String {
        RelationshipDetailFormatter.displayOrFallback(details.passengers)
      }

      private var lengthDisplay: String {
        RelationshipDetailFormatter.measurement(details.length, unit: String(localized: "m"))
      }

      private var maxSpeedDisplay: String {
        RelationshipDetailFormatter.measurement(
          details.maxAtmospheringSpeed,
          unit: String(localized: "km/h")
        )
      }

      private var cargoDisplay: String {
        RelationshipDetailFormatter.measurement(
          details.cargoCapacity, unit: String(localized: "kg"))
      }

      private var consumablesDisplay: String {
        RelationshipDetailFormatter.displayOrFallback(details.consumables)
      }
    }
  }
#endif
