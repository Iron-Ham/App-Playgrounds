import Foundation

enum GameError: Error {
  case outOfBounds
  case invalidInsertion
  case negativeShipHealth
  case unknown
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

struct ShipIndex: Hashable {
  let x: Int
  let y: Int
}

extension Array where Element == Ship {
  static func random(gameSize: Int) throws(GameError) -> [Ship] {
    var ships: [Ship] = []

    for _ in 0..<Int.random(in: 1...5) {
      if let type = Ship.ShipType.random() {
        ships.append(Ship(type: type))
      } else {
        throw GameError.unknown
      }
    }

    return ships
  }
}

@Observable
class Game {
  static let defaultGridSize: Int = 10
  private(set) var board: [ShipIndex: Ship] = [:]

  private var ships: [Ship] = []

  var firedLocations: [ShipIndex: Bool] = [:]
  var gridSize: Int

  init(
    gridSize: Int = Game.defaultGridSize,
    ships: [Ship],
    randomPlacements: Bool = false
  ) throws(GameError) {
    self.gridSize = gridSize
    self.ships = ships

    if randomPlacements {
      try randomizeGrid(with: ships)
    }
  }

  func reset() {
    board = [:]
  }

  func randomizeGrid(with ships: [Ship]? = nil) throws(GameError) {
    if let ships {
      self.ships = ships
    }

    for ship in self.ships {
      let insertionX = Int.random(in: 0..<gridSize)
      let insertionY = Int.random(in: 0..<gridSize)
      try insert(ship: ship, x: insertionX, y: insertionY, horizontal: Bool.random())
    }
  }

  func insert(ship: Ship, x: Int, y: Int, horizontal: Bool) throws(GameError) {
    let range = 0..<gridSize
    let endIndex = ship.type.startingHealth - 1 + (horizontal ? x : y)
    guard range ~= x, range ~= y, range ~= endIndex else {
      print("eeesh")
      throw .outOfBounds
    }

    for value in (horizontal ? x...endIndex : y...endIndex) {
      let insertionX = horizontal ? value : x
      let insertionY = horizontal ? y : value
      guard try getValue(x: insertionX, y: insertionY) == nil else {
        throw GameError.invalidInsertion
      }
      board[ShipIndex(x: insertionX, y: insertionY)] = ship
    }
  }

  func getValue(x: Int, y: Int) throws(GameError) -> Ship? {
    if x < gridSize, y < gridSize {
      board[ShipIndex(x: x, y: y)]
    } else {
      throw .outOfBounds
    }
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
    board.values.isEmpty
  }

  func fireShot(x: Int, y: Int) throws(GameError) -> TurnResult {
    if let ship = try getValue(x: x, y: y) {
      firedLocations[ShipIndex(x: x, y: y)] = true
      ship.health -= 1
      board.removeValue(forKey: ShipIndex(x: x, y: y))
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
