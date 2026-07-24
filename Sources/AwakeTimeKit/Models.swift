import Foundation
import SwiftData

public enum ClockMode: String, Codable, CaseIterable, Identifiable, Sendable {
  case manual
  case adaptiveUnlock
  case clickToStart
  case weeklySchedule

  public var id: String { rawValue }
}

public enum WakeSource: String, Codable, CaseIterable, Sendable {
  case manual
  case quickStart
  case adaptiveConfirmed
  case adaptiveAutomatic
  case weeklySchedule
}

public enum AppLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
  case system
  case simplifiedChinese
  case english

  public var id: String { rawValue }

  public var resolved: AppLanguage {
    guard self == .system else { return self }
    let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
    return preferred.hasPrefix("zh") ? .simplifiedChinese : .english
  }
}

public enum Weekday: Int, Codable, CaseIterable, Identifiable, Sendable {
  case sunday = 1
  case monday = 2
  case tuesday = 3
  case wednesday = 4
  case thursday = 5
  case friday = 6
  case saturday = 7

  public var id: Int { rawValue }
  public var isWeekend: Bool { self == .saturday || self == .sunday }
}

public struct DailySchedule: Codable, Equatable, Sendable {
  public var weekday: Weekday
  public var isEnabled: Bool
  public var hour: Int
  public var minute: Int

  public init(weekday: Weekday, isEnabled: Bool = false, hour: Int = 8, minute: Int = 0) {
    self.weekday = weekday
    self.isEnabled = isEnabled
    self.hour = hour
    self.minute = minute
  }
}

public struct WeeklySchedule: Codable, Equatable, Sendable {
  public var days: [DailySchedule]

  public init(days: [DailySchedule] = Weekday.allCases.map { DailySchedule(weekday: $0) }) {
    self.days = days
  }

  public subscript(weekday: Weekday) -> DailySchedule {
    get { days.first(where: { $0.weekday == weekday }) ?? DailySchedule(weekday: weekday) }
    set {
      if let index = days.firstIndex(where: { $0.weekday == weekday }) {
        days[index] = newValue
      } else {
        days.append(newValue)
      }
    }
  }
}

public struct SleepObservation: Codable, Equatable, Sendable {
  public var sleepAt: Date
  public var wakeAt: Date
  public var unlockAt: Date

  public init(sleepAt: Date, wakeAt: Date, unlockAt: Date) {
    self.sleepAt = sleepAt
    self.wakeAt = wakeAt
    self.unlockAt = unlockAt
  }

  public var sleepDuration: TimeInterval {
    max(0, wakeAt.timeIntervalSince(sleepAt))
  }
}

@Model
public final class WakeRecord {
  @Attribute(.unique) public var id: UUID
  public var wakeAt: Date
  public var createdAt: Date
  public var sourceRawValue: String
  public var confidence: Double?
  public var wasCorrected: Bool
  public var logicalDayKey: String
  public var sleepDuration: TimeInterval?

  public init(
    id: UUID = UUID(),
    wakeAt: Date,
    createdAt: Date = Date(),
    source: WakeSource,
    confidence: Double? = nil,
    wasCorrected: Bool = false,
    logicalDayKey: String,
    sleepDuration: TimeInterval? = nil
  ) {
    self.id = id
    self.wakeAt = wakeAt
    self.createdAt = createdAt
    self.sourceRawValue = source.rawValue
    self.confidence = confidence
    self.wasCorrected = wasCorrected
    self.logicalDayKey = logicalDayKey
    self.sleepDuration = sleepDuration
  }

  public var source: WakeSource {
    get { WakeSource(rawValue: sourceRawValue) ?? .manual }
    set { sourceRawValue = newValue.rawValue }
  }
}

public struct WakeSample: Equatable, Sendable {
  public var wakeAt: Date
  public var sleepDuration: TimeInterval?
  public var source: WakeSource
  public var wasCorrected: Bool

  public init(wakeAt: Date, sleepDuration: TimeInterval?, source: WakeSource, wasCorrected: Bool) {
    self.wakeAt = wakeAt
    self.sleepDuration = sleepDuration
    self.source = source
    self.wasCorrected = wasCorrected
  }
}

public enum WakeInferenceDecision: Equatable, Sendable {
  case ask(confidence: Double)
  case automatic(confidence: Double)
}

public struct ScheduledOccurrence: Equatable, Sendable {
  public var date: Date
  public var logicalDayKey: String

  public init(date: Date, logicalDayKey: String) {
    self.date = date
    self.logicalDayKey = logicalDayKey
  }
}
