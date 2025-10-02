#if canImport(Persistence)
  import Foundation
  import Persistence
  import SwiftUI

  extension RelationshipDetailScreens {
    struct FilmSummaryDetailView: View {
      let screen: Screen
      let film: PersistenceService.FilmSummary

      var body: some View {
        RelationshipDetailContainer(
          title: film.title,
          subtitle: subtitle,
          iconName: screen.iconName,
          gradient: screen.accentGradient
        ) {
          RelationshipDetailSection(
            title: String(localized: "Saga placement"),
            iconName: "sparkles"
          ) {
            RelationshipDetailRow(
              label: String(localized: "Episode"),
              value: "Episode \(film.episodeId)",
              systemImage: "rectangle.3.offgrid"
            )
            RelationshipDetailRow(
              label: String(localized: "Featured timeline"),
              value: timelineSummary,
              systemImage: "clock"
            )
          }

          RelationshipDetailSection(
            title: String(localized: "Release"),
            iconName: "calendar"
          ) {
            RelationshipDetailRow(
              label: String(localized: "Premiere"),
              value: releaseDateDisplay,
              systemImage: "calendar"
            )
          }

          RelationshipDetailSection(
            title: String(localized: "Canonical reference"),
            iconName: "link"
          ) {
            RelationshipDetailLinkRow(
              label: String(localized: "API resource"),
              url: film.id
            )
          }

          RelationshipDetailCallout(
            text: String(
              localized:
                "Full film dossiers—including cast, plot arcs, and continuity notes—are coming soon."
            )
          )
        }
      }

      private var subtitle: String? {
        RelationshipDetailFormatter.filmSubtitle(for: film)
      }

      private var timelineSummary: String {
        String(localized: "Episode \(film.episodeId)")
      }

      private var releaseDateDisplay: String {
        guard let releaseDate = film.releaseDate else {
          return String(localized: "Release date unknown")
        }
        return Self.releaseFormatter.string(from: releaseDate)
      }
    }
  }

  private extension RelationshipDetailScreens.FilmSummaryDetailView {
    static let releaseFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateStyle = .long
      return formatter
    }()
  }
#endif
