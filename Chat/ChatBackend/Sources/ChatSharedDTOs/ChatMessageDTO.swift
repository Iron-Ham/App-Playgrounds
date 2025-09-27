import Foundation

public struct ChatMessageDTO: Codable, Sendable, Identifiable, Hashable {
  public let id: UUID
  public let roomID: UUID
  public let sender: String
  public let body: String
  public let createdAt: Date

  public init(
    id: UUID,
    roomID: UUID,
    sender: String,
    body: String,
    createdAt: Date
  ) {
    self.id = id
    self.roomID = roomID
    self.sender = sender
    self.body = body
    self.createdAt = createdAt
  }
}

public struct CreateChatMessageDTO: Codable, Sendable {
  public let sender: String
  public let body: String

  public init(sender: String, body: String) {
    self.sender = sender
    self.body = body
  }
}
