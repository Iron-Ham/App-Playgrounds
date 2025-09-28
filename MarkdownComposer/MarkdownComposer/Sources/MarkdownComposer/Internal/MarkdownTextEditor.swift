import SwiftUI

struct MarkdownTextEditor: View {
  @Binding var text: String
  var configuration: MarkdownComposerConfiguration

  init(text: Binding<String>, configuration: MarkdownComposerConfiguration) {
    _text = text
    self.configuration = configuration
  }

  var body: some View {
    Representable(text: $text, configuration: configuration)
  }

  #if canImport(UIKit)
  struct Representable: UIViewRepresentable {
    @Binding var text: String
    var configuration: MarkdownComposerConfiguration

    func makeCoordinator() -> Coordinator {
      Coordinator(text: $text, configuration: configuration)
    }

    func makeUIView(context: Context) -> UITextView {
      let textView = UITextView()
      textView.delegate = context.coordinator
      textView.isScrollEnabled = configuration.isScrollEnabled
      textView.isEditable = configuration.isEditable
      textView.autocorrectionType = configuration.autocorrection ? .yes : .no
      textView.backgroundColor = context.coordinator.resolved.backgroundColor
      textView.textContainerInset = configuration.contentInsets.uiEdgeInsets
      textView.textContainer.lineFragmentPadding = 0
      textView.adjustsFontForContentSizeCategory = true
      textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
      textView.setContentHuggingPriority(.defaultLow, for: .horizontal)

      if let cursorColor = context.coordinator.resolved.cursorColor {
        textView.tintColor = cursorColor
      }

      textView.text = text
      context.coordinator.applyStyling(to: textView)
      return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
      context.coordinator.update(configuration: configuration)

      if textView.text != text {
        textView.text = text
      }

      let resolved = context.coordinator.resolved

      if textView.isEditable != resolved.isEditable {
        textView.isEditable = resolved.isEditable
      }

      if textView.isScrollEnabled != resolved.isScrollEnabled {
        textView.isScrollEnabled = resolved.isScrollEnabled
      }

      if textView.autocorrectionType == .no && resolved.autocorrection {
        textView.autocorrectionType = .yes
      } else if textView.autocorrectionType != .no && !resolved.autocorrection {
        textView.autocorrectionType = .no
      }

      let insets = resolved.contentInsets.uiEdgeInsets
      if textView.textContainerInset != insets {
        textView.textContainerInset = insets
      }

      if textView.backgroundColor != resolved.backgroundColor {
        textView.backgroundColor = resolved.backgroundColor
      }

      if let cursorColor = resolved.cursorColor, textView.tintColor != cursorColor {
        textView.tintColor = cursorColor
      }

      context.coordinator.applyStyling(to: textView)
    }
    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
      @Binding var text: String
      private(set) var configuration: MarkdownComposerConfiguration
      private(set) var resolved: MarkdownComposerConfiguration.Resolved
      private var isApplyingStyle = false

      init(text: Binding<String>, configuration: MarkdownComposerConfiguration) {
        _text = text
        self.configuration = configuration
        self.resolved = configuration.resolved()
        super.init()
      }

      func update(configuration: MarkdownComposerConfiguration) {
        guard configuration != self.configuration else { return }
        self.configuration = configuration
        self.resolved = configuration.resolved()
      }

      func applyStyling(to textView: UITextView) {
        guard !isApplyingStyle else { return }
        isApplyingStyle = true
        let selectedRange = textView.selectedRange
        resolved.styler.apply(to: textView.textStorage)
        textView.selectedRange = selectedRange
        isApplyingStyle = false
      }

      func textViewDidChange(_ textView: UITextView) {
        text = textView.text
        applyStyling(to: textView)
      }
    }
  }
  #elseif canImport(AppKit)
  struct Representable: NSViewRepresentable {
    @Binding var text: String
    var configuration: MarkdownComposerConfiguration

    func makeCoordinator() -> Coordinator {
      Coordinator(text: $text, configuration: configuration)
    }

    func makeNSView(context: Context) -> NSScrollView {
      let scrollView = NSTextView.scrollableTextView()
      scrollView.hasVerticalScroller = configuration.isScrollEnabled
      scrollView.hasHorizontalScroller = false
      guard let textView = scrollView.documentView as? NSTextView else {
        return scrollView
      }

      textView.delegate = context.coordinator
      textView.isRichText = false
      textView.isEditable = configuration.isEditable
      textView.allowsUndo = true
      textView.usesAdaptiveColorMappingForDarkAppearance = true
      textView.textContainerInset = configuration.contentInsets.textContainerInset
      textView.textContainer?.lineFragmentPadding = 0
      textView.backgroundColor = context.coordinator.resolved.backgroundColor
      if let cursorColor = context.coordinator.resolved.cursorColor {
        textView.insertionPointColor = cursorColor
      }

      textView.string = text
      context.coordinator.applyStyling(to: textView)
      return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
      guard let textView = scrollView.documentView as? NSTextView else { return }

      context.coordinator.update(configuration: configuration)
      let resolved = context.coordinator.resolved

      scrollView.hasVerticalScroller = resolved.isScrollEnabled

      if textView.string != text {
        textView.string = text
      }

      if textView.isEditable != resolved.isEditable {
        textView.isEditable = resolved.isEditable
      }

    textView.backgroundColor = resolved.backgroundColor
    textView.textContainerInset = resolved.contentInsets.textContainerInset

      if let cursorColor = resolved.cursorColor {
        textView.insertionPointColor = cursorColor
      }

      context.coordinator.applyStyling(to: textView)
    }

  @MainActor
  final class Coordinator: NSObject, NSTextViewDelegate {
      @Binding var text: String
      private(set) var configuration: MarkdownComposerConfiguration
      private(set) var resolved: MarkdownComposerConfiguration.Resolved
      private var isApplyingStyle = false

      init(text: Binding<String>, configuration: MarkdownComposerConfiguration) {
        _text = text
        self.configuration = configuration
        self.resolved = configuration.resolved()
      }

      func update(configuration: MarkdownComposerConfiguration) {
        guard configuration != self.configuration else { return }
        self.configuration = configuration
        self.resolved = configuration.resolved()
      }

      func applyStyling(to textView: NSTextView) {
        guard !isApplyingStyle else { return }
        isApplyingStyle = true
        let selectedRanges = textView.selectedRanges
        if let textStorage = textView.textStorage {
          resolved.styler.apply(to: textStorage)
        }
        textView.selectedRanges = selectedRanges
        isApplyingStyle = false
      }

      func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        text = textView.string
        applyStyling(to: textView)
      }
    }
  }
  #endif
}
