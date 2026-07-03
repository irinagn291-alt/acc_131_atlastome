import UIKit
@preconcurrency import Alamofire
import OneSignalFramework

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppConfiguration.serverBaseURL = "https://iosapp-atlastome.pro"

        OneSignal.initialize("fb34bbe8-825f-48a0-82e9-60fd4fe7fb8a", withLaunchOptions: launchOptions)
        OneSignal.Notifications.requestPermission({ _ in }, fallbackToSettings: false)
        application.registerForRemoteNotifications()

        return true
    }
}
