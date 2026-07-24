import AwakeTimeKit
import Combine
import Foundation

@MainActor
final class PreferencesStore: ObservableObject {
  private enum Key {
    static let mode = "clockMode"
    static let language = "appLanguage"
    static let weeklySchedule = "weeklySchedule"
    static let onboardingComplete = "onboardingComplete"
  }

  private let defaults: UserDefaults

  @Published var mode: ClockMode {
    didSet { defaults.set(mode.rawValue, forKey: Key.mode) }
  }

  @Published var language: AppLanguage {
    didSet { defaults.set(language.rawValue, forKey: Key.language) }
  }

  @Published var weeklySchedule: WeeklySchedule {
    didSet {
      if let data = try? JSONEncoder().encode(weeklySchedule) {
        defaults.set(data, forKey: Key.weeklySchedule)
      }
    }
  }

  @Published var onboardingComplete: Bool {
    didSet { defaults.set(onboardingComplete, forKey: Key.onboardingComplete) }
  }

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    mode = ClockMode(rawValue: defaults.string(forKey: Key.mode) ?? "") ?? .clickToStart
    language = AppLanguage(rawValue: defaults.string(forKey: Key.language) ?? "") ?? .system
    if let data = defaults.data(forKey: Key.weeklySchedule),
      let decoded = try? JSONDecoder().decode(WeeklySchedule.self, from: data)
    {
      weeklySchedule = decoded
    } else {
      weeklySchedule = WeeklySchedule()
    }
    onboardingComplete = defaults.bool(forKey: Key.onboardingComplete)
  }
}
