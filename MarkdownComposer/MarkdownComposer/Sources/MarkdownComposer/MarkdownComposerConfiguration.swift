import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif

#if canImport(AppKit)
  import AppKit
#endif

public struct MarkdownComposerConfiguration: Equatable {
  public var fontSize: CGFloat
  public var fontWeight: Font.Weight
  public var textColor: Color
  public var tokenColor: Color
  public var codeBackgroundColor: Color
  public var linkColor: Color
  public var quoteBarColor: Color
  public var quoteBackgroundColor: Color
  public var strikethroughColor: Color
  public var tableBorderColor: Color
  public var tableHeaderBackgroundColor: Color
  public var tableRowBackgroundColor: Color
  public var backgroundColor: Color
  public var cursorColor: Color?
  public var placeholder: String?
  public var placeholderColor: Color
  public var contentInsets: EdgeInsets
  public var isEditable: Bool
  public var isScrollEnabled: Bool
  public var autocorrection: Bool

  public init(
    fontSize: CGFloat = 17,
    fontWeight: Font.Weight = .regular,
    textColor: Color = .primary,
    tokenColor: Color = .secondary,
    codeBackgroundColor: Color = Color.primary.opacity(0.1),
    linkColor: Color = .accentColor,
    quoteBarColor: Color = .secondary,
    quoteBackgroundColor: Color = Color.secondary.opacity(0.08),
    strikethroughColor: Color = .secondary,
    tableBorderColor: Color = .secondary,
    tableHeaderBackgroundColor: Color = Color.secondary.opacity(0.12),
    tableRowBackgroundColor: Color = Color.secondary.opacity(0.05),
    backgroundColor: Color = .clear,
    cursorColor: Color? = nil,
    placeholder: String? = nil,
    placeholderColor: Color = .secondary,
    contentInsets: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
    isEditable: Bool = true,
    isScrollEnabled: Bool = true,
    autocorrection: Bool = true
  ) {
    self.fontSize = fontSize
    self.fontWeight = fontWeight
    self.textColor = textColor
    self.tokenColor = tokenColor
    self.codeBackgroundColor = codeBackgroundColor
    self.linkColor = linkColor
    self.quoteBarColor = quoteBarColor
    self.quoteBackgroundColor = quoteBackgroundColor
    self.strikethroughColor = strikethroughColor
    self.tableBorderColor = tableBorderColor
    self.tableHeaderBackgroundColor = tableHeaderBackgroundColor
    self.tableRowBackgroundColor = tableRowBackgroundColor
    self.backgroundColor = backgroundColor
    self.cursorColor = cursorColor
    self.placeholder = placeholder
    self.placeholderColor = placeholderColor
    self.contentInsets = contentInsets
    self.isEditable = isEditable
    self.isScrollEnabled = isScrollEnabled
    self.autocorrection = autocorrection
  }

  public static var `default`: MarkdownComposerConfiguration { MarkdownComposerConfiguration() }

  public static func == (lhs: MarkdownComposerConfiguration, rhs: MarkdownComposerConfiguration)
    -> Bool
  {
    lhs.fontSize == rhs.fontSize && lhs.fontWeight == rhs.fontWeight
      && lhs.textColor == rhs.textColor && lhs.tokenColor == rhs.tokenColor
      && lhs.codeBackgroundColor == rhs.codeBackgroundColor && lhs.linkColor == rhs.linkColor
      && lhs.quoteBarColor == rhs.quoteBarColor
      && lhs.quoteBackgroundColor == rhs.quoteBackgroundColor
      && lhs.strikethroughColor == rhs.strikethroughColor
      && lhs.tableBorderColor == rhs.tableBorderColor
      && lhs.tableHeaderBackgroundColor == rhs.tableHeaderBackgroundColor
      && lhs.tableRowBackgroundColor == rhs.tableRowBackgroundColor
      && lhs.backgroundColor == rhs.backgroundColor && lhs.cursorColor == rhs.cursorColor
      && lhs.placeholder == rhs.placeholder && lhs.placeholderColor == rhs.placeholderColor
      && lhs.contentInsets.isApproximatelyEqual(to: rhs.contentInsets)
      && lhs.isEditable == rhs.isEditable && lhs.isScrollEnabled == rhs.isScrollEnabled
      && lhs.autocorrection == rhs.autocorrection
  }
}

extension MarkdownComposerConfiguration {
  struct Resolved {
    var styler: DefaultMarkdownStyler
    var backgroundColor: PlatformColor
    var cursorColor: PlatformColor?
    var contentInsets: EdgeInsets
    var isEditable: Bool
    var isScrollEnabled: Bool
    var autocorrection: Bool
  }

  func resolved() -> Resolved {
    let fontPalette = MarkdownFontPalette.system(size: fontSize, weight: fontWeight.platformWeight)
    let colors = MarkdownColorPalette(
      text: PlatformColor.from(color: textColor, fallback: PlatformColor.markdownLabel),
      token: PlatformColor.from(color: tokenColor, fallback: PlatformColor.markdownToken),
      codeBackground: PlatformColor.from(
        color: codeBackgroundColor, fallback: PlatformColor.markdownCodeBackground),
      link: PlatformColor.from(color: linkColor, fallback: PlatformColor.markdownLink),
      quoteBar: PlatformColor.from(color: quoteBarColor, fallback: PlatformColor.markdownToken),
      quoteBackground: PlatformColor.from(
        color: quoteBackgroundColor, fallback: PlatformColor.markdownQuoteBackground),
      strikethrough: PlatformColor.from(
        color: strikethroughColor, fallback: PlatformColor.markdownToken),
      tableBorder: PlatformColor.from(
        color: tableBorderColor, fallback: PlatformColor.markdownTableBorder),
      tableHeaderBackground: PlatformColor.from(
        color: tableHeaderBackgroundColor, fallback: PlatformColor.markdownTableHeaderBackground),
      tableRowBackground: PlatformColor.from(
        color: tableRowBackgroundColor, fallback: PlatformColor.markdownTableRowBackground)
    )
    let styler = DefaultMarkdownStyler(fonts: fontPalette, colors: colors)
    let resolvedBackground = PlatformColor.from(color: backgroundColor, fallback: .clear)
    let resolvedCursor = cursorColor.map {
      PlatformColor.from(color: $0, fallback: resolvedBackground)
    }

    return Resolved(
      styler: styler,
      backgroundColor: resolvedBackground,
      cursorColor: resolvedCursor,
      contentInsets: contentInsets,
      isEditable: isEditable,
      isScrollEnabled: isScrollEnabled,
      autocorrection: autocorrection
    )
  }
}

extension Font.Weight {
  fileprivate var platformWeight: PlatformFontWeight {
    #if canImport(UIKit)
      switch self {
      case .ultraLight: return .ultraLight
      case .thin: return .thin
      case .light: return .light
      case .regular: return .regular
      case .medium: return .medium
      case .semibold: return .semibold
      case .bold: return .bold
      case .heavy: return .heavy
      case .black: return .black
      default: return .regular
      }
    #else
      switch self {
      case .ultraLight: return .ultraLight
      case .thin: return .thin
      case .light: return .light
      case .regular: return .regular
      case .medium: return .medium
      case .semibold: return .semibold
      case .bold: return .bold
      case .heavy: return .heavy
      case .black: return .black
      default: return .regular
      }
    #endif
  }
}

extension EdgeInsets {
  #if canImport(UIKit)
    var uiEdgeInsets: UIEdgeInsets {
      UIEdgeInsets(top: top, left: leading, bottom: bottom, right: trailing)
    }
  #endif

  #if canImport(AppKit)
    var textContainerInset: NSSize {
      NSSize(width: max(leading, trailing), height: max(top, bottom))
    }
  #endif

  func isApproximatelyEqual(to other: EdgeInsets) -> Bool {
    top == other.top && leading == other.leading && bottom == other.bottom
      && trailing == other.trailing
  }
}
