import Foundation

public enum AwakeClockEngine {
  public static let secondsPerDay: TimeInterval = 24 * 60 * 60

  public static func elapsed(from wakeAt: Date?, to now: Date) -> TimeInterval? {
    guard let wakeAt else { return nil }
    return max(0, now.timeIntervalSince(wakeAt))
  }

  public static func formatted(from wakeAt: Date?, to now: Date) -> String {
    guard let elapsed = elapsed(from: wakeAt, to: now) else { return "--:--" }
    let totalMinutes = Int(elapsed) / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    return String(format: "%02d:%02d", hours, minutes)
  }

  public static func nightStartsAfter(sleepDuration: TimeInterval) -> TimeInterval {
    max(0, (secondsPerDay - sleepDuration) / 2)
  }

  public static func bedtimeStartsAfter(sleepDuration: TimeInterval) -> TimeInterval {
    max(0, secondsPerDay - sleepDuration)
  }

  public static func bedtimeDate(
    from wakeAt: Date?,
    sleepDuration: TimeInterval
  ) -> Date? {
    guard let wakeAt else { return nil }
    return wakeAt.addingTimeInterval(
      bedtimeStartsAfter(sleepDuration: sleepDuration)
    )
  }

  public static func sleepReminderStartsAfter(
    sleepDuration: TimeInterval,
    leadTime: TimeInterval
  ) -> TimeInterval {
    max(0, bedtimeStartsAfter(sleepDuration: sleepDuration) - max(0, leadTime))
  }

  public static func sleepReminderDate(
    from wakeAt: Date?,
    sleepDuration: TimeInterval,
    leadTime: TimeInterval
  ) -> Date? {
    guard let wakeAt else { return nil }
    return wakeAt.addingTimeInterval(
      sleepReminderStartsAfter(sleepDuration: sleepDuration, leadTime: leadTime)
    )
  }

  public static func upcomingSleepReminderDate(
    from wakeAt: Date?,
    after now: Date,
    sleepDuration: TimeInterval,
    leadTime: TimeInterval
  ) -> Date? {
    guard let wakeAt, wakeAt <= now else { return nil }
    guard
      let reminderDate = sleepReminderDate(
        from: wakeAt,
        sleepDuration: sleepDuration,
        leadTime: leadTime
      ),
      reminderDate > now
    else { return nil }
    return reminderDate
  }

  public static func isNight(
    from wakeAt: Date?,
    to now: Date,
    sleepDuration: TimeInterval
  ) -> Bool {
    guard let elapsed = elapsed(from: wakeAt, to: now) else { return false }
    return elapsed >= nightStartsAfter(sleepDuration: sleepDuration)
  }
}

public enum DayKey {
  public static func make(for date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    return String(
      format: "%04d-%02d-%02d",
      components.year ?? 0,
      components.month ?? 0,
      components.day ?? 0
    )
  }
}
