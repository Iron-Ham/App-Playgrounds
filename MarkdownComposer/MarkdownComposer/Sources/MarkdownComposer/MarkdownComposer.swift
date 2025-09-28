import SwiftUI

public struct MarkdownComposer: View {
  @Binding private var text: String
  private var configuration: MarkdownComposerConfiguration

  public init(text: Binding<String>, configuration: MarkdownComposerConfiguration = .default) {
    _text = text
    self.configuration = configuration
  }

  public var body: some View {
    ZStack(alignment: .topLeading) {
      MarkdownTextEditor(text: $text, configuration: configuration)

      if text.isEmpty, let placeholder = configuration.placeholder {
        Text(placeholder)
          .foregroundColor(configuration.placeholderColor)
          .padding(configuration.contentInsets)
          .allowsHitTesting(false)
      }
    }
    .background(configuration.backgroundColor)
  }
}

@available(iOS 17.0, *)
@available(macOS 14.0, *)
#Preview {
  @Previewable @State var text: String = """
    Hello, _Steve_, my name is **Billy Joel Armstrong**, the lead singer of a band called ~~The Muppets~~ Green Day.
    
    This is a quote:
    
    > Once upon a midnight dreary
    
    This is a numbered list:
    
    1. One
    2. Two
    3. Three
    
    This is a bullet list:
    
    - One
    - Two
    - Three
    
    This is a bullet list, but with stars:
    
    * One
    * Two
    * Three
    
    And this is a [link](https://www.google.com).
    
    But my mortal enemy, the table:
    
    | Before | After |
    | --- | --- |
    | Jajaja | Hahaha |
    """
  MarkdownComposer(text: $text, configuration: .init(placeholder: "Write a story"))
}

