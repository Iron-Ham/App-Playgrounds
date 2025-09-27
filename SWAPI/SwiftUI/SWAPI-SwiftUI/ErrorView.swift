import SwiftUI

struct ErrorView: View {
  let errorTitle: String
  let errorDescription: String?

  let action: (() async throws -> Void)?
  var body: some View {
    ContentUnavailableView {
      VStack {
        Image(systemName: "xmark.octagon")
          .font(.largeTitle)
          .foregroundStyle(.red)
          .padding(.vertical)
        Text(errorTitle)
          .font(.headline)
          .foregroundStyle(.primary)

        if let errorDescription {
          Text(errorDescription)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        if let action {
          Button {
            Task {
              try await action()
            }
          } label: {
            Text("Try again")
          }
          .padding(.top)
        }
      }
    }
  }
}

#Preview {
  ErrorView(errorTitle: "An error has occurred", errorDescription: "Unknown error", action: { })
}
