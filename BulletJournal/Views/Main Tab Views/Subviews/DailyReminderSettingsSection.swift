import SwiftUI

/// Settings section for daily reminder configuration
///
/// Provides a clean interface for users to enable/disable daily reminders
/// and set their preferred notification time.
///
/// ## Features
/// - Toggle to enable/disable reminders
/// - Time picker for selecting reminder time
/// - Permission status indicator
/// - Link to system settings if permission denied
///
/// ## Usage
/// Add to your SettingsView:
/// ```swift
/// List {
///     DailyReminderSettingsSection()
///     // ... other settings
/// }
/// ```
struct DailyReminderSettingsSection: View {
    // Settings stored in AppStorage for persistence
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderTimeHour") private var reminderHour = 20  // Default: 8 PM
    @AppStorage("reminderTimeMinute") private var reminderMinute = 0
    
    @State private var showingPermissionAlert = false
    @State private var reminderTime: Date = Date()
    @State private var hasCheckedPermission = false
    
    var body: some View {
        Section {
            // Enable/Disable Toggle
            Toggle(isOn: $reminderEnabled) {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.orange)
                    Text("Daily Reminder")
                }
            }
            .onChange(of: reminderEnabled) { _, newValue in
                if newValue {
                    // Check permission when enabling
                    Task {
                        await handleReminderToggle(enabled: newValue)
                    }
                } else {
                    // Just disable
                    Task {
                        await NotificationManager.shared.cancelDailyReminder()
                    }
                }
            }
            
            // Time Picker (only show when enabled)
            if reminderEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: reminderTime) { _, newValue in
                    // Extract hour and minute
                    let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                    reminderHour = components.hour ?? 20
                    reminderMinute = components.minute ?? 0
                    
                    // Reschedule notification
                    Task {
                        await NotificationManager.shared.scheduleDailyReminder(
                            at: newValue,
                            enabled: reminderEnabled
                        )
                    }
                }
            }
            
            #if DEBUG
            // Test button (only in DEBUG builds)
            if reminderEnabled {
                Button("🧪 Test Notification (5 sec)") {
                    Task {
                        await NotificationManager.shared.testNotificationNow()
                    }
                }
                .foregroundColor(.orange)
            }
            #endif
            
        } header: {
            Text("Reminders")
        } footer: {
            if reminderEnabled {
                Text("Get notified to complete your daily tasks")
            } else {
                Text("Enable to receive daily reminders about incomplete tasks")
            }
        }
        .onAppear {
            // Initialize time picker with saved values
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            if let date = Calendar.current.date(from: components) {
                reminderTime = date
            }
            
            // Check permission status
            if !hasCheckedPermission {
                hasCheckedPermission = true
                Task {
                    await checkPermissionStatus()
                }
            }
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                // User cancelled, disable the toggle
                reminderEnabled = false
            }
        } message: {
            Text("HarborDot needs permission to send notifications. Please enable notifications in Settings.")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Handles toggling the reminder on
    private func handleReminderToggle(enabled: Bool) async {
        guard enabled else {
            await NotificationManager.shared.cancelDailyReminder()
            return
        }
        
        // Check permission
        let hasPermission = await checkNotificationPermission()
        
        if hasPermission {
            // Schedule reminder
            let time = Calendar.current.date(
                bySettingHour: reminderHour,
                minute: reminderMinute,
                second: 0,
                of: Date()
            ) ?? Date()
            
            await NotificationManager.shared.scheduleDailyReminder(
                at: time,
                enabled: true
            )
        } else {
            // Show alert
            showingPermissionAlert = true
        }
    }
    
    /// Checks if notification permission is granted
    private func checkNotificationPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    /// Checks permission status on appear
    private func checkPermissionStatus() async {
        let hasPermission = await checkNotificationPermission()
        
        // If enabled but no permission, disable
        if reminderEnabled && !hasPermission {
            await MainActor.run {
                reminderEnabled = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        List {
            DailyReminderSettingsSection()
        }
        .navigationTitle("Settings")
    }
}
