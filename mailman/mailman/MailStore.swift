import Combine
import Foundation

struct Mailbox: Identifiable, Hashable, Codable {
  typealias ID = String

  let id: ID
  var displayName: String
  var icon: String
  var unreadCount: Int

  static let allInboxesID = "allInboxes"
}

struct Message: Identifiable, Hashable, Codable {
  let id: UUID
  let mailboxID: Mailbox.ID
  var senderName: String
  var senderEmail: String
  var subject: String
  var preview: String
  var body: String
  var receivedAt: Date
  var isUnread: Bool
  var isFlagged: Bool

  var formattedReceivedAt: String {
    Message.dateFormatter.string(from: receivedAt)
  }

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }()
}

@MainActor
final class MailStore: ObservableObject {
  static let shared = MailStore()

  @Published private(set) var mailboxes: [Mailbox]
  @Published private var messagesByMailbox: [Mailbox.ID: [Message]]

  private init(isPreview: Bool = false) {
    let now = Date()
    let messages = Self.makeSampleMessages(anchor: now)
    self.messagesByMailbox = Dictionary(grouping: messages, by: { $0.mailboxID })

    var mailboxes = Self.makeSampleMailboxes()
    for index in mailboxes.indices {
      let id = mailboxes[index].id
      let unread = Self.unreadCount(for: id, within: messages)
      mailboxes[index].unreadCount = unread
    }
    if let aggregateIndex = mailboxes.firstIndex(where: { $0.id == Mailbox.allInboxesID }) {
      let unread = messages.filter { $0.isUnread }.count
      mailboxes[aggregateIndex].unreadCount = unread
    }
    self.mailboxes = mailboxes
  }

  static func makePreviewStore() -> MailStore {
    MailStore(isPreview: true)
  }

  var defaultMailbox: Mailbox? {
    mailbox(id: Mailbox.allInboxesID) ?? mailboxes.first
  }

  func mailbox(id: Mailbox.ID) -> Mailbox? {
    mailboxes.first(where: { $0.id == id })
  }

  func messages(for mailbox: Mailbox?) -> [Message] {
    guard let mailbox else { return [] }
    if mailbox.id == Mailbox.allInboxesID {
      return messagesByMailbox.values
        .flatMap { $0 }
        .sorted(by: { $0.receivedAt > $1.receivedAt })
    } else {
      return (messagesByMailbox[mailbox.id] ?? [])
        .sorted(by: { $0.receivedAt > $1.receivedAt })
    }
  }

  func message(id: Message.ID) -> Message? {
    messagesByMailbox.values
      .flatMap { $0 }
      .first(where: { $0.id == id })
  }

  private static func unreadCount(for mailboxID: Mailbox.ID, within messages: [Message]) -> Int {
    messages
      .filter { $0.mailboxID == mailboxID && $0.isUnread }
      .count
  }

  private static func makeSampleMailboxes() -> [Mailbox] {
    [
      Mailbox(
        id: Mailbox.allInboxesID,
        displayName: "All Inboxes",
        icon: "tray.full",
        unreadCount: 0
      ),
      Mailbox(id: "icloud", displayName: "iCloud", icon: "icloud", unreadCount: 0),
      Mailbox(id: "gmail", displayName: "Gmail", icon: "envelope", unreadCount: 0),
      Mailbox(id: "vip", displayName: "VIP", icon: "star", unreadCount: 0),
    ]
  }

  private static func makeSampleMessages(anchor now: Date) -> [Message] {
    [
      Message(
        id: UUID(),
        mailboxID: "icloud",
        senderName: "Zoom",
        senderEmail: "no-reply@zoom.com",
        subject: "Meeting assets for iOS Team Meeting are ready",
        preview: "Meeting summary quick recap of the decisions from today...",
        body: Self.makeBody(
          intro: "Hi Hesham,",
          paragraphs: [
            "Thanks for joining the iOS Team Meeting earlier today.",
            "We attached the deck, meeting recording, and the list of follow-up items for the next sprint.",
            "Let us know if you need anything else before the beta cut.",
          ],
          outro: "— Zoom Team"
        ),
        receivedAt: now.addingTimeInterval(-60 * 60),
        isUnread: true,
        isFlagged: false
      ),
      Message(
        id: UUID(),
        mailboxID: "gmail",
        senderName: "John Smith",
        senderEmail: "johnsmith@example.com",
        subject: "Invitation: iOS Tech Discussion",
        preview: "You have been invited to attend an event named iOS Tech Discussion...",
        body: Self.makeBody(
          intro: "Hey Hesham,",
          paragraphs: [
            "I would love for you to join the weekly iOS Tech Discussion next Thursday.",
            "We are covering multi-window best practices on iPad and would value your insights.",
          ],
          outro: "Talk soon,\nJohn"
        ),
        receivedAt: now.addingTimeInterval(-2 * 60 * 60),
        isUnread: false,
        isFlagged: true
      ),
      Message(
        id: UUID(),
        mailboxID: "gmail",
        senderName: "Sally Jones",
        senderEmail: "Sally@example.com",
        subject: "Updated invitation: Email Experiences Town Hall",
        preview: "As we are still getting final confirmations, here is the updated agenda...",
        body: Self.makeBody(
          intro: "Hi Hesham,",
          paragraphs: [
            "We pushed the Email Experiences Town Hall back by 30 minutes to accommodate the leadership sync.",
            "A fresh calendar invite is attached below with the new dial-in details.",
            "Appreciate you sharing the updates with your team.",
          ],
          outro: "Best,\nSally"
        ),
        receivedAt: now.addingTimeInterval(-3 * 60 * 60 - 600),
        isUnread: true,
        isFlagged: false
      ),
      Message(
        id: UUID(),
        mailboxID: "icloud",
        senderName: "Neon Team",
        senderEmail: "coteam@neon.tech",
        subject: "Update to your Neon Free Plan via Vercel Marketplace",
        preview:
          "We’re notifying you about an update to the limits of your Neon Postgres database account...",
        body: Self.makeBody(
          intro: "Hello Hesham,",
          paragraphs: [
            "We updated the free plan limits to include 30 projects, 100 compute-hours, and 0.5 GB per project.",
            "Paid plans now start at $5/month and are fully usage-based.",
          ],
          outro: "Regards,\nThe Neon Team"
        ),
        receivedAt: now.addingTimeInterval(-60 * 60 * 24),
        isUnread: false,
        isFlagged: false
      ),
      Message(
        id: UUID(),
        mailboxID: "vip",
        senderName: "Robert Lamport",
        senderEmail: "robert@example.com",
        subject: "Updated invitation: Email Pioneers Speaker Series",
        preview: "This event will be recorded and shared for those who cannot attend live...",
        body: Self.makeBody(
          intro: "Hi Hesham,",
          paragraphs: [
            "We locked in the final speaker lineup for Email Pioneers.",
            "Let me know if you want time on the agenda for the Mailman demo.",
          ],
          outro: "Cheers,\nRobert"
        ),
        receivedAt: now.addingTimeInterval(-60 * 60 * 26),
        isUnread: true,
        isFlagged: true
      ),
    ]
  }

  private static func makeBody(intro: String, paragraphs: [String], outro: String) -> String {
    ([intro] + paragraphs + [outro]).joined(separator: "\n\n")
  }
}
