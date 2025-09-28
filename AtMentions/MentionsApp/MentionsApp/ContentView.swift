import Markdown
import Markup
import SwiftUI

private func normalizedTaskListMarkup(_ text: String) -> String {
  text
    .replacingOccurrences(of: "- []", with: "- [ ]")
    .replacingOccurrences(of: "- [x]", with: "- [x]")
    .replacingOccurrences(of: "- [X]", with: "- [x]")
}

private let markupText = """
Hey @octocat, you did a great job with the last icon design! Seriously!  **amazing job**. 

I have a _few_ questions though:

1. Q1
2. Q2
3. Q3

As you said last week:

> We are who we are

TODO:

- [] Banana 
- [ ] Banananana 
- [x] Bananananananana

Also: Have you been to [Google?](https://www.google.com).
"""

private let originalDocument = Document(parsing: normalizedTaskListMarkup(markupText))

struct ContentView: View {

  @State private var mentions: [MentionRewriter.Mention] = []
  @State private var rewrittenMarkupSource: String = ""
  @State private var rewrittenDocument: Document? = nil
  @State private var taskStates: [String: Bool] = [:]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Original Markdown")
          .font(.headline)

        Text(markupText)
          .font(.system(.body, design: .monospaced))
          .textSelection(.enabled)

        Divider()

        Text("Detected Mentions")
          .font(.headline)

        if mentions.isEmpty {
          Text("No mentions found.")
            .foregroundStyle(.secondary)
        } else {
          VStack(alignment: .leading, spacing: 8) {
            ForEach(mentions, id: \.username) { mention in
              HStack(spacing: 8) {
                Text(mention.displayText)
                  .fontWeight(.semibold)
                Text("username: @\(mention.username)")
                  .foregroundStyle(.secondary)
              }
            }
          }
        }

        Divider()
        
        Text("Rendered Rewritten Preview")
          .font(.headline)

        if let rewrittenDocument {
          RenderedMarkupView(
            document: rewrittenDocument,
            taskStates: $taskStates,
            pathPrefix: "rewritten"
          )
        } else {
          Text("Processing…")
            .foregroundStyle(.secondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
    }
    .task {
      let document = originalDocument
      let collectedMentions = MentionRewriter.collectMentions(in: document)

      var rewriter = MentionRewriter()
      let rewritten = (rewriter.visit(document) as? Document) ?? document
      let formatted = rewritten.format()

      let originalTaskStates = collectTaskStates(in: document, prefix: "original")
      let rewrittenTaskStates = collectTaskStates(in: rewritten, prefix: "rewritten")
      let combinedTaskStates = originalTaskStates.merging(rewrittenTaskStates) { current, _ in current }

      await MainActor.run {
        mentions = collectedMentions
        rewrittenMarkupSource = formatted
        rewrittenDocument = rewritten
        if taskStates.isEmpty {
          taskStates = combinedTaskStates
        } else {
          for (key, value) in combinedTaskStates where taskStates[key] == nil {
            taskStates[key] = value
          }
        }
      }
    }
  }
}

private func collectTaskStates(in root: any Markup, prefix: String) -> [String: Bool] {
  var results: [String: Bool] = [:]

  func traverse(_ node: Markup, path: [Int]) {
    if let list = node as? UnorderedList {
      for (index, element) in list.children.enumerated() {
        guard let item = element as? ListItem else { continue }
        let itemPath = path + [index]
        if let checkbox = item.checkbox {
          results[taskListKey(prefix: prefix, path: itemPath)] = (checkbox == .checked)
        }
        traverse(item, path: itemPath)
      }
      return
    }

    if let list = node as? OrderedList {
      for (index, element) in list.children.enumerated() {
        guard let item = element as? ListItem else { continue }
        let itemPath = path + [index]
        if let checkbox = item.checkbox {
          results[taskListKey(prefix: prefix, path: itemPath)] = (checkbox == .checked)
        }
        traverse(item, path: itemPath)
      }
      return
    }

    for (index, child) in node.children.enumerated() {
      traverse(child, path: path + [index])
    }
  }

  traverse(root, path: [])
  return results
}

#Preview {
  ContentView()
}
