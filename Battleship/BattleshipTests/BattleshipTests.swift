import Testing

@testable import Battleship

struct BattleshipTests {
  @Test
  func example() throws {
    var board: Board = Board(underlying: [:], boardSize: 10)
    let battleShip = Ship(type: .battleship)
    let submarine = Ship(type: .submarine)
    let aircraft = Ship(type: .aircraftCarrier)
    let destroyer = Ship(type: .destroyer)
    let cruiser = Ship(type: .cruiser)
    try! board.insert(ship: battleShip, x: 1, y: 1, horizontal: true)
    try! board.insert(ship: submarine, x: 3, y: 2, horizontal: false)
    try! board.insert(ship: aircraft, x: 6, y: 2, horizontal: false)
    try! board.insert(ship: destroyer, x: 2, y: 7, horizontal: true)
    try! board.insert(ship: cruiser, x: 7, y: 8, horizontal: true)
    let game = Game(board: board)

    #expect(try game.fireShot(x: 0, y: 0) == .miss)
    #expect(try game.fireShot(x: 1, y: 1) == .hit)
    #expect(try game.fireShot(x: 1, y: 1) == .miss)
    #expect(try game.fireShot(x: 2, y: 1) == .hit)
    #expect(try game.fireShot(x: 3, y: 1) == .hit)
    #expect(try game.fireShot(x: 4, y: 1) == .sunk(battleShip))
    #expect(!game.isGameOver)
    #expect(try game.fireShot(x: 3, y: 2) == .hit)
    #expect(try game.fireShot(x: 3, y: 3) == .hit)
    #expect(try game.fireShot(x: 3, y: 4) == .sunk(submarine))
    #expect(game.isGameOver)
  }
}
