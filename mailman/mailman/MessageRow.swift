import SwiftUI

struct MessageRow: View {
  let message: Message

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(message.senderName)
          .font(.headline)
        Spacer()
        Text(message.formattedReceivedAt)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text(message.subject)
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(message.isUnread ? .primary : .secondary)

      Text(message.preview)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
    .padding(.vertical, 8)
  }
}
