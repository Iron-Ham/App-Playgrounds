import SwiftUI

struct ContentView: View {
  @State var game: Game = try! Game(ships: .random(), randomPlacements: true)

  @State var isShowingAlert = false
  @State var turnResult: Game.TurnResult?

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
        .alert(turnResult?.displayText ?? "", isPresented: $isShowingAlert, actions: {

        })
        .disabled(game.isGameOver)
        .aspectRatio(1, contentMode: .fit)
        .padding()

        Text("\(Set(game.board.values).count) ships remaining")
      }
      .navigationTitle("Battleship")
    }
  }
}

#Preview {
  ContentView()
}
