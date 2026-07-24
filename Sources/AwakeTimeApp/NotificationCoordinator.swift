import Foundation
import UserNotifications

final class NotificationCoordinator: NSObject, UNUserNotificationCenterDelegate {
  private enum Identifier {
    static let confirmCategory = "AWAKE_CONFIRM_CATEGORY"
    static let automaticCategory = "AWAKE_AUTOMATIC_CATEGORY"
    static let confirmAction = "AWAKE_CONFIRM_ACTION"
    static let dismissAction = "AWAKE_DISMISS_ACTION"
    static let undoAction = "AWAKE_UNDO_ACTION"
  }

  var onConfirm: (() -> Void)?
  var onDismiss: (() -> Void)?
  var onUndo: ((UUID?) -> Void)?

  override init() {
    super.init()
    let center = UNUserNotificationCenter.current()
    center.delegate = self
    updateActionTitles(confirm: "Start New Day", dismiss: "Not This Time", undo: "Undo")
  }

  func updateActionTitles(confirm: String, dismiss: String, undo: String) {
    registerCategories(confirmTitle: confirm, dismissTitle: dismiss, undoTitle: undo)
  }

  func requestAuthorization() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
  }

  func sendConfirmation(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.categoryIdentifier = Identifier.confirmCategory
    let request = UNNotificationRequest(identifier: "wake-confirm", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
  }

  func sendAutomaticReset(title: String, body: String, recordID: UUID) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.categoryIdentifier = Identifier.automaticCategory
    content.userInfo = ["recordID": recordID.uuidString]
    let request = UNNotificationRequest(
      identifier: "wake-auto-\(recordID.uuidString)", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
  }

  func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      completion(settings.authorizationStatus)
    }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let id = response.actionIdentifier
    if id == Identifier.confirmAction || id == UNNotificationDefaultActionIdentifier {
      onConfirm?()
    } else if id == Identifier.dismissAction {
      onDismiss?()
    } else if id == Identifier.undoAction {
      let value = response.notification.request.content.userInfo["recordID"] as? String
      onUndo?(value.flatMap(UUID.init(uuidString:)))
    }
    completionHandler()
  }

  private func registerCategories(confirmTitle: String, dismissTitle: String, undoTitle: String) {
    let confirm = UNNotificationAction(identifier: Identifier.confirmAction, title: confirmTitle)
    let dismiss = UNNotificationAction(identifier: Identifier.dismissAction, title: dismissTitle)
    let undo = UNNotificationAction(
      identifier: Identifier.undoAction, title: undoTitle, options: [.destructive])
    let confirmCategory = UNNotificationCategory(
      identifier: Identifier.confirmCategory,
      actions: [confirm, dismiss],
      intentIdentifiers: []
    )
    let automaticCategory = UNNotificationCategory(
      identifier: Identifier.automaticCategory,
      actions: [undo],
      intentIdentifiers: []
    )
    UNUserNotificationCenter.current().setNotificationCategories([
      confirmCategory, automaticCategory,
    ])
  }
}
