import XCTest

@testable import AwakeTimeKit

final class AwakeClockEngineTests: XCTestCase {
  func testNoWakeRecordShowsPlaceholder() {
    XCTAssertEqual(AwakeClockEngine.formatted(from: nil, to: Date()), "--:--")
  }

  func testElapsedClockDoesNotWrapAtTwentyFourHours() {
    let wake = Date(timeIntervalSince1970: 1_000_000)
    XCTAssertEqual(
      AwakeClockEngine.formatted(from: wake, to: wake.addingTimeInterval(24 * 3600)),
      "24:00"
    )
    XCTAssertEqual(
      AwakeClockEngine.formatted(from: wake, to: wake.addingTimeInterval(49 * 3600 + 7 * 60)),
      "49:07"
    )
  }

  func testFutureWakeTimeClampsToZero() {
    let now = Date(timeIntervalSince1970: 1_000_000)
    XCTAssertEqual(
      AwakeClockEngine.formatted(from: now.addingTimeInterval(300), to: now),
      "00:00"
    )
  }

  func testEightHoursOfSleepChangesToNightAfterEightAwakeHours() {
    let wake = Date(timeIntervalSince1970: 1_000_000)
    let sleepDuration = 8 * 60 * 60.0

    XCTAssertEqual(AwakeClockEngine.nightStartsAfter(sleepDuration: sleepDuration), 8 * 60 * 60)
    XCTAssertFalse(
      AwakeClockEngine.isNight(
        from: wake,
        to: wake.addingTimeInterval(8 * 60 * 60 - 1),
        sleepDuration: sleepDuration
      ))
    XCTAssertTrue(
      AwakeClockEngine.isNight(
        from: wake,
        to: wake.addingTimeInterval(8 * 60 * 60),
        sleepDuration: sleepDuration
      ))
  }

  func testNightThresholdChangesWithPreferredSleepDuration() {
    XCTAssertEqual(
      AwakeClockEngine.nightStartsAfter(sleepDuration: 6 * 60 * 60),
      9 * 60 * 60
    )
  }

  func testSleepReminderUsesBedtimeMinusLeadTime() {
    let wake = Date(timeIntervalSince1970: 1_000_000)

    XCTAssertEqual(
      AwakeClockEngine.bedtimeStartsAfter(sleepDuration: 8 * 60 * 60),
      16 * 60 * 60
    )
    XCTAssertEqual(
      AwakeClockEngine.sleepReminderStartsAfter(
        sleepDuration: 8 * 60 * 60,
        leadTime: 60 * 60
      ),
      15 * 60 * 60
    )
    XCTAssertEqual(
      AwakeClockEngine.sleepReminderDate(
        from: wake,
        sleepDuration: 8 * 60 * 60,
        leadTime: 60 * 60
      ),
      wake.addingTimeInterval(15 * 60 * 60)
    )
  }

  func testSleepReminderSupportsLeadTimeBoundaries() {
    XCTAssertEqual(
      AwakeClockEngine.sleepReminderStartsAfter(
        sleepDuration: 8 * 60 * 60,
        leadTime: 0
      ),
      16 * 60 * 60
    )
    XCTAssertEqual(
      AwakeClockEngine.sleepReminderStartsAfter(
        sleepDuration: 8 * 60 * 60,
        leadTime: 4 * 60 * 60
      ),
      12 * 60 * 60
    )
  }

  func testSleepReminderRequiresWakeTimeAndClampsNegativeLeadTime() {
    XCTAssertNil(
      AwakeClockEngine.sleepReminderDate(
        from: nil,
        sleepDuration: 8 * 60 * 60,
        leadTime: 60 * 60
      ))
    XCTAssertEqual(
      AwakeClockEngine.sleepReminderStartsAfter(
        sleepDuration: 8 * 60 * 60,
        leadTime: -60
      ),
      16 * 60 * 60
    )
  }

  func testUpcomingSleepReminderOnlyReturnsFutureReminderForPastWakeTime() {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let sleepDuration = 8 * 60 * 60.0
    let leadTime = 60 * 60.0

    XCTAssertNil(
      AwakeClockEngine.upcomingSleepReminderDate(
        from: nil,
        after: now,
        sleepDuration: sleepDuration,
        leadTime: leadTime
      ))
    XCTAssertNil(
      AwakeClockEngine.upcomingSleepReminderDate(
        from: now.addingTimeInterval(60),
        after: now,
        sleepDuration: sleepDuration,
        leadTime: leadTime
      ))
    XCTAssertNil(
      AwakeClockEngine.upcomingSleepReminderDate(
        from: now.addingTimeInterval(-16 * 60 * 60),
        after: now,
        sleepDuration: sleepDuration,
        leadTime: leadTime
      ))
    XCTAssertEqual(
      AwakeClockEngine.upcomingSleepReminderDate(
        from: now.addingTimeInterval(-14 * 60 * 60),
        after: now,
        sleepDuration: sleepDuration,
        leadTime: leadTime
      ),
      now.addingTimeInterval(60 * 60)
    )
  }

  func testElapsedTimeUsesAbsoluteDurationAcrossDaylightSavingChange() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
    let beforeSpringForward = try XCTUnwrap(
      calendar.date(
        from: DateComponents(
          year: 2026, month: 3, day: 8, hour: 1, minute: 30
        )))
    let afterSpringForward = try XCTUnwrap(
      calendar.date(
        from: DateComponents(
          year: 2026, month: 3, day: 8, hour: 3, minute: 30
        )))

    XCTAssertEqual(
      AwakeClockEngine.formatted(from: beforeSpringForward, to: afterSpringForward),
      "01:00"
    )
  }
}
