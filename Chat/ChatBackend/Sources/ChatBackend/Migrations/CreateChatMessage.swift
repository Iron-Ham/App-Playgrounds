import Fluent

struct CreateChatMessage: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema(ChatMessage.schema)
      .id()
      .field("room_id", .uuid, .required, .references(ChatRoom.schema, .id, onDelete: .cascade))
      .field("sender", .string, .required)
      .field("body", .string, .required)
      .field("created_at", .datetime)
      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema(ChatMessage.schema).delete()
  }
}
