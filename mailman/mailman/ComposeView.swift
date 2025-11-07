import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ComposeView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var store: MailStore
  @State private var toField: String = ""
  @State private var ccField: String = ""
  @State private var subject: String = ""
  @State private var messageBody: AttributedString = ""
  @State private var isSending = false
  @State private var alert: ComposeAlert?
  @State private var attachments: [AttachmentItem] = []
  @State private var isPresentingAttachmentImporter = false
  @State private var mediaPickerItems: [PhotosPickerItem] = []
  @FocusState private var focusedField: Field?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {
          headers
          Divider()
          TextEditor(text: $messageBody)
            .textInputFormattingControlVisibility(.hidden, for: .inputAssistant)
            .toolbar {
              ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button {
                  isPresentingAttachmentImporter = true
                } label: {
                  Label("Attachment…", systemImage: "paperclip")
                }
                .disabled(isSending)
                PhotosPicker(
                  selection: $mediaPickerItems,
                  matching: .any(of: [.images, .videos])
                ) {
                  Label("Photo/Video…", systemImage: "photo.on.rectangle")
                }
                .disabled(isSending)
              }
            }
            .scrollDisabled(true)
            .font(.body)
            .padding([.leading, .trailing], 12)
            .padding(.top, 8)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemBackground))
            .frame(maxWidth: .infinity, minHeight: 320, maxHeight: .infinity)
          if !attachments.isEmpty {
            Divider()
            attachmentsSection
          }
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
    .fileImporter(
      isPresented: $isPresentingAttachmentImporter,
      allowedContentTypes: [.item],
      allowsMultipleSelection: true
    ) { result in
      handleAttachmentImport(result)
    }
    .onChange(of: mediaPickerItems) { _, newItems in
      handleMediaSelection(newItems)
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

  private var attachmentsSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Attachments")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: 12) {
          ForEach(attachments) { item in
            AttachmentCard(item: item) {
              removeAttachment(item)
            }
            .frame(width: 240)
          }
        }
        .padding(.vertical, 4)
      }
    }
    .padding(.horizontal, 12)
    .padding(.top, 12)
    .padding(.bottom, 16)
  }

  @ToolbarContentBuilder
  private var toolbar: some ToolbarContent {
    if UIDevice.current.userInterfaceIdiom == .phone {
      ToolbarItem(placement: .navigationBarLeading) {
        Button("Cancel") { dismiss() }
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
    let draftBody = composedBodyWithAttachments()

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
          dismiss()
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
    attachments = []
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

  private func handleAttachmentImport(_ result: Result<[URL], Error>) {
    do {
      let urls = try result.get()
      let newItems = urls.map { AttachmentItem(url: $0) }
      attachments.append(contentsOf: newItems)
    } catch {
      alert = ComposeAlert(title: "Unable to Add Attachments", message: error.localizedDescription)
    }
  }

  private func handleMediaSelection(_ items: [PhotosPickerItem]) {
    guard !items.isEmpty else { return }

    Task {
      var imported: [AttachmentItem] = []
      var firstError: Error?

      for item in items {
        do {
          if let attachment = try await importMediaItem(item) {
            imported.append(attachment)
          }
        } catch {
          if firstError == nil {
            firstError = error
          }
        }
      }

      await MainActor.run {
        if !imported.isEmpty {
          attachments.append(contentsOf: imported)
        }
        mediaPickerItems = []
        if let error = firstError {
          alert = ComposeAlert(
            title: "Unable to Add Media",
            message: error.localizedDescription
          )
        }
      }
    }
  }

  private func importMediaItem(_ item: PhotosPickerItem) async throws -> AttachmentItem? {
    guard let data = try await item.loadTransferable(type: Data.self) else {
      return nil
    }

    let contentType = item.supportedContentTypes.first ?? .data
    let fileExtension = contentType.preferredFilenameExtension ?? "dat"
    let fileName = makeFilename(for: item, preferredExtension: fileExtension)
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(fileName)
    try data.write(to: tempURL, options: [.atomic])
    return AttachmentItem(url: tempURL, contentType: contentType, displayName: fileName)
  }

  private func makeFilename(for item: PhotosPickerItem, preferredExtension ext: String) -> String {
    let rawBase =
      item.itemIdentifier?.split(separator: "/").last.map(String.init)
      ?? "Attachment"
    let sanitizedBase = sanitizeFilename(rawBase)
    let base = sanitizedBase.isEmpty ? "Attachment" : sanitizedBase
    return "\(base)-\(UUID().uuidString.prefix(6)).\(ext)"
  }

  private func sanitizeFilename(_ value: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
    let scalars = value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
    let collapsed = String(scalars)
      .replacingOccurrences(of: "-{2,}", with: "-", options: .regularExpression)
    return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-_ "))
  }

  private func removeAttachment(_ attachment: AttachmentItem) {
    attachments.removeAll { $0.id == attachment.id }
  }

  private func composedBodyWithAttachments() -> AttributedString {
    guard !attachments.isEmpty else { return messageBody }

    var combined = messageBody
    if !combined.characters.isEmpty {
      combined.append(AttributedString("\n\n"))
    }

    let header = AttributedString("Attachments:\n")
    combined.append(header)

    let names = attachments.map { "• \($0.displayName)" }.joined(separator: "\n")
    combined.append(AttributedString(names))

    return combined
  }

  private func insertSignature() {
    appendToBodyIfNeeded(prefixSpacing: true, text: "—\nYou")
  }

  private func insertCurrentDate() {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .short
    let dateString = formatter.string(from: Date())
    appendToBodyIfNeeded(prefixSpacing: true, text: dateString)
  }

  private func insertQuote() {
    appendToBodyIfNeeded(prefixSpacing: true, text: "> ")
  }

  private func appendToBodyIfNeeded(prefixSpacing: Bool, text: String) {
    let additions = AttributedString(text)
    var updated = messageBody
    if prefixSpacing, !updated.characters.isEmpty {
      updated.append(AttributedString("\n\n"))
    }
    updated.append(additions)
    messageBody = updated
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

private struct AttachmentCard: View {
  var item: AttachmentItem
  var onRemove: () -> Void

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      AttachmentPreview(item: item)
        .frame(width: 56, height: 56)

      VStack(alignment: .leading, spacing: 4) {
        Text(item.displayName)
          .font(.callout)
          .lineLimit(1)
        if let subtitle = item.subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer(minLength: 8)

      Button(action: onRemove) {
        Image(systemName: "xmark.circle.fill")
          .symbolRenderingMode(.hierarchical)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Remove attachment \(item.displayName)")
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(.thinMaterial)
    )
  }
}

private struct AttachmentPreview: View {
  var item: AttachmentItem
  @State private var previewImage: Image?

  var body: some View {
    ZStack(alignment: .topTrailing) {
      previewContent
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
        )

      if let badge = item.badgeText {
        Text(badge)
          .font(.caption.bold())
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(.thinMaterial, in: Capsule())
          .offset(x: -6, y: 6)
      }
    }
    .aspectRatio(1, contentMode: .fit)
    .onAppear(perform: loadPreviewIfNeeded)
  }

  @ViewBuilder
  private var previewContent: some View {
    if let previewImage {
      previewImage
        .resizable()
        .scaledToFill()
        .clipped()
    } else if item.isVideo {
      ZStack {
        Color(uiColor: .systemGray5)
        Image(systemName: "play.rectangle.fill")
          .font(.title2)
          .foregroundStyle(.secondary)
      }
    } else {
      ZStack {
        Color(uiColor: .systemGray5)
        Image(systemName: "doc.fill")
          .font(.title2)
          .foregroundStyle(.secondary)
      }
    }
  }

  private func loadPreviewIfNeeded() {
    guard previewImage == nil, item.isImage else { return }

    Task(priority: .userInitiated) {
      guard previewImage == nil else { return }
      if let uiImage = UIImage(contentsOfFile: item.url.path) {
        let image = Image(uiImage: uiImage)
        await MainActor.run {
          previewImage = image
        }
      }
    }
  }
}

private struct AttachmentItem: Identifiable {
  let id = UUID()
  let url: URL
  let contentType: UTType?
  let displayName: String
  let fileSize: Int?

  init(url: URL, contentType: UTType? = nil, displayName: String? = nil) {
    self.url = url

    let resourceValues = try? url.resourceValues(
      forKeys: [.fileSizeKey, .contentTypeKey, .nameKey]
    )

    self.fileSize = resourceValues?.fileSize

    if let displayName {
      self.displayName = displayName
    } else if let name = resourceValues?.name {
      self.displayName = name
    } else {
      self.displayName = url.lastPathComponent
    }

    let resolvedContentType =
      contentType ?? resourceValues?.contentType
      ?? UTType(filenameExtension: url.pathExtension)
    self.contentType = resolvedContentType
  }

  var subtitle: String? {
    switch (contentType?.localizedDescription, fileSizeDescription) {
    case (let description?, let size?):
      return "\(description) • \(size)"
    case (let description?, nil):
      return description
    case (nil, let size?):
      return size
    default:
      return nil
    }
  }

  var badgeText: String? {
    if let ext = contentType?.preferredFilenameExtension, !ext.isEmpty {
      return ext.uppercased()
    }
    let fallback = url.pathExtension
    return fallback.isEmpty ? nil : fallback.uppercased()
  }

  var isImage: Bool {
    contentType?.conforms(to: .image) ?? false
  }

  var isVideo: Bool {
    contentType?.conforms(to: .movie) ?? false
  }

  private var fileSizeDescription: String? {
    guard let fileSize else { return nil }
    return Self.byteCountFormatter.string(fromByteCount: Int64(fileSize))
  }

  private static let byteCountFormatter: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .file
    return formatter
  }()
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
