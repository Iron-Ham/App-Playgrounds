import Foundation

enum GameError: Error {
  case outOfBounds
  case invalidInsertion
  case negativeShipHealth
  case unknown
}

struct Board {
  var underlying: [ShipIndex: Ship]

  var boardSize: Int

  var isBoardEmpty: Bool { underlying.values.isEmpty }

  var shipsRemaining: Int {
    Set(underlying.values).count
  }

  mutating func insert(ship: Ship, x: Int, y: Int, horizontal: Bool) throws(GameError) {
    let range = 0..<boardSize
    let endIndex = ship.type.startingHealth - 1 + (horizontal ? x : y)
    guard range ~= x, range ~= y, range ~= endIndex else {
      print("eeesh")
      throw .outOfBounds
    }

    for value in (horizontal ? x...endIndex : y...endIndex) {
      let insertionX = horizontal ? y : value
      let insertionY = horizontal ? value : x
      guard try getValue(x: insertionX, y: insertionY) == nil else {
        throw GameError.invalidInsertion
      }
      underlying[ShipIndex(x: insertionX, y: insertionY)] = ship
    }
  }

  @discardableResult
  mutating func remove(at index: ShipIndex) -> Ship? {
    underlying.removeValue(forKey: index)
  }

  func getValue(x: Int, y: Int) throws(GameError) -> Ship? {
    if x < boardSize, y < boardSize {
      underlying[ShipIndex(x: x, y: y)]
    } else {
      throw .outOfBounds
    }
  }
}

extension Board {
  static var defaultBoard: Board {
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

    return board
  }
}

class Ship: Hashable {
  var health: Int
  let name: String
  let type: ShipType

  init(type: ShipType) {
    self.health = type.startingHealth
    self.name = type.title
    self.type = type
  }

  static func == (lhs: Ship, rhs: Ship) -> Bool {
    lhs.health == rhs.health && lhs.name == rhs.name && lhs.type == rhs.type
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(health)
    hasher.combine(name)
    hasher.combine(type)
  }
}

extension Ship {
  enum ShipType: CaseIterable, Hashable {
    case battleship, submarine, aircraftCarrier, destroyer, cruiser

    var startingHealth: Int {
      switch self {
      case .battleship:
        4
      case .submarine:
        3
      case .aircraftCarrier:
        5
      case .destroyer:
        2
      case .cruiser:
        3
      }
    }

    var title: String {
      switch self {
      case .aircraftCarrier:
        "Aircraft Carrier"
      case .battleship:
        "Battleship"
      case .cruiser:
        "Cruiser"
      case .destroyer:
        "Destroyer"
      case .submarine:
        "Submarine"
      }
    }

    var symbol: String {
      switch self {
      case .aircraftCarrier:
        "A"
      case .submarine:
        "S"
      case .destroyer:
        "D"
      case .battleship:
        "B"
      case .cruiser:
        "C"
      }
    }

    static func random<G: RandomNumberGenerator>(using generator: inout G) -> ShipType? {
      ShipType.allCases.randomElement(using: &generator)
    }

    static func random() -> ShipType? {
      var generator = SystemRandomNumberGenerator()
      return ShipType.random(using: &generator)
    }
  }
}

nonisolated struct ShipIndex: Hashable {
  let x: Int
  let y: Int
}

@Observable
class Game {
  static let defaultGridSize: Int = 10
  private(set) var board: Board

  var firedLocations: [ShipIndex: Bool] = [:]
  var gridSize: Int

  init(
    gridSize: Int = Game.defaultGridSize,
    board: Board = .defaultBoard
  ) {
    self.gridSize = gridSize
    self.board = board
  }

  func insert(ship: Ship, x: Int, y: Int, horizontal: Bool) throws(GameError) {
    try board.insert(ship: ship, x: x, y: y, horizontal: horizontal)
  }

  func getValue(x: Int, y: Int) throws(GameError) -> Ship? {
    try board.getValue(x: x, y: y)
  }

  enum TurnResult: Hashable {
    case miss
    case hit
    case sunk(Ship)

    var displayText: String {
      switch self {
      case .miss:
        "Miss"
      case .hit:
        "Hit"
      case .sunk(let ship):
        "You sunk \(ship.name)"
      }
    }
  }

  var isGameOver: Bool {
    board.isBoardEmpty
  }

  func fireShot(x: Int, y: Int) throws(GameError) -> TurnResult {
    if let ship = try getValue(x: x, y: y) {
      firedLocations[ShipIndex(x: x, y: y)] = true
      ship.health -= 1
      board.remove(at: ShipIndex(x: x, y: y))
      if ship.health == 0 {
        return .sunk(ship)
      } else if ship.health > 0 {
        return .hit
      } else {
        throw .negativeShipHealth
      }
    } else {
      firedLocations[ShipIndex(x: x, y: y)] = false
      return .miss
    }
  }
}
