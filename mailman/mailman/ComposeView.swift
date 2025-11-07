import SwiftUI
import UIKit

struct ComposeView: View {
  @EnvironmentObject private var store: MailStore
  var onClose: () -> Void = {}
  @State private var toField: String = ""
  @State private var ccField: String = ""
  @State private var subject: String = ""
  @State private var messageBody: String = ""
  @State private var isSending = false
  @State private var alert: ComposeAlert?
  @FocusState private var focusedField: Field?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {
          headers
          Divider()
          TextEditor(text: $messageBody)
            .scrollDisabled(true)
            .font(.body)
            .padding([.leading, .trailing], 12)
            .padding(.top, 8)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemBackground))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .disabled(isSending)
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
    .alert(item: $alert) { item in
      Alert(
        title: Text(item.title),
        message: Text(item.message),
        dismissButton: .default(Text("OK"))
      )
    }
  }

  private var headers: some View {
    VStack(spacing: 0) {
      ComposeField(
        title: "To",
        text: $toField,
        textContentType: .emailAddress,
        keyboardType: .emailAddress
      )
      .focused($focusedField, equals: .to)
      Divider()
      ComposeField(
        title: "Cc/Bcc",
        text: $ccField,
        textContentType: .emailAddress,
        keyboardType: .emailAddress
      )
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
    if UIDevice.current.userInterfaceIdiom == .phone {
      ToolbarItem(placement: .navigationBarLeading) {
        Button("Cancel") { onClose() }
          .disabled(isSending)
      }
    }
    ToolbarItem(placement: .navigationBarTrailing) {
      if isSending {
        ProgressView()
      } else {
        Button("Send") {
          send()
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .disabled(isSendDisabled)
      }
    }
  }

  private var isSendDisabled: Bool {
    isSending || trimmed(toField).isEmpty || trimmed(subject).isEmpty
  }

  private func send() {
    guard !isSendDisabled else { return }

    isSending = true
    let draftTo = toField
    let draftCc = ccField
    let draftSubject = subject
    let draftBody = messageBody

    Task {
      do {
        try await store.sendDraft(
          to: draftTo,
          cc: draftCc,
          subject: draftSubject,
          body: draftBody
        )

        await MainActor.run {
          resetForm()
          isSending = false
          onClose()
        }
      } catch {
        await MainActor.run {
          isSending = false
          alert = ComposeAlert(
            title: "Unable to Send",
            message: errorMessage(for: error)
          )
        }
      }
    }
  }

  private func resetForm() {
    toField = ""
    ccField = ""
    subject = ""
    messageBody = ""
  }

  private func trimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func errorMessage(for error: Error) -> String {
    if let localized = error as? LocalizedError,
      let description = localized.errorDescription
    {
      return description
    }
    return error.localizedDescription
  }
}

private struct ComposeField: View {
  var title: String
  @Binding var text: String
  var textContentType: UITextContentType? = nil
  var keyboardType: UIKeyboardType = .default

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Text(title)
        .font(.subheadline)
        .frame(width: 90, alignment: .trailing)
        .foregroundStyle(.secondary)
      TextField("", text: $text, axis: .vertical)
        .textFieldStyle(.plain)
        .font(.body)
        .keyboardType(keyboardType)
        .textContentType(textContentType)
        .frame(maxWidth: .infinity)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
  }
}

extension ComposeView {
  private enum Field: Hashable {
    case to
    case cc
    case subject
  }

  private struct ComposeAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
  }
}

#Preview {
  ComposeView()
    .environmentObject(MailStore.makePreviewStore())
}
