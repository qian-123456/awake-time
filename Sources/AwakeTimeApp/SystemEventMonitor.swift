import AppKit
import AwakeTimeKit
import Foundation

final class SystemEventMonitor {
  private enum Key {
    static let pendingSleep = "pendingSleepAt"
    static let pendingWake = "pendingWakeAt"
  }

  private let defaults: UserDefaults
  private let onObservation: (SleepObservation) -> Void
  private var observers: [NSObjectProtocol] = []
  private var started = false

  init(defaults: UserDefaults = .standard, onObservation: @escaping (SleepObservation) -> Void) {
    self.defaults = defaults
    self.onObservation = onObservation
  }

  deinit {
    let center = NSWorkspace.shared.notificationCenter
    observers.forEach(center.removeObserver)
  }

  func start() {
    guard !started else { return }
    started = true
    let center = NSWorkspace.shared.notificationCenter
    observers.append(
      center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) {
        [weak self] _ in
        self?.recordSleep()
      })
    observers.append(
      center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) {
        [weak self] _ in
        self?.recordWake()
      })
    observers.append(
      center.addObserver(
        forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, queue: .main
      ) { [weak self] _ in
        self?.recordUnlock()
      })

    if defaults.object(forKey: Key.pendingSleep) != nil {
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
        self?.recordUnlock()
      }
    }
  }

  private func recordSleep() {
    defaults.set(Date(), forKey: Key.pendingSleep)
    defaults.removeObject(forKey: Key.pendingWake)
  }

  private func recordWake() {
    guard defaults.object(forKey: Key.pendingSleep) != nil else { return }
    defaults.set(Date(), forKey: Key.pendingWake)
  }

  private func recordUnlock() {
    guard let sleepAt = defaults.object(forKey: Key.pendingSleep) as? Date else { return }
    let unlockAt = Date()
    let wakeAt = (defaults.object(forKey: Key.pendingWake) as? Date) ?? unlockAt
    defaults.removeObject(forKey: Key.pendingSleep)
    defaults.removeObject(forKey: Key.pendingWake)
    onObservation(SleepObservation(sleepAt: sleepAt, wakeAt: wakeAt, unlockAt: unlockAt))
  }
}
