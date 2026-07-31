import AppKit
import AwakeTimeKit
import SwiftData
import SwiftUI

extension Notification.Name {
  static let awakeTimeReopenRequested = Notification.Name("AwakeTimeReopenRequested")
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApplication.shared.setActivationPolicy(.accessory)
  }

  func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    NotificationCenter.default.post(name: .awakeTimeReopenRequested, object: nil)
    return true
  }
}

@MainActor
final class AppLifecycleController {
  private let appState: AppState
  private let modelContainer: ModelContainer
  private var statusBarController: StatusBarController?
  private var launchObserver: NSObjectProtocol?
  private var reopenObserver: NSObjectProtocol?

  init(appState: AppState, modelContainer: ModelContainer) {
    self.appState = appState
    self.modelContainer = modelContainer
    launchObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didFinishLaunchingNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in self?.installStatusBar() }
    }
    reopenObserver = NotificationCenter.default.addObserver(
      forName: .awakeTimeReopenRequested,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in self?.statusBarController?.showControlWindow() }
    }
    DispatchQueue.main.async { [weak self] in
      self?.installStatusBar()
    }
  }

  deinit {
    if let launchObserver {
      NotificationCenter.default.removeObserver(launchObserver)
    }
    if let reopenObserver {
      NotificationCenter.default.removeObserver(reopenObserver)
    }
  }

  private func installStatusBar() {
    guard statusBarController == nil else { return }
    guard NSApplication.shared.isRunning else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        self?.installStatusBar()
      }
      return
    }
    let controller = StatusBarController(
      appState: appState,
      modelContainer: modelContainer
    )
    statusBarController = controller
    controller.showControlWindow()
  }
}

@main
struct AwakeTimeApplication: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  private let modelContainer: ModelContainer
  @StateObject private var appState: AppState
  private let lifecycleController: AppLifecycleController

  init() {
    do {
      let container = try AwakeTimeStore.makeContainer()
      modelContainer = container
      let state = AppState(modelContext: container.mainContext)
      _appState = StateObject(wrappedValue: state)
      lifecycleController = AppLifecycleController(
        appState: state,
        modelContainer: container
      )
    } catch {
      fatalError("Unable to create Awake Time data store: \(error)")
    }
  }

  var body: some Scene {
    Settings {
      SettingsRootView()
        .environmentObject(appState)
        .modelContainer(modelContainer)
    }
  }
}
