import SwiftUI

struct ContentView: View {
  @State
  var game: Game = Game()
  @State
  var isShowingAlert = false
  @State
  var turnResult: Game.TurnResult?
  @State
  var isGameOver = false

  init(board: Board = .defaultBoard) {
    game = Game(board: board)
  }

  private func buttonColor(isFired: Bool?) -> Color {
    switch isFired {
    case .none:
      Color.blue
    case true:
      Color.green
    case false:
      Color.gray
    }
  }

  private var alertTitle: String {
    if game.isGameOver {
      "Game Over"
    } else {
      turnResult?.displayText ?? ""
    }
  }

  var body: some View {
    NavigationStack {
      VStack {
        Grid {
          ForEach(0..<game.gridSize, id: \.self) { col in
            GridRow {
              ForEach(0..<game.gridSize, id: \.self) { row in
                let isFired = game.firedLocations[ShipIndex(x: col, y: row)]
                Button {
                  turnResult = try? game.fireShot(x: col, y: row)
                  isShowingAlert = true
                  isGameOver = game.isGameOver
                } label: {
                  ZStack {
                    RoundedRectangle(cornerRadius: 6)
                      .foregroundStyle(.clear)
                    Text("\(col), \(row)")
                      .foregroundStyle(.primary)
                      .font(.title2)
                  }
                }
                .buttonStyle(.glassProminent)
                .tint(buttonColor(isFired: isFired))
                .disabled(game.firedLocations[ShipIndex(x: col, y: row)] != nil)
              }
            }
          }
        }
        .alert(
          alertTitle, isPresented: $isShowingAlert, actions: {},
          message: {
            if game.isGameOver {
              Text(turnResult?.displayText ?? "")
            } else {
              EmptyView()
            }
          }
        )
        .disabled(game.isGameOver)
        .aspectRatio(1, contentMode: .fit)
        .padding()

        Text("\(game.board.shipsRemaining) ships remaining")
      }
      .navigationTitle("Battleship")
    }
  }
}

#Preview {
  ContentView()
}
