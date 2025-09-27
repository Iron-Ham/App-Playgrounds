import ChatSharedDTOs
import SwiftUI

struct ContentView: View {
  @State var chatRooms: [ChatRoomDTO] = []
  @State var selectedChatRoom: ChatRoomDTO?
  @State var error: Error?

  private func fetch() async {
    do {
      chatRooms = try await Client.rooms()
    } catch {
      self.error = error
    }
  }

  var body: some View {
    NavigationSplitView {
      Group {
        if chatRooms.isEmpty {
          NoChatRoomsView()
        } else if let error {
          ErrorView(
            errorTitle: "An unknown error occurred.",
            errorDescription: error.localizedDescription,
            action: {
              await fetch()
            }
          )
        } else {
          List(chatRooms, selection: $selectedChatRoom) { chatRoom in
            NavigationLink(value: chatRoom) {
              ChatRoomCell(chatRoom: chatRoom)
            }
          }
        }
      }
      .navigationTitle("Chat Rooms")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button {
            // TODO: Create Chat Room
          } label: {
            Image(systemName: "plus")
              .foregroundStyle(.green)
          }
        }
      }
      .task {
        await fetch()
      }
    } detail: {
      if selectedChatRoom != nil {
        ChatRoomView(chatRoom: $selectedChatRoom)
      } else {
        ContentUnavailableView("Select a chat room", systemImage: "message")
      }
    }
  }
}

#Preview {
  ContentView()
}
