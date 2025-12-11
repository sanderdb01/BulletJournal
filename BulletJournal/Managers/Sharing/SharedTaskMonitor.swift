import Foundation
import SwiftData
import CloudKit
internal import Combine

/// Monitors and updates properties of shared tasks
@MainActor
class SharedTasksMonitor: ObservableObject {
    static let shared = SharedTasksMonitor()
    
    private var timer: Timer?
    private var modelContext: ModelContext?
    private var isRunning = false
    
    private init() {}
    
    // MARK: - Setup
    
    /// Initialize the monitor with a model context and start periodic updates
    func start(with context: ModelContext) {
        print("🔄 SharedTasksMonitor: Starting")
        self.modelContext = context
        
        // Do initial update
        Task {
            await updateAllSharedTasks()
        }
        
        // ⚠️ DISABLED: Periodic updates can be heavy during development
        // Uncomment this when you're ready for production
        // startPeriodicUpdates()
        
        print("ℹ️ SharedTasksMonitor: Periodic updates disabled (call forceUpdate() manually)")
    }
    
    /// Stop the monitor and clean up
    func stop() {
        print("🛑 SharedTasksMonitor: Stopping")
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    // MARK: - Periodic Updates
    
    private func startPeriodicUpdates() {
        guard timer == nil else { return }
        
        isRunning = true
        
        // Create timer that fires every 60 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                await self.updateAllSharedTasks()
            }
        }
        
        print("✅ SharedTasksMonitor: Periodic updates started (every 60 seconds)")
    }
    
    // MARK: - Update Shared Tasks
    
    /// Updates properties for all shared tasks
    /// Call this:
    /// - On app launch (automatic when start() is called)
    /// - After accepting a share
    /// - Periodically every 60 seconds (automatic)
    func updateAllSharedTasks() async {
        guard let context = modelContext else {
            print("⚠️ SharedTasksMonitor: No model context available")
            return
        }
        
        print("\n🔍 SharedTasksMonitor: Checking for shared tasks...")
        
        do {
            // ONLY fetch tasks that are marked as shared
            // This prevents checking hundreds of non-shared tasks
            let descriptor = FetchDescriptor<TaskItem>(
                predicate: #Predicate { $0.isShared == true }
            )
            let sharedTasks = try context.fetch(descriptor)
            
            guard !sharedTasks.isEmpty else {
                print("ℹ️ SharedTasksMonitor: No shared tasks found")
                return
            }
            
            print("📊 Found \(sharedTasks.count) shared task(s) to check")
            
            var updatedCount = 0
            var errorCount = 0
            
            for task in sharedTasks {
                guard let taskId = task.id else { continue }
                
                // Try to fetch share for this task
                do {
                    let record = try await CloudKitHelper.shared.fetchRecord(for: taskId)
                    
                    if let share = try await CloudKitHelper.shared.fetchShare(for: record) {
                        // This task has a share - update properties if needed
                        let needsUpdate = task.shareOwnerName == nil ||
                                        task.shareParticipantNames?.isEmpty ?? true
                        
                        if needsUpdate {
                            try await SharePropertyUpdater.updateTaskSharingProperties(
                                taskId: taskId,
                                share: share,
                                modelContext: context
                            )
                            updatedCount += 1
                        }
                        
                    } else {
                        // Task is marked as shared but no share exists - clear properties
                        try await SharePropertyUpdater.clearTaskSharingProperties(
                            taskId: taskId,
                            modelContext: context
                        )
                        updatedCount += 1
                    }
                    
                } catch {
                    // Task not found in CloudKit or other error - skip it
                    errorCount += 1
                    continue
                }
            }
            
            if updatedCount > 0 {
                print("✅ SharedTasksMonitor: Updated \(updatedCount) task(s)")
            }
            
            if errorCount > 0 {
                print("⚠️ SharedTasksMonitor: \(errorCount) task(s) skipped (not synced or error)")
            }
            
            if updatedCount == 0 && errorCount == 0 {
                print("ℹ️ SharedTasksMonitor: No updates needed")
            }
            
        } catch {
            print("❌ SharedTasksMonitor: Error fetching tasks: \(error)")
        }
    }
    
    /// Force an immediate update (useful after accepting a share)
    func forceUpdate() async {
        print("⚡️ SharedTasksMonitor: Force update requested")
        await updateAllSharedTasks()
    }
}
