import SwiftUI
import UIKit

final class ComposeSceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let closeScene = { SceneCoordinator.destroy(scene: windowScene) }

    let rootView = ComposeView(onClose: closeScene)
      .environmentObject(MailStore.shared)

    let hostingController = UIHostingController(rootView: rootView)
    hostingController.view.backgroundColor = .systemBackground
    if #available(iOS 16.0, *) {
      hostingController.sizingOptions = .intrinsicContentSize
    }

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = hostingController
    window.backgroundColor = .systemBackground
    window.makeKeyAndVisible()
    self.window = window
    windowScene.title = "New Message"
  }

  func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
    NSUserActivity(activityType: SceneActivityType.compose)
  }
}
