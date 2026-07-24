import Foundation

public enum WakeInferenceEngine {
  public static func evaluate(
    observation: SleepObservation,
    history: [WakeSample],
    calendar: Calendar = .current
  ) -> WakeInferenceDecision {
    let trusted = history.filter { sample in
      sample.wasCorrected
        || sample.source == .manual
        || sample.source == .quickStart
        || sample.source == .adaptiveConfirmed
    }
    guard trusted.count >= 5 else {
      return .ask(confidence: 0)
    }

    let candidateWeekday = calendar.component(.weekday, from: observation.unlockAt)
    let candidateIsWeekend = candidateWeekday == 1 || candidateWeekday == 7
    let comparable = trusted.filter { sample in
      let weekday = calendar.component(.weekday, from: sample.wakeAt)
      let isWeekend = weekday == 1 || weekday == 7
      return isWeekend == candidateIsWeekend
    }
    let timeSamples = comparable.count >= 3 ? comparable : trusted
    let minuteValues = timeSamples.map { minuteOfDay($0.wakeAt, calendar: calendar) }
    let expectedMinute = circularMean(minutes: minuteValues)
    let deviations = minuteValues.map { circularDistance($0, expectedMinute) }
    let medianDeviation = percentile(deviations, fraction: 0.5)
    let tolerance = max(45, min(180, medianDeviation * 2.5 + 30))
    let timeDistance = circularDistance(
      minuteOfDay(observation.unlockAt, calendar: calendar), expectedMinute)
    let timeConfidence = max(0, 1 - timeDistance / tolerance)

    let sleepSamples = trusted.compactMap(\.sleepDuration).filter { $0 > 0 }
    guard sleepSamples.count >= 3 else {
      return .ask(confidence: timeConfidence * 0.5)
    }
    let lowerQuartile = percentile(sleepSamples, fraction: 0.25)
    let personalizedFloor = lowerQuartile * 0.75
    let sleepConfidence = min(1, observation.sleepDuration / max(personalizedFloor, 1))
    let confidence = min(1, timeConfidence * 0.65 + sleepConfidence * 0.35)

    if timeDistance <= tolerance, observation.sleepDuration >= personalizedFloor, confidence >= 0.78
    {
      return .automatic(confidence: confidence)
    }
    return .ask(confidence: confidence)
  }

  private static func minuteOfDay(_ date: Date, calendar: Calendar) -> Double {
    let components = calendar.dateComponents([.hour, .minute, .second], from: date)
    return Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
      + Double(components.second ?? 0) / 60
  }

  private static func circularMean(minutes: [Double]) -> Double {
    guard !minutes.isEmpty else { return 0 }
    let radians = minutes.map { $0 / 1440 * 2 * Double.pi }
    let x = radians.reduce(0) { $0 + cos($1) } / Double(radians.count)
    let y = radians.reduce(0) { $0 + sin($1) } / Double(radians.count)
    var angle = atan2(y, x)
    if angle < 0 { angle += 2 * Double.pi }
    return angle / (2 * Double.pi) * 1440
  }

  private static func circularDistance(_ lhs: Double, _ rhs: Double) -> Double {
    let direct = abs(lhs - rhs)
    return min(direct, 1440 - direct)
  }

  private static func percentile(_ values: [Double], fraction: Double) -> Double {
    guard !values.isEmpty else { return 0 }
    let sorted = values.sorted()
    let index = Double(sorted.count - 1) * min(max(fraction, 0), 1)
    let lower = Int(index.rounded(.down))
    let upper = Int(index.rounded(.up))
    guard lower != upper else { return sorted[lower] }
    let weight = index - Double(lower)
    return sorted[lower] * (1 - weight) + sorted[upper] * weight
  }
}
