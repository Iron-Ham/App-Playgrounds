import Markdown
import Testing

@testable import Markup

@Test func rewritesMentionsWithDefaultRenderer() throws {
  let document = Document(parsing: "Hello @alice and @bob.")
  var rewriter = MentionRewriter()

  guard let updated = rewriter.visit(document) as? Document,
        let paragraph = updated.child(at: 0) as? Paragraph else {
    Issue.record("Expected rewritten document with a paragraph root")
    return
  }

  let children = Array(paragraph.inlineChildren)
  #expect(children.count == 5)

  guard
    let firstLink = children[1] as? Link,
    let secondLink = children[3] as? Link
  else {
    Issue.record("Expected links emitted for mentions")
    return
  }

  #expect(firstLink.destination == "mention:alice")
  #expect((firstLink.child(at: 0) as? Text)?.string == "@alice")
  #expect(secondLink.destination == "mention:bob")
  #expect((secondLink.child(at: 0) as? Text)?.string == "@bob")
}

@Test func respectsValidatorAndCustomRenderer() throws {
  let document = Document(parsing: "Ping @valid and @bots")
  let renderer: MentionRewriter.Renderer = { mention in
    let attributesJSON = "{\"kind\":\"mention\",\"user\":\"\(mention.username)\"}"
    return InlineAttributes(attributes: attributesJSON, Text(mention.displayText))
  }
  var rewriter = MentionRewriter(
    isValidMention: { $0.username != "bots" },
    render: renderer
  )

  guard let updated = rewriter.visit(document) as? Document,
        let paragraph = updated.child(at: 0) as? Paragraph else {
    Issue.record("Expected rewritten paragraph")
    return
  }

  let children = Array(paragraph.inlineChildren)
  #expect(children.count == 4)
  #expect(children[0].plainText == "Ping ")

  guard let attributes = children[1] as? InlineAttributes else {
    Issue.record("Expected InlineAttributes for valid mention")
    return
  }

  #expect(attributes.attributes.contains("\"user\":\"valid\""))
  #expect(children[2].plainText == " and ")
  #expect(children[3].plainText == "@bots")
}

@Test func rewritesMentionsInsideEmphasis() throws {
  let document = Document(parsing: "*Contact @team* for help")
  var rewriter = MentionRewriter()

  guard let updated = rewriter.visit(document) as? Document,
        let paragraph = updated.child(at: 0) as? Paragraph else {
    Issue.record("Expected paragraph containing emphasis")
    return
  }

  let paragraphChildren = Array(paragraph.inlineChildren)
  guard let emphasis = paragraphChildren.first as? Emphasis else {
    Issue.record("Expected emphasis node as first child")
    return
  }

  let emphasisChildren = Array(emphasis.inlineChildren)
  #expect(emphasisChildren.count == 2)
  #expect((emphasisChildren[1] as? Link)?.destination == "mention:team")
}

@Test func collectMentionsReturnsUniqueUsernames() throws {
  let document = Document(parsing: "@one, @two, @one")
  let mentions = MentionRewriter.collectMentions(in: document)
  #expect(mentions.map(\.username) == ["one", "two"])
}

@Test func asyncRewriteSupportsNetworkValidation() async throws {
  let document = Document(parsing: "Ping @slow and @fast.")

  let rewritten = await MentionRewriter.rewrite(document) { mention in
    try? await Task.sleep(nanoseconds: 500_000)
    return mention.username == "fast"
  }

  guard let paragraph = rewritten.child(at: 0) as? Paragraph else {
    Issue.record("Expected paragraph in rewritten document")
    return
  }

  let children = Array(paragraph.inlineChildren)
  #expect(children.count == 5)
  #expect(children[1].plainText == "@slow")
  #expect((children[3] as? Link)?.destination == "mention:fast")
  #expect((children[3] as? Link)?.child(at: 0) as? Text != nil)
}
