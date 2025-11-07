import SwiftUI

struct ContentView: View {
  @EnvironmentObject private var store: MailStore

  @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
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
      .tag(mailbox)
    }
    .navigationTitle("Mailboxes")
    .listStyle(.sidebar)
  }

  private var messageList: some View {
    let messages = store.messages(for: selectedMailbox)

    return List(messages, selection: $selectedMessage) { message in
      MessageRow(message: message)
        .contentShape(Rectangle())
        .tag(message)
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

#Preview {
  ContentView()
    .environmentObject(MailStore.makePreviewStore())
}
