import API
import Dependencies

private enum ClientKey: DependencyKey {
  public static let liveValue = Client()
  public static let testValue = Client()
  public static let previewValue = Client()
}

extension DependencyValues {
  public var client: Client {
    get { self[ClientKey.self] }
    set { self[ClientKey.self] = newValue }
  }
}
