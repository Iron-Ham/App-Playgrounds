import ChatSharedDTOs
import SwiftUI

struct ChatRoomCell: View {
  let chatRoom: ChatRoomDTO
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(chatRoom.name)
          .font(.body)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
        Spacer()
        Text(
          chatRoom.updatedAt
            .formatted(.relative(presentation: .numeric, unitsStyle: .narrow))
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
      }
      if let topic = chatRoom.topic {
        Text(topic)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
  }
}
