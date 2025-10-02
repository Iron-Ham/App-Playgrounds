#if canImport(Persistence)
  import API
  import Persistence
  import SwiftUI
  #if os(macOS)
    import AppKit
  #endif

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

  // MARK: - Character Detail

  private struct CharacterDetailView: View {
    let screen: RelationshipDetailScreens.Screen
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

        RelationshipDetailSection(title: String(localized: "Canonical reference"), iconName: "link")
        {
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

  // MARK: - Planet Detail

  private struct PlanetDetailView: View {
    let screen: RelationshipDetailScreens.Screen
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

        RelationshipDetailSection(title: String(localized: "Canonical reference"), iconName: "link")
        {
          RelationshipDetailLinkRow(label: String(localized: "API resource"), url: details.id)
        }

        RelationshipDetailCallout(
          text: String(
            localized:
              "Atmospheric composition, notable residents, and trade data are on the roadmap."
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

  // MARK: - Species Detail

  private struct SpeciesDetailView: View {
    let screen: RelationshipDetailScreens.Screen
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

        RelationshipDetailSection(title: String(localized: "Canonical reference"), iconName: "link")
        {
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
      RelationshipDetailFormatter.measurement(details.averageHeight, unit: String(localized: "cm"))
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

  // MARK: - Starship Detail

  private struct StarshipDetailView: View {
    let screen: RelationshipDetailScreens.Screen
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

        RelationshipDetailSection(title: String(localized: "Canonical reference"), iconName: "link")
        {
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

  // MARK: - Vehicle Detail

  private struct VehicleDetailView: View {
    let screen: RelationshipDetailScreens.Screen
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

        RelationshipDetailSection(title: String(localized: "Canonical reference"), iconName: "link")
        {
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

  // MARK: - Shared Layout

  private struct RelationshipDetailContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let iconName: String
    let gradient: LinearGradient
    @ViewBuilder
    let content: Content

    init(
      title: String,
      subtitle: String?,
      iconName: String,
      gradient: LinearGradient,
      @ViewBuilder content: () -> Content
    ) {
      self.title = title
      self.subtitle = subtitle
      self.iconName = iconName
      self.gradient = gradient
      self.content = content()
    }

    var body: some View {
      ScrollView {
        VStack(spacing: 24) {
          hero
          content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
      }
      .background(RelationshipDetailColors.surface)
      .navigationTitle(title)
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
    }

    private var hero: some View {
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(gradient)
        .frame(height: 180)
        .overlay(alignment: .leading) {
          VStack(alignment: .leading, spacing: 12) {
            Image(systemName: iconName)
              .font(.system(size: 36, weight: .semibold))
              .symbolRenderingMode(.hierarchical)
              .foregroundStyle(Color.white.opacity(0.9))

            Text(title)
              .font(.system(size: 32, weight: .bold, design: .rounded))
              .foregroundStyle(Color.white)

            if let subtitle, !subtitle.isEmpty {
              Text(subtitle)
                .font(.headline)
                .foregroundStyle(Color.white.opacity(0.9))
            }
          }
          .padding(24)
        }
        .shadow(color: Color.black.opacity(0.16), radius: 20, x: 0, y: 10)
    }
  }

  private struct RelationshipDetailSection<Content: View>: View {
    let title: String
    let iconName: String?
    @ViewBuilder
    let content: Content

    init(title: String, iconName: String? = nil, @ViewBuilder content: () -> Content) {
      self.title = title
      self.iconName = iconName
      self.content = content()
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 12) {
          if let iconName {
            Image(systemName: iconName)
              .font(.title3)
              .symbolRenderingMode(.hierarchical)
              .foregroundStyle(.tint)
          }

          Text(title)
            .font(.headline)
        }

        VStack(alignment: .leading, spacing: 16) {
          content
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(24)
      .background(
        RoundedRectangle(cornerRadius: 28, style: .continuous)
          .fill(RelationshipDetailColors.sectionBackground)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 28, style: .continuous)
          .stroke(Color.primary.opacity(0.05), lineWidth: 1)
      )
    }
  }

  private struct RelationshipDetailNavigationRow: View {
    let title: String
    let subtitle: String?
    let iconName: String
    let destination: RelationshipDetailScreens.Screen

    var body: some View {
      NavigationLink(value: destination) {
        HStack(alignment: .center, spacing: 12) {
          Image(systemName: iconName)
            .font(.body.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)

          VStack(alignment: .leading, spacing: 4) {
            Text(title)
              .font(.body)
              .foregroundStyle(.primary)
            if let subtitle, !subtitle.isEmpty {
              Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }

          Spacer(minLength: 0)

          Image(systemName: "chevron.forward")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
        }
      }
      .buttonStyle(.plain)
    }
  }

  private struct RelationshipDetailRow: View {
    let label: String
    let value: String
    let systemImage: String?

    init(label: String, value: String, systemImage: String? = nil) {
      self.label = label
      self.value = value
      self.systemImage = systemImage
    }

    var body: some View {
      HStack(alignment: .top, spacing: 12) {
        if let systemImage {
          Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }

        VStack(alignment: .leading, spacing: 4) {
          Text(label)
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(value)
            .font(.body)
            .foregroundStyle(.primary)
        }

        Spacer(minLength: 0)
      }
    }
  }

  private struct RelationshipDetailFilmRow: View {
    let film: PersistenceService.FilmSummary

    var body: some View {
      HStack(alignment: .center, spacing: 12) {
        Image(systemName: "film")
          .font(.body.weight(.semibold))
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 4) {
          Text(film.title)
            .font(.body)
            .foregroundStyle(.primary)
            .accessibilityLabel(Text(film.title))

          Text(RelationshipDetailFormatter.filmSubtitle(for: film))
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 0)
      }
    }
  }

  private struct RelationshipDetailLinkRow: View {
    let label: String
    let url: URL

    var body: some View {
      Link(destination: url) {
        HStack(alignment: .center, spacing: 12) {
          VStack(alignment: .leading, spacing: 4) {
            Text(label)
              .font(.caption)
              .foregroundStyle(.secondary)

            Text(url.absoluteString)
              .font(.footnote)
              .foregroundStyle(.primary)
              .multilineTextAlignment(.leading)
              .lineLimit(2)
          }

          Spacer(minLength: 0)

          Image(systemName: "arrow.up.right")
            .font(.body.weight(.semibold))
            .foregroundStyle(.tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.plain)
    }
  }

  private struct RelationshipDetailCallout: View {
    let text: String

    var body: some View {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: "sparkles")
          .font(.title3)
          .foregroundStyle(.tint)

        Text(text)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(RelationshipDetailColors.calloutBackground)
      )
    }
  }

  private enum RelationshipDetailFormatter {
    private static let unknownTokens: Set<String> = ["unknown", "n/a", "none"]

    private static let measurementNumberFormatter: NumberFormatter = {
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      formatter.maximumFractionDigits = 1
      return formatter
    }()

    private static let percentageFormatter: NumberFormatter = {
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      formatter.maximumFractionDigits = 1
      return formatter
    }()

    private static let populationFormatter: NumberFormatter = {
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      formatter.maximumFractionDigits = 0
      return formatter
    }()

    private static let filmReleaseFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      return formatter
    }()

    static var unknownDisplay: String { String(localized: "Unknown") }

    static var notDocumentedDisplay: String { String(localized: "Not documented") }

    static func joinedLine(_ components: [String?]) -> String? {
      let items = components.compactMap { nonEmpty($0) }
      guard !items.isEmpty else { return nil }
      return items.joined(separator: " • ")
    }

    static func nonEmpty(_ value: String?) -> String? {
      guard let value else { return nil }
      let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }

    static func list(_ items: [String]) -> String {
      guard !items.isEmpty else { return notDocumentedDisplay }
      return ListFormatter.localizedString(byJoining: items)
    }

    static func displayOrFallback(_ raw: String) -> String {
      fallback(for: raw)
    }

    static func birthYear(_ birthYear: PersonResponse.BirthYear) -> String {
      let trimmed = birthYear.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return unknownDisplay }
      if isUnknown(trimmed) { return unknownDisplay }
      return trimmed.uppercased()
    }

    static func birthEra(_ birthYear: PersonResponse.BirthYear) -> String? {
      guard let era = birthYear.era else { return nil }
      switch era {
      case .beforeBattleOfYavin:
        return String(localized: "Before the Battle of Yavin")
      case .afterBattleOfYavin:
        return String(localized: "After the Battle of Yavin")
      }
    }

    static func relativeYear(_ birthYear: PersonResponse.BirthYear) -> String? {
      guard let value = birthYear.relativeYear else { return nil }
      guard let formatted = measurementNumberFormatter.string(from: NSNumber(value: value)) else {
        return nil
      }
      return String(localized: "\(formatted) years from Yavin")
    }

    static func measurement(_ raw: String, unit: String) -> String {
      guard let numeric = numericValue(from: raw) else {
        return fallback(for: raw)
      }
      let formatted =
        measurementNumberFormatter.string(from: NSNumber(value: numeric))
        ?? String(numeric)
      return "\(formatted) \(unit)"
    }

    static func duration(_ raw: String, unit: String) -> String {
      measurement(raw, unit: unit)
    }

    static func percentage(_ raw: String) -> String {
      guard let numeric = numericValue(from: raw) else {
        return fallback(for: raw)
      }
      let formatted =
        percentageFormatter.string(from: NSNumber(value: numeric))
        ?? String(numeric)
      return "\(formatted)%"
    }

    static func colorSummary(_ descriptors: [ColorDescriptor]) -> String {
      let names =
        descriptors
        .map { $0.displayName }
        .compactMap { nonEmpty($0) }
      guard !names.isEmpty else { return notDocumentedDisplay }
      return list(names)
    }

    static func population(_ raw: String) -> String {
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return unknownDisplay }
      if isUnknown(trimmed) { return unknownDisplay }

      let digits = trimmed.filter { $0.isNumber }
      guard !digits.isEmpty, let value = Double(digits) else { return trimmed }
      if let formatted = populationFormatter.string(from: NSNumber(value: value)) {
        return formatted
      }
      return trimmed
    }

    static func planetSummary(for planet: PersistenceService.PlanetDetails) -> String {
      let climate = planet.climates.isEmpty ? nil : list(planet.climates.map(\.displayName))
      let populationValue = population(planet.population)
      let populationLine =
        populationValue == unknownDisplay
        ? nil
        : String(localized: "Population \(populationValue)")
      return joinedLine([climate, populationLine]) ?? notDocumentedDisplay
    }

    static func speciesSummary(for species: PersistenceService.SpeciesDetails) -> String {
      joinedLine([
        titleCased(species.classification),
        nonEmpty(displayOrFallback(species.language)),
      ]) ?? notDocumentedDisplay
    }

    static func starshipSummary(for starship: PersistenceService.StarshipDetails) -> String {
      joinedLine([
        nonEmpty(starship.model),
        nonEmpty(starship.starshipClass.displayName),
      ]) ?? notDocumentedDisplay
    }

    static func vehicleSummary(for vehicle: PersistenceService.VehicleDetails) -> String {
      joinedLine([
        nonEmpty(vehicle.model),
        nonEmpty(vehicle.vehicleClass.displayName),
      ]) ?? notDocumentedDisplay
    }

    static func filmSubtitle(for film: PersistenceService.FilmSummary) -> String {
      let release = film.releaseDate.flatMap { filmReleaseFormatter.string(from: $0) }
      return joinedLine([
        String(localized: "Episode \(film.episodeId)"),
        release,
      ]) ?? String(localized: "Release date unknown")
    }

    static func titleCased(_ raw: String) -> String? {
      nonEmpty(raw)?.localizedCapitalized
    }

    private static func fallback(for raw: String) -> String {
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return unknownDisplay }
      if isUnknown(trimmed) { return unknownDisplay }
      return trimmed
    }

    private static func numericValue(from raw: String) -> Double? {
      let filtered = raw.filter { character in
        character.isNumber || character == "." || character == "-"
      }
      guard !filtered.isEmpty else { return nil }
      return Double(filtered)
    }

    private static func isUnknown(_ raw: String) -> Bool {
      unknownTokens.contains(raw.lowercased())
    }
  }

  private enum RelationshipDetailColors {
    static var surface: Color {
      #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
      #else
        Color(.systemBackground)
      #endif
    }

    static var sectionBackground: Color {
      #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
      #else
        Color(.secondarySystemBackground)
      #endif
    }

    static var calloutBackground: Color {
      #if os(macOS)
        Color(nsColor: .underPageBackgroundColor)
      #else
        Color(.tertiarySystemBackground)
      #endif
    }
  }
#endif
