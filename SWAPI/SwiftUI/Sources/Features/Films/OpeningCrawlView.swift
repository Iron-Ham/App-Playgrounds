import Foundation
import SwiftUI

struct OpeningCrawlView: View {
  struct Content: Equatable {
    var title: String
    var episodeNumber: Int?
    var openingText: String
  }

  let content: Content

  @Environment(\.dismiss)
  private var dismiss

  @State
  private var crawlHeight: CGFloat = 1

  @State
  private var animationStartDate: Date = .now

  private let crawlColor = Color(red: 1.0, green: 0.84, blue: 0.1)

  var body: some View {
    ZStack {
      StarfieldBackground()

      GeometryReader { geometry in
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
          let containerHeight = geometry.size.height
          let effectiveDistance = crawlHeight + containerHeight * 1.6
          let pointsPerSecond: CGFloat = 32
          let duration = max(Double(effectiveDistance / pointsPerSecond), 24)
          let elapsed = timeline.date.timeIntervalSince(animationStartDate)
          let normalizedProgress =
            duration > 0
            ? CGFloat((elapsed.truncatingRemainder(dividingBy: duration)) / duration)
            : 0

          let startOffset = containerHeight * 0.6
          let endOffset = -crawlHeight - containerHeight * 0.9
          let offset = startOffset + (endOffset - startOffset) * normalizedProgress

          VStack {
            Spacer(minLength: 0)

            crawlContent
              .frame(width: min(geometry.size.width * 0.8, 520))
              .background(
                GeometryReader { proxy in
                  Color.clear.preference(
                    key: CrawlHeightPreferenceKey.self,
                    value: proxy.size.height
                  )
                }
              )
              .offset(y: offset)
              .rotation3DEffect(
                .degrees(24),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.7
              )
              .shadow(color: crawlColor.opacity(0.45), radius: 20, x: 0, y: -8)
              .accessibilityElement(children: .combine)

            Spacer(minLength: 0)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
      }
      .padding(.top, 40)
      .onPreferenceChange(CrawlHeightPreferenceKey.self) { height in
        guard height > 0 else { return }
        if abs(height - crawlHeight) > 1 {
          crawlHeight = height
          animationStartDate = .now
        }
      }

      LinearGradient(
        colors: [Color.black.opacity(0), Color.black.opacity(0.95)],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      .allowsHitTesting(false)

      VStack {
        HStack {
          Button {
            dismiss()
          } label: {
            Label("Close", systemImage: "xmark.circle.fill")
              .labelStyle(.iconOnly)
              .font(.system(size: 28, weight: .semibold))
              .foregroundStyle(Color.white.opacity(0.82))
              .padding(12)
          }
          .accessibilityLabel("Close opening crawl")

          Spacer()
        }
        Spacer()
      }
      .padding(.top, 12)
      .padding(.horizontal)
    }
    .background(Color.black)
    .ignoresSafeArea()
    .onAppear {
      animationStartDate = .now
    }
    #if os(iOS)
      .statusBarHidden(true)
    #endif
  }

  private var crawlContent: some View {
    VStack(spacing: 28) {
      Text(episodeLine)
        .font(.system(size: 30, weight: .semibold, design: .rounded))
        .tracking(8)
        .foregroundStyle(crawlColor)
        .multilineTextAlignment(.center)

      Text(content.title.uppercased())
        .font(.system(size: 48, weight: .black, design: .rounded))
        .tracking(6)
        .foregroundStyle(crawlColor)
        .multilineTextAlignment(.center)

      Text(formattedCrawl)
        .font(.system(size: 24, weight: .medium, design: .rounded))
        .lineSpacing(10)
        .multilineTextAlignment(.center)
        .foregroundStyle(crawlColor)
        .padding(.horizontal)
    }
    .frame(maxWidth: .infinity)
  }

  private var episodeLine: String {
    guard let episodeNumber = content.episodeNumber, episodeNumber > 0 else {
      return "Episode"
    }
    return "Episode \(romanNumeral(for: episodeNumber))"
  }

  private var formattedCrawl: AttributedString {
    let raw = content.openingText
      .replacingOccurrences(of: "\r", with: "")
      .components(separatedBy: "\n")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n\n")

    var attributed = AttributedString(raw)
    attributed.kern = 1.5
    return attributed
  }

  private func romanNumeral(for value: Int) -> String {
    let numerals: [(Int, String)] = [
      (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
      (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
      (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
    ]

    var number = max(1, value)
    var result = ""

    for (arabic, roman) in numerals {
      while number >= arabic {
        number -= arabic
        result.append(roman)
      }
    }

    return result
  }
}

private struct CrawlHeightPreferenceKey: PreferenceKey {
  static let defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

private struct StarfieldBackground: View {
  private struct Star: Identifiable {
    let id = UUID()
    let position: CGPoint
    let radius: CGFloat
    let baseBrightness: Double
    let twinkleSpeed: Double
    let twinklePhase: Double

    static func random() -> Star {
      Star(
        position: CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1)),
        radius: CGFloat.random(in: 0.5...2.4),
        baseBrightness: Double.random(in: 0.35...1.0),
        twinkleSpeed: Double.random(in: 0.4...1.2),
        twinklePhase: Double.random(in: 0...(2 * .pi))
      )
    }
  }

  private let stars: [Star] = (0..<220).map { _ in Star.random() }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        LinearGradient(
          colors: [
            Color.black,
            Color(red: 0.03, green: 0.03, blue: 0.08),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
          Canvas { context, size in
            let time = timeline.date.timeIntervalSinceReferenceDate

            for star in stars {
              let point = CGPoint(
                x: star.position.x * size.width,
                y: star.position.y * size.height
              )

              let twinkle = 0.4 + 0.6 * sin(time * star.twinkleSpeed + star.twinklePhase)
              let brightness = star.baseBrightness * (0.75 + 0.25 * twinkle)
              let scale = 0.96 + 0.08 * twinkle

              let clampedBrightness = max(0, min(1, brightness))

              let rect = CGRect(
                x: point.x - (star.radius * scale) / 2,
                y: point.y - (star.radius * scale) / 2,
                width: star.radius * scale,
                height: star.radius * scale
              )

              context.fill(
                Path(ellipseIn: rect),
                with: .color(Color.white.opacity(clampedBrightness))
              )
            }
          }
        }
        .blendMode(.screen)
        .opacity(0.85)
        .ignoresSafeArea()
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
  }
}
