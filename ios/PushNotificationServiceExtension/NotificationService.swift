import AppMetricaCore
import AppMetricaPush
import UserNotifications

/// NSE (Notification Service Extension) — учёт метрики **Delivered** в AppMetrica.
/// Target: PushNotificationServiceExtension.appex
private let appMetricaAppGroup = "group.com.kredit7.dney.appmetrica"

class NotificationService: UNNotificationServiceExtension {
  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    AppMetricaPush.setExtensionAppGroup(appMetricaAppGroup)
    AppMetricaPush.handleDidReceive(request)

    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    AppMetrica.sendEventsBuffer()

    if let bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }

  override func serviceExtensionTimeWillExpire() {
    if let contentHandler, let bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }
}
