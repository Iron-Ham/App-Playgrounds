import SwiftUI

struct ComposeView: View {
  var onClose: () -> Void = {}
  @State private var toField: String = ""
  @State private var ccField: String = ""
  @State private var subject: String = ""
  @State private var messageBody: String = ""
  @FocusState private var focusedField: Field?

  private enum Field: Hashable {
    case to
    case cc
    case subject
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        headers
        Divider()
        TextEditor(text: $messageBody)
          .font(.body)
          .padding([.leading, .trailing], 12)
          .padding(.top, 8)
          .scrollContentBackground(.hidden)
          .background(Color(uiColor: .systemBackground))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(uiColor: .systemBackground))
      .navigationTitle("New Message")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarRole(.editor)
      .toolbar { toolbar }
      .task {
        if toField.isEmpty {
          focusedField = .to
        }
      }
    }
    .background(Color(uiColor: .systemBackground))
    .frame(minWidth: 420, minHeight: 520)
  }

  private var headers: some View {
    VStack(spacing: 0) {
      ComposeField(title: "To", text: $toField)
        .focused($focusedField, equals: .to)
      Divider()
      ComposeField(title: "Cc/Bcc", text: $ccField)
        .focused($focusedField, equals: .cc)
      Divider()
      ComposeField(title: "Subject", text: $subject)
        .focused($focusedField, equals: .subject)
    }
    .textInputAutocapitalization(.never)
    .disableAutocorrection(true)
  }

  @ToolbarContentBuilder
  private var toolbar: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button("Cancel") { onClose() }
    }
    ToolbarItem(placement: .navigationBarTrailing) {
      Button("Send") {
        onClose()
      }
      .keyboardShortcut(.return, modifiers: [.command])
      .disabled(toField.isEmpty || subject.isEmpty)
    }
  }
}

private struct ComposeField: View {
  var title: String
  @Binding var text: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Text(title)
        .font(.subheadline)
        .frame(width: 90, alignment: .trailing)
        .foregroundStyle(.secondary)
      TextField("", text: $text, axis: .vertical)
        .textFieldStyle(.plain)
        .font(.body)
        .frame(maxWidth: .infinity)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
  }
}

#Preview {
  ComposeView()
}

extension ComposeView {
  static let preferredWindowSize = CGSize(width: 600, height: 680)
}
