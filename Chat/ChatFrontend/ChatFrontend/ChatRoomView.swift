import ChatSharedDTOs
import SwiftUI

struct ChatRoomView: View {
  @Binding var chatRoom: ChatRoomDTO?
  @State var messages: [ChatMessageDTO] = []
  @State var messageText: String = ""

  func fetch() async {
    guard let chatRoom else { return }
    do {
      messages = try await Client.messages(roomId: chatRoom.id)
    } catch {
      // TODO: Error Handling
      print(error)
    }
  }

  func sendMessage() async {
    guard let chatRoom else { return }
    do {
      let message = try await Client.sendMessage(roomId: chatRoom.id, sender: "Current-User", body: messageText)
      messages.append(message)
      await fetch()
    } catch {
      // TODO: Error Handling
      print(error)
    }
  }

  var body: some View {
    NavigationStack {
      List(messages) { message in
        VStack(alignment: .leading) {
          HStack {
            Text(message.sender)
              .font(.title3)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)

            Spacer()

            Text(message.createdAt.formatted(.relative(presentation: .numeric, unitsStyle: .narrow)))
          }
          Text(message.body)
        }
        .listRowSeparator(.hidden)
      }
      .navigationTitle(chatRoom?.name ?? "")
      .toolbar {
        ToolbarItem(placement: .bottomBar) {
          HStack {
            TextField("Send a message", text: $messageText)
              .padding()
            Button {
              Task {
                await sendMessage()
              }
            } label: {
              Image(systemName: "arrow.up.circle.fill")
                .foregroundStyle(messageText.isEmpty ? Color.secondary : Color.accentColor)
            }
            .padding(.trailing)
            .disabled(messageText.isEmpty)
          }
        }
      }
      .listStyle(.inset)
      .task {
        await fetch()
      }
      .onChange(of: chatRoom) {
        Task {
          await fetch()
        }
      }
    }
  }
}
