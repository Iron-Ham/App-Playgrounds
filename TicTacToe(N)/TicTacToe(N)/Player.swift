enum Player: Hashable {
  case one, two

  var name: String {
    switch self {
    case .one:
      "Player 1"
    case .two:
      "Player 2"
    }
  }

  var symbolName: String {
    switch self {
    case .one:
      "xmark"
    case .two:
      "circle"
    }
  }
}
