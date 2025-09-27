import ChatSharedDTOs
import Foundation
import Playgrounds

enum Client {
  private static let localhost = "http://localhost:8080"

  private static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }

  private static var encoder: JSONEncoder {
    JSONEncoder()
  }

  static func rooms() async throws -> [ChatRoomDTO] {
    let url = URL(string: Client.localhost + "/rooms")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try decoder.decode([ChatRoomDTO].self, from: data)
  }

  static func messages(roomId: UUID) async throws -> [ChatMessageDTO] {
    let url = URL(string: Client.localhost + "/rooms/\(roomId)/messages?limit=25")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try decoder.decode([ChatMessageDTO].self, from: data)
  }

  static func sendMessage(roomId: UUID, sender: String, body: String) async throws -> ChatMessageDTO
  {
    let url = URL(string: Client.localhost + "/rooms/\(roomId)/messages")!
    let message = CreateChatMessageDTO(sender: sender, body: body)
    let encodedMessage = try encoder.encode(message)
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = encodedMessage
    let (data, _) = try await URLSession.shared.data(for: request)
    let json = try? JSONSerialization.jsonObject(with: data, options: [])
    return try decoder.decode(ChatMessageDTO.self, from: data)
  }
}
