import AppKit
import Combine
import SwiftData
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
  private let appState: AppState
  private let modelContainer: ModelContainer
  private let statusItem: NSStatusItem
  private let popover = NSPopover()
  private var observation: AnyCancellable?
  private var controlWindow: NSWindow?
  private var displayedIconName: String?

  init(appState: AppState, modelContainer: ModelContainer) {
    self.appState = appState
    self.modelContainer = modelContainer
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    super.init()

    configureButton()
    popover.behavior = .transient
    popover.contentSize = NSSize(width: 340, height: 460)
    popover.contentViewController = NSHostingController(
      rootView: MenuPopoverView()
        .environmentObject(appState)
        .modelContainer(modelContainer)
    )

    observation = appState.objectWillChange.sink { [weak self] _ in
      DispatchQueue.main.async {
        self?.updateButton()
      }
    }
  }

  private func configureButton() {
    guard let button = statusItem.button else { return }
    button.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    button.imagePosition = .imageLeading
    button.imageHugsTitle = true
    button.target = self
    button.action = #selector(togglePopover(_:))
    updateButton()
  }

  private func updateButton() {
    guard let button = statusItem.button else { return }
    let iconName = appState.isNight ? "moon.stars.fill" : "sun.max.fill"
    if displayedIconName != iconName {
      button.image = NSImage(
        systemSymbolName: iconName,
        accessibilityDescription: "Awake Time"
      )
      button.image?.isTemplate = true
      displayedIconName = iconName
    }
    button.title = appState.displayText
    button.setAccessibilityLabel("Awake Time \(appState.displayText)")
  }

  func showControlWindow() {
    let window: NSWindow
    if let controlWindow {
      window = controlWindow
    } else {
      window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 360, height: 500),
        styleMask: [.titled, .closable, .miniaturizable],
        backing: .buffered,
        defer: false
      )
      window.title = "Awake Time"
      window.isReleasedWhenClosed = false
      window.setFrameAutosaveName("AwakeTimeControlWindow")
      window.contentViewController = NSHostingController(
        rootView: MenuPopoverView()
          .environmentObject(appState)
          .modelContainer(modelContainer)
      )
      window.center()
      controlWindow = window
    }

    NSApplication.shared.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
  }

  @objc private func togglePopover(_ sender: Any?) {
    guard let button = statusItem.button else { return }
    if popover.isShown {
      popover.performClose(sender)
    } else {
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
      popover.contentViewController?.view.window?.makeKey()
    }
  }
}
