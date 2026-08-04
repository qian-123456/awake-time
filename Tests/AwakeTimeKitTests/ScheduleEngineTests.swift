import XCTest

@testable import AwakeTimeKit

final class ScheduleEngineTests: XCTestCase {
  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  func testUsesTodaysOccurrenceAfterScheduledTime() throws {
    let now = try XCTUnwrap(
      calendar.date(
        from: DateComponents(
          year: 2026, month: 7, day: 23, hour: 10
        )))
    var schedule = WeeklySchedule()
    schedule[.thursday] = DailySchedule(weekday: .thursday, isEnabled: true, hour: 8, minute: 30)

    let occurrence = try XCTUnwrap(
      ScheduleEngine.mostRecentOccurrence(
        before: now,
        schedule: schedule,
        calendar: calendar
      ))
    XCTAssertEqual(occurrence.logicalDayKey, "2026-07-23")
    XCTAssertEqual(calendar.component(.hour, from: occurrence.date), 8)
    XCTAssertEqual(calendar.component(.minute, from: occurrence.date), 30)
  }

  func testSkipsFutureTimeAndUsesPreviousEnabledDay() throws {
    let now = try XCTUnwrap(
      calendar.date(
        from: DateComponents(
          year: 2026, month: 7, day: 23, hour: 7
        )))
    var schedule = WeeklySchedule()
    schedule[.wednesday] = DailySchedule(weekday: .wednesday, isEnabled: true, hour: 9, minute: 0)
    schedule[.thursday] = DailySchedule(weekday: .thursday, isEnabled: true, hour: 8, minute: 0)

    let occurrence = try XCTUnwrap(
      ScheduleEngine.mostRecentOccurrence(
        before: now,
        schedule: schedule,
        calendar: calendar
      ))
    XCTAssertEqual(occurrence.logicalDayKey, "2026-07-22")
  }

  func testDisabledScheduleHasNoOccurrence() {
    XCTAssertNil(
      ScheduleEngine.mostRecentOccurrence(
        before: Date(),
        schedule: WeeklySchedule(),
        calendar: calendar
      ))
  }

  func testOccurrenceUsesLocalWallClockInProvidedTimeZone() throws {
    var tokyoCalendar = Calendar(identifier: .gregorian)
    tokyoCalendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
    let now = try XCTUnwrap(
      tokyoCalendar.date(
        from: DateComponents(
          year: 2026, month: 8, day: 4, hour: 9
        )))
    var schedule = WeeklySchedule()
    schedule[.tuesday] = DailySchedule(
      weekday: .tuesday,
      isEnabled: true,
      hour: 8,
      minute: 15
    )

    let occurrence = try XCTUnwrap(
      ScheduleEngine.mostRecentOccurrence(
        before: now,
        schedule: schedule,
        calendar: tokyoCalendar
      ))

    XCTAssertEqual(occurrence.logicalDayKey, "2026-08-04")
    XCTAssertEqual(tokyoCalendar.component(.hour, from: occurrence.date), 8)
    XCTAssertEqual(tokyoCalendar.component(.minute, from: occurrence.date), 15)
  }
}
