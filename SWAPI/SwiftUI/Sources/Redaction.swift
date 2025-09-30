import SwiftUI

extension String {
  static func placeholder(length: Int) -> String {
    String(Array(repeating: "X", count: length))
  }
}

extension View {
  @ViewBuilder
  func redacted(if condition: @autoclosure () -> Bool) -> some View {
    redacted(reason: condition() ? .placeholder : [])
  }
}
