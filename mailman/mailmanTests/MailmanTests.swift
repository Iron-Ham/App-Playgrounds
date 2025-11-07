//
//  mailmanTests.swift
//  mailmanTests
//
//  Created by Hesham Salman on 11/6/25.
//

import Testing

@testable import mailman

@MainActor
struct MailmanTests {
  @Test func sendDraftAddsMessageToSentMailbox() async throws {
    let store = MailStore.makePreviewStore()
    let sentMailbox = try #require(store.mailbox(id: Mailbox.sentID))

    let initialMessages = store.messages(for: sentMailbox)
    try await store.sendDraft(
      to: "learner@example.com",
      cc: "",
      subject: "Curriculum Notes",
      body: AttributedString("Cover scene delegation and SwiftUI interop.")
    )

    let updatedMessages = store.messages(for: sentMailbox)
    #expect(updatedMessages.count == initialMessages.count + 1)

    let latestMessage = try #require(updatedMessages.first)
    #expect(latestMessage.subject == "Curriculum Notes")
    #expect(!latestMessage.isUnread)
    #expect(latestMessage.mailboxID == Mailbox.sentID)
  }

  @Test func sendDraftValidatesEmailAddresses() async throws {
    let store = MailStore.makePreviewStore()

    await #expect(throws: MailStore.DraftError.missingRecipients) {
      try await store.sendDraft(
        to: "   ",
        cc: "",
        subject: "Hi",
        body: AttributedString("")
      )
    }

    await #expect(throws: MailStore.DraftError.invalidAddress("invalid")) {
      try await store.sendDraft(
        to: "invalid",
        cc: "",
        subject: "Test",
        body: AttributedString("Body")
      )
    }
  }
}
