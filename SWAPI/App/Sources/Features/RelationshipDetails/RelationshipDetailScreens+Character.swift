#if canImport(Persistence)
  import API
  import Persistence
  import SwiftUI

  extension RelationshipDetailScreens {
    struct CharacterDetailView: View {
      let screen: Screen
      let details: PersistenceService.CharacterDetails

      var body: some View {
        RelationshipDetailContainer(
          title: details.name,
          subtitle: subtitle,
          iconName: screen.iconName,
          gradient: screen.accentGradient
        ) {
          RelationshipDetailSection(
            title: String(localized: "Vitals"), iconName: "person.text.rectangle"
          ) {
            RelationshipDetailRow(
              label: String(localized: "Gender"), value: genderDisplay,
              systemImage: "figure.arms.open")
            RelationshipDetailRow(
              label: String(localized: "Birth year"), value: birthYearDisplay,
              systemImage: "calendar")
            if let eraDescription {
              RelationshipDetailRow(
                label: String(localized: "Galactic era"), value: eraDescription,
                systemImage: "sparkles")
            }
            if let relativeYearDescription {
              RelationshipDetailRow(
                label: String(localized: "Relative year"), value: relativeYearDescription,
                systemImage: "timeline.selection")
            }
            RelationshipDetailRow(
              label: String(localized: "Height"), value: heightDisplay, systemImage: "ruler")
            RelationshipDetailRow(
              label: String(localized: "Mass"), value: massDisplay, systemImage: "scalemass")
          }

          RelationshipDetailSection(
            title: String(localized: "Appearance"), iconName: "paintpalette"
          ) {
            RelationshipDetailRow(
              label: String(localized: "Hair"), value: hairColorDisplay,
              systemImage: "comb")
            RelationshipDetailRow(
              label: String(localized: "Skin"), value: skinColorDisplay,
              systemImage: "paintbrush")
            RelationshipDetailRow(
              label: String(localized: "Eyes"), value: eyeColorDisplay,
              systemImage: "eye")
          }

          RelationshipDetailSection(
            title: String(localized: "Origins & Affiliations"), iconName: "globe.europe.africa"
          ) {
            if let homeworld = details.homeworld {
              RelationshipDetailNavigationRow(
                title: homeworld.name,
                subtitle: RelationshipDetailFormatter.planetSummary(for: homeworld),
                iconName: "globe.europe.africa",
                destination: .planet(homeworld)
              )
            } else {
              RelationshipDetailRow(
                label: String(localized: "Homeworld"),
                value: RelationshipDetailFormatter.unknownDisplay,
                systemImage: "globe.europe.africa"
              )
            }

            if details.species.isEmpty {
              RelationshipDetailRow(
                label: String(localized: "Species"),
                value: RelationshipDetailFormatter.notDocumentedDisplay,
                systemImage: "leaf"
              )
            } else {
              ForEach(details.species) { species in
                RelationshipDetailNavigationRow(
                  title: species.name,
                  subtitle: RelationshipDetailFormatter.speciesSummary(for: species),
                  iconName: "leaf",
                  destination: .species(species)
                )
              }
            }
          }

          if !details.starships.isEmpty || !details.vehicles.isEmpty {
            RelationshipDetailSection(
              title: String(localized: "Piloted craft"), iconName: "airplane"
            ) {
              if details.starships.isEmpty {
                RelationshipDetailRow(
                  label: String(localized: "Starships"),
                  value: RelationshipDetailFormatter.notDocumentedDisplay,
                  systemImage: "airplane"
                )
              } else {
                ForEach(details.starships) { starship in
                  RelationshipDetailNavigationRow(
                    title: starship.name,
                    subtitle: RelationshipDetailFormatter.starshipSummary(for: starship),
                    iconName: "airplane",
                    destination: .starship(starship)
                  )
                }
              }

              if details.vehicles.isEmpty {
                RelationshipDetailRow(
                  label: String(localized: "Vehicles"),
                  value: RelationshipDetailFormatter.notDocumentedDisplay,
                  systemImage: "car"
                )
              } else {
                ForEach(details.vehicles) { vehicle in
                  RelationshipDetailNavigationRow(
                    title: vehicle.name,
                    subtitle: RelationshipDetailFormatter.vehicleSummary(for: vehicle),
                    iconName: "car",
                    destination: .vehicle(vehicle)
                  )
                }
              }
            }
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
                "Affiliations, loadouts, and behind-the-scenes lore are in active production."
            )
          )
        }
      }

      private var subtitle: String? {
        RelationshipDetailFormatter.joinedLine([
          RelationshipDetailFormatter.nonEmpty(details.gender.displayName),
          birthYearSubtitle,
        ])
      }

      private var genderDisplay: String {
        RelationshipDetailFormatter.displayOrFallback(details.gender.displayName)
      }

      private var birthYearDisplay: String {
        RelationshipDetailFormatter.birthYear(details.birthYear)
      }

      private var birthYearSubtitle: String? {
        let raw = details.birthYear.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        if raw.lowercased() == "unknown" { return nil }
        return raw.uppercased()
      }

      private var eraDescription: String? {
        RelationshipDetailFormatter.birthEra(details.birthYear)
      }

      private var relativeYearDescription: String? {
        RelationshipDetailFormatter.relativeYear(details.birthYear)
      }

      private var heightDisplay: String {
        RelationshipDetailFormatter.measurement(details.height, unit: String(localized: "cm"))
      }

      private var massDisplay: String {
        RelationshipDetailFormatter.measurement(details.mass, unit: String(localized: "kg"))
      }

      private var hairColorDisplay: String {
        RelationshipDetailFormatter.colorSummary(details.hairColors)
      }

      private var skinColorDisplay: String {
        RelationshipDetailFormatter.colorSummary(details.skinColors)
      }

      private var eyeColorDisplay: String {
        RelationshipDetailFormatter.colorSummary(details.eyeColors)
      }
    }
  }
#endif
