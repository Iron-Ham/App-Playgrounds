import ChatSharedDTOs
import Fluent
import Foundation
import Vapor

final class ChatMessage: Model, @unchecked Sendable {
  static let schema = "chat_messages"

  @ID(key: .id)
  var id: UUID?

  @Parent(key: "room_id")
  var room: ChatRoom

  @Field(key: "sender")
  var sender: String

  @Field(key: "body")
  var body: String

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    roomID: ChatRoom.IDValue,
    sender: String,
    body: String
  ) {
    self.id = id
    self.$room.id = roomID
    self.sender = sender
    self.body = body
  }

  func toDTO() throws -> ChatMessageDTO {
    guard let id = self.id else {
      throw Abort(.internalServerError, reason: "Cannot create DTO for unpersisted ChatMessage")
    }
    
    guard let createdAt = self.createdAt else {
      throw Abort(.internalServerError, reason: "ChatMessage missing createdAt timestamp")
    }

    return ChatMessageDTO(
      id: id,
      roomID: self.$room.id,
      sender: self.sender,
      body: self.body,
      createdAt: createdAt
    )
  }
}
