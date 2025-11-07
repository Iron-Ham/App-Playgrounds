import SwiftUI

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
          ContentUnavailableView(
            "Message Unavailable",
            systemImage: "envelope.open",
            description: Text(
              "It may have been removed or moved to another mailbox."
            )
          )
        }
      }
      .frame(minWidth: 360, minHeight: 480)
    }
  }
}
