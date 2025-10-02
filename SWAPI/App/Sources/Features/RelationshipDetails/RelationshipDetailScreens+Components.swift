#if canImport(Persistence)
  import API
  import Persistence
  import SwiftUI
  #if os(macOS)
    import AppKit
  #endif

  extension RelationshipDetailScreens {
    struct RelationshipDetailContainer<Content: View>: View {
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

    struct RelationshipDetailSection<Content: View>: View {
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

    struct RelationshipDetailNavigationRow: View {
      let title: String
      let subtitle: String?
      let iconName: String
      let destination: Screen

      var body: some View {
        NavigationLink {
          RelationshipDetailScreens.makeView(for: destination)
        } label: {
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

    struct RelationshipDetailRow: View {
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

    struct RelationshipDetailFilmRow: View {
      let film: PersistenceService.FilmSummary

      var body: some View {
        NavigationLink {
          RelationshipDetailScreens.makeView(for: .film(film))
        } label: {
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

            Image(systemName: "chevron.forward")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.tertiary)
              .accessibilityHidden(true)
          }
        }
        .buttonStyle(.plain)
      }
    }

    struct RelationshipDetailLinkRow: View {
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

    struct RelationshipDetailCallout: View {
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

    enum RelationshipDetailFormatter {
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

    enum RelationshipDetailColors {
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
  }
#endif
