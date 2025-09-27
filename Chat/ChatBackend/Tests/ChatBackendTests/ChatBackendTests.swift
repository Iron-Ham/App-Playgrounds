import ChatSharedDTOs
import Fluent
import Testing
import VaporTesting

@testable import ChatBackend

@Suite("App Tests with DB", .serialized)
struct ChatBackendTests {
  private func withApp(_ test: (Application) async throws -> Void) async throws {
    let app = try await Application.make(.testing)
    do {
      try await configure(app)
      try await app.autoMigrate()
      try await test(app)
      try await app.autoRevert()
    } catch {
      try? await app.autoRevert()
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  @Test("Root route returns status message")
  func rootRoute() async throws {
    try await withApp { app in
      try await app.testing().test(
        .GET, "",
        afterResponse: { res async in
          #expect(res.status == .ok)
          #expect(res.body.string == "Chat backend is running.")
        })
    }
  }

  @Test("List available chat rooms")
  func listRooms() async throws {
    try await withApp { app in
      try await app.testing().test(
        .GET, "rooms",
        afterResponse: { res async throws in
          #expect(res.status == .ok)
          let rooms = try res.content.decode([ChatRoomDTO].self)
          #expect(!rooms.isEmpty)
          #expect(rooms.allSatisfy { !$0.name.isEmpty })
        })
    }
  }

  @Test("Create a new chat room")
  func createRoom() async throws {
    try await withApp { app in
      let payload = CreateChatRoomDTO(name: "QA", topic: "Support requests")

      try await app.testing().test(
        .POST,
        "rooms",
        beforeRequest: { req in
          try req.content.encode(payload)
        },
        afterResponse: { res async throws in
          #expect(res.status == .ok)
          let response = try res.content.decode(ChatRoomDTO.self)
          #expect(response.name == payload.name)
          let stored = try await ChatRoom.query(on: app.db)
            .filter(\.$name == payload.name)
            .first()
          #expect(stored != nil)
        }
      )
    }
  }

  @Test("Reject blank room names")
  func createRoomValidation() async throws {
    try await withApp { app in
      let payload = CreateChatRoomDTO(name: "   ", topic: nil)

      try await app.testing().test(
        .POST,
        "rooms",
        beforeRequest: { req in
          try req.content.encode(payload)
        },
        afterResponse: { res async in
          #expect(res.status == .badRequest)
        }
      )
    }
  }

  @Test("Fetch messages for a room")
  func fetchMessages() async throws {
    try await withApp { app in
      guard let room = try await ChatRoom.query(on: app.db).first() else {
        #expect(Bool(false), "Expected seeded chat rooms to exist")
        return
      }

      let roomID = try room.requireID()

      try await app.testing().test(
        .GET, "rooms/\(roomID)/messages",
        afterResponse: { res async throws in
          #expect(res.status == .ok)
          let messages = try res.content.decode([ChatMessageDTO].self)
          #expect(messages.allSatisfy { $0.roomID == roomID })
        })
    }
  }

  @Test("Show room with inlined messages")
  func showRoomWithMessages() async throws {
    try await withApp { app in
      guard let room = try await ChatRoom.query(on: app.db).first() else {
        #expect(Bool(false), "Expected seeded chat rooms to exist")
        return
      }

      let roomID = try room.requireID()

      try await app.testing().test(
        .GET, "rooms/\(roomID)?includeMessages=true",
        afterResponse: { res async throws in
          #expect(res.status == .ok)
          let response = try res.content.decode(ChatRoomDTO.self)
          #expect(response.messages != nil)
          #expect(response.messages?.allSatisfy { $0.roomID == roomID } ?? false)
        })
    }
  }

  @Test("Send a message to a room")
  func sendMessage() async throws {
    try await withApp { app in
      guard let room = try await ChatRoom.query(on: app.db).first() else {
        #expect(Bool(false), "Expected seeded chat rooms to exist")
        return
      }

      let roomID = try room.requireID()

      let payload = CreateChatMessageDTO(sender: "TestUser", body: "Hello from tests")

      try await app.testing().test(
        .POST,
        "rooms/\(roomID)/messages",
        beforeRequest: { req in
          try req.content.encode(payload)
        },
        afterResponse: { res async throws in
          #expect(res.status == .ok)
          let response = try res.content.decode(ChatMessageDTO.self)
          #expect(response.sender == payload.sender)
          #expect(response.body == payload.body)
          let stored = try await ChatMessage.query(on: app.db)
            .filter(\.$room.$id == roomID)
            .filter(\.$sender == payload.sender)
            .filter(\.$body == payload.body)
            .first()
          #expect(stored != nil)
        }
      )
    }
  }

  @Test("Reject blank messages")
  func sendMessageValidation() async throws {
    try await withApp { app in
      guard let room = try await ChatRoom.query(on: app.db).first() else {
        #expect(Bool(false), "Expected seeded chat rooms to exist")
        return
      }

      let roomID = try room.requireID()
      let payload = CreateChatMessageDTO(sender: " ", body: " ")

      try await app.testing().test(
        .POST,
        "rooms/\(roomID)/messages",
        beforeRequest: { req in
          try req.content.encode(payload)
        },
        afterResponse: { res async in
          #expect(res.status == .badRequest)
        }
      )
    }
  }
}
