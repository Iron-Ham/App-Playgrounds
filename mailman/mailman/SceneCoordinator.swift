import SwiftUI

enum SceneActivityType {
  static let message = "com.ironham.mailman.message"
  static let compose = "com.ironham.mailman.compose"
}

enum SceneUserInfoKey {
  static let messageID = "messageID"
}

@MainActor
enum SceneCoordinator {
  static var canActivateAdditionalScenes: Bool {
    UIApplication.shared.supportsMultipleScenes
  }

  static func activateComposeScene() {
    guard canActivateAdditionalScenes else { return }
    guard
      var request = UISceneSessionActivationRequest(
        hostingDelegateClass: ComposeSceneDelegate.self,
        id: SceneActivityType.compose
      )
    else {
      assertionFailure("Unable to build compose scene activation request")
      return
    }

    request.options = makeActivationOptions()

    Task { @MainActor in
      UIApplication.shared.activateSceneSession(for: request)
    }
  }

  static func activateMessageScene(for messageID: Message.ID) {
    guard canActivateAdditionalScenes else { return }
    let activity = NSUserActivity(activityType: SceneActivityType.message)
    activity.title = "Message"
    activity.targetContentIdentifier = "message-\(messageID.uuidString)"
    activity.addUserInfoEntries(from: [SceneUserInfoKey.messageID: messageID.uuidString])
    requestScene(with: activity)
  }

  static func destroy(scene: UIWindowScene) {
    Task { @MainActor in
      let options = UIWindowSceneDestructionRequestOptions()
      options.windowDismissalAnimation = .standard
      UIApplication.shared.requestSceneSessionDestruction(
        scene.session,
        options: options,
        errorHandler: nil
      )
    }
  }

  private static func requestScene(with activity: NSUserActivity) {
    Task { @MainActor in
      let options = makeActivationOptions()
      let request = UISceneSessionActivationRequest(
        userActivity: activity,
        options: options
      )
      UIApplication.shared.activateSceneSession(for: request)
    }
  }

  private static func makeActivationOptions() -> UIWindowScene.ActivationRequestOptions {
    let options = UIWindowScene.ActivationRequestOptions()
    options.placement = .prominent()
    if let requester = activeWindowScene() {
      options.requestingScene = requester
    }
    return options
  }

  private static func activeWindowScene() -> UIWindowScene? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first(where: { $0.activationState == .foregroundActive })
  }
}

extension NSUserActivity {
  static func messageDetailActivity(id: Message.ID) -> NSUserActivity {
    let activity = NSUserActivity(activityType: SceneActivityType.message)
    activity.title = "Message"
    activity.targetContentIdentifier = "message-\(id.uuidString)"
    activity.addUserInfoEntries(from: [SceneUserInfoKey.messageID: id.uuidString])
    return activity
  }
}
