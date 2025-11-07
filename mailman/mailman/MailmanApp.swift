import SwiftUI

final class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let activity = options.userActivities.first ?? connectingSceneSession.stateRestorationActivity

    let configurationName: String
    switch activity?.activityType {
    case SceneActivityType.compose:
      configurationName = "Compose"
    case SceneActivityType.message:
      configurationName = "Message"
    default:
      configurationName = "Default Configuration"
    }

    return UISceneConfiguration(name: configurationName, sessionRole: connectingSceneSession.role)
  }
}

@main
struct MailmanApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(MailStore.shared)
    }
  }
}
