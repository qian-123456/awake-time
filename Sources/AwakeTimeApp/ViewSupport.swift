import AwakeTimeKit
import Foundation

enum ViewSupport {
  static func dateTime(_ date: Date, language: AppLanguage) -> String {
    let formatter = DateFormatter()
    formatter.locale =
      language.resolved == .simplifiedChinese
      ? Locale(identifier: "zh_Hans_CN")
      : Locale(identifier: "en_US")
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  static func time(_ date: Date, language: AppLanguage) -> String {
    let formatter = DateFormatter()
    formatter.locale =
      language.resolved == .simplifiedChinese
      ? Locale(identifier: "zh_Hans_CN")
      : Locale(identifier: "en_US")
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}
