import Fluent

struct SeedChatData: AsyncMigration {
  func prepare(on database: any Database) async throws {
    let lounge = ChatRoom(name: "General", topic: "Casual conversations")
    let dev = ChatRoom(name: "Developers", topic: "Share code and tips")

    try await lounge.create(on: database)
    try await dev.create(on: database)

    let welcomeMessages: [ChatMessage] = [
      ChatMessage(
        roomID: try lounge.requireID(), sender: "System", body: "Welcome to the General room!"),
      ChatMessage(roomID: try lounge.requireID(), sender: "Alicia", body: "Hey everyone 👋"),
      ChatMessage(
        roomID: try dev.requireID(), sender: "System", body: "Discuss upcoming sprint here."),
    ]

    for message in welcomeMessages {
      try await message.create(on: database)
    }
  }

  func revert(on database: any Database) async throws {
    try await ChatMessage.query(on: database).delete()
    try await ChatRoom.query(on: database).delete()
  }
}
