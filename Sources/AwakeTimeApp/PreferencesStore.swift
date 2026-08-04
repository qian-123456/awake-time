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
    static let preferredSleepDuration = "preferredSleepDuration"
    static let sleepReminderEnabled = "sleepReminderEnabled"
    static let sleepReminderLeadTime = "sleepReminderLeadTime"
  }

  static let defaultSleepDuration: TimeInterval = 8 * 60 * 60
  static let sleepDurationRange: ClosedRange<TimeInterval> = (4 * 60 * 60)...(12 * 60 * 60)
  static let defaultSleepReminderLeadTime: TimeInterval = 60 * 60
  static let sleepReminderLeadTimeRange: ClosedRange<TimeInterval> = 0...(4 * 60 * 60)

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

  @Published var preferredSleepDuration: TimeInterval {
    didSet { defaults.set(preferredSleepDuration, forKey: Key.preferredSleepDuration) }
  }

  @Published var sleepReminderEnabled: Bool {
    didSet { defaults.set(sleepReminderEnabled, forKey: Key.sleepReminderEnabled) }
  }

  @Published var sleepReminderLeadTime: TimeInterval {
    didSet { defaults.set(sleepReminderLeadTime, forKey: Key.sleepReminderLeadTime) }
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
    let storedSleepDuration = defaults.object(forKey: Key.preferredSleepDuration) as? TimeInterval
    preferredSleepDuration = Self.sleepDurationRange.clamp(storedSleepDuration ?? Self.defaultSleepDuration)
    if defaults.object(forKey: Key.sleepReminderEnabled) == nil {
      sleepReminderEnabled = true
    } else {
      sleepReminderEnabled = defaults.bool(forKey: Key.sleepReminderEnabled)
    }
    let storedLeadTime = defaults.object(forKey: Key.sleepReminderLeadTime) as? TimeInterval
    sleepReminderLeadTime = Self.sleepReminderLeadTimeRange.clamp(
      storedLeadTime ?? Self.defaultSleepReminderLeadTime
    )
  }
}

private extension ClosedRange where Bound == TimeInterval {
  func clamp(_ value: TimeInterval) -> TimeInterval {
    Swift.min(Swift.max(value, lowerBound), upperBound)
  }
}
