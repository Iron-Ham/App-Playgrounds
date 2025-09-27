import Foundation
import FoundationModels
import Playgrounds
import SwiftUI

/// Generates `SwiftUI.Color` values from descriptive natural language names using Foundation Models guided generation.
/// Assumes the `FoundationModels` framework is present and available: Users must have a device that supports it, and must have it enabled on that device.
public enum ColorGenerator {

  public struct RGBA: Sendable, Equatable {
    public let r: Double
    public let g: Double
    public let b: Double
    public let a: Double
    public init(r: Double, g: Double, b: Double, a: Double = 1) {
      func clamp(_ v: Double) -> Double { min(1, max(0, v)) }
      self.r = clamp(r)
      self.g = clamp(g)
      self.b = clamp(b)
      self.a = clamp(a)
    }
  }

  @Generable(description: "RGB color 0-1 components for a named color")
  struct GeneratedColor {
    @Guide(description: "Red 0-1", .range(0...1)) var red: Double
    @Guide(description: "Green 0-1", .range(0...1)) var green: Double
    @Guide(description: "Blue 0-1", .range(0...1)) var blue: Double
  }

  /// Generate a `Color` for a descriptive name.
  /// - Parameter name: Human readable color description (e.g. "Forest Green").
  /// - Returns: A model-generated color.
  public static func color(named name: String) async throws -> Color {
    let rgba = try await rgba(named: name)
    return Color(red: rgba.r, green: rgba.g, blue: rgba.b, opacity: rgba.a)
  }

  /// Generate a `UIColor` for a descriptive name.
  /// - Parameter name: Human readable color description (e.g. "Electric Yellow").
  /// - Returns: A model-generated color.
  public static func uiColor(named name: String) async throws -> UIColor {
    let rgba = try await rgba(named: name)
    return UIColor(red: rgba.r, green: rgba.g, blue: rgba.b, alpha: rgba.a)
  }

  /// Generate RGBA components for a descriptive name.
  /// - Parameter name: Color name phrase.
  /// - Returns: Generated RGBA values.
  public static func rgba(named name: String) async throws -> RGBA {
    let generated = try await generate(name: name)
    return RGBA(r: generated.red, g: generated.green, b: generated.blue, a: 1)
  }

  static func generate(name: String) async throws -> GeneratedColor {
    let session = LanguageModelSession(
      model: SystemLanguageModel(useCase: .general, guardrails: .permissiveContentTransformations)
    )
    let prompt = "Return only RGB components for color name: \(name)"
    return try await session.respond(
      to: prompt,
      generating: GeneratedColor.self
    ).content
  }
}

#Preview("Color") {
  @Previewable @State var foregroundColor: Color = .primary
  Text("Hello")
    .foregroundStyle(foregroundColor)
    .task {
      do {
        let color = try await ColorGenerator.color(named: "Sky Blue")
        foregroundColor = color
      } catch {
        print(error)
      }
    }
}
