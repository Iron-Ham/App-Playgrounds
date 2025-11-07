import SwiftUI

struct ContentView: View {
  @EnvironmentObject private var store: MailStore

  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var selectedMailbox: Mailbox?
  @State private var selectedMessage: Message?
  @State private var isShowingComposeSheet = false

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      mailboxList
    } content: {
      messageList
    } detail: {
      messageDetail
        .toolbar { toolbarContent }
    }
    .task { configureInitialSelectionIfNeeded() }
    .onChange(of: selectedMailbox) { _, newValue in
      updateSelection(for: newValue)
    }
    .sheet(isPresented: $isShowingComposeSheet) {
      composeSheet()
    }
  }

  private var mailboxList: some View {
    List(store.mailboxes, selection: $selectedMailbox) { mailbox in
      HStack {
        Label(mailbox.displayName, systemImage: mailbox.icon)
        Spacer()
        if mailbox.unreadCount > 0 {
          Text("\(mailbox.unreadCount)")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
      .tag(Optional(mailbox))
    }
    .navigationTitle("Mailboxes")
    .listStyle(.sidebar)
  }

  private var messageList: some View {
    let messages = store.messages(for: selectedMailbox)

    return List(messages, selection: $selectedMessage) { message in
      MessageRow(message: message)
        .contentShape(Rectangle())
        .tag(Optional(message))
        .contextMenu {
          Button {
            SceneCoordinator.activateMessageScene(for: message.id)
          } label: {
            Label("Open in New Window", systemImage: "uiwindow.split.2x1")
          }
        }
    }
    .navigationTitle(selectedMailbox?.displayName ?? "Messages")
    .overlay {
      if messages.isEmpty {
        PlaceholderView(title: "No Mail", subtitle: "Messages for this mailbox appear here.")
      }
    }
    .listStyle(.plain)
  }

  private var messageDetail: some View {
    Group {
      if let message = selectedMessage {
        MessageDetailView(message: message)
          .navigationTitle(message.subject)
          .navigationBarTitleDisplayMode(.inline)
      } else {
        PlaceholderView(title: "Select a Message", subtitle: "Choose a conversation to read.")
      }
    }
    .background(Color(uiColor: .systemBackground))
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItemGroup(placement: .topBarTrailing) {
      if let message = selectedMessage {
        Button {
          SceneCoordinator.activateMessageScene(for: message.id)
        } label: {
          Label("Open Window", systemImage: "uiwindow.split.2x1")
        }
        .disabled(!SceneCoordinator.canActivateAdditionalScenes)
      }

      Button {
        if SceneCoordinator.canActivateAdditionalScenes {
          SceneCoordinator.activateComposeScene()
        } else {
          isShowingComposeSheet = true
        }
      } label: {
        Label("Compose", systemImage: "square.and.pencil")
      }
      .keyboardShortcut("n", modifiers: [.command])
    }
  }

  private func updateSelection(for mailbox: Mailbox?) {
    guard let mailbox else {
      selectedMessage = nil
      return
    }

    let messages = store.messages(for: mailbox)
    if let current = selectedMessage, messages.contains(current) {
      return
    }
    selectedMessage = messages.first
  }

  private func configureInitialSelectionIfNeeded() {
    guard selectedMailbox == nil else { return }
    selectedMailbox = store.defaultMailbox
    selectedMessage = store.messages(for: selectedMailbox).first
  }

  private func composeSheet() -> some View {
    ComposeView(onClose: { isShowingComposeSheet = false })
      .environmentObject(store)
  }
}

struct MessageRow: View {
  let message: Message

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(message.senderName)
          .font(.headline)
        Spacer()
        Text(message.formattedReceivedAt)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text(message.subject)
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(message.isUnread ? .primary : .secondary)

      Text(message.preview)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
    .padding(.vertical, 8)
  }
}

struct MessageDetailView: View {
  let message: Message

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text(message.subject)
            .font(.title2.weight(.semibold))
          HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
              Text(message.senderName)
                .font(.headline)
              Text(message.senderEmail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(message.formattedReceivedAt)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
        }

        Divider()

        Text(message.body)
          .font(.body)
          .foregroundStyle(.primary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(24)
    }
    .background(Color(uiColor: .secondarySystemBackground))
  }
}

struct PlaceholderView: View {
  var title: String
  var subtitle: String

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "envelope.open")
        .font(.largeTitle)
        .foregroundStyle(.tertiary)
      Text(title)
        .font(.headline)
        .foregroundStyle(.secondary)
      Text(subtitle)
        .font(.subheadline)
        .foregroundStyle(.tertiary)
    }
    .multilineTextAlignment(.center)
    .padding()
  }
}

struct MessageSceneView: View {
  let messageID: Message.ID?
  @EnvironmentObject private var store: MailStore

  var body: some View {
    NavigationStack {
      Group {
        if let messageID, let message = store.message(id: messageID) {
          MessageDetailView(message: message)
            .navigationTitle(message.subject)
            .navigationBarTitleDisplayMode(.inline)
        } else {
          PlaceholderView(
            title: "Message Unavailable",
            subtitle: "It may have been removed or moved to another mailbox."
          )
        }
      }
      .frame(minWidth: 360, minHeight: 480)
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(MailStore.makePreviewStore())
}
