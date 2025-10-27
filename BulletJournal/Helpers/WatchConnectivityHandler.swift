#if os(iOS)
import Foundation
import WatchConnectivity
import SwiftData
internal import Combine

/// Handles Watch Connectivity messages from Apple Watch
class WatchConnectivityHandler: NSObject, ObservableObject {
    static let shared = WatchConnectivityHandler()
    
    private let voiceManager = VoiceToTaskManager()
    private var modelContext: ModelContext?
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        print("✅ iPhone: ModelContext set for Watch Connectivity")
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("✅ iPhone: Watch Connectivity activated")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityHandler: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ iPhone: WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("✅ iPhone: WCSession activated successfully")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("⚠️ iPhone: WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("⚠️ iPhone: WCSession deactivated, reactivating...")
        session.activate()
    }
    
    // MARK: - Handle Messages from Watch
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📨 iPhone: Received message from Watch: \(message)")
        
        guard let action = message["action"] as? String else {
            replyHandler(["success": false, "error": "No action specified"])
            return
        }
        
        switch action {
        case "createTaskFromVoice":
            handleCreateTaskFromVoice(message: message, replyHandler: replyHandler)
        default:
            replyHandler(["success": false, "error": "Unknown action"])
        }
    }
    
    // MARK: - Task Creation from Voice
    
   private func handleCreateTaskFromVoice(message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
       guard let text = message["text"] as? String else {
           replyHandler(["success": false, "error": "No text provided"])
           return
       }
       
       guard let context = modelContext else {
           replyHandler(["success": false, "error": "ModelContext not available"])
           return
       }
       
       print("🤖 iPhone: Processing voice text with AI: '\(text)'")
       
       // Fetch available tags
       let tagDescriptor = FetchDescriptor<Tag>()
       let availableTags = (try? context.fetch(tagDescriptor)) ?? []
       voiceManager.setAvailableTags(availableTags)
       
       // Process with AI on iPhone
       Task { @MainActor in
           // Wait for AI to parse
           await voiceManager.parseTaskWithAI(from: text)
           
           // Give it a moment to complete
           try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
           
           guard let parsed = voiceManager.parsedTask else {
               replyHandler(["success": false, "error": "AI parsing failed"])
               return
           }
           
           print("✅ iPhone: AI parsed:")
           print("   - Name: '\(parsed.taskName)'")
           print("   - Tag: \(parsed.colorTag ?? "none")")
           
           do {
               let success = try await createTaskFromParsed(parsed, context: context, availableTags: availableTags)
               
               if success {
                   replyHandler(["success": true, "taskName": parsed.taskName])
               } else {
                   replyHandler(["success": false, "error": "Failed to create task"])
               }
           } catch {
               print("❌ iPhone: Error: \(error.localizedDescription)")
               replyHandler(["success": false, "error": error.localizedDescription])
           }
       }
   }
    
    @MainActor
    private func createTaskFromParsed(_ parsed: ParsedTask, context: ModelContext, availableTags: [Tag]) async throws -> Bool {
        // Get or create today's log
        let today = Calendar.current.startOfDay(for: Date())
        let dayLogDescriptor = FetchDescriptor<DayLog>()
        let allLogs = try context.fetch(dayLogDescriptor)
        
        let todayLog: DayLog
        if let existingLog = allLogs.first(where: {
            guard let date = $0.date else { return false }
            return Calendar.current.isDate(date, inSameDayAs: today)
        }) {
            todayLog = existingLog
        } else {
            todayLog = DayLog(date: today)
            context.insert(todayLog)
        }
        
        // Create the task
        let newTask = TaskItem(
            name: parsed.taskName,
            color: "blue", // Default, will be updated if tag matched
            notes: parsed.notes ?? "",
            status: .normal,
            reminderTime: parsed.reminderTime
        )
        
        // Match and set tag
        if let tagName = parsed.colorTag,
           let matchedTag = availableTags.first(where: {
               $0.name?.lowercased() == tagName.lowercased() && $0.isPrimary == true
           }) {
            newTask.setPrimaryTag(matchedTag)
            print("🎨 iPhone: Matched tag '\(tagName)' to '\(matchedTag.name ?? "")'")
        }
        
        // Set recurrence if specified
        if let voicePattern = parsed.voiceRecurrencePattern {
            newTask.isRecurring = true
            let frequency: RecurrenceRule.RecurrenceFrequency = {
                switch voicePattern {
                case .daily: return .daily
                case .weekly: return .weekly
                case .monthly: return .monthly
                case .yearly: return .monthly
                }
            }()
            
            let interval = voicePattern == .yearly ? 12 : 1
            let rule = RecurrenceRule(frequency: frequency, interval: interval)
            newTask.recurrenceRule = rule.toJSONString()
        }
        
        // Schedule notification if reminder time is set
        if let reminderTime = parsed.reminderTime {
            let notificationId = await NotificationManager.shared.scheduleTaskNotification(
                task: newTask,
                date: reminderTime
            )
            newTask.notificationId = notificationId
        }
        
        todayLog.addTask(newTask)
        context.insert(newTask)
        
        try context.save()
        
        print("✅ iPhone: Task created and saved: '\(parsed.taskName)'")
        
        return true
    }
}
#endif
