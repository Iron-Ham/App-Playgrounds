import Foundation
import Markdown

/// A reusable `MarkupRewriter` that scans inline text for `@mention` tokens and rewrites
/// them into structured inline markup when they pass a caller-provided validation check.
///
/// Usage overview:
/// ```swift
/// var document = Document(parsing: "Hey @octocat!")
/// var rewriter = MentionRewriter()
/// if let updated = rewriter.visit(document) as? Document {
///   document = updated
/// }
/// ```
///
/// The default renderer wraps mentions in a `Link` that uses the `mention:` scheme—consumers
/// can inspect the destination or provide their own renderer closure to emit a different
/// inline node (for example, an `InlineAttributes`, a `CustomInline`, or a `Link` with a
/// product-specific URL).
///
/// For clients that must vet mentions asynchronously (such as via a network lookup), the
/// `collectMentions(in:)` helper surfaces every mention token ahead of time and the
/// `rewrite(_:validateAsync:render:)` helper orchestrates the two-phase validation + rewrite flow.
public struct MentionRewriter: MarkupRewriter {

  /// Describes a detected mention token.
  public struct Mention: Equatable, Sendable {
    /// The account identifier without the leading `@`.
    public let username: String
    /// The literal display text, including the leading `@`.
    public let displayText: String
  }

  /// Validation hook deciding whether a detected mention should be rendered.
  public typealias Validator = (Mention) -> Bool

  /// Renderer hook responsible for producing inline markup for a validated mention.
  public typealias Renderer = (Mention) -> InlineMarkup

  /// Create a rewriter with optional custom validator and renderer.
  /// - Parameters:
  ///   - isValidMention: Called for every detected mention. Return `false` to leave the
  ///     text untouched. Defaults to accepting every mention.
  ///   - render: Produces inline markup for accepted mentions. Defaults to a `Link` with a
  ///     `mention:` destination and `@username` text.
  public init(
    isValidMention: @escaping Validator = { _ in true },
    render: Renderer? = nil
  ) {
    self.isValidMention = isValidMention
    self.render = render ?? MentionRewriter.defaultRenderer
  }

  private let isValidMention: Validator
  private let render: Renderer

  // MARK: - MarkupRewriter

  public mutating func visitParagraph(_ paragraph: Paragraph) -> (any Markup)? {
    if let updated: Paragraph = rewriteBasicInlineContainer(paragraph) {
      return updated
    }
    return defaultVisit(paragraph)
  }

  public mutating func visitEmphasis(_ emphasis: Emphasis) -> (any Markup)? {
    if let updated: Emphasis = rewriteBasicInlineContainer(emphasis) {
      return updated
    }
    return defaultVisit(emphasis)
  }

  public mutating func visitStrong(_ strong: Strong) -> (any Markup)? {
    if let updated: Strong = rewriteBasicInlineContainer(strong) {
      return updated
    }
    return defaultVisit(strong)
  }

  public mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> (any Markup)? {
    if let updated: Strikethrough = rewriteBasicInlineContainer(strikethrough) {
      return updated
    }
    return defaultVisit(strikethrough)
  }

  public mutating func visitTableCell(_ cell: Table.Cell) -> (any Markup)? {
    let colspan = cell.colspan
    let rowspan = cell.rowspan
    if let rewrittenChildren = rewriteInlineChildren(Array(cell.inlineChildren)).resultIfChanged {
      return Table.Cell(colspan: colspan, rowspan: rowspan, rewrittenChildren, inheritSourceRange: true)
    }
    return defaultVisit(cell)
  }

  public mutating func visitHeading(_ heading: Heading) -> (any Markup)? {
    if let rewrittenChildren = rewriteInlineChildren(Array(heading.inlineChildren)).resultIfChanged {
      return Heading(level: heading.level, rewrittenChildren)
    }
    return defaultVisit(heading)
  }

  // For all other markup, fall back to the default traversal behaviour
  public mutating func visitText(_ text: Text) -> (any Markup)? {
    // Text nodes are rewritten by their containing inline container.
    return text
  }

  // MARK: - Inline container rewriting

  private mutating func rewriteBasicInlineContainer<C: BasicInlineContainer & Markup>(_ container: C) -> C? {
    guard let rewrittenChildren = rewriteInlineChildren(Array(container.inlineChildren)).resultIfChanged else {
      return nil
    }
    return C(rewrittenChildren, inheritSourceRange: true)
  }

  private mutating func rewriteInlineChildren(_ children: [InlineMarkup]) -> RewriteResult {
    var rewritten: [InlineMarkup] = []
    var changed = false

    for child in children {
      if let text = child as? Text {
        let (pieces, textChanged) = rewrite(text)
        if textChanged {
          rewritten.append(contentsOf: pieces)
          changed = true
        } else {
          rewritten.append(text)
        }
        continue
      }

      if let visited = visit(child) {
        guard let inline = visited as? InlineMarkup else {
          // Fallback: if a consumer accidentally renders something non-inline, keep plain text.
          rewritten.append(Text(visited.format()))
          changed = true
          continue
        }
        if !inline.isIdentical(to: child) {
          changed = true
        }
        rewritten.append(inline)
      } else {
        changed = true
        // Dropped child - omit from rewritten array.
      }
    }

    return RewriteResult(children: changed ? rewritten : children, didChange: changed)
  }

  private mutating func rewrite(_ text: Text) -> ([InlineMarkup], Bool) {
    let content = text.string
    guard !content.isEmpty else { return ([], false) }

    var output: [InlineMarkup] = []
    var cursor = content.startIndex
    var changed = false

  for match in Self.detectMentions(in: content) {
      if cursor < match.range.lowerBound {
        let prefix = String(content[cursor..<match.range.lowerBound])
        if !prefix.isEmpty {
          output.append(Text(prefix))
        }
      }

      let mentionText = String(content[match.range])
      let mention = Mention(username: match.username, displayText: mentionText)

      if isValidMention(mention) {
        output.append(render(mention))
        changed = true
      } else {
        output.append(Text(mentionText))
      }

      cursor = match.range.upperBound
    }

    if cursor < content.endIndex {
      let suffix = String(content[cursor...])
      if !suffix.isEmpty {
        output.append(Text(suffix))
      }
    }

    return (output, changed)
  }

  // MARK: - Mention detection

  fileprivate static func detectMentions(in text: String) -> [MentionMatch] {
    guard text.contains("@") else { return [] }

    var matches: [MentionMatch] = []
    var index = text.startIndex

    while index < text.endIndex {
      let character = text[index]
      if character == "@" {
        let leftBoundaryIsValid: Bool = {
          guard index > text.startIndex else { return true }
          let previous = text[text.index(before: index)]
          return !previous.isMentionWordCharacter
        }()

        if leftBoundaryIsValid {
          var cursor = text.index(after: index)
          var length = 0
          while cursor < text.endIndex, length < MentionRewriter.maxUsernameLength, text[cursor].isMentionWordCharacter {
            length += 1
            cursor = text.index(after: cursor)
          }

          if length > 0 {
            let rightBoundaryIsValid = cursor == text.endIndex || !text[cursor].isMentionWordCharacter
            if rightBoundaryIsValid {
              let usernameRange = text.index(after: index)..<cursor
              let username = String(text[usernameRange])
              matches.append(MentionMatch(username: username, range: index..<cursor))
            }
          }

          index = cursor
          continue
        }
      }

      index = text.index(after: index)
    }

    return matches
  }

  private static func defaultRenderer(_ mention: Mention) -> InlineMarkup {
    Link(destination: "mention:\(mention.username)", Text(mention.displayText))
  }

  private struct RewriteResult {
    let children: [InlineMarkup]
    let didChange: Bool

    var resultIfChanged: [InlineMarkup]? { didChange ? children : nil }
  }

  /// Collect mentions found anywhere in a markup tree, optionally deduplicating by username.
  /// The collection order matches their first appearance.
  public static func collectMentions(in markup: any Markup, uniqueByUsername: Bool = true) -> [Mention] {
    var walker = MentionWalker()
    walker.visit(markup)
    guard uniqueByUsername else { return walker.mentions }

    var seen: Set<String> = []
    var unique: [Mention] = []
    for mention in walker.mentions where seen.insert(mention.username).inserted {
      unique.append(mention)
    }
    return unique
  }

  /// Convenience helper for asynchronous validation scenarios. Mentions are collected first and
  /// then validated using an `async` predicate before performing a single synchronous rewrite.
  ///
  /// - Parameters:
  ///   - root: Root markup element to rewrite.
  ///   - validateAsync: Awaitable predicate that returns `true` when a mention should be rendered.
  ///   - render: Optional renderer override matching the synchronous initializer.
  /// - Returns: The rewritten markup with validated mentions rendered, or the original markup if
  ///   no mentions passed validation.
  public static func rewrite<Root: Markup>(
    _ root: Root,
    validateAsync: @escaping (Mention) async -> Bool,
    render: Renderer? = nil
  ) async -> Root {
    let mentions = collectMentions(in: root)
    guard !mentions.isEmpty else { return root }

    var validUsernames: Set<String> = []
    for mention in mentions {
      if await validateAsync(mention) {
        validUsernames.insert(mention.username)
      }
    }

    guard !validUsernames.isEmpty else { return root }

    var rewriter = MentionRewriter(isValidMention: { mention in
      validUsernames.contains(mention.username)
    }, render: render)

    return (rewriter.visit(root) as? Root) ?? root
  }

  private static let maxUsernameLength = 30
}

private extension Character {
  var isMentionWordCharacter: Bool {
    if isNumber || isLetter { return true }
    return self == "_"
  }
}

  fileprivate struct MentionMatch {
    let username: String
    let range: Range<String.Index>
  }

private struct MentionWalker: MarkupWalker {
  var mentions: [MentionRewriter.Mention] = []

  mutating func visitText(_ text: Text) {
    for match in MentionRewriter.detectMentions(in: text.string) {
      let display = String(text.string[match.range])
      mentions.append(.init(username: match.username, displayText: display))
    }
  }
}
