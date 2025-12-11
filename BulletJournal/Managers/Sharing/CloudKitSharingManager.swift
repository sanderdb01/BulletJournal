import Foundation
import CloudKit
import SwiftUI
import SwiftData
internal import Combine

@MainActor
class CloudKitSharingManager: ObservableObject {
    static let shared = CloudKitSharingManager()
    
    private let helper = CloudKitHelper.shared
    
    @Published var activeShare: CKShare?
    @Published var activeRecord: CKRecord?
    @Published var sharingError: Error?
    @Published var isLoading = false
    
    // Store modelContext reference
    var modelContext: ModelContext?
    
    // MARK: - Share a Task
    
    func shareTask(
        _ taskId: UUID,
        taskName: String,
        completion: @escaping (Result<(CKShare, CKRecord), Error>) -> Void
    ) {
        isLoading = true
        sharingError = nil
        
        print("=" * 60)
        print("🚀 STARTING SHARE PROCESS")
        print("=" * 60)
        print("📋 Task ID: \(taskId)")
        print("📋 Task Name: \(taskName)")
        
        Task {
            do {
                // Step 1: Check iCloud status
                print("\n📍 Step 1: Checking iCloud status...")
                let iCloudAvailable = await helper.checkiCloudStatus()
                guard iCloudAvailable else {
                    throw CloudKitError.notSignedIntoiCloud
                }
                
                // Step 2: Fetch the CKRecord for this task
                print("\n📍 Step 2: Fetching CKRecord...")
                let record = try await helper.fetchRecord(for: taskId)
                print("✅ CKRecord fetched: \(record.recordID.recordName)")
                
                // Step 3: Check if already shared
                print("\n📍 Step 3: Checking for existing share...")
                if let existingShare = try await helper.fetchShare(for: record) {
                    print("ℹ️ Task is already shared")
                    
                    // Update task properties with latest share info
                    if let context = modelContext {
                        try await SharePropertyUpdater.updateTaskSharingProperties(
                            taskId: taskId,
                            share: existingShare,
                            modelContext: context
                        )
                    }
                    
                    await MainActor.run {
                        self.activeShare = existingShare
                        self.activeRecord = record
                        self.isLoading = false
                        print("\n✅ SUCCESS: Using existing share")
                        print("=" * 60)
                        completion(.success((existingShare, record)))
                    }
                    return
                }
                
                // Step 4: Create new share
                print("\n📍 Step 4: Creating new share...")
                let share = try await helper.createShare(for: record, taskName: taskName)
                print("✅ Share created successfully")
                
                // Step 5: Update task properties
                print("\n📍 Step 5: Updating task properties...")
                if let context = modelContext {
                    try await SharePropertyUpdater.updateTaskSharingProperties(
                        taskId: taskId,
                        share: share,
                        modelContext: context
                    )
                }
                
                await MainActor.run {
                    self.activeShare = share
                    self.activeRecord = record
                    self.isLoading = false
                    print("\n✅ SUCCESS: Share ready to send")
                    print("📱 Share URL: \(share.url?.absoluteString ?? "no URL")")
                    print("=" * 60)
                    completion(.success((share, record)))
                }
                
            } catch let error as CloudKitError {
                print("\n❌ CLOUDKIT ERROR")
                print("❌ Error: \(error.localizedDescription)")
                print("=" * 60)
                
                await MainActor.run {
                    self.sharingError = error
                    self.isLoading = false
                    completion(.failure(error))
                }
                
            } catch {
                print("\n❌ UNEXPECTED ERROR")
                print("❌ Error: \(error.localizedDescription)")
                print("=" * 60)
                
                await MainActor.run {
                    self.sharingError = error
                    self.isLoading = false
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Stop Sharing
    
    func stopSharing(
        taskId: UUID,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        isLoading = true
        sharingError = nil
        
        print("=" * 60)
        print("🛑 STOPPING SHARE")
        print("=" * 60)
        print("📋 Task ID: \(taskId)")
        
        Task {
            do {
                // Fetch the record
                print("\n📍 Fetching CKRecord...")
                let record = try await helper.fetchRecord(for: taskId)
                
                // Stop sharing
                print("\n📍 Removing share...")
                try await helper.stopSharing(record: record)
                
                // Clear task properties
                print("\n📍 Clearing task properties...")
                if let context = modelContext {
                    try await SharePropertyUpdater.clearTaskSharingProperties(
                        taskId: taskId,
                        modelContext: context
                    )
                }
                
                await MainActor.run {
                    self.activeShare = nil
                    self.activeRecord = nil
                    self.isLoading = false
                    print("\n✅ SUCCESS: Sharing stopped")
                    print("=" * 60)
                    completion(.success(()))
                }
                
            } catch {
                print("\n❌ ERROR STOPPING SHARE")
                print("❌ Error: \(error.localizedDescription)")
                print("=" * 60)
                
                await MainActor.run {
                    self.sharingError = error
                    self.isLoading = false
                    completion(.failure(error))
                }
            }
        }
    }
   
   // MARK: - Cancel Share (User Didn't Send It)
   
   /// Cleans up when user creates a share but cancels without sending
   func cancelShare(
       taskId: UUID,
       share: CKShare,
       completion: @escaping (Result<Void, Error>) -> Void
   ) {
       print("=" * 60)
       print("🚫 CANCELLING UNUSED SHARE")
       print("=" * 60)
       print("📋 Task ID: \(taskId)")
       
       Task {
           do {
               // Delete the share from CloudKit
               print("\n📍 Deleting share...")
               try await helper.deleteShare(share)
               
               // Clear task properties
               print("\n📍 Clearing task properties...")
               if let context = modelContext {
                   try await SharePropertyUpdater.clearTaskSharingProperties(
                       taskId: taskId,
                       modelContext: context
                   )
               }
               
               await MainActor.run {
                   self.activeShare = nil
                   self.activeRecord = nil
                   print("\n✅ SUCCESS: Share cancelled and cleaned up")
                   print("=" * 60)
                   completion(.success(()))
               }
               
           } catch {
               print("\n❌ ERROR CANCELLING SHARE")
               print("❌ Error: \(error.localizedDescription)")
               print("=" * 60)
               
               await MainActor.run {
                   // Even if deletion fails, clear the local state
                   self.activeShare = nil
                   self.activeRecord = nil
                   completion(.success(()))
               }
           }
       }
   }
    // MARK: - Accept Share
    
    func acceptShare(metadata: CKShare.Metadata) async throws {
        print("=" * 60)
        print("📥 ACCEPTING SHARE")
        print("=" * 60)
        
        try await helper.acceptShare(metadata: metadata)
        
        print("\n✅ SUCCESS: Share accepted")
        print("ℹ️ SwiftData will sync the task within 10-30 seconds")
        print("=" * 60)
        
        // Note: We can't update TaskItem properties here because we don't have the taskId yet
        // SwiftData will create the TaskItem when it syncs the CKRecord
        // The task will need to check its share status when it appears
    }
    
    // MARK: - Clear State
    
    func clearState() {
        activeShare = nil
        activeRecord = nil
        sharingError = nil
        isLoading = false
    }
}

// MARK: - Helper Extension

private func *(lhs: String, rhs: Int) -> String {
    return String(repeating: lhs, count: rhs)
}
