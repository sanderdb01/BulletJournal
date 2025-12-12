import Foundation
import SwiftData

/// Manages anchor task processing
///
/// Anchor tasks automatically carry forward to the next day if not completed.
/// Processing happens once per day on first app launch after midnight.
///
/// ## Features
/// - Copies incomplete anchors from yesterday to today
/// - Tracks lineage to show "Day X" count
/// - Prevents duplicate copying
/// - Each copied task is independent (editable)
///
/// ## Usage
/// ```swift
/// // Call on app launch
/// await AnchorManager.shared.processAnchors(context: modelContext)
/// ```
@MainActor
class AnchorManager {
    static let shared = AnchorManager()
    
    private init() {}
    
    /// Processes anchors from yesterday
    ///
    /// Finds incomplete anchor tasks from yesterday and copies them to today.
    /// Only processes yesterday to avoid overwhelming users who haven't opened
    /// the app in several days.
    ///
    /// - Parameter context: SwiftData model context
    func processAnchors(context: ModelContext) async {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        print("📍 Processing anchors for \(formatDate(today))")
        
        // Fetch yesterday's day log
        let descriptor = FetchDescriptor<DayLog>()
        
        do {
            let allLogs = try context.fetch(descriptor)
            
            guard let yesterdayLog = allLogs.first(where: { log in
                guard let logDate = log.date else { return false }
                return Calendar.current.isDate(logDate, inSameDayAs: yesterday)
            }) else {
                print("📍 No log for yesterday (\(formatDate(yesterday)))")
                return
            }
            
            // Find incomplete anchor tasks (anything except .complete)
            let anchorTasks = yesterdayLog.tasks?.filter { task in
                task.isAnchor == true && task.status != .complete
            } ?? []
            
            guard !anchorTasks.isEmpty else {
                print("📍 No incomplete anchors from yesterday")
                return
            }
            
            print("📍 Found \(anchorTasks.count) anchor(s) to process")
            
            // Get or create today's log
            let todayLog = getOrCreateDayLog(for: today, context: context)
            
            // Copy each anchor to today
            var copiedCount = 0
            for anchorTask in anchorTasks {
                // Check if already copied (prevent duplicates)
                let alreadyExists = todayLog.tasks?.contains { task in
                    task.anchorSourceId == anchorTask.id ||
                    (task.anchorSourceId == anchorTask.anchorSourceId && anchorTask.anchorSourceId != nil)
                } ?? false
                
                if alreadyExists {
                    print("📍 Anchor '\(anchorTask.name ?? "")' already exists today - skipping")
                    continue
                }
                
                // Copy the task
                let copiedTask = anchorTask.makeCopy(for: today)
                copiedTask.status = .normal  // Reset to normal
                
                // Track lineage
                if let originalSourceId = anchorTask.anchorSourceId {
                    // This is already a carried-over anchor, keep original source
                    copiedTask.anchorSourceId = originalSourceId
                    copiedTask.anchorDayCount = (anchorTask.anchorDayCount ?? 1) + 1
                } else {
                    // This is the first time carrying over
                    copiedTask.anchorSourceId = anchorTask.id
                    copiedTask.anchorDayCount = 2  // Day 2 (original was day 1)
                }
               copiedTask.isAnchor = true
                
                // Add to today
                todayLog.addTask(copiedTask)
                context.insert(copiedTask)
                
                let dayCount = copiedTask.anchorDayCount ?? 1
                print("⚓️ Anchored '\(copiedTask.name ?? "")' to today (Day \(dayCount))")
                copiedCount += 1
            }
            
            try context.save()
            
            if copiedCount > 0 {
                print("✅ Anchor processing complete - \(copiedCount) task(s) carried forward")
            } else {
                print("📍 All anchors already processed for today")
            }
            
        } catch {
            print("❌ Error processing anchors: \(error)")
        }
    }
    
    /// Gets or creates a DayLog for a specific date
    private func getOrCreateDayLog(for date: Date, context: ModelContext) -> DayLog {
        let descriptor = FetchDescriptor<DayLog>()
        
        do {
            let allLogs = try context.fetch(descriptor)
            
            if let existing = allLogs.first(where: { log in
                guard let logDate = log.date else { return false }
                return Calendar.current.isDate(logDate, inSameDayAs: date)
            }) {
                return existing
            }
            
            // Create new
            let newLog = DayLog(date: date)
            context.insert(newLog)
            return newLog
            
        } catch {
            print("❌ Error fetching day logs: \(error)")
            let newLog = DayLog(date: date)
            context.insert(newLog)
            return newLog
        }
    }
    
    /// Formats a date for logging
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
