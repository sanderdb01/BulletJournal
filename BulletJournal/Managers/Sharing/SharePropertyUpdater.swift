import Foundation
import SwiftData
import CloudKit

/// Helper to update TaskItem properties when shares are created or accepted
class SharePropertyUpdater {
    
    /// Updates a TaskItem's sharing properties after a share is created or accepted
    /// This should be called on the ModelContext's actor
    @MainActor
    static func updateTaskSharingProperties(
        taskId: UUID,
        share: CKShare,
        modelContext: ModelContext
    ) async throws {
        print("🔄 Updating task sharing properties for: \(taskId)")
        
        // Fetch the task from SwiftData
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.id == taskId }
        )
        
        guard let tasks = try? modelContext.fetch(descriptor),
              let task = tasks.first else {
            print("⚠️ Task not found in SwiftData: \(taskId)")
            throw ShareUpdateError.taskNotFound
        }
        
        // Update sharing properties
        task.isShared = true
        
        // Get owner name
        if let ownerName = share.owner.userIdentity.nameComponents?.formatted() {
            task.shareOwnerName = ownerName
            print("✅ Owner: \(ownerName)")
        } else if let email = share.owner.userIdentity.lookupInfo?.emailAddress {
            task.shareOwnerName = email
            print("✅ Owner (email): \(email)")
        } else {
            task.shareOwnerName = "Unknown"
            print("⚠️ Owner name unknown")
        }
        
        // Get participant names (excluding owner)
        var participantNames: [String] = []
        for participant in share.participants where participant != share.owner {
            if let name = participant.userIdentity.nameComponents?.formatted() {
                participantNames.append(name)
            } else if let email = participant.userIdentity.lookupInfo?.emailAddress {
                participantNames.append(email)
            } else if let phone = participant.userIdentity.lookupInfo?.phoneNumber {
                participantNames.append(phone)
            } else {
                participantNames.append("Unknown User")
            }
        }
        
        task.shareParticipantNames = participantNames
        print("✅ Participants: \(participantNames)")
        
        // Save changes
        try modelContext.save()
        print("✅ Task sharing properties updated successfully")
    }
    
    /// Updates a task to mark it as no longer shared
    @MainActor
    static func clearTaskSharingProperties(
        taskId: UUID,
        modelContext: ModelContext
    ) async throws {
        print("🔄 Clearing task sharing properties for: \(taskId)")
        
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.id == taskId }
        )
        
        guard let tasks = try? modelContext.fetch(descriptor),
              let task = tasks.first else {
            print("⚠️ Task not found in SwiftData: \(taskId)")
            throw ShareUpdateError.taskNotFound
        }
        
        task.isShared = false
        task.shareOwnerName = nil
        task.shareParticipantNames = []
        
        try modelContext.save()
        print("✅ Task sharing properties cleared")
    }
}

enum ShareUpdateError: Error {
    case taskNotFound
}
