import ChatSharedDTOs
import Foundation
import Vapor

extension ChatMessageDTO: Content {}

extension CreateChatMessageDTO: Content {
  func toModel(roomID: ChatRoom.IDValue) throws -> ChatMessage {
    let trimmedSender = self.sender.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedBody = self.body.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedSender.isEmpty else {
      throw Abort(.badRequest, reason: "Sender must not be empty")
    }

    guard !trimmedBody.isEmpty else {
      throw Abort(.badRequest, reason: "Message body must not be empty")
    }

    return ChatMessage(roomID: roomID, sender: trimmedSender, body: trimmedBody)
  }
}
