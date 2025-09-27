import Fluent
import Vapor

func routes(_ app: Application) throws {
  app.get { _ async in
    "Chat backend is running."
  }

  try app.register(collection: ChatRoomController())
}
