import SwiftUI

struct MessageDetailView: View {
  let message: Message

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text(message.subject)
            .font(.title2.weight(.semibold))
          if message.isFlagged {
            Label("Flagged", systemImage: "flag.fill")
              .font(.footnote)
              .foregroundStyle(.orange)
          }
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

struct MessageInspectorView: View {
  let message: Message
  @EnvironmentObject private var store: MailStore

  var body: some View {
    Form {
      Section("Summary") {
        LabeledContent("Mailbox", value: mailboxDisplayName)
        LabeledContent("Received", value: receivedAtDescription)
      }

      Section("Sender") {
        LabeledContent("Name", value: message.senderName)
        LabeledContent("Email", value: message.senderEmail)
      }

      Section("Status") {
        Label(
          message.isUnread ? "Unread" : "Read",
          systemImage: message.isUnread ? "envelope.badge" : "envelope.open"
        )
        Label(
          message.isFlagged ? "Flagged" : "Not Flagged",
          systemImage: message.isFlagged ? "flag.fill" : "flag.slash"
        )
      }

      Section("Identifiers") {
        LabeledContent("Message ID", value: message.id.uuidString)
      }
    }
    .formStyle(.grouped)
    .frame(minWidth: 260)
  }

  private var mailboxDisplayName: String {
    store.mailbox(id: message.mailboxID)?.displayName ?? message.mailboxID
  }

  private var receivedAtDescription: String {
    message.receivedAt.formatted(date: .abbreviated, time: .shortened)
  }
}
