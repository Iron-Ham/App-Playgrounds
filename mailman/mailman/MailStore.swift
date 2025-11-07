import Combine
import Foundation

struct Mailbox: Identifiable, Hashable, Codable {
  typealias ID = String

  let id: ID
  var displayName: String
  var icon: String
  var unreadCount: Int

  static let allInboxesID = "allInboxes"
  static let sentID = "sent"
}

struct Message: Identifiable, Hashable, Codable {
  let id: UUID
  let mailboxID: Mailbox.ID
  var senderName: String
  var senderEmail: String
  var subject: String
  var preview: String
  var body: AttributedString
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
  private let currentUser = (name: "You", email: "me@example.com")

  private init() {
    let now = Date()
    let messages = Self.makeSampleMessages(anchor: now)
    self.messagesByMailbox = Dictionary(grouping: messages, by: { $0.mailboxID })
    self.mailboxes = Self.makeSampleMailboxes()

    ensureMessageStorageExistsForConfiguredMailboxes()
    recalculateMailboxMetadata()
  }

  static func makePreviewStore() -> MailStore {
    MailStore()
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
      return
        messagesByMailbox
        .filter { $0.key != Mailbox.sentID }
        .values
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

  enum DraftError: LocalizedError, Equatable {
    case missingRecipients
    case invalidAddress(String)

    var errorDescription: String? {
      switch self {
      case .missingRecipients:
        "Add at least one valid email address."
      case .invalidAddress(let address):
        "\(address) doesn’t look like a valid email address."
      }
    }
  }

  func sendDraft(
    to rawTo: String,
    cc rawCc: String,
    subject rawSubject: String,
    body rawBody: AttributedString
  )
    async throws
  {
    let toRecipients = try parseRecipients(from: rawTo, allowEmpty: false)
    let ccRecipients = try parseRecipients(from: rawCc, allowEmpty: true)

    // Mirror the async shape of a real network call to reinforce structured concurrency.
    try await Task.sleep(for: .milliseconds(250))

    let normalizedSubject = rawSubject.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalizedBody = Self.trimmedBody(rawBody)

    let newMessage = Message(
      id: UUID(),
      mailboxID: Mailbox.sentID,
      senderName: currentUser.name,
      senderEmail: currentUser.email,
      subject: normalizedSubject.isEmpty ? "(No Subject)" : normalizedSubject,
      preview: Self.makePreviewText(from: normalizedBody),
      body: Self.composeBody(
        to: toRecipients,
        cc: ccRecipients,
        originalBody: normalizedBody
      ),
      receivedAt: Date(),
      isUnread: false,
      isFlagged: false
    )

    messagesByMailbox[Mailbox.sentID, default: []].insert(newMessage, at: 0)
    recalculateMailboxMetadata()
  }

  func setMessage(_ id: Message.ID, isUnread: Bool) {
    mutateMessage(id: id) { message, mailboxID in
      guard message.isUnread != isUnread else { return }
      message.isUnread = isUnread
    }
  }

  func toggleFlag(for id: Message.ID) {
    mutateMessage(id: id) { message, _ in
      message.isFlagged.toggle()
    }
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
      Mailbox(id: Mailbox.sentID, displayName: "Sent", icon: "paperplane", unreadCount: 0),
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
      Message(
        id: UUID(),
        mailboxID: Mailbox.sentID,
        senderName: "You",
        senderEmail: "me@example.com",
        subject: "Mailman onboarding notes",
        preview: "Recapping the talking points for the next Mailman walkthrough...",
        body: Self.makeBody(
          intro: "Hi Team,",
          paragraphs: [
            "Thanks for joining the walkthrough earlier today.",
            "Attached is the latest deck along with a summary of open action items.",
          ],
          outro: "Best,\nYou"
        ),
        receivedAt: now.addingTimeInterval(-60 * 60 * 12),
        isUnread: false,
        isFlagged: false
      ),
    ]
  }

  private static func makeBody(intro: String, paragraphs: [String], outro: String)
    -> AttributedString
  {
    var result = AttributedString()
    let segments = [intro] + paragraphs + [outro]

    for (index, segment) in segments.enumerated() {
      if index > 0 {
        result.append(AttributedString("\n\n"))
      }
      result.append(AttributedString(segment))
    }

    return result
  }

  private static func makePreviewText(from body: AttributedString) -> String {
    let plain = String(body.characters)
    guard !plain.isEmpty else { return "No additional details." }
    return plain.split(separator: "\n").first.map(String.init) ?? plain
  }

  private static func trimmedBody(_ body: AttributedString) -> AttributedString {
    var trimmed = body

    while let first = trimmed.characters.first, isWhitespaceOrNewline(first) {
      let next = trimmed.index(afterCharacter: trimmed.startIndex)
      trimmed.removeSubrange(trimmed.startIndex..<next)
    }

    while let last = trimmed.characters.last, isWhitespaceOrNewline(last) {
      let before = trimmed.index(beforeCharacter: trimmed.endIndex)
      trimmed.removeSubrange(before..<trimmed.endIndex)
    }

    return trimmed
  }

  private static func isWhitespaceOrNewline(_ character: Character) -> Bool {
    character.isWhitespace || character.isNewline
  }

  private static func composeBody(
    to recipients: [String],
    cc: [String],
    originalBody: AttributedString
  ) -> AttributedString {
    var headerLines: [String] = ["To: \(recipients.joined(separator: ", "))"]
    if !cc.isEmpty {
      headerLines.append("Cc: \(cc.joined(separator: ", "))")
    }

    var composed = AttributedString(headerLines.joined(separator: "\n"))
    composed.append(AttributedString("\n\n"))

    if originalBody.characters.isEmpty {
      composed.append(AttributedString("(No Message Body)"))
    } else {
      composed.append(originalBody)
    }

    return composed
  }

  private func parseRecipients(from string: String, allowEmpty: Bool) throws -> [String] {
    let separators = CharacterSet(charactersIn: ",;\n")
    let components =
      string
      .components(separatedBy: separators)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    if components.isEmpty {
      if allowEmpty {
        return []
      } else {
        throw DraftError.missingRecipients
      }
    }

    for address in components where address.contains(" ") || !address.contains("@") {
      throw DraftError.invalidAddress(address)
    }

    return components
  }

  private func ensureMessageStorageExistsForConfiguredMailboxes() {
    for mailbox in mailboxes where mailbox.id != Mailbox.allInboxesID {
      messagesByMailbox[mailbox.id] = messagesByMailbox[mailbox.id, default: []]
    }
  }

  private func recalculateMailboxMetadata() {
    let aggregateMessages =
      messagesByMailbox
      .filter { $0.key != Mailbox.sentID }
      .values
      .flatMap { $0 }

    for index in mailboxes.indices {
      let mailboxID = mailboxes[index].id
      if mailboxID == Mailbox.allInboxesID {
        mailboxes[index].unreadCount = aggregateMessages.filter(\.isUnread).count
      } else {
        let mailboxMessages = messagesByMailbox[mailboxID, default: []]
        mailboxes[index].unreadCount = mailboxMessages.filter(\.isUnread).count
      }
    }
  }

  private func mutateMessage(id: Message.ID, mutation: (inout Message, Mailbox.ID) -> Void) {
    for mailboxID in Array(messagesByMailbox.keys) {
      guard var messages = messagesByMailbox[mailboxID],
        let index = messages.firstIndex(where: { $0.id == id })
      else { continue }

      mutation(&messages[index], mailboxID)
      messagesByMailbox[mailboxID] = messages
      recalculateMailboxMetadata()
      return
    }
  }
}
