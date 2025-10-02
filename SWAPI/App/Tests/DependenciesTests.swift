import API
import Dependencies
import Persistence
import Foundation
import Testing

@testable import StarWarsDB

@Suite("SwiftUI dependency wiring")
struct SwiftUIDependenciesTests {
  @Test
  func clientDependencyCanBeOverridden() async throws {
    let filmsURL = URL(string: "https://swapi.info/api/films")!
    ClientURLProtocolStub.stub(url: filmsURL, data: Data("[]".utf8))
    defer { ClientURLProtocolStub.removeAll() }

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ClientURLProtocolStub.self]
    configuration.waitsForConnectivity = false
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    let client = Client(session: URLSession(configuration: configuration))

    try await withDependencies {
      $0.client = client
    } operation: {
      struct Harness {
        @Dependency(\.client)
        var client: Client

        func loadFilms() async throws -> Int {
          try await client.films().count
        }
      }

      let harness = Harness()
      let count = try await harness.loadFilms()
      #expect(count == 0)
    }
  }

  @Test
  func persistenceServiceDependencyCanBeOverridden() async throws {
    let sampleFilm = PersistenceService.FilmDetails(
      id: URL(string: "https://swapi.dev/api/films/preview")!,
      title: "Preview Hope",
      episodeId: 0,
      openingCrawl: "Preview crawl...",
      director: "Preview Director",
      producers: ["Preview Producer"],
      releaseDate: nil,
      created: .now,
      edited: .now
    )

    let service = PersistenceService(
      setup: { _ in },
      importSnapshot: { _ in },
      observeChanges: { AsyncStream { _ in } },
      shutdown: {},
      fetchFilms: { [sampleFilm] },
      fetchRelationshipSummary: { _ in PersistenceService.FilmRelationshipSummary() },
      fetchRelationshipEntities: { _, _ in [] }
    )

    try await withDependencies {
      $0.persistenceService = service
      $0.configurePersistence = {}
      $0.persistenceCoordinator = PersistenceCoordinator(
        persistenceService: service,
        configurationProvider: { .init(storage: .inMemory()) },
        snapshotProvider: { .init() }
      )
    } operation: {
      struct Harness {
        @Dependency(\.persistenceService)
        var persistenceService: PersistenceService
        @Dependency(\.persistenceCoordinator)
        var persistenceCoordinator: PersistenceCoordinator

        func filmCount() async throws -> Int {
          try await persistenceCoordinator.loadFilms().count
        }
      }

      let harness = Harness()
      let count = try await harness.filmCount()
      #expect(count == 1)
    }
  }
}

final class ClientURLProtocolStub: URLProtocol {
  private struct Stub {
    let data: Data
    let headers: [String: String]
    let statusCode: Int
  }

  nonisolated(unsafe) private static var stubs: [URL: Stub] = [:]
  private static let lock = NSLock()

  static func stub(
    url: URL,
    data: Data,
    statusCode: Int = 200,
    headers: [String: String] = ["Content-Type": "application/json"]
  ) {
    lock.lock()
    stubs[url] = Stub(data: data, headers: headers, statusCode: statusCode)
    lock.unlock()
  }

  static func removeAll() {
    lock.lock()
    stubs.removeAll()
    lock.unlock()
  }

  private static func stub(for url: URL) -> Stub? {
    lock.lock()
    let value = stubs[url]
    lock.unlock()
    return value
  }

  override class func canInit(with request: URLRequest) -> Bool {
    guard let url = request.url else { return false }
    return stub(for: url) != nil
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let url = request.url, let stub = Self.stub(for: url) else {
      client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
      return
    }

    if let response = HTTPURLResponse(
      url: url,
      statusCode: stub.statusCode,
      httpVersion: "HTTP/1.1",
      headerFields: stub.headers
    ) {
      client?.urlProtocol(
        self,
        didReceive: response,
        cacheStoragePolicy: .notAllowed
      )
    }

    client?.urlProtocol(self, didLoad: stub.data)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}
