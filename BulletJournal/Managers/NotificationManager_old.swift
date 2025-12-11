//import Foundation
//import UserNotifications
//import SwiftData
//
//class NotificationManager {
//    static let shared = NotificationManager()
//    
//    private init() {}
//    
//    // Request notification permission
//    func requestAuthorization() async -> Bool {
//        do {
//            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
//                options: [.alert, .sound, .badge]
//            )
//            return granted
//        } catch {
//            print("Error requesting notification authorization: \(error)")
//            return false
//        }
//    }
//    
//    // Check current authorization status
//    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
//        let settings = await UNUserNotificationCenter.current().notificationSettings()
//        return settings.authorizationStatus
//    }
//    
//    // Schedule notification for a task
//    func scheduleTaskNotification(task: TaskItem, date: Date) async -> String? {
//        // Make sure we have permission
//        let status = await checkAuthorizationStatus()
//        guard status == .authorized else {
//            print("Notification permission not granted")
//            return nil
//        }
//        
//        guard let taskName = task.name,
//              let reminderTime = task.reminderTime else {
//            return nil
//        }
//        
//        // Create notification content
//        let content = UNMutableNotificationContent()
//        content.title = "Task Reminder"
//        content.body = taskName
//        content.sound = .default
//        
//        // Add task color as category for visual distinction
//        if let color = task.color {
//            content.categoryIdentifier = "task.\(color)"
//        }
//        
//        // Create trigger from reminder time
//        let components = Calendar.current.dateComponents(
//            [.year, .month, .day, .hour, .minute],
//            from: reminderTime
//        )
//        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
//        
//        // Create unique identifier
//        let identifier = UUID().uuidString
//        
//        // Create request
//        let request = UNNotificationRequest(
//            identifier: identifier,
//            content: content,
//            trigger: trigger
//        )
//        
//        // Schedule notification
//        do {
//            try await UNUserNotificationCenter.current().add(request)
//            print("✅ Scheduled notification for: \(taskName) at \(reminderTime)")
//            return identifier
//        } catch {
//            print("❌ Error scheduling notification: \(error)")
//            return nil
//        }
//    }
//    
//    // Cancel notification for a task
//    func cancelTaskNotification(notificationId: String) {
//        UNUserNotificationCenter.current().removePendingNotificationRequests(
//            withIdentifiers: [notificationId]
//        )
//        print("❌ Cancelled notification: \(notificationId)")
//    }
//    
//    // Schedule daily summary notification
//    func scheduleDailySummary(hour: Int, minute: Int) async {
//        let content = UNMutableNotificationContent()
//        content.title = "Daily Summary"
//        content.body = "Check your tasks for today"
//        content.sound = .default
//        content.categoryIdentifier = "daily.summary"
//        
//        // Trigger every day at specified time
//        var dateComponents = DateComponents()
//        dateComponents.hour = hour
//        dateComponents.minute = minute
//        
//        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
//        
//        let request = UNNotificationRequest(
//            identifier: "daily-summary",
//            content: content,
//            trigger: trigger
//        )
//        
//        do {
//            try await UNUserNotificationCenter.current().add(request)
//            print("✅ Scheduled daily summary for \(hour):\(minute)")
//        } catch {
//            print("❌ Error scheduling daily summary: \(error)")
//        }
//    }
//    
//    // Cancel daily summary
//    func cancelDailySummary() {
//        UNUserNotificationCenter.current().removePendingNotificationRequests(
//            withIdentifiers: ["daily-summary"]
//        )
//    }
//    
//    // Get all pending notifications
//    func getPendingNotifications() async -> [UNNotificationRequest] {
//        return await UNUserNotificationCenter.current().pendingNotificationRequests()
//    }
//}
