import SwiftUI

/// Placeholder screen shown while full relationship detail views are under construction.
struct RelationshipDetailPlaceholder: View {
  let title: String
  let iconName: String
  let accentGradient: LinearGradient
  let headline: String
  let message: String

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .fill(accentGradient)
          .frame(width: 120, height: 120)
          .overlay {
            Image(systemName: iconName)
              .font(.system(size: 48, weight: .bold))
              .foregroundStyle(.white)
          }
          .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 8)
          .padding(.top, 48)

        VStack(spacing: 8) {
          Text(headline)
            .font(.title2)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center)

          Text(message)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }

        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity)
      .padding(.bottom, 48)
    }
    .navigationTitle(title)
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}
