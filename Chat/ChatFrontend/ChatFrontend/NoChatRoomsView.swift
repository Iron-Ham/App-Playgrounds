import SwiftUI

struct NoChatRoomsView: View {
 var body: some View {
   ContentUnavailableView {
     VStack {
       Image(systemName: "exclamationmark.message")
         .font(.largeTitle)
         .foregroundStyle(.green)
         .padding()

       Text("No chat rooms")
         .font(.headline)
         .foregroundStyle(.primary)
       Text("Create a chat room for yourself and others to join!")
         .font(.subheadline)
         .foregroundStyle(.secondary)
     }
   }
 }
}

#Preview {
  NoChatRoomsView()
}
