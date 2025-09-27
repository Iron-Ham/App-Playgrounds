import Foundation
import Playgrounds

struct Move: Hashable {
  let player: Player
  let position: Int
}

enum GameState {
  case inProgress
  case tie
  case winner(Player)

  var isOver: Bool {
    if case .inProgress = self {
      false
    } else {
      true
    }
  }
}

@Observable
class Game {
  static var minimumBoardSize = 3
  static var defaultBoardSize = 4
  static func makeBoard(size: Int) -> [Player?] {
    Array(
      repeating: nil,
      count: size * size
    )
  }

  private(set) var gameSize = Game.defaultBoardSize {
    didSet {
      reset()
    }
  }

  var board: [Player?] = makeBoard(size: Game.defaultBoardSize)

  var history: [Move] = []
  var currentPlayer: Player = .one

  var isUndoAvailable: Bool { !history.isEmpty }
  var isResetAvailable: Bool { !history.isEmpty }

  var currentDisplayText: String {
    switch currentState {
    case .inProgress:
      "\(currentPlayer.name)'s turn"
    case .tie:
      "Tie!"
    case .winner(let player):
      "Winner: \(player.name)"
    }
  }

  var currentState: GameState = .inProgress

  func updateGameSize(newSize: Int) {
    guard newSize >= Game.minimumBoardSize else { return }
    gameSize = newSize
  }

  func player(at position: Int) -> Player? {
    guard isValidIndex(position) else { return nil }
    return board[position]
  }

  private func isValidIndex(_ index: Int) -> Bool {
    index >= 0 && index < gameSize*gameSize
  }

  func calculateState() -> GameState {
    // Quick optimization: If there have been less moves than 2*boardSize - 1, game's on
    if history.count < 2 * gameSize - 1 {
      return .inProgress
    }

    // Horizontal
    if let player = checkHorizontal() {
      return .winner(player)
    }

    // Vertical
    if let player = checkVertical() {
      return .winner(player)
    }

    // Diagonal
    if let player = checkDiagonal() {
      return .winner(player)
    }

    // Other states
    if board.allSatisfy({ $0 != nil }) {
      return .tie
    } else {
      return .inProgress
    }
  }

  func reset() {
    board = Game.makeBoard(size: gameSize)
    history.removeAll()
    currentPlayer = .one
    currentState = .inProgress
  }

  @discardableResult
  func undo() -> Move? {
    guard let move = history.popLast() else { return nil }
    board[move.position] = nil
    currentPlayer = currentPlayer == .one ? .two : .one
    currentState = calculateState()
    return move
  }

  func play(position: Int) {
    guard board[position] == nil else { return }
    let move = Move(player: currentPlayer, position: position)
    board[position] = currentPlayer
    history.append(move)
    currentPlayer = currentPlayer == .one ? .two : .one
    currentState = calculateState()
  }

  private func check(group: [Player?]) -> Player? {
    if let player = group.first, group.allSatisfy({ $0 == player }) {
      player
    } else {
      nil
    }
  }

  private func checkDiagonal() -> Player? {
    // Possible win conditions:
    //   1. Diagonal (primary). "Primary" is being defined as top-left to bottom-right ("\")
    //   2. Diagonal (secondary). "Secondary" is being defined as bottom-left to top-right. ("/")
    if let winner = check(group: primaryDiagonal()) {
      winner
    } else if let winner = check(group: secondaryDiagonal()) {
      winner
    } else {
      nil
    }
  }

  private func primaryDiagonal() -> [Player?] {
    var primary: [Player?] = []
    for i in stride(from: 0, to: board.count, by: gameSize+1) {
      primary.append(board[i])
    }
    assert(primary.count == gameSize)
    return primary
  }

  private func secondaryDiagonal() -> [Player?] {
    var secondary: [Player?] = []
    for i in stride(from: gameSize-1, to: board.count-1, by: gameSize-1) {
      secondary.append(board[i])
    }
    assert(secondary.count == gameSize)
    return secondary
  }

  private func checkVertical() -> Player? {
    for startValue in 0..<gameSize {
      if let player = check(group: createColumn(startValue: startValue)) {
        return player
      }
    }
    return nil
  }

  private func createColumn(startValue: Int) -> [Player?] {
    var column: [Player?] = []
    for i in stride(from: startValue, to: gameSize*gameSize, by: gameSize) {
      column.append(board[i])
    }
    assert(column.count == gameSize)
    return column
  }

  private func checkHorizontal() -> Player? {
    for i in stride(from: 0, through: gameSize*gameSize, by: gameSize) {
      let row = board[0..<i]
      if let player = check(group: Array(row)) {
        return player
      }
    }
    return nil
  }
}
