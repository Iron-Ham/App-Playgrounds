#if canImport(Persistence)
  import Persistence
  import SwiftUI

  private struct OpenFilmDetailsActionKey: EnvironmentKey {
    static let defaultValue: (PersistenceService.FilmSummary) -> Void = { _ in }
  }

  extension EnvironmentValues {
    var openFilmDetails: (PersistenceService.FilmSummary) -> Void {
      get { self[OpenFilmDetailsActionKey.self] }
      set { self[OpenFilmDetailsActionKey.self] = newValue }
    }
  }
#endif
