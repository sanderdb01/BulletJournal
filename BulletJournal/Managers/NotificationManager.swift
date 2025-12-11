import Foundation
import UserNotifications
import SwiftData

/// Manages all notification types for HarborDot
///
/// This manager handles:
/// - Per-task reminders with specific times
/// - Daily reminder for incomplete tasks (smart checking)
/// - Future: Per-tag reminders
///
/// ## Usage
/// ```swift
/// let manager = NotificationManager.shared
/// manager.modelContext = modelContext
///
/// // Schedule task reminder
/// let id = await manager.scheduleTaskNotification(task: task, date: date)
///
/// // Schedule daily reminder
/// await manager.scheduleDailyReminder(at: date, enabled: true)
/// ```
class NotificationManager {
    static let shared = NotificationManager()
    
    /// SwiftData context for checking task status
    ///
    /// Must be set before using daily reminder features
    var modelContext: ModelContext?
    
    private init() {}
    
    // MARK: - Permission Handling
    
    /// Request notification permission
    ///
    /// - Returns: `true` if permission granted, `false` otherwise
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    ///
    /// - Returns: Current notification authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    /// Requests permission if needed
    ///
    /// - Returns: `true` if permission is granted or was already granted
    private func requestPermissionIfNeeded() async -> Bool {
        let status = await checkAuthorizationStatus()
        
        switch status {
        case .authorized, .provisional:
            return true
            
        case .notDetermined:
            return await requestAuthorization()
            
        case .denied, .ephemeral:
            return false
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Per-Task Notifications
    
    /// Schedule notification for a specific task
    ///
    /// Creates a one-time notification for a task at its reminder time.
    ///
    /// - Parameters:
    ///   - task: The task to create a reminder for
    ///   - date: The date/time for the notification
    /// - Returns: Notification identifier, or `nil` if scheduling failed
    ///
    /// ## Example
    /// ```swift
    /// let notificationId = await manager.scheduleTaskNotification(
    ///     task: myTask,
    ///     date: reminderDate
    /// )
    /// myTask.notificationId = notificationId
    /// ```
    func scheduleTaskNotification(task: TaskItem, date: Date) async -> String? {
        // Make sure we have permission
        let status = await checkAuthorizationStatus()
        guard status == .authorized else {
            print("Notification permission not granted")
            return nil
        }
        
        guard let taskName = task.name,
              let reminderTime = task.reminderTime else {
            return nil
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = taskName
        content.sound = .default
        
        // Add task color as category for visual distinction
        if let color = task.color {
            content.categoryIdentifier = "task.\(color)"
        }
        
        // Add task ID to user info for navigation
        if let taskId = task.id {
            content.userInfo = [
                "type": "task-reminder",
                "taskId": taskId.uuidString
            ]
        }
        
        // Create trigger from reminder time
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create unique identifier
        let identifier = UUID().uuidString
        
        // Create request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Scheduled notification for: \(taskName) at \(reminderTime)")
            return identifier
        } catch {
            print("❌ Error scheduling notification: \(error)")
            return nil
        }
    }
    
    /// Cancel notification for a task
    ///
    /// Removes a scheduled task notification by its identifier
    ///
    /// - Parameter notificationId: The notification identifier to cancel
    func cancelTaskNotification(notificationId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationId]
        )
        print("🔕 Cancelled notification: \(notificationId)")
    }
    
    // MARK: - Daily Reminder (Smart Checking)
    
    /// The notification identifier for daily reminders
    private let dailyReminderIdentifier = "daily-reminder"
    
    /// Schedules or updates the daily reminder notification
    ///
    /// Creates a one-time notification for today at the specified time.
    /// **Smart checking:** Only sends if there are incomplete tasks at notification time.
    ///
    /// - Parameters:
    ///   - time: The time of day to send the reminder
    ///   - enabled: Whether the reminder should be active
    ///
    /// ## Example
    /// ```swift
    /// // Set reminder for 8:00 PM
    /// let time = Calendar.current.date(
    ///     bySettingHour: 20,
    ///     minute: 0,
    ///     second: 0,
    ///     of: Date()
    /// )!
    /// await manager.scheduleDailyReminder(at: time, enabled: true)
    /// ```
    ///
    /// - Important: Requires notification permission and ModelContext to be set
    /// - Note: This is re-scheduled daily. Call this from app initialization to restore.
    func scheduleDailyReminder(at time: Date, enabled: Bool) async {
        // Cancel existing reminder
        await cancelDailyReminder()
        
        guard enabled else {
            print("📵 Daily reminder disabled")
            return
        }
        
        // Request permission if needed
        let hasPermission = await requestPermissionIfNeeded()
        guard hasPermission else {
            print("⚠️ Notification permission denied")
            return
        }
        
        // Extract hour and minute
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        guard let hour = components.hour, let minute = components.minute else {
            print("❌ Invalid time components")
            return
        }
        
        // ✅ CHECK: Do we have incomplete tasks right now?
        let incompleteCount = getIncompleteTaskCount()
        
        if incompleteCount == 0 {
            print("📵 All tasks complete - skipping reminder for today")
            // Will be re-scheduled tomorrow when app opens
            return
        }
        
        print("📋 Found \(incompleteCount) incomplete task(s) - scheduling reminder")
        
        // Calculate next occurrence of this time
        let now = Date()
        var targetDate = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: now)!
        
        // If the time has already passed today, schedule for tomorrow
        if targetDate <= now {
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
            print("⏭️ Time has passed today, scheduling for tomorrow")
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Complete Your Tasks"
        content.body = "You have \(incompleteCount) unfinished task\(incompleteCount == 1 ? "" : "s") for today. Take a moment to update them!"
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"
        
        // Store context info
        content.userInfo = [
            "type": "daily-reminder",
            "incompleteCount": incompleteCount
        ]
        
        // Create trigger for specific date/time (one-time, not repeating)
        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: targetDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerComponents,
            repeats: false  // ✅ One-time notification
        )
        
        // Create request
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        do {
            try await UNUserNotificationCenter.current().add(request)
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            print("✅ Daily reminder scheduled for \(formatter.string(from: targetDate))")
        } catch {
            print("❌ Failed to schedule daily reminder: \(error)")
        }
    }
    
    /// Cancels the daily reminder notification
    ///
    /// Removes the scheduled notification. Call this when the user
    /// disables reminders in settings.
    ///
    /// - Note: Safe to call even if no reminder is scheduled
    func cancelDailyReminder() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [dailyReminderIdentifier]
        )
        print("📵 Daily reminder cancelled")
    }
    
    /// Checks if there are incomplete tasks for today
    ///
    /// Used to determine whether to actually send the notification.
    /// A task is considered incomplete if its status is `.normal`.
    ///
    /// - Returns: The number of incomplete tasks for today
    ///
    /// - Note: Future enhancement: filter by specific tag
    func getIncompleteTaskCount() -> Int {
        guard let context = modelContext else {
            print("⚠️ ModelContext not set")
            return 0
        }
        
        let today = Date()
        let descriptor = FetchDescriptor<DayLog>()
        
        do {
            let allLogs = try context.fetch(descriptor)
            
            // Find today's log
            guard let todayLog = allLogs.first(where: { log in
                guard let logDate = log.date else { return false }
                return Calendar.current.isDate(logDate, inSameDayAs: today)
            }) else {
                return 0
            }
            
            // Count incomplete tasks (status = .normal)
            let incompleteTasks = todayLog.tasks?.filter { task in
                task.status == .normal
            } ?? []
            
            return incompleteTasks.count
            
        } catch {
            print("❌ Error fetching tasks: \(error)")
            return 0
        }
    }
    
    /// Refreshes the daily reminder for the current day
    ///
    /// Call this method:
    /// - On app launch (to restore/update reminder for today)
    /// - After midnight (to schedule for new day)
    /// - When tasks are completed (to cancel if all done)
    ///
    /// This checks current task status and either schedules or skips
    /// the reminder based on whether there are incomplete tasks.
    ///
    /// ## Example
    /// ```swift
    /// // Call on app launch
    /// .onAppear {
    ///     Task {
    ///         await NotificationManager.shared.refreshDailyReminder()
    ///     }
    /// }
    /// ```
    func refreshDailyReminder() async {
        // Get saved settings
        let defaults = UserDefaults.standard
        let enabled = defaults.bool(forKey: "reminderEnabled")
        let hour = defaults.integer(forKey: "reminderTimeHour")
        let minute = defaults.integer(forKey: "reminderTimeMinute")
        
        guard enabled else {
            print("📵 Reminder disabled in settings")
            return
        }
        
        // Reconstruct the time
        var components = DateComponents()
        components.hour = hour == 0 && minute == 0 ? 20 : hour  // Default to 8 PM if not set
        components.minute = minute
        
        if let time = Calendar.current.date(from: components) {
            await scheduleDailyReminder(at: time, enabled: true)
        }
    }
    
    // MARK: - Future: Per-Tag Reminders
    
    /// Schedules per-tag reminders (Future implementation - Phase 2)
    ///
    /// This method is a placeholder for future implementation where
    /// users can set different reminder times for different tags.
    ///
    /// - Parameters:
    ///   - tag: The tag to set a reminder for
    ///   - time: When to send the reminder for this tag
    ///   - enabled: Whether this tag's reminder is active
    ///
    /// ## Future Architecture
    /// ```swift
    /// // Will store in Tag model:
    /// class Tag {
    ///     var reminderTime: Date?
    ///     var reminderEnabled: Bool = false
    /// }
    ///
    /// // Will create multiple notification identifiers:
    /// "daily-reminder-tag-{tag.id}"
    /// ```
    func scheduleTagReminder(tag: Tag, at time: Date, enabled: Bool) async {
        // TODO: Phase 2 implementation
        print("🚧 Per-tag reminders not yet implemented")
        
        // Future implementation will:
        // 1. Use tag-specific notification identifier: "daily-reminder-tag-{tag.id}"
        // 2. Filter tasks by tag when checking incomplete status
        // 3. Customize notification message per tag
        // 4. Store reminder settings in Tag model
    }
    
    // MARK: - Legacy Methods (Deprecated)
    
    /// Schedule daily summary notification
    ///
    /// - Deprecated: Use `scheduleDailyReminder(at:enabled:)` instead
    /// - Note: This method doesn't check for incomplete tasks (old behavior)
    @available(*, deprecated, message: "Use scheduleDailyReminder(at:enabled:) instead for smart checking")
    func scheduleDailySummary(hour: Int, minute: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Daily Summary"
        content.body = "Check your tasks for today"
        content.sound = .default
        content.categoryIdentifier = "daily.summary"
        
        // Trigger every day at specified time
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily-summary",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Scheduled daily summary for \(hour):\(minute)")
        } catch {
            print("❌ Error scheduling daily summary: \(error)")
        }
    }
    
    /// Cancel daily summary
    ///
    /// - Deprecated: Use `cancelDailyReminder()` instead
    @available(*, deprecated, message: "Use cancelDailyReminder() instead")
    func cancelDailySummary() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["daily-summary"]
        )
    }
    
    // MARK: - Utility
    
    /// Get all pending notifications
    ///
    /// Useful for debugging and showing user what notifications are scheduled
    ///
    /// - Returns: Array of all pending notification requests
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    
    #if DEBUG
    /// Test function - schedules a notification in 5 seconds
    ///
    /// Only available in DEBUG builds for testing purposes
    func testNotificationNow() async {
        let content = UNMutableNotificationContent()
        content.title = "Test: Complete Your Tasks"
        content.body = "This is a test notification - fired 5 seconds ago!"
        content.sound = .default
        
        // Fire in 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test-reminder-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        print("🧪 Test notification scheduled for 5 seconds from now")
    }
    #endif
}

// MARK: - Notification Extensions

/// Posted when user taps daily reminder notification
extension Notification.Name {
    static let openDayView = Notification.Name("openDayView")
}
