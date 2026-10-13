import UIKit
import UserNotifications

// Shows notifications even while the app is in the foreground (good for testing).
final class NotifDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotifDelegate()
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

enum Notifier {
    static func setup() {
        UNUserNotificationCenter.current().delegate = NotifDelegate.shared
    }

    // Ask for permission (first time), or send them to Settings if they said no.
    static func enable() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { s in
            switch s.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
            case .denied:
                DispatchQueue.main.async {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            default:
                break
            }
        }
    }

    // Red number on the app icon (unseen cravings). 0 clears it.
    static func setBadge(_ n: Int) {
        UNUserNotificationCenter.current().setBadgeCount(max(0, n))
    }

    // Fire a local notification now.
    static func fire(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
