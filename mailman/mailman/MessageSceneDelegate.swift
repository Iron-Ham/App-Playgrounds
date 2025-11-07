import SwiftUI
import UIKit

final class MessageSceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  private var messageID: Message.ID?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    messageID = Self.resolveMessageID(connectionOptions: connectionOptions, session: session)

    let rootView = MessageSceneView(messageID: messageID)
      .environmentObject(MailStore.shared)

    let hostingController = UIHostingController(rootView: rootView)
    hostingController.view.backgroundColor = .systemBackground
    hostingController.sizingOptions = .intrinsicContentSize

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = hostingController
    window.makeKeyAndVisible()
    self.window = window

    if let messageID, let message = MailStore.shared.message(id: messageID) {
      windowScene.title = message.subject
    } else {
      windowScene.title = "Message"
    }
  }

  func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
    guard let messageID else { return nil }
    return NSUserActivity.messageDetailActivity(id: messageID)
  }

  private static func resolveMessageID(
    connectionOptions: UIScene.ConnectionOptions,
    session: UISceneSession
  ) -> Message.ID? {
    if let activity = connectionOptions.userActivities.first ?? session.stateRestorationActivity,
      activity.activityType == SceneActivityType.message,
      let idString = activity.userInfo?[SceneUserInfoKey.messageID] as? String,
      let uuid = UUID(uuidString: idString)
    {
      return uuid
    }
    return nil
  }
}
