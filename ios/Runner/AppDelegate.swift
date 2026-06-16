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

    let pushDelegate = AppMetricaPush.userNotificationCenterDelegate
    pushDelegate.nextDelegate = self
    UNUserNotificationCenter.current().delegate = pushDelegate

    Messaging.messaging().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    super.userNotificationCenter(
      center,
      willPresent: notification,
      withCompletionHandler: completionHandler
    )
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    // FlutterFire подхватит токен в Dart.
  }
}
