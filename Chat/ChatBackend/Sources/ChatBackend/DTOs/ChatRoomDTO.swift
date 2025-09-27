import ChatSharedDTOs
import Foundation
import Vapor

extension ChatRoomDTO: Content {}

extension CreateChatRoomDTO: Content {
  func toModel() throws -> ChatRoom {
    let trimmedName = self.name.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedName.isEmpty else {
      throw Abort(.badRequest, reason: "Room name can't be empty")
    }

    let trimmedTopic = self.topic?.trimmingCharacters(in: .whitespacesAndNewlines)
    let sanitizedTopic = (trimmedTopic?.isEmpty ?? true) ? nil : trimmedTopic

    return ChatRoom(name: trimmedName, topic: sanitizedTopic)
  }
}
