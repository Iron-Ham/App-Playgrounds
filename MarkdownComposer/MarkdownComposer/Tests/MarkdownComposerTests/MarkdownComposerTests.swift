import Foundation
import Testing

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#endif

@testable import MarkdownComposer

@Test func defaultStylerPreservesMarkdownTokens() throws {
  let configuration = MarkdownComposerConfiguration()
  let resolved = configuration.resolved()
  let original = "**Bold** _italic_ `code`"
  let storage = NSTextStorage(string: original)

  resolved.styler.apply(to: storage)

  #expect(storage.string == original)
}

@Test func defaultStylerAppliesExpectedTraits() throws {
  let configuration = MarkdownComposerConfiguration()
  let resolved = configuration.resolved()
  let storage = NSTextStorage(string: "**Bold** _italic_ `code`")
  resolved.styler.apply(to: storage)

  let string = storage.string as NSString

  let boldRange = string.range(of: "Bold")
  let italicRange = string.range(of: "italic")
  let codeRange = string.range(of: "code")
  let openingBoldTokenRange = NSRange(location: string.range(of: "**Bold**").location, length: 2)

  let boldFont = storage.attribute(.font, at: boldRange.location, effectiveRange: nil) as AnyObject?
  let italicFont = storage.attribute(.font, at: italicRange.location, effectiveRange: nil) as AnyObject?
  let codeFont = storage.attribute(.font, at: codeRange.location, effectiveRange: nil) as AnyObject?
  let tokenColor = storage.attribute(.foregroundColor, at: openingBoldTokenRange.location, effectiveRange: nil) as AnyObject?

  #expect(boldFont === resolved.styler.fonts.bold)
  #expect(italicFont === resolved.styler.fonts.italic)
  #expect(codeFont === resolved.styler.fonts.monospace)

  #if canImport(UIKit)
  if let color = tokenColor as? UIColor {
    #expect(color.isEqual(resolved.styler.colors.token))
  } else {
    Issue.record("Token color should be a UIColor instance")
  }
  #elseif canImport(AppKit)
  if let color = tokenColor as? NSColor {
    #expect(color.isEqual(resolved.styler.colors.token))
  } else {
    Issue.record("Token color should be an NSColor instance")
  }
  #endif

}

@Test func defaultStylerStylesLists() throws {
  let configuration = MarkdownComposerConfiguration()
  let resolved = configuration.resolved()
  let storage = NSTextStorage(string: "- Bullet item\n1. Numbered item")

  resolved.styler.apply(to: storage)

  let string = storage.string as NSString
  let bulletRange = string.range(of: "-")
  let orderedRange = string.range(of: "1.")

  let bulletColor = storage.attribute(.foregroundColor, at: bulletRange.location, effectiveRange: nil)
  let orderedColor = storage.attribute(.foregroundColor, at: orderedRange.location, effectiveRange: nil)

  #expect(colorsEqual(bulletColor, resolved.styler.colors.token))
  #expect(colorsEqual(orderedColor, resolved.styler.colors.token))

  if let paragraphStyle = storage.attribute(.paragraphStyle, at: bulletRange.location, effectiveRange: nil) as? NSParagraphStyle {
    #expect(paragraphStyle.headIndent > 0)
  } else {
    Issue.record("List lines should have a paragraph style with indentation")
  }
}

@Test func defaultStylerStylesBlockquotes() throws {
  let configuration = MarkdownComposerConfiguration()
  let resolved = configuration.resolved()
  let storage = NSTextStorage(string: "> Blockquote line")

  resolved.styler.apply(to: storage)

  let markerRange = NSRange(location: 0, length: 1)

  let markerColor = storage.attribute(.foregroundColor, at: markerRange.location, effectiveRange: nil)
  let backgroundColor = storage.attribute(.backgroundColor, at: markerRange.location, effectiveRange: nil)

  #expect(colorsEqual(markerColor, resolved.styler.colors.quoteBar))
  #expect(colorsEqual(backgroundColor, resolved.styler.colors.quoteBackground))
}

@Test func defaultStylerStylesLinks() throws {
  let configuration = MarkdownComposerConfiguration()
  let resolved = configuration.resolved()
  let storage = NSTextStorage(string: "[Link](https://example.com)")

  resolved.styler.apply(to: storage)

  let string = storage.string as NSString
  let textRange = string.range(of: "Link")
  let urlRange = string.range(of: "https://example.com")

  let linkColor = storage.attribute(.foregroundColor, at: textRange.location, effectiveRange: nil)
  let underlineStyle = storage.attribute(.underlineStyle, at: textRange.location, effectiveRange: nil) as? Int
  let urlFont = storage.attribute(.font, at: urlRange.location, effectiveRange: nil) as AnyObject?

  #expect(colorsEqual(linkColor, resolved.styler.colors.link))
  #expect(underlineStyle == NSUnderlineStyle.single.rawValue)
  #expect(urlFont === resolved.styler.fonts.monospace)
}

@Test func defaultStylerAppliesStrikethroughAttributes() throws {
  let configuration = MarkdownComposerConfiguration()
  let resolved = configuration.resolved()
  let storage = NSTextStorage(string: "~~gone~~")

  resolved.styler.apply(to: storage)

  let string = storage.string as NSString
  let contentRange = string.range(of: "gone")

  let style = storage.attribute(.strikethroughStyle, at: contentRange.location, effectiveRange: nil) as? Int
  let color = storage.attribute(.strikethroughColor, at: contentRange.location, effectiveRange: nil)

  #expect(style == NSUnderlineStyle.single.rawValue)
  #expect(colorsEqual(color, resolved.styler.colors.strikethrough))
}

@Test func defaultStylerStylesTables() throws {
  let configuration = MarkdownComposerConfiguration()
  let resolved = configuration.resolved()
  let storage = NSTextStorage(string: """
  | Name | Score |
  | :--- | ---: |
  | Sam  |  42  |
  """)

  resolved.styler.apply(to: storage)

  let string = storage.string as NSString
  let pipeRange = string.range(of: "|")
  let headerTextRange = string.range(of: "Name")
  let bodyTextRange = string.range(of: "Sam")
  let separatorDashRange = string.range(of: "-")

  let pipeColor = storage.attribute(.foregroundColor, at: pipeRange.location, effectiveRange: nil)
  let headerBackground = storage.attribute(.backgroundColor, at: headerTextRange.location, effectiveRange: nil)
  let bodyBackground = storage.attribute(.backgroundColor, at: bodyTextRange.location, effectiveRange: nil)
  let headerFont = storage.attribute(.font, at: headerTextRange.location, effectiveRange: nil) as AnyObject?
  let separatorColor = storage.attribute(.foregroundColor, at: separatorDashRange.location, effectiveRange: nil)

  #expect(colorsEqual(pipeColor, resolved.styler.colors.tableBorder))
  #expect(colorsEqual(headerBackground, resolved.styler.colors.tableHeaderBackground))
  #expect(colorsEqual(bodyBackground, resolved.styler.colors.tableRowBackground))
  #expect(headerFont === resolved.styler.fonts.bold)
  #expect(colorsEqual(separatorColor, resolved.styler.colors.tableBorder))
}

func colorsEqual(_ value: Any?, _ expected: PlatformColor) -> Bool {
#if canImport(UIKit)
  guard let color = value as? UIColor else { return false }
  return color.isEqual(expected)
#else
  guard let color = value as? NSColor else { return false }
  let lhs = color.usingColorSpace(.deviceRGB) ?? color
  let rhs = expected.usingColorSpace(.deviceRGB) ?? expected
  return lhs.isEqual(rhs)
#endif
}
