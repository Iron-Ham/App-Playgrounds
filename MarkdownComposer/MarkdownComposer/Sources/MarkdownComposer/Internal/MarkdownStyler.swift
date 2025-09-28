import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformFont = UIFont
typealias PlatformFontWeight = UIFont.Weight
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformFont = NSFont
typealias PlatformFontWeight = NSFont.Weight
typealias PlatformColor = NSColor
#endif

protocol MarkdownStyler {
  func apply(to textStorage: MarkdownTextStorage)
}

struct DefaultMarkdownStyler: MarkdownStyler {
  var fonts: MarkdownFontPalette
  var colors: MarkdownColorPalette

  init(fonts: MarkdownFontPalette, colors: MarkdownColorPalette) {
    self.fonts = fonts
    self.colors = colors
  }

  func apply(to textStorage: MarkdownTextStorage) {
    resetAttributes(of: textStorage)
    applyBlockquotes(using: blockquoteRegex, to: textStorage)
    applyTables(to: textStorage)
    applyUnorderedList(using: unorderedListRegex, to: textStorage)
    applyOrderedList(using: orderedListRegex, to: textStorage)
    applyStrong(using: strongAsteriskRegex, tokenLength: 2, to: textStorage)
    applyStrong(using: strongUnderscoreRegex, tokenLength: 2, to: textStorage)
    applyItalic(using: italicAsteriskRegex, tokenLength: 1, to: textStorage)
    applyItalic(using: italicUnderscoreRegex, tokenLength: 1, to: textStorage)
    applyStrikethrough(using: strikethroughRegex, tokenLength: 2, to: textStorage)
    applyLinks(using: linkRegex, to: textStorage)
    applyInlineCode(using: inlineCodeRegex, tokenLength: 1, to: textStorage)
  }

  private func resetAttributes(of textStorage: MarkdownTextStorage) {
    guard textStorage.length > 0 else { return }
    textStorage.setAttributes([
      .font: fonts.body,
      .foregroundColor: colors.text
    ], range: NSRange(location: 0, length: textStorage.length))
  }

  private func applyStrong(using regex: NSRegularExpression, tokenLength: Int, to storage: MarkdownTextStorage) {
    storage.enumerateMatches(for: regex, contentGroup: 1, leadingTokenLength: tokenLength, trailingTokenLength: tokenLength) { match in
      storage.addAttributes([
        .foregroundColor: colors.token
      ], range: match.leadingTokenRange)
      storage.addAttributes([
        .foregroundColor: colors.token
      ], range: match.trailingTokenRange)
      storage.addAttributes([
        .font: fonts.bold,
      ], range: match.contentRange)
    }
  }

  private func applyItalic(using regex: NSRegularExpression, tokenLength: Int, to storage: MarkdownTextStorage) {
    storage.enumerateMatches(for: regex, contentGroup: 1, leadingTokenLength: tokenLength, trailingTokenLength: tokenLength) { match in
      storage.addAttributes([
        .foregroundColor: colors.token
      ], range: match.leadingTokenRange)
      storage.addAttributes([
        .foregroundColor: colors.token
      ], range: match.trailingTokenRange)
      storage.addAttributes([
        .font: fonts.italic,
      ], range: match.contentRange)
    }
  }

  private func applyInlineCode(using regex: NSRegularExpression, tokenLength: Int, to storage: MarkdownTextStorage) {
    storage.enumerateMatches(for: regex, contentGroup: 1, leadingTokenLength: tokenLength, trailingTokenLength: tokenLength) { match in
      storage.addAttributes([
        .foregroundColor: colors.token,
        .font: fonts.monospace
      ], range: match.leadingTokenRange)
      storage.addAttributes([
        .foregroundColor: colors.token,
        .font: fonts.monospace
      ], range: match.trailingTokenRange)
      storage.addAttributes([
        .foregroundColor: colors.text,
        .font: fonts.monospace,
        .backgroundColor: colors.codeBackground
      ], range: match.contentRange)
    }
  }

  private func applyStrikethrough(using regex: NSRegularExpression, tokenLength: Int, to storage: MarkdownTextStorage) {
    storage.enumerateMatches(for: regex, contentGroup: 1, leadingTokenLength: tokenLength, trailingTokenLength: tokenLength) { match in
      storage.addAttributes([
        .foregroundColor: colors.token
      ], range: match.leadingTokenRange)
      storage.addAttributes([
        .foregroundColor: colors.token
      ], range: match.trailingTokenRange)
      storage.addAttributes([
        .strikethroughStyle: NSUnderlineStyle.single.rawValue,
        .strikethroughColor: colors.strikethrough
      ], range: match.contentRange)
    }
  }

  private func applyLinks(using regex: NSRegularExpression, to storage: MarkdownTextStorage) {
    let nsString = storage.string as NSString
    let matches = regex.matches(in: storage.string, range: NSRange(location: 0, length: nsString.length))
    for match in matches {
      guard match.numberOfRanges >= 3 else { continue }
      let fullRange = match.range(at: 0)
      let textRange = match.range(at: 1)
      let urlRange = match.range(at: 2)

      let leftBracketRange = NSRange(location: fullRange.location, length: 1)
      let rightBracketRange = NSRange(location: textRange.location + textRange.length, length: 1)
      let leftParenthesisRange = NSRange(location: rightBracketRange.location + 1, length: 1)
      let rightParenthesisRange = NSRange(location: fullRange.location + fullRange.length - 1, length: 1)

      for markerRange in [leftBracketRange, rightBracketRange, leftParenthesisRange, rightParenthesisRange] where markerRange.isValid(within: nsString.length) {
        storage.addAttributes([
          .foregroundColor: colors.token
        ], range: markerRange)
      }

      if textRange.isValid(within: nsString.length) {
        storage.addAttributes([
          .foregroundColor: colors.link,
          .underlineStyle: NSUnderlineStyle.single.rawValue,
          .underlineColor: colors.link
        ], range: textRange)
      }

      if urlRange.isValid(within: nsString.length) {
        storage.addAttributes([
          .foregroundColor: colors.token,
          .font: fonts.monospace
        ], range: urlRange)
      }
    }
  }

  private func applyUnorderedList(using regex: NSRegularExpression, to storage: MarkdownTextStorage) {
    applyList(using: regex, markerGroup: 2, contentGroup: 3, to: storage)
  }

  private func applyOrderedList(using regex: NSRegularExpression, to storage: MarkdownTextStorage) {
    applyList(using: regex, markerGroup: 2, contentGroup: 3, to: storage)
  }

  private func applyList(using regex: NSRegularExpression, markerGroup: Int, contentGroup: Int, to storage: MarkdownTextStorage) {
    let nsString = storage.string as NSString
    let matches = regex.matches(in: storage.string, range: NSRange(location: 0, length: nsString.length))
    for match in matches {
      guard match.numberOfRanges > max(markerGroup, contentGroup) else { continue }
      let markerRange = match.range(at: markerGroup)
      if markerRange.isValid(within: nsString.length) {
        storage.addAttributes([
          .foregroundColor: colors.token
        ], range: markerRange)
      }

      let lineRange = nsString.lineRange(for: match.range(at: 0))
      let paragraphStyle = listParagraphStyle(mergingWith: paragraphStyle(from: storage, at: lineRange.location))
      storage.addAttributes([
        .paragraphStyle: paragraphStyle
      ], range: lineRange)
    }
  }

  private func applyBlockquotes(using regex: NSRegularExpression, to storage: MarkdownTextStorage) {
    let nsString = storage.string as NSString
    let matches = regex.matches(in: storage.string, range: NSRange(location: 0, length: nsString.length))
    for match in matches {
      guard match.numberOfRanges >= 3 else { continue }
      let markerRange = match.range(at: 1)
      if markerRange.isValid(within: nsString.length) {
        storage.addAttributes([
          .foregroundColor: colors.quoteBar
        ], range: markerRange)
      }

      let lineRange = nsString.lineRange(for: match.range(at: 0))
      let paragraphStyle = quoteParagraphStyle(mergingWith: paragraphStyle(from: storage, at: lineRange.location))
      storage.addAttributes([
        .paragraphStyle: paragraphStyle,
        .backgroundColor: colors.quoteBackground
      ], range: lineRange)
    }
  }

  private func applyTables(to storage: MarkdownTextStorage) {
    guard storage.length > 0 else { return }
    let lines = tableLines(for: storage)
    guard !lines.isEmpty else { return }

    var index = 0
    while index < lines.count {
      let header = lines[index]
      if isTableContentRow(header),
         index + 1 < lines.count,
         isTableSeparatorLine(lines[index + 1]) {
        var block: [MarkdownTableLine] = [header, lines[index + 1]]
        var cursor = index + 2
        while cursor < lines.count, isTableContentRow(lines[cursor]) {
          block.append(lines[cursor])
          cursor += 1
        }
        styleTableBlock(block, in: storage)
        index = cursor
      } else {
        index += 1
      }
    }
  }

  private func styleTableBlock(_ lines: [MarkdownTableLine], in storage: MarkdownTextStorage) {
    guard lines.count >= 2 else { return }
    let header = lines[0]
    if header.range.length > 0 {
      storage.addAttributes([
        .backgroundColor: colors.tableHeaderBackground
      ], range: header.range)
      highlightTablePipes(in: header, storage: storage)
      applyHeaderFont(for: header, in: storage)
    }

    let separator = lines[1]
    highlightTableSeparatorCharacters(in: separator, storage: storage)

    for (index, line) in lines.enumerated() {
      guard line.range.length > 0 else { continue }
      if index >= 2 {
        storage.addAttributes([
          .backgroundColor: colors.tableRowBackground
        ], range: line.range)
      }
      highlightTablePipes(in: line, storage: storage)
    }
  }

  private func highlightTablePipes(in line: MarkdownTableLine, storage: MarkdownTextStorage) {
    guard line.range.length > 0 else { return }
    let nsLine = line.text as NSString
    let length = nsLine.length
    for index in 0..<length {
      if nsLine.character(at: index) == 124 { // |
        let range = NSRange(location: line.range.location + index, length: 1)
        storage.addAttributes([
          .foregroundColor: colors.tableBorder
        ], range: range)
      }
    }
  }

  private func highlightTableSeparatorCharacters(in line: MarkdownTableLine, storage: MarkdownTextStorage) {
    guard line.range.length > 0 else { return }
    let nsLine = line.text as NSString
    let length = nsLine.length
    for index in 0..<length {
      let character = nsLine.character(at: index)
      if character == 124 || character == 45 || character == 58 { // | - :
        let range = NSRange(location: line.range.location + index, length: 1)
        storage.addAttributes([
          .foregroundColor: colors.tableBorder
        ], range: range)
      }
    }
  }

  private func applyHeaderFont(for line: MarkdownTableLine, in storage: MarkdownTextStorage) {
    guard line.range.length > 0 else { return }
    let nsLine = line.text as NSString
    let length = nsLine.length
    var segmentStart = 0
    for index in 0...length {
      let isDivider = index == length || nsLine.character(at: index) == 124
      if isDivider {
        let segmentLength = index - segmentStart
        if segmentLength > 0 {
          let segmentRange = NSRange(location: segmentStart, length: segmentLength)
          let trimmedRange = trimWhitespace(in: nsLine, range: segmentRange)
          if trimmedRange.length > 0 {
            let globalRange = NSRange(location: line.range.location + trimmedRange.location, length: trimmedRange.length)
            storage.addAttributes([
              .font: fonts.bold
            ], range: globalRange)
          }
        }
        segmentStart = index + 1
      }
    }
  }

  private func tableLines(for storage: MarkdownTextStorage) -> [MarkdownTableLine] {
    guard storage.length > 0 else { return [] }
    let nsString = storage.string as NSString
    var lines: [MarkdownTableLine] = []
    let fullRange = NSRange(location: 0, length: nsString.length)

    nsString.enumerateSubstrings(in: fullRange, options: [.byLines]) { _, substringRange, _, _ in
      var contentRange = substringRange
      while contentRange.length > 0 {
        let lastIndex = contentRange.location + contentRange.length - 1
        let character = nsString.character(at: lastIndex)
        if character == 10 || character == 13 { // \n or \r
          contentRange.length -= 1
        } else {
          break
        }
      }

      if contentRange.length < 0 {
        contentRange.length = 0
      }

      let text: String
      if contentRange.length > 0 {
        text = nsString.substring(with: contentRange)
      } else {
        text = ""
      }

      lines.append(MarkdownTableLine(text: text, range: contentRange))
    }

    return lines
  }

  private func isTableContentRow(_ line: MarkdownTableLine) -> Bool {
    let trimmed = line.text.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty, trimmed.contains("|") else { return false }
    let nsTrimmed = trimmed as NSString
    let range = NSRange(location: 0, length: nsTrimmed.length)
    return tableSeparatorRegex.firstMatch(in: trimmed, options: [], range: range) == nil
  }

  private func isTableSeparatorLine(_ line: MarkdownTableLine) -> Bool {
    let trimmed = line.text.trimmingCharacters(in: .whitespaces)
    guard trimmed.contains("|") || trimmed.contains("-") else { return false }
    let nsTrimmed = trimmed as NSString
    let range = NSRange(location: 0, length: nsTrimmed.length)
    return tableSeparatorRegex.firstMatch(in: trimmed, options: [], range: range) != nil
  }

  private func trimWhitespace(in line: NSString, range: NSRange) -> NSRange {
    var start = range.location
    var end = range.location + range.length
    let whitespace = CharacterSet.whitespacesAndNewlines

    while start < end {
      let character = line.character(at: start)
      if let scalar = UnicodeScalar(character), whitespace.contains(scalar) {
        start += 1
      } else {
        break
      }
    }

    while end > start {
      let character = line.character(at: end - 1)
      if let scalar = UnicodeScalar(character), whitespace.contains(scalar) {
        end -= 1
      } else {
        break
      }
    }

    return NSRange(location: start, length: end - start)
  }

  private struct MarkdownTableLine {
    let text: String
    let range: NSRange
  }

  private func paragraphStyle(from storage: MarkdownTextStorage, at location: Int) -> NSMutableParagraphStyle {
    if let textStorage = storage as? NSTextStorage,
       let existing = textStorage.attribute(.paragraphStyle, at: location, effectiveRange: nil) as? NSParagraphStyle {
      return (existing.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
    }
    return NSMutableParagraphStyle()
  }

  private func listParagraphStyle(mergingWith existing: NSMutableParagraphStyle) -> NSMutableParagraphStyle {
    existing.firstLineHeadIndent = 0
    let indent = fonts.body.pointSize * 1.6
    existing.headIndent = max(existing.headIndent, indent)
    existing.paragraphSpacing = max(existing.paragraphSpacing, fonts.body.pointSize * 0.2)
    existing.tabStops = []
    existing.lineBreakMode = .byWordWrapping
    return existing
  }

  private func quoteParagraphStyle(mergingWith existing: NSMutableParagraphStyle) -> NSMutableParagraphStyle {
    let indent = fonts.body.pointSize * 1.1
    existing.headIndent = max(existing.headIndent, indent)
    existing.paragraphSpacing = max(existing.paragraphSpacing, fonts.body.pointSize * 0.25)
    existing.paragraphSpacingBefore = max(existing.paragraphSpacingBefore, fonts.body.pointSize * 0.15)
    existing.tabStops = []
    existing.lineBreakMode = .byWordWrapping
    return existing
  }
}

private let strongAsteriskRegex = try! NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*", options: [])
private let strongUnderscoreRegex = try! NSRegularExpression(pattern: "__(.+?)__", options: [])
private let italicAsteriskRegex = try! NSRegularExpression(pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)", options: [])
private let italicUnderscoreRegex = try! NSRegularExpression(pattern: "(?<!_)_(?!_)(.+?)(?<!_)_(?!_)", options: [])
private let inlineCodeRegex = try! NSRegularExpression(pattern: "`([^`]+)`", options: [])
private let strikethroughRegex = try! NSRegularExpression(pattern: "~~(.+?)~~", options: [])
private let unorderedListRegex = try! NSRegularExpression(pattern: "(?m)^(\\s*)([-*+])\\s+(.+)$", options: [])
private let orderedListRegex = try! NSRegularExpression(pattern: "(?m)^(\\s*)(\\d+\\.)\\s+(.+)$", options: [])
private let blockquoteRegex = try! NSRegularExpression(pattern: "(?m)^(\\s{0,3}>\\s?)(.+)$", options: [])
private let linkRegex = try! NSRegularExpression(pattern: "\\[(.+?)\\]\\((.+?)\\)", options: [])
private let tableSeparatorRegex = try! NSRegularExpression(pattern: "^\\|?\\s*:?-{3,}:?\\s*(\\|\\s*:?-{3,}:?\\s*)+\\|?\\s*$", options: [])

struct MarkdownFontPalette {
  var body: PlatformFont
  var bold: PlatformFont
  var italic: PlatformFont
  var monospace: PlatformFont

  static func system(size: CGFloat, weight: PlatformFontWeight = .regular) -> MarkdownFontPalette {
    #if canImport(UIKit)
    let body = UIFont.systemFont(ofSize: size, weight: weight)
    let bold = UIFont.systemFont(ofSize: size, weight: .bold)
    let italic = UIFont.italicSystemFont(ofSize: size)
    let monospace = UIFont.monospacedSystemFont(ofSize: size, weight: weight)
    #else
    let body = NSFont.systemFont(ofSize: size, weight: weight)
    let bold = NSFont.systemFont(ofSize: size, weight: .bold)
    let monospace = NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    let italic = NSFontManager.shared.convert(body, toHaveTrait: .italicFontMask)
    #endif
    return MarkdownFontPalette(body: body, bold: bold, italic: italic, monospace: monospace)
  }
}

struct MarkdownColorPalette {
  var text: PlatformColor
  var token: PlatformColor
  var codeBackground: PlatformColor
  var link: PlatformColor
  var quoteBar: PlatformColor
  var quoteBackground: PlatformColor
  var strikethrough: PlatformColor
  var tableBorder: PlatformColor
  var tableHeaderBackground: PlatformColor
  var tableRowBackground: PlatformColor
}

protocol MarkdownTextStorage: AnyObject {
  var string: String { get }
  var length: Int { get }
  func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange)
  func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange)
}

#if canImport(UIKit)
extension NSTextStorage: MarkdownTextStorage {}
#elseif canImport(AppKit)
extension NSTextStorage: MarkdownTextStorage {}
#endif

private struct MarkdownRegexMatch {
  let fullRange: NSRange
  let contentRange: NSRange
  let leadingTokenRange: NSRange
  let trailingTokenRange: NSRange
}

private extension MarkdownTextStorage {
  func enumerateMatches(for regex: NSRegularExpression, contentGroup: Int, leadingTokenLength: Int, trailingTokenLength: Int, handler: (MarkdownRegexMatch) -> Void) {
    let length = self.length
    guard length > 0 else { return }
    let matches = regex.matches(in: string, range: NSRange(location: 0, length: length))
    for match in matches {
      let fullRange = match.range(at: 0)
      guard let contentRange = match.optionalRange(at: contentGroup) else { continue }
      let leadingTokenRange = NSRange(location: fullRange.location, length: leadingTokenLength)
      let trailingTokenRange = NSRange(location: fullRange.upperBound - trailingTokenLength, length: trailingTokenLength)
      guard leadingTokenRange.isValid(within: length), trailingTokenRange.isValid(within: length), contentRange.isValid(within: length) else { continue }
      handler(MarkdownRegexMatch(
        fullRange: fullRange,
        contentRange: contentRange,
        leadingTokenRange: leadingTokenRange,
        trailingTokenRange: trailingTokenRange
      ))
    }
  }
}

private extension NSRange {
  var upperBound: Int { location + length }

  func isValid(within totalLength: Int) -> Bool {
    location >= 0 && upperBound <= totalLength && length >= 0
  }
}

private extension NSTextCheckingResult {
  func optionalRange(at index: Int) -> NSRange? {
    let range = self.range(at: index)
    return range.location == NSNotFound ? nil : range
  }
}

extension PlatformColor {
  static var markdownLabel: PlatformColor {
    #if canImport(UIKit)
    .label
    #else
    .labelColor
    #endif
  }

  static var markdownToken: PlatformColor {
    #if canImport(UIKit)
    .tertiaryLabel
    #else
    .tertiaryLabelColor
    #endif
  }

  static var markdownCodeBackground: PlatformColor {
    #if canImport(UIKit)
    UIColor { traits in
      traits.userInterfaceStyle == .dark ? UIColor.systemGray5 : UIColor.systemGray5.withAlphaComponent(0.6)
    }
    #else
    PlatformColor.controlAccentColor.withAlphaComponent(0.1)
    #endif
  }

  static var markdownLink: PlatformColor {
    #if canImport(UIKit)
    .link
    #else
    .linkColor
    #endif
  }

  static var markdownQuoteBackground: PlatformColor {
    #if canImport(UIKit)
    UIColor { traits in
      traits.userInterfaceStyle == .dark
        ? UIColor.secondarySystemBackground.withAlphaComponent(0.4)
        : UIColor.secondarySystemBackground.withAlphaComponent(0.6)
    }
    #else
    PlatformColor.controlBackgroundColor.withAlphaComponent(0.5)
    #endif
  }

  static var markdownTableBorder: PlatformColor {
    #if canImport(UIKit)
    .separator
    #else
    .separatorColor
    #endif
  }

  static var markdownTableHeaderBackground: PlatformColor {
    #if canImport(UIKit)
    UIColor { traits in
      traits.userInterfaceStyle == .dark
        ? UIColor.systemGray5.withAlphaComponent(0.55)
        : UIColor.systemGray5.withAlphaComponent(0.28)
    }
    #else
    PlatformColor.controlHighlightColor.withAlphaComponent(0.35)
    #endif
  }

  static var markdownTableRowBackground: PlatformColor {
    #if canImport(UIKit)
    UIColor { traits in
      traits.userInterfaceStyle == .dark
        ? UIColor.secondarySystemBackground.withAlphaComponent(0.35)
        : UIColor.secondarySystemBackground.withAlphaComponent(0.18)
    }
    #else
    PlatformColor.controlBackgroundColor.withAlphaComponent(0.25)
    #endif
  }

  static func from(color: Color, fallback: PlatformColor) -> PlatformColor {
    #if canImport(UIKit)
    if #available(iOS 14.0, tvOS 14.0, *) {
      return UIColor(color)
    }
    return fallback
    #else
    if #available(macOS 11.0, *) {
      return NSColor(color)
    }
    return fallback
    #endif
  }
}
