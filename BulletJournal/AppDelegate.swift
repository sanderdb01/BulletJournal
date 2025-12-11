import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // ✅ CRITICAL: Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        print("✅ AppDelegate initialized - notification delegate set")
        return true
    }
    
    // ✅ CRITICAL: Show notifications even when app is open
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 Notification will present: \(notification.request.identifier)")
        print("   Title: \(notification.request.content.title)")
        print("   Body: \(notification.request.content.body)")
        
        // Show notification even if app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap (when user taps the notification)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        print("📱 User tapped notification: \(identifier)")
        
        // Handle different notification types
        if identifier.starts(with: "daily-reminder") {
            // Navigate to today's tasks (optional - implement later)
            print("→ Should navigate to DayView")
            
            // Optional: Post notification for your app to handle
            NotificationCenter.default.post(
                name: .openDayView,
                object: nil
            )
        } else if identifier.starts(with: "test-reminder") {
            print("→ Test notification tapped")
        }
        
        completionHandler()
    }
}
