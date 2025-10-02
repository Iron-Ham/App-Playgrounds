#if os(macOS)
  import AppKit
  import SwiftUI

  @MainActor
  final class OpeningCrawlFullScreenPresenter: NSObject, NSWindowDelegate {
    static let shared = OpeningCrawlFullScreenPresenter()

    private var windowController: NSWindowController?
    private var dismissalHandler: (() -> Void)?

    func present(content: OpeningCrawlView.Content, onDismiss: @escaping () -> Void) {
      dismiss(shouldNotify: false)

      dismissalHandler = onDismiss

      let hostingController = NSHostingController(
        rootView: OpeningCrawlView(content: content) { [weak self] in
          self?.dismiss()
        }
      )

      let window = NSWindow(contentViewController: hostingController)
      window.delegate = self
      window.styleMask = [.borderless]
      window.level = .screenSaver
      window.isOpaque = true
      window.backgroundColor = .black
      window.hasShadow = false
      window.animationBehavior = .none
      window.isReleasedWhenClosed = false
      window.collectionBehavior = [
        .canJoinAllSpaces,
        .fullScreenAuxiliary,
        .stationary,
        .ignoresCycle,
      ]

      if let screen = NSApp.keyWindow?.screen ?? NSScreen.main ?? NSScreen.screens.first {
        window.setFrame(screen.frame, display: true)
      }

      windowController = NSWindowController(window: window)
      windowController?.shouldCascadeWindows = false
      windowController?.showWindow(nil)

      NSApp.activate(ignoringOtherApps: true)
    }

    func dismiss() {
      dismiss(shouldNotify: true)
    }

    private func dismiss(shouldNotify: Bool) {
      guard let controller = windowController else {
        if shouldNotify {
          dismissalHandler = nil
        }
        return
      }

      controller.close()
      windowController = nil

      if shouldNotify, let handler = dismissalHandler {
        dismissalHandler = nil
        handler()
      } else if !shouldNotify {
        dismissalHandler = nil
      }
    }

    func windowWillClose(_ notification: Notification) {
      if let window = notification.object as? NSWindow, window == windowController?.window {
        windowController = nil
        if let handler = dismissalHandler {
          dismissalHandler = nil
          handler()
        }
      }
    }
  }
#endif
