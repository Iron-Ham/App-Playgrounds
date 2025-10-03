import Testing

@testable import Battleship

struct BattleshipTests {
  @Test
  func example() throws {
    let battleShip = Ship(type: .battleship)
    let submarine = Ship(type: .submarine)
    let game = try Game(ships: [battleShip, submarine])

    try game.insert(ship: battleShip, x: 1, y: 1, horizontal: true)

    try game.insert(ship: submarine, x: 3, y: 2, horizontal: false)

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

  struct Insertion {
    func test() throws {
      for _ in (0..<100) {
        try Game(ships: .random(), randomPlacements: true)
      }
    }
  }
}
