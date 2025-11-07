import SwiftUI

struct MessageDetailView: View {
  let message: Message

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text(message.subject)
            .font(.title2.weight(.semibold))
          HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
              Text(message.senderName)
                .font(.headline)
              Text(message.senderEmail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(message.formattedReceivedAt)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
        }

        Divider()

        Text(message.body)
          .font(.body)
          .foregroundStyle(.primary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(24)
    }
    .background(Color(uiColor: .secondarySystemBackground))
  }
}
