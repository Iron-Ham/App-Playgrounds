import ChatSharedDTOs
import Fluent
import Vapor

struct ChatRoomController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    let rooms = routes.grouped("rooms")

    rooms.get(use: self.index)
    rooms.post(use: self.create)
    rooms.group(":roomID") { room in
      room.get(use: self.show)
      room.get("messages", use: self.listMessages)
      room.post("messages", use: self.createMessage)
    }
  }

  @Sendable
  func index(req: Request) async throws -> [ChatRoomDTO] {
    let rooms = try await ChatRoom.query(on: req.db)
      .sort(\.$createdAt, .descending)
      .all()
    return rooms.map { $0.toDTO() }
  }

  @Sendable
  func create(req: Request) async throws -> ChatRoomDTO {
    let payload = try req.content.decode(CreateChatRoomDTO.self)
    let room = try payload.toModel()
    try await room.create(on: req.db)
    return room.toDTO()
  }

  @Sendable
  func show(req: Request) async throws -> ChatRoomDTO {
    let room = try await self.requireRoom(req: req)
    let includeMessages = req.query[Bool.self, at: "includeMessages"] ?? false

    guard includeMessages else {
      return room.toDTO()
    }

    let messages = try await room.$messages
      .query(on: req.db)
      .sort(\.$createdAt, .descending)
      .limit(100)
      .all()
      .reversed()

    return room.toDTO(includeMessages: true, messages: Array(messages))
  }

  @Sendable
  func listMessages(req: Request) async throws -> [ChatMessageDTO] {
    let room = try await self.requireRoom(req: req)
    let limit = req.query[Int.self, at: "limit"] ?? 50
    let clampedLimit = min(max(limit, 1), 200)

    let messages = try await room.$messages
      .query(on: req.db)
      .sort(\.$createdAt, .descending)
      .limit(clampedLimit)
      .all()
      .reversed()

    return Array(messages).map { $0.toDTO() }
  }

  @Sendable
  func createMessage(req: Request) async throws -> ChatMessageDTO {
    let room = try await self.requireRoom(req: req)
    let payload = try req.content.decode(CreateChatMessageDTO.self)
    let roomID = try room.requireID()
    let message = try payload.toModel(roomID: roomID)
    try await message.create(on: req.db)
    return message.toDTO()
  }

  private func requireRoom(req: Request) async throws -> ChatRoom {
    guard let roomID = req.parameters.get("roomID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid room identifier")
    }

    guard let room = try await ChatRoom.find(roomID, on: req.db) else {
      throw Abort(.notFound, reason: "Chat room not found")
    }

    return room
  }
}
