import Foundation

public enum ScheduleEngine {
  public static func mostRecentOccurrence(
    before now: Date,
    schedule: WeeklySchedule,
    calendar: Calendar = .autoupdatingCurrent
  ) -> ScheduledOccurrence? {
    for dayOffset in 0...7 {
      guard let candidateDay = calendar.date(byAdding: .day, value: -dayOffset, to: now) else {
        continue
      }
      let weekdayValue = calendar.component(.weekday, from: candidateDay)
      guard let weekday = Weekday(rawValue: weekdayValue) else { continue }
      let setting = schedule[weekday]
      guard setting.isEnabled else { continue }

      var components = calendar.dateComponents([.year, .month, .day], from: candidateDay)
      components.hour = setting.hour
      components.minute = setting.minute
      components.second = 0

      guard let occurrence = calendar.date(from: components), occurrence <= now else {
        continue
      }
      return ScheduledOccurrence(
        date: occurrence,
        logicalDayKey: DayKey.make(for: occurrence, calendar: calendar)
      )
    }
    return nil
  }
}
