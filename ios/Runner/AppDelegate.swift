import AppMetricaPush
import FirebaseCore
import FirebaseMessaging
import Flutter
import UIKit
import UserNotifications

/// App Group для обмена данными между приложением и NSE (Notification Service Extension).
/// Target NSE: PushNotificationServiceExtension
private let appMetricaAppGroup = "group.com.kredit7.dney.appmetrica"

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    AppMetricaPush.setExtensionAppGroup(appMetricaAppGroup)
    // UNUserNotificationCenter.delegate настраивает appmetrica_push_plugin:
    // Plugin → AppMetrica delegate → FlutterAppDelegate/FCM.
    // Ручная установка delegate/nextDelegate здесь вызывает бесконечную рекурсию при тапе по push.

    Messaging.messaging().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
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
