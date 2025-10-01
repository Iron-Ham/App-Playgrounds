import API
import Dependencies

extension Client: @retroactive TestDependencyKey {}
extension Client: @retroactive DependencyKey {
  public static let liveValue = Client()
  public static let testValue = Client()
  public static let previewValue = Client()
}

extension DependencyValues {
  public var client: Client {
    get { self[Client.self] }
    set { self[Client.self] = newValue }
  }
}
