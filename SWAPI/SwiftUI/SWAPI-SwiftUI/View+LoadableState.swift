import SwiftUI

extension View {
  @ViewBuilder
  func loadableState<Loading: View, ErrorContent: View, EmptyContent: View>(
    hasLoadedInitialData: Bool,
    isContentEmpty: Bool,
    error: Error?,
    @ViewBuilder loadingView: () -> Loading,
    @ViewBuilder errorView: (_ error: Error) -> ErrorContent,
    @ViewBuilder emptyView: () -> EmptyContent
  ) -> some View {
    if !hasLoadedInitialData {
      loadingView()
    } else if let error, isContentEmpty {
      errorView(error)
    } else if isContentEmpty {
      emptyView()
    } else {
      self
    }
  }
}
