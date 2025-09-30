// swiftlint:disable:this file_name
// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
// Generated using tuist — https://github.com/tuist/tuist

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
public enum SWAPISwiftUIStrings: Sendable {
  /// Plural format key: "%#@value@"
  public static func charactersCount(_ p1: Int) -> String {
    return SWAPISwiftUIStrings.tr("FilmDetail", "characters-count",p1)
  }
  /// Plural format key: "%#@value@"
  public static func planetsCount(_ p1: Int) -> String {
    return SWAPISwiftUIStrings.tr("FilmDetail", "planets-count",p1)
  }
  /// Plural format key: "%#@value@"
  public static func speciesCount(_ p1: Int) -> String {
    return SWAPISwiftUIStrings.tr("FilmDetail", "species-count",p1)
  }
  /// Plural format key: "%#@value@"
  public static func starshipsCount(_ p1: Int) -> String {
    return SWAPISwiftUIStrings.tr("FilmDetail", "starships-count",p1)
  }
  /// Plural format key: "%#@value@"
  public static func vehiclesCount(_ p1: Int) -> String {
    return SWAPISwiftUIStrings.tr("FilmDetail", "vehicles-count",p1)
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension SWAPISwiftUIStrings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = Bundle.module.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
// swiftformat:enable all
// swiftlint:enable all
