import ChatSharedDTOs
import Fluent
import Foundation
import Vapor

final class ChatRoom: Model, @unchecked Sendable {
  static let schema = "chat_rooms"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "name")
  var name: String

  @OptionalField(key: "topic")
  var topic: String?

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  @Children(for: \.$room)
  var messages: [ChatMessage]

  init() {}

  init(
    id: UUID? = nil,
    name: String,
    topic: String? = nil
  ) {
    self.id = id
    self.name = name
    self.topic = topic
  }

  func toDTO(includeMessages: Bool = false, messages: [ChatMessage] = []) throws -> ChatRoomDTO {
    guard let id = self.id else {
      throw Abort(.internalServerError, reason: "Cannot create DTO for unpersisted ChatRoom")
    }
    
    guard let createdAt = self.createdAt else {
      throw Abort(.internalServerError, reason: "ChatRoom missing createdAt timestamp")
    }
    
    guard let updatedAt = self.updatedAt else {
      throw Abort(.internalServerError, reason: "ChatRoom missing updatedAt timestamp")
    }

    let resolvedMessages: [ChatMessage]
    if includeMessages {
      resolvedMessages = messages.isEmpty ? self.$messages.value ?? [] : messages
    } else {
      resolvedMessages = []
    }

    return ChatRoomDTO(
      id: id,
      name: self.name,
      topic: self.topic,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messages: includeMessages ? try resolvedMessages.map { try $0.toDTO() } : nil
    )
  }
}
