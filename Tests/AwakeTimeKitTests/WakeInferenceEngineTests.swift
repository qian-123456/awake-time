import XCTest

@testable import AwakeTimeKit

final class WakeInferenceEngineTests: XCTestCase {
  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  func testLearningPeriodAlwaysAsks() throws {
    let observation = SleepObservation(
      sleepAt: try date(2026, 7, 22, 23, 0),
      wakeAt: try date(2026, 7, 23, 7, 0),
      unlockAt: try date(2026, 7, 23, 7, 5)
    )
    let decision = WakeInferenceEngine.evaluate(
      observation: observation,
      history: Array(trainingHistory().prefix(4)),
      calendar: calendar
    )
    guard case .ask = decision else {
      return XCTFail("Expected the learning period to ask")
    }
  }

  func testPersonalPatternCanAutomaticallyAcceptOvernightWake() throws {
    let observation = SleepObservation(
      sleepAt: try date(2026, 7, 22, 23, 0),
      wakeAt: try date(2026, 7, 23, 7, 55),
      unlockAt: try date(2026, 7, 23, 8, 5)
    )
    let decision = WakeInferenceEngine.evaluate(
      observation: observation,
      history: trainingHistory(),
      calendar: calendar
    )
    guard case .automatic(let confidence) = decision else {
      return XCTFail("Expected a high-confidence automatic decision")
    }
    XCTAssertGreaterThanOrEqual(confidence, 0.78)
  }

  func testShortNapDoesNotAutomaticallyReset() throws {
    let observation = SleepObservation(
      sleepAt: try date(2026, 7, 23, 13, 0),
      wakeAt: try date(2026, 7, 23, 13, 40),
      unlockAt: try date(2026, 7, 23, 13, 41)
    )
    let decision = WakeInferenceEngine.evaluate(
      observation: observation,
      history: trainingHistory(),
      calendar: calendar
    )
    guard case .ask = decision else {
      return XCTFail("Expected a short nap to require confirmation")
    }
  }

  func testUnconfirmedAutomaticRecordsDoNotTrainTheModel() throws {
    let automaticOnly = trainingHistory().map {
      WakeSample(
        wakeAt: $0.wakeAt,
        sleepDuration: $0.sleepDuration,
        source: .adaptiveAutomatic,
        wasCorrected: false
      )
    }
    let observation = SleepObservation(
      sleepAt: try date(2026, 7, 22, 23, 0),
      wakeAt: try date(2026, 7, 23, 7, 55),
      unlockAt: try date(2026, 7, 23, 8, 5)
    )
    let decision = WakeInferenceEngine.evaluate(
      observation: observation,
      history: automaticOnly,
      calendar: calendar
    )
    guard case .ask = decision else {
      return XCTFail("Automatic records must not reinforce the model without confirmation")
    }
  }

  private func trainingHistory() -> [WakeSample] {
    (0..<7).compactMap { offset in
      guard let wake = try? date(2026, 7, 16 - offset, 8, offset * 2) else { return nil }
      return WakeSample(
        wakeAt: wake,
        sleepDuration: TimeInterval((7 * 60 + 30 + offset) * 60),
        source: .adaptiveConfirmed,
        wasCorrected: true
      )
    }
  }

  private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) throws
    -> Date
  {
    try XCTUnwrap(
      calendar.date(
        from: DateComponents(
          year: year,
          month: month,
          day: day,
          hour: hour,
          minute: minute
        )))
  }
}
