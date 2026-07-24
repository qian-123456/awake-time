import Foundation

public enum AwakeClockEngine {
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
}

public enum DayKey {
  public static func make(for date: Date, calendar: Calendar = .current) -> String {
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    return String(
      format: "%04d-%02d-%02d",
      components.year ?? 0,
      components.month ?? 0,
      components.day ?? 0
    )
  }
}
