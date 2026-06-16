import AppMetricaPush
import FirebaseCore
import FirebaseMessaging
import Flutter
import UIKit
import UserNotifications

/// App Group для обмена данными между приложением и NSE (Notification Service Extension).
/// Target NSE: PushNotificationServiceExtension
private let appMetricaAppGroup = "group.com.kredit7.dney.appmetrica"

private enum PendingPushOpenStorage {
  private static let pendingKey = "pending_push_open_flag"
  private static let payloadKey = "pending_push_open_payload"

  static func save(_ userInfo: [AnyHashable: Any]) {
    let payload = AppMetricaPush.userData(forNotification: userInfo) ?? ""
    UserDefaults.standard.set(true, forKey: pendingKey)
    UserDefaults.standard.set(payload, forKey: payloadKey)
  }

  static func consume() -> [String: Any]? {
    guard UserDefaults.standard.bool(forKey: pendingKey) else { return nil }
    let payload = UserDefaults.standard.string(forKey: payloadKey) ?? ""
    clear()
    return [
      "opened": true,
      "payload": payload,
    ]
  }

  static func clear() {
    UserDefaults.standard.removeObject(forKey: pendingKey)
    UserDefaults.standard.removeObject(forKey: payloadKey)
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var pendingPushOpenChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    AppMetricaPush.setExtensionAppGroup(appMetricaAppGroup)
    // UNUserNotificationCenter.delegate настраивает appmetrica_push_plugin:
    // Plugin → AppMetrica delegate → FlutterAppDelegate/FCM.
    // Ручная установка delegate/nextDelegate здесь вызывает бесконечную рекурсию при тапе по push.

    if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      PendingPushOpenStorage.save(userInfo)
    }

    Messaging.messaging().delegate = self

    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    setupPendingPushOpenChannel()
    return didFinish
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    setupPendingPushOpenChannel()
    clearApplicationBadge()
    super.applicationDidBecomeActive(application)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    if AppMetricaPush.isNotificationRelated(toSDK: userInfo) {
      PendingPushOpenStorage.save(userInfo)
    }
    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }

  private func setupPendingPushOpenChannel() {
    guard pendingPushOpenChannel == nil,
          let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "com.kredit7.dney/pending_push_open",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "consumePendingPushOpen":
        result(PendingPushOpenStorage.consume())
      case "clearPendingPushOpen":
        PendingPushOpenStorage.clear()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    pendingPushOpenChannel = channel
  }

  private func clearApplicationBadge() {
    if #available(iOS 16.0, *) {
      UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    } else {
      UIApplication.shared.applicationIconBadgeNumber = 0
    }
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    // FlutterFire подхватит токен в Dart.
  }
}
