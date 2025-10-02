import Foundation
import QuartzCore
import SwiftUI

struct OpeningCrawlView: View {
  struct Content: Equatable {
    var title: String
    var episodeNumber: Int?
    var openingText: String
  }

  let content: Content
  var onClose: (() -> Void)? = nil
  @State
  private var sentences: [String]

  @Environment(\.dismiss)
  private var dismiss

  private let crawlColor = Color(red: 1.0, green: 0.84, blue: 0.1)
  @State
  private var crawlHeight: CGFloat = 1
  @State
  private var lastContainerHeight: CGFloat = 0
  @State
  private var animationStartDate: Date = .now
  @State
  private var formattedCrawl: AttributedString

  init(content: Content, onClose: (() -> Void)? = nil) {
    self.content = content
    self.onClose = onClose
    let normalized = OpeningCrawlView.normalize(openingText: content.openingText)
    let initialSentences = OpeningCrawlView.splitIntoSentences(from: normalized)
    _sentences = State(initialValue: initialSentences)
    _formattedCrawl = State(
      initialValue: OpeningCrawlView.makeAttributedCrawl(
        sentences: initialSentences,
        paragraphSpacing: OpeningCrawlView.defaultTypography.paragraphSpacing,
        lineSpacing: OpeningCrawlView.defaultTypography.lineSpacing,
        kerning: OpeningCrawlView.defaultTypography.bodyKerning
      )
    )
  }

  private struct CrawlTypography: Equatable {
    let episodeSize: CGFloat
    let episodeTracking: CGFloat
    let titleSize: CGFloat
    let titleTracking: CGFloat
    let bodySize: CGFloat
    let bodyKerning: CGFloat
    let spacing: CGFloat
    let lineSpacing: CGFloat
    let paragraphSpacing: CGFloat
    let bodyInset: CGFloat
  }

  private static let defaultTypography = CrawlTypography(
    episodeSize: 30,
    episodeTracking: 6.0,
    titleSize: 48,
    titleTracking: 4.5,
    bodySize: 20,
    bodyKerning: 1.5,
    spacing: 24,
    lineSpacing: 6,
    paragraphSpacing: 18,
    bodyInset: 18
  )

  private struct CrawlHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
      value = max(value, nextValue())
    }
  }

  private struct ContainerHeightObserver: View {
    let height: CGFloat
    @Binding
    var lastHeight: CGFloat

    var body: some View {
      Color.clear
        .onAppear {
          lastHeight = height
        }
        .onChange(of: height) { _, newValue in
          guard abs(newValue - lastHeight) > 0.5 else { return }
          lastHeight = newValue
        }
    }
  }

  var body: some View {
    ZStack {
      StarfieldBackground()

      GeometryReader { geometry in
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
          let containerHeight = geometry.size.height

          let availableWidth = min(geometry.size.width * 0.88, geometry.size.height * 1.4)
          let typography = crawlTypography(for: geometry.size, width: availableWidth)
          let duration = animationDuration(
            crawlHeight: crawlHeight, containerHeight: containerHeight)
          let elapsed = max(0, timeline.date.timeIntervalSince(animationStartDate))
          let normalizedTime = duration > 0 ? min(elapsed / duration, 1) : 1
          let easedProgress = easeOutCubic(normalizedTime)

          let startOffset = crawlStartOffset(containerHeight: containerHeight)
          let endOffset = crawlEndOffset(crawlHeight: crawlHeight, containerHeight: containerHeight)
          let offset = startOffset + (endOffset - startOffset) * easedProgress

          VStack {
            Spacer(minLength: 0)

            crawlContent(typography: typography, formattedText: formattedCrawl)
              .frame(width: availableWidth)
              .background(
                GeometryReader { proxy in
                  Color.clear.preference(
                    key: CrawlHeightPreferenceKey.self,
                    value: proxy.size.height
                  )
                }
              )
              .scaleEffect(x: 1.08, y: 1, anchor: .bottom)
              .rotation3DEffect(
                .degrees(58),
                axis: (x: 1, y: 0, z: 0),
                anchor: .bottom,
                anchorZ: 0,
                perspective: 0.82
              )
              .offset(y: offset)
              .shadow(color: crawlColor.opacity(0.35), radius: 18, x: 0, y: -10)
              .accessibilityElement(children: .combine)

            Spacer(minLength: 0)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
          .onAppear {
            updateFormattedCrawl(for: typography)
          }
          .onChange(of: typography) { _, newValue in
            updateFormattedCrawl(for: newValue)
          }
          //          .onChange(of: content) { _, newValue in
          //            let normalized = OpeningCrawlView.normalize(openingText: newValue.openingText)
          //            let updatedSentences = OpeningCrawlView.splitIntoSentences(from: normalized)
          //            sentences = updatedSentences
          //            updateFormattedCrawl(for: typography)
          //          }
        }
        .background(
          ContainerHeightObserver(
            height: geometry.size.height,
            lastHeight: $lastContainerHeight
          )
        )
      }
      .padding(.horizontal, 32)
      .padding(.bottom, 48)
      .onPreferenceChange(CrawlHeightPreferenceKey.self) { height in
        guard height > 0 else { return }
        let delta = abs(height - crawlHeight)
        guard delta > 1 else { return }

        let now = Date()
        let containerHeight = lastContainerHeight > 0 ? lastContainerHeight : height
        let previousDuration = animationDuration(
          crawlHeight: crawlHeight, containerHeight: containerHeight)
        let elapsed = max(0, now.timeIntervalSince(animationStartDate))
        let progress = previousDuration > 0 ? min(elapsed / previousDuration, 1) : 0

        crawlHeight = height

        let newDuration = animationDuration(crawlHeight: height, containerHeight: containerHeight)
        if progress >= 1 || newDuration.isZero {
          animationStartDate = now
        } else {
          animationStartDate = now.addingTimeInterval(-progress * newDuration)
        }
      }

      LinearGradient(
        gradient: Gradient(stops: [
          .init(color: Color.black.opacity(0.95), location: 0.0),
          .init(color: Color.black.opacity(0.8), location: 0.18),
          .init(color: Color.black.opacity(0.0), location: 0.4),
          .init(color: Color.black.opacity(0.0), location: 0.65),
          .init(color: Color.black.opacity(0.92), location: 1.0),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      .allowsHitTesting(false)

      VStack {
        HStack {
          Button {
            close()
          } label: {
            Label("Close", systemImage: "xmark.circle.fill")
              .labelStyle(.iconOnly)
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundStyle(Color.white.opacity(0.82))
              .padding(12)
          }
          .accessibilityLabel("Close opening crawl")
          #if os(macOS)
            .keyboardShortcut(.cancelAction)
          #endif

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
    #if os(macOS)
      .onExitCommand {
        close()
      }
    #endif
    #if os(iOS)
      .statusBarHidden(true)
      .interactiveDismissDisabled(true)
    #endif
  }

  private func crawlTypography(for containerSize: CGSize, width: CGFloat) -> CrawlTypography {
    guard containerSize.width > 0, containerSize.height > 0, width > 0 else {
      return OpeningCrawlView.defaultTypography
    }

    func clamp(_ value: CGFloat, min lower: CGFloat, max upper: CGFloat) -> CGFloat {
      min(max(value, lower), upper)
    }

    let widthScale = clamp(width / 340, min: 0.92, max: 2.25)
    let heightScale = clamp(containerSize.height / 650, min: 0.9, max: 1.75)
    let scale = clamp((widthScale * 0.7 + heightScale * 0.3), min: 0.96, max: 2.2)

    let episodeSize = min(66, 30 * scale)
    let titleSize = min(112, 48 * scale)
    let bodySize = clamp(20 * scale * 1.05, min: 19, max: 36)
    let spacing = max(22, 26 * min(scale, 1.45))
    let lineSpacing = max(5, 7 * min(scale, 1.25))
    let paragraphSpacing = max(14, 18 * min(scale, 1.35))
    let inset = clamp(width * 0.05, min: 16, max: width * 0.22)

    return CrawlTypography(
      episodeSize: episodeSize,
      episodeTracking: 6.3 * min(scale, 1.4),
      titleSize: titleSize,
      titleTracking: 4.4 * min(scale, 1.3),
      bodySize: bodySize,
      bodyKerning: 1.7 * min(scale, 1.35),
      spacing: spacing,
      lineSpacing: lineSpacing,
      paragraphSpacing: paragraphSpacing,
      bodyInset: inset
    )
  }

  private func scrollSpeed(containerHeight: CGFloat) -> CGFloat {
    max(containerHeight * 0.05, 12)
  }

  private func crawlTravelDistance(crawlHeight: CGFloat, containerHeight: CGFloat) -> CGFloat {
    crawlHeight + containerHeight * 1.7
  }

  private func animationDuration(crawlHeight: CGFloat, containerHeight: CGFloat) -> Double {
    let distance = crawlTravelDistance(crawlHeight: crawlHeight, containerHeight: containerHeight)
    let pointsPerSecond = scrollSpeed(containerHeight: containerHeight)
    return max(Double(distance / pointsPerSecond), 55)
  }

  private func crawlStartOffset(containerHeight: CGFloat) -> CGFloat {
    containerHeight * 1.18
  }

  private func crawlEndOffset(crawlHeight: CGFloat, containerHeight: CGFloat) -> CGFloat {
    -crawlHeight - containerHeight * 0.32
  }

  private func easeOutCubic(_ progress: Double) -> CGFloat {
    let clamped = max(0, min(1, progress))
    let eased = 1 - pow(1 - clamped, 3)
    return CGFloat(eased)
  }

  private func crawlContent(
    typography: CrawlTypography, formattedText: AttributedString
  ) -> some View {
    VStack(spacing: typography.spacing) {
      Text(episodeLine)
        .font(.system(size: typography.episodeSize, weight: .semibold, design: .default))
        .tracking(typography.episodeTracking)
        .foregroundStyle(crawlColor)
        .multilineTextAlignment(.center)

      Text(content.title.uppercased())
        .font(.system(size: typography.titleSize, weight: .heavy, design: .default))
        .tracking(typography.titleTracking)
        .foregroundStyle(crawlColor)
        .multilineTextAlignment(.center)

      Text(formattedText)
        .font(.system(size: typography.bodySize, weight: .semibold, design: .default))
        .foregroundStyle(crawlColor)
        .padding(.horizontal, typography.bodyInset)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
  }

  private func updateFormattedCrawl(for typography: CrawlTypography) {
    formattedCrawl = OpeningCrawlView.makeAttributedCrawl(
      sentences: sentences,
      paragraphSpacing: typography.paragraphSpacing,
      lineSpacing: typography.lineSpacing,
      kerning: typography.bodyKerning
    )
  }

  private func close() {
    if let onClose {
      onClose()
    } else {
      dismiss()
    }
  }

  private var episodeLine: String {
    guard let episodeNumber = content.episodeNumber, episodeNumber > 0 else {
      return "Episode"
    }
    return "Episode \(romanNumeral(for: episodeNumber))"
  }

  private static func makeAttributedCrawl(
    sentences: [String],
    paragraphSpacing: CGFloat,
    lineSpacing: CGFloat,
    kerning: CGFloat
  ) -> AttributedString {
    guard !sentences.isEmpty else {
      return AttributedString()
    }
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .justified
    paragraphStyle.paragraphSpacing = paragraphSpacing
    paragraphStyle.lineSpacing = lineSpacing

    let attributes: [NSAttributedString.Key: Any] = [
      .kern: kerning,
      .paragraphStyle: paragraphStyle,
    ]
    let attributedBuilder = NSMutableAttributedString()

    for (index, sentence) in sentences.enumerated() {
      attributedBuilder.append(NSAttributedString(string: sentence, attributes: attributes))

      if index < sentences.count - 1 {
        attributedBuilder.append(NSAttributedString(string: "\n\n", attributes: attributes))
      }
    }

    return AttributedString(attributedBuilder)
  }

  private static func normalize(openingText: String) -> String {
    openingText
      .replacingOccurrences(of: "\r", with: " ")
      .replacingOccurrences(of: "\n", with: " ")
      .components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .joined(separator: " ")
  }

  private static func splitIntoSentences(from text: String) -> [String] {
    guard !text.isEmpty else { return [] }

    let pattern = "(?<=[.!?])\\s+(?=[A-Z0-9])"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
      return [text]
    }

    let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
    var sentences: [String] = []
    var currentIndex = text.startIndex

    regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
      guard let match = match, let matchRange = Range(match.range, in: text) else { return }
      let sentenceRange = currentIndex..<matchRange.lowerBound
      let sentence = text[sentenceRange].trimmingCharacters(in: .whitespacesAndNewlines)
      if !sentence.isEmpty {
        sentences.append(sentence)
      }
      currentIndex = matchRange.upperBound
    }

    let tail = text[currentIndex...].trimmingCharacters(in: .whitespacesAndNewlines)
    if !tail.isEmpty {
      sentences.append(tail)
    }

    return sentences
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

  @State
  private var stars: [Star] = StarfieldBackground.generateStars()

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

  private static func generateStars(count: Int = 220) -> [Star] {
    (0..<count).map { _ in Star.random() }
  }
}
