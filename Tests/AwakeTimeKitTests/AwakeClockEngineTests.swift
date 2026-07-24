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
