import Dependencies

extension Client: DependencyKey {
  public static let liveValue = Client()
  public static let testValue = Client()
  public static let previewValue = Client()
}

public extension DependencyValues {
  var client: Client {
    get { self[Client.self] }
    set { self[Client.self] = newValue }
  }
}
