#if canImport(Persistence)
  import Persistence
  import SwiftUI

  private struct OpenFilmDetailsActionKey: EnvironmentKey {
    static let defaultValue: @Sendable (PersistenceService.FilmSummary) -> Void = { _ in }
  }

  extension EnvironmentValues {
    var openFilmDetails: @Sendable (PersistenceService.FilmSummary) -> Void {
      get { self[OpenFilmDetailsActionKey.self] }
      set { self[OpenFilmDetailsActionKey.self] = newValue }
    }
  }
#endif
