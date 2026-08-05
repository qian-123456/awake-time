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
}