import SwiftUI

struct ContentView: View {
  @EnvironmentObject private var store: MailStore

  @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
  @SceneStorage("ContentView.selectedMailboxID") private var selectedMailboxID: Mailbox.ID?
  @SceneStorage("ContentView.selectedMessageID") private var selectedMessageID: String?
  @State private var isShowingComposeSheet = false

  private var selectedMailbox: Mailbox? {
    guard let id = selectedMailboxID else { return nil }
    return store.mailbox(id: id)
  }

  private var selectedMessage: Message? {
    guard
      let idString = selectedMessageID,
      let uuid = UUID(uuidString: idString)
    else { return nil }
    return store.message(id: uuid)
  }

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
    .onChange(of: selectedMailboxID) { _, newValue in
      updateSelection(for: newValue)
    }
    .sheet(isPresented: $isShowingComposeSheet) {
      composeSheet()
    }
  }

  private var mailboxList: some View {
    List(store.mailboxes, selection: $selectedMailboxID) { mailbox in
      HStack {
        Label(mailbox.displayName, systemImage: mailbox.icon)
        Spacer()
        if mailbox.unreadCount > 0 {
          Text("\(mailbox.unreadCount)")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
      .tag(mailbox.id)
    }
    .navigationTitle("Mailboxes")
    .listStyle(.sidebar)
  }

  private var messageList: some View {
    let messages = store.messages(for: selectedMailbox)

    return List(messages, selection: $selectedMessageID) { message in
      MessageRow(message: message)
        .contentShape(Rectangle())
        .tag(message.id.uuidString)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
          Button {
            store.setMessage(message.id, isUnread: !message.isUnread)
          } label: {
            Label(
              message.isUnread ? "Mark as Read" : "Mark as Unread",
              systemImage: message.isUnread ? "envelope.open" : "envelope.badge"
            )
          }
          .tint(.blue)
        }
        .swipeActions {
          Button {
            store.toggleFlag(for: message.id)
          } label: {
            Label(
              message.isFlagged ? "Remove Flag" : "Flag",
              systemImage: message.isFlagged ? "flag.slash" : "flag"
            )
          }
          .tint(.orange)
        }
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
        ContentUnavailableView(
          "No Mail",
          systemImage: "envelope.open",
          description: Text(
            "Messages for this mailbox appear here."
          )
        )
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
        ContentUnavailableView(
          "Select a Message",
          systemImage: "envelope.open",
          description: Text(
            "Choose a conversation to read."
          )
        )
      }
    }
    .background(Color(uiColor: .systemBackground))
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItemGroup {
      if let message = selectedMessage {
        Button {
          store.setMessage(message.id, isUnread: !message.isUnread)
        } label: {
          Label(
            message.isUnread ? "Mark as Read" : "Mark as Unread",
            systemImage: message.isUnread ? "envelope.open" : "envelope.badge"
          )
        }

        Button {
          store.toggleFlag(for: message.id)
        } label: {
          Label(
            message.isFlagged ? "Remove Flag" : "Flag",
            systemImage: message.isFlagged ? "flag.slash" : "flag"
          )
        }
      }
    }
    ToolbarSpacer(.flexible)
    ToolbarItem {
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

  private func updateSelection(for mailboxID: Mailbox.ID?) {
    guard let mailboxID, let mailbox = store.mailbox(id: mailboxID) else {
      selectedMessageID = nil
      return
    }

    let messages = store.messages(for: mailbox)
    if let currentID = selectedMessageID,
      messages.contains(where: { $0.id.uuidString == currentID })
    {
      return
    }

    selectedMessageID = messages.first?.id.uuidString
  }

  private func configureInitialSelectionIfNeeded() {
    if let storedMailboxID = selectedMailboxID,
      store.mailbox(id: storedMailboxID) == nil
    {
      selectedMailboxID = nil
    }

    if selectedMailboxID == nil, let mailbox = store.defaultMailbox {
      selectedMailboxID = mailbox.id
    }

    if let mailbox = selectedMailbox {
      if let identifier = selectedMessageID,
        let uuid = UUID(uuidString: identifier),
        store.message(id: uuid) != nil
      {
        return
      }

      selectedMessageID = store.messages(for: mailbox).first?.id.uuidString
    }
  }

  private func composeSheet() -> some View {
    ComposeView(onClose: { isShowingComposeSheet = false })
      .environmentObject(store)
  }
}

#Preview {
  ContentView()
    .environmentObject(MailStore.makePreviewStore())
}
