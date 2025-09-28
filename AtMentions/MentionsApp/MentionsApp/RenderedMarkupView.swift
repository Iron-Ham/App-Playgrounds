import Markdown
import SwiftUI

typealias MarkupPath = [Int]

func taskListKey(prefix: String, path: MarkupPath) -> String {
  guard !path.isEmpty else { return prefix }
  var components: [String] = [prefix]
  components.append(contentsOf: path.map(String.init))
  return components.joined(separator: ".")
}

struct RenderedMarkupView: View {
  let document: Document
  @Binding var taskStates: [String: Bool]
  let pathPrefix: String

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(Array(document.children.enumerated()), id: \.offset) { index, child in
        MarkupBlockView(
          markup: child,
          path: [index],
          pathPrefix: pathPrefix,
          taskStates: $taskStates
        )
      }
    }
  }
}

private struct MarkupBlockView: View {
  let markup: Markup
  let path: MarkupPath
  let pathPrefix: String
  @Binding var taskStates: [String: Bool]

  var body: some View {
    switch markup {
    case let paragraph as Paragraph:
      InlineTextView(markup: paragraph)

    case let heading as Heading:
      InlineTextView(markup: heading)
        .font(heading.font)

    case _ as ThematicBreak:
      Divider()

    case let codeBlock as CodeBlock:
      ScrollView(.horizontal) {
        Text(codeBlock.codeAttributed)
          .font(.system(.body, design: .monospaced))
          .padding(12)
          .background(.secondary.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }

    case let quote as BlockQuote:
      BlockQuoteView(
        blockQuote: quote,
        path: path,
        pathPrefix: pathPrefix,
        taskStates: $taskStates
      )

    case let list as UnorderedList:
      ListContainerView(
        items: listItems(in: list),
        style: .unordered,
        path: path,
        pathPrefix: pathPrefix,
        taskStates: $taskStates
      )

    case let list as OrderedList:
      ListContainerView(
        items: listItems(in: list),
        style: .ordered(start: Int(list.startIndex)),
        path: path,
        pathPrefix: pathPrefix,
        taskStates: $taskStates
      )

    default:
      if markup.childCount > 0 {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(Array(blockChildren(of: markup).enumerated()), id: \.offset) { index, child in
            MarkupBlockView(
              markup: child,
              path: path + [index],
              pathPrefix: pathPrefix,
              taskStates: $taskStates
            )
          }
        }
      } else {
        Text(markup.format())
      }
    }
  }
}

private struct InlineTextView: View {
  let markup: Markup

  var body: some View {
    if let attributed = markup.attributedString {
      Text(attributed)
    } else {
      Text(markup.format())
    }
  }
}

private struct BlockQuoteView: View {
  let blockQuote: BlockQuote
  let path: MarkupPath
  let pathPrefix: String
  @Binding var taskStates: [String: Bool]

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Rectangle()
        .fill(.secondary)
        .frame(width: 3)
        .cornerRadius(1.5)

      VStack(alignment: .leading, spacing: 8) {
        ForEach(Array(blockChildren(of: blockQuote).enumerated()), id: \.offset) { index, child in
          MarkupBlockView(
            markup: child,
            path: path + [index],
            pathPrefix: pathPrefix,
            taskStates: $taskStates
          )
        }
      }
    }
    .padding(12)
    .background(.secondary.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }
}

private struct ListContainerView: View {
  enum Style {
    case unordered
    case ordered(start: Int)
  }

  let items: [ListItem]
  let style: Style
  let path: MarkupPath
  let pathPrefix: String
  @Binding var taskStates: [String: Bool]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(Array(items.enumerated()), id: \.offset) { index, item in
        let itemPath = path + [index]
        ListItemRow(
          item: item,
          style: style,
          index: index,
          path: itemPath,
          pathPrefix: pathPrefix,
          taskStates: $taskStates
        )
      }
    }
  }
}

private struct ListItemRow: View {
  let item: ListItem
  let style: ListContainerView.Style
  let index: Int
  let path: MarkupPath
  let pathPrefix: String
  @Binding var taskStates: [String: Bool]

  var body: some View {
    if let checkbox = item.checkbox {
      let key = taskListKey(prefix: pathPrefix, path: path)
      let defaultValue = (checkbox == .checked)
      let isOn = taskStates[key] ?? defaultValue

      Button {
        taskStates[key] = !isOn
      } label: {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
          Image(systemName: isOn ? "checkmark.square.fill" : "square")
            .foregroundStyle(isOn ? Color.accentColor : Color.secondary)

          VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blockChildren(of: item).enumerated()), id: \.offset) { childIndex, child in
              MarkupBlockView(
                markup: child,
                path: path + [childIndex],
                pathPrefix: pathPrefix,
                taskStates: $taskStates
              )
            }
          }
        }
      }
      .buttonStyle(.plain)
      .accessibilityLabel(item.format())
      .accessibilityValue(isOn ? "Completed" : "Not completed")

    } else {
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        marker
          .font(.body)

        VStack(alignment: .leading, spacing: 8) {
          ForEach(Array(blockChildren(of: item).enumerated()), id: \.offset) { childIndex, child in
            MarkupBlockView(
              markup: child,
              path: path + [childIndex],
              pathPrefix: pathPrefix,
              taskStates: $taskStates
            )
          }
        }
      }
      .alignmentGuide(.leading) { context in
        context[.leading]
      }
    }
  }

  @ViewBuilder
  private var marker: some View {
    switch style {
    case .unordered:
      Text("•")
    case let .ordered(start):
      Text("\(start + index).")
    }
  }
}

private extension Heading {
  var font: Font {
    switch level {
    case 1: return .largeTitle.bold()
    case 2: return .title.bold()
    case 3: return .title2.bold()
    case 4: return .title3.bold()
    case 5: return .headline
    default: return .subheadline
    }
  }
}

private extension Markup {
  var attributedString: AttributedString? {
    try? AttributedString(markdown: format())
  }
}

private extension CodeBlock {
  var codeAttributed: AttributedString {
    (try? AttributedString(markdown: "```\n\(code)\n```")) ?? AttributedString(code)
  }
}

private func listItems(in list: UnorderedList) -> [ListItem] {
  Array(list.children).compactMap { $0 as? ListItem }
}

private func listItems(in list: OrderedList) -> [ListItem] {
  Array(list.children).compactMap { $0 as? ListItem }
}

private func blockChildren(of markup: Markup) -> [Markup] {
  Array(markup.children)
}
