import SwiftUI

struct ContentView: View {
  @State private var game = Game()

  var body: some View {
    VStack {
      Stepper(
        "Board Size: \(game.gameSize)x\(game.gameSize)",
        value: Binding(
          get: { game.gameSize },
          set: { game.updateGameSize(newSize: $0) }
        )
      )
      .font(.headline)
      .foregroundStyle(.secondary)
      ScrollView([.vertical, .horizontal]) {
        Grid {
          ForEach(0..<game.gameSize, id: \.self) { row in
            GridRow {
              ForEach(0..<game.gameSize, id: \.self) { col in
                let position = (row * game.gameSize) + col
                Button {
                  game.play(position: position)
                } label: {
                  ZStack {
                    RoundedRectangle(cornerRadius: 4)
                      .fill(.thinMaterial)
                    if let player = game.player(at: position) {
                      Image(systemName: player.symbolName)
                        .foregroundStyle(player.symbolTint)
                    }
                  }
                }
                .frame(width: 24, height: 24)
                .disabled(game.currentState.isOver)
              }
            }
          }
        }
      }
      .scrollBounceBehavior(.basedOnSize, axes: [.horizontal, .vertical])
      Text(game.currentDisplayText)
        .font(.title3)
        .foregroundStyle(.primary)
    }
    .padding()
    .navigationTitle("Tic-Tac-Toe (N)")
    .toolbar {
      ToolbarItem(placement: .bottomBar) {
        Button {
          game.reset()
        } label: {
          Text("Reset")
        }
      }

      ToolbarSpacer(placement: .bottomBar)

      ToolbarItem(placement: .bottomBar) {
        Button {
          game.undo()
        } label: {
          Text("Undo")
        }
      }
    }
  }
}

private extension Player {
  var symbolTint: Color {
    switch self {
    case .one:
      Color.primary
    case .two:
      Color.red
    }
  }
}

#Preview {
  NavigationStack {
    ContentView()
  }
}
