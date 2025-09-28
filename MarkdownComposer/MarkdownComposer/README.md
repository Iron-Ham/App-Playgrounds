# MarkdownComposer

MarkdownComposer is a reusable SwiftUI component that behaves like a traditional text field or text view, but understands Markdown. While you type, it highlights Markdown spans (bold, italic, inline code) without altering the characters you write, so the original formatting tokens remain part of the text buffer.

## Features

- ✅ Live styling for `**bold**`, `*italic*` / `_italic_`, `` `inline code` ``, and `~~strikethrough~~`
- ✅ Highlights unordered (`-`, `*`, `+`) and ordered (`1.`, `2.` …) list markers with proper indentation
- ✅ Brings attention to block quotes with a subtle bar and background tint
- ✅ Styles Markdown links with accent color and underline while keeping the raw URL visible
- ✅ Recognizes Markdown tables with bold headers, tinted rows, and highlighted dividers
- ✅ Preserves Markdown tokens in the underlying `String`
- ✅ Works on iOS and macOS with native editing controls (`UITextView` / `NSTextView`)
- ✅ Fully configurable fonts, colors, placeholder, cursor, and content insets
- ✅ Ships as a Swift Package with automated tests

## Installation

Add **MarkdownComposer** to your project using Swift Package Manager:

1. In Xcode, open **File › Add Packages…**
2. Paste the repository URL: `https://github.com/Iron-Ham/App-Playgrounds`
3. Select the **MarkdownComposer** product and add it to your target

You can also declare it manually in `Package.swift`:

```swift
.package(url: "https://github.com/Iron-Ham/App-Playgrounds", branch: "main")
```

Then add `MarkdownComposer` to your target's dependencies.

## Quick start

```swift
import SwiftUI
import MarkdownComposer

struct EditorDemo: View {
  @State private var notes = """
  ## Meeting Notes
  - [ ] Outline the release plan
  - [x] Check in with design
  """

  var body: some View {
    MarkdownComposer(text: $notes)
      .padding()
  }
}
```

The user sees live Markdown styling as they type, but the stored string still contains the raw Markdown characters.

## Configuration

Create a `MarkdownComposerConfiguration` to customize fonts, colors, placeholder text, and behavior:

```swift
let configuration = MarkdownComposerConfiguration(
  fontSize: 18,
  fontWeight: .medium,
  textColor: .primary,
  tokenColor: .teal,
  codeBackgroundColor: Color.teal.opacity(0.15),
  linkColor: .blue,
  quoteBarColor: .teal,
  quoteBackgroundColor: Color.teal.opacity(0.08),
  strikethroughColor: .teal,
  tableBorderColor: .teal,
  tableHeaderBackgroundColor: Color.teal.opacity(0.12),
  tableRowBackgroundColor: Color.teal.opacity(0.05),
  backgroundColor: Color(.secondarySystemBackground),
  cursorColor: .teal,
  placeholder: "Write something in *Markdown*…",
  contentInsets: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
  isEditable: true,
  isScrollEnabled: true,
  autocorrection: false
)

MarkdownComposer(text: $notes, configuration: configuration)
  .padding()
  .background(Color(.systemGroupedBackground))
  .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
```

### What gets styled today

- `**bold**` and `__bold__`
- `*italic*` and `_italic_`
- `` `inline code` ``
- `~~strikethrough~~`
- `-`, `*`, `+` unordered lists and `1.` ordered lists
- `> block quotes`
- `[links](https://example.com)`
- Tables with pipe dividers (`|`) and alignment rows (`---`, `:---`, `---:`)

Tokens are rendered in a subdued color so people can still see the Markdown syntax.

### Roadmap ideas

- [ ] Heading styling
- [ ] Markdown shortcuts (e.g. `⌘B` for `**bold**`)
- [ ] Custom token grammar injection

## Testing

Run the package tests to verify the styling engine:

```bash
cd MarkdownComposer
swift test
```

Tests assert that Markdown tokens are preserved and that fonts/colors are applied to the correct ranges.

## License

This package is released under the MIT license. See [`LICENSE`](../LICENSE) for details.
