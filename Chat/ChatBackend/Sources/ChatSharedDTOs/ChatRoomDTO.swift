import Foundation

public struct ChatRoomDTO: Codable, Sendable, Identifiable, Hashable {
  public let id: UUID
  public let name: String
  public let topic: String?
  public let createdAt: Date
  public let updatedAt: Date
  public let messages: [ChatMessageDTO]?

  public init(
    id: UUID,
    name: String,
    topic: String? = nil,
    createdAt: Date,
    updatedAt: Date,
    messages: [ChatMessageDTO]? = nil
  ) {
    self.id = id
    self.name = name
    self.topic = topic
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.messages = messages
  }
}

public struct CreateChatRoomDTO: Codable, Sendable {
  public let name: String
  public let topic: String?

  public init(name: String, topic: String? = nil) {
    self.name = name
    self.topic = topic
  }
}
