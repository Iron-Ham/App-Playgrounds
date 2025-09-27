import ChatSharedDTOs
import Fluent
import Foundation

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

  func toDTO(includeMessages: Bool = false, messages: [ChatMessage] = []) -> ChatRoomDTO {
    let resolvedMessages: [ChatMessage]
    if includeMessages {
      resolvedMessages = messages.isEmpty ? self.$messages.value ?? [] : messages
    } else {
      resolvedMessages = []
    }

    return ChatRoomDTO(
      id: self.id,
      name: self.name,
      topic: self.topic,
      createdAt: self.createdAt,
      updatedAt: self.updatedAt,
      messages: includeMessages ? resolvedMessages.map { $0.toDTO() } : nil
    )
  }
}
