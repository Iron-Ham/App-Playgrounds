import FluentPersistence
import SwiftUI

extension FilmDetailView {
  @ViewBuilder
  func openingCrawlExperience(for film: Film, onClose: @escaping () -> Void) -> some View {
    OpeningCrawlView(
      content: .init(
        title: film.title,
        episodeNumber: film.episodeId,
        openingText: film.openingCrawl
      ),
      onClose: onClose
    )
    .environment(\.colorScheme, .dark)
  }
}

extension FilmDetailView {
  struct OpeningCrawlCallout: View {
    @Environment(\.colorScheme)
    private var colorScheme

    var body: some View {
      ZStack {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .fill(.ultraThinMaterial)
          .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
              .strokeBorder(Color.yellow.opacity(0.45), lineWidth: 1.5)
              .blendMode(.screen)
          }
          .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.2), radius: 14, y: 10)

        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack")
              .symbolRenderingMode(.hierarchical)
              .font(.system(size: 32, weight: .semibold))
              .foregroundStyle(
                LinearGradient(
                  colors: [Color.yellow, Color.orange.opacity(0.9)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .shadow(color: Color.yellow.opacity(0.4), radius: 12, y: 6)

            VStack(alignment: .leading, spacing: 4) {
              Text("Experience the crawl")
                .font(.headline)
                .foregroundStyle(Color.primary)

              Text("Watch the animated intro exactly how it appears on screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
          }

          HStack(spacing: 8) {
            Spacer()
            Text("Launch cinematic crawl")
              .font(.footnote.weight(.semibold))
              .textCase(.uppercase)
              .tracking(1.2)
              .foregroundStyle(Color.yellow)
            Image(systemName: "chevron.right")
              .font(.footnote.weight(.bold))
              .foregroundStyle(Color.yellow.opacity(0.9))
          }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
      }
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
      .padding(.vertical, 6)
    }
  }
}
