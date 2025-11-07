import SwiftUI
import UIKit

final class ComposeSceneDelegate: NSObject, UIHostingSceneDelegate {
  static var rootScene: some Scene {
    WindowGroup("New Message", id: SceneActivityType.compose) {
      ComposeView()
        .environmentObject(MailStore.shared)
    }
    .commands {
      TextEditingCommands()
    }
    .windowResizability(.contentMinSize)
    .defaultSize(width: 420, height: 520)
  }

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    windowScene.title = "New Message"
  }

  func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
    NSUserActivity(activityType: SceneActivityType.compose)
  }
}
