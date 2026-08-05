import Foundation

public enum WakeTimeGranularity {
  public static let minuteStep = 5

  public static func floorToStep(
    _ date: Date,
    calendar: Calendar = .autoupdatingCurrent
  ) -> Date {
    var components = calendar.dateComponents(
      [.year, .month, .day, .hour, .minute],
      from: date
    )
    let minute = components.minute ?? 0
    components.minute = minute / minuteStep * minuteStep
    components.second = 0
    components.nanosecond = 0
    return calendar.date(from: components) ?? date
  }

  public static func addingMinutes(
    _ amount: Int,
    toHour hour: Int,
    minute: Int
  ) -> (hour: Int, minute: Int) {
    let minutesInDay = 24 * 60
    let totalMinutes = hour * 60 + minute + amount
    let normalizedMinutes = (totalMinutes % minutesInDay + minutesInDay) % minutesInDay
    return (normalizedMinutes / 60, normalizedMinutes % 60)
  }
}
