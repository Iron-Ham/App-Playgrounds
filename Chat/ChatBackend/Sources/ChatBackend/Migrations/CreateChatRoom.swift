import Fluent

struct CreateChatRoom: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema(ChatRoom.schema)
      .id()
      .field("name", .string, .required)
      .field("topic", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "name")
      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema(ChatRoom.schema).delete()
  }
}
