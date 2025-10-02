#if canImport(FluentPersistence)
  import API
  import FluentPersistence
  import SwiftUI
  #if os(macOS)
    import AppKit
  #endif

  /// Shared namespace for the dedicated relationship detail experiences presented from a film.
  enum RelationshipDetailScreens {
    enum Screen: Hashable {
      case character(FluentPersistenceService.CharacterDetails)
      case planet(FluentPersistenceService.PlanetDetails)
      case species(FluentPersistenceService.SpeciesDetails)
      case starship(FluentPersistenceService.StarshipDetails)
      case vehicle(FluentPersistenceService.VehicleDetails)

      init(entity: FluentPersistenceService.RelationshipEntity) {
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

      var relationship: FluentPersistenceService.Relationship {
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
    let details: FluentPersistenceService.CharacterDetails

    var body: some View {
      RelationshipDetailContainer(
        title: details.name,
        subtitle: subtitle,
        iconName: screen.iconName,
        gradient: screen.accentGradient
      ) {
        RelationshipDetailSection(
          title: String(localized: "Profile"), iconName: "person.crop.circle"
        ) {
          RelationshipDetailRow(
            label: String(localized: "Gender"), value: genderDisplay,
            systemImage: "figure.arms.open")
          RelationshipDetailRow(
            label: String(localized: "Birth year"), value: birthYearDisplay, systemImage: "calendar"
          )
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
        }

        RelationshipDetailSection(title: String(localized: "Canonical reference"), iconName: "link")
        {
          RelationshipDetailLinkRow(label: String(localized: "API resource"), url: details.id)
        }

        RelationshipDetailCallout(
          text: String(
            localized:
              "More character lore, affiliations, and equipment will arrive in future updates."
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
  }

  // MARK: - Planet Detail

  private struct PlanetDetailView: View {
    let screen: RelationshipDetailScreens.Screen
    let details: FluentPersistenceService.PlanetDetails

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
            label: String(localized: "Population"), value: populationSummary,
            systemImage: "person.3")
        }

        RelationshipDetailSection(title: String(localized: "Canonical reference"), iconName: "link")
        {
          RelationshipDetailLinkRow(label: String(localized: "API resource"), url: details.id)
        }

        RelationshipDetailCallout(
          text: String(
            localized:
              "Future releases will chart terrains, gravity, and resident bios for each world."
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
        return String(localized: "Not documented")
      }
      return RelationshipDetailFormatter.list(details.climates.map(\.displayName))
    }

    private var populationSummary: String {
      RelationshipDetailFormatter.population(details.population)
    }
  }

  // MARK: - Species Detail

  private struct SpeciesDetailView: View {
    let screen: RelationshipDetailScreens.Screen
    let details: FluentPersistenceService.SpeciesDetails

    var body: some View {
      RelationshipDetailContainer(
        title: details.name,
        subtitle: subtitle,
        iconName: screen.iconName,
        gradient: screen.accentGradient
      ) {
        RelationshipDetailSection(title: String(localized: "Culture"), iconName: "leaf") {
          RelationshipDetailRow(
            label: String(localized: "Classification"),
            value: RelationshipDetailFormatter.displayOrFallback(details.classification),
            systemImage: "square.grid.2x2")
          RelationshipDetailRow(
            label: String(localized: "Language"),
            value: RelationshipDetailFormatter.displayOrFallback(details.language),
            systemImage: "character.book.closed")
        }

        RelationshipDetailSection(title: String(localized: "Canonical reference"), iconName: "link")
        {
          RelationshipDetailLinkRow(label: String(localized: "API resource"), url: details.id)
        }

        RelationshipDetailCallout(
          text: String(
            localized:
              "Expect lifecycle traits, homeworld spotlights, and cultural highlights soon."
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
  }

  // MARK: - Starship Detail

  private struct StarshipDetailView: View {
    let screen: RelationshipDetailScreens.Screen
    let details: FluentPersistenceService.StarshipDetails

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
    let details: FluentPersistenceService.VehicleDetails

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
      guard !items.isEmpty else { return String(localized: "Not documented") }
      return ListFormatter.localizedString(byJoining: items)
    }

    static func displayOrFallback(_ raw: String) -> String {
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return String(localized: "Unknown") }
      let lowered = trimmed.lowercased()
      if ["unknown", "n/a", "none"].contains(lowered) {
        return String(localized: "Unknown")
      }
      return trimmed
    }

    static func birthYear(_ birthYear: PersonResponse.BirthYear) -> String {
      let trimmed = birthYear.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return String(localized: "Unknown") }
      if trimmed.lowercased() == "unknown" {
        return String(localized: "Unknown")
      }
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
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      formatter.maximumFractionDigits = 1
      guard let formatted = formatter.string(from: NSNumber(value: value)) else {
        return nil
      }
      return String(localized: "\(formatted) years from Yavin")
    }

    static func population(_ raw: String) -> String {
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return String(localized: "Unknown") }
      let lowered = trimmed.lowercased()
      if ["unknown", "n/a", "none"].contains(lowered) {
        return String(localized: "Unknown")
      }

      let digits = trimmed.filter { $0.isNumber }
      guard !digits.isEmpty, let value = Double(digits) else { return trimmed }
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      formatter.maximumFractionDigits = 0
      if let formatted = formatter.string(from: NSNumber(value: value)) {
        return formatted
      }
      return trimmed
    }

    static func titleCased(_ raw: String) -> String? {
      nonEmpty(raw)?.localizedCapitalized
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
