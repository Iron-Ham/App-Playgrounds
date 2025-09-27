import ChatSharedDTOs
import Fluent
import Foundation

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

  func toDTO() -> ChatMessageDTO {
    ChatMessageDTO(
      id: self.id,
      roomID: self.$room.id,
      sender: self.sender,
      body: self.body,
      createdAt: self.createdAt
    )
  }
}
