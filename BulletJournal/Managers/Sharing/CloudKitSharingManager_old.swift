//import Foundation
//import CloudKit
//import SwiftUI
//internal import Combine
//
//@MainActor
//class CloudKitSharingManager: ObservableObject {
//   static let shared = CloudKitSharingManager()
//   
//   private let helper = CloudKitHelper.shared
//   @Published var activeShare: CKShare?
//   @Published var activeRecord: CKRecord?
//   @Published var sharingError: Error?
//   @Published var isLoading = false
//   
//   // MARK: - Share a Task
//   
//   func shareTask(_ taskId: UUID, taskName: String, completion: @escaping (Result<(CKShare, CKRecord), Error>) -> Void) {
//      isLoading = true
//      
//      Task {
//         do {
//            // TESTING
//            //               await helper.listZones()
//            //               await helper.listAllRecords()
//            //               await helper.listRecordsInZone()
//            //               await helper.listRecentTasksInZone()
//            
//            // 🧪 TEMPORARY TEST - Force use a known UUID
////            let testTaskId = UUID(uuidString: "3137AB47-2250-4FDD-BC4D-BD7DBBBD0876")!
////            let testTaskName = "21 Days of Drawing"
////            
////            print("\n⚠️ TESTING WITH KNOWN UUID: \(testTaskId)")
//            
////            await helper.listRecentTasksInZone()
//            
//            // Step 1: Fetch the CKRecord for this task
//            print("🔄 Step 1: Fetching CKRecord for task \(taskId)")
//                        let record = try await helper.fetchRecord(for: taskId)
//            // Use test UUID instead of actual
////            let record = try await helper.fetchRecord(for: testTaskId)  // ← Use test ID
//            
//            // Step 2: Check if already shared
//            if let existingShare = try await helper.fetchShare(for: record) {
//               print("ℹ️ Task already shared, using existing share")
//               await MainActor.run {
//                  self.activeShare = existingShare
//                  self.activeRecord = record
//                  self.isLoading = false
//                  completion(.success((existingShare, record)))
//               }
//               return
//            }
//            
//            // Step 3: Create new share
//            print("🔄 Step 2: Creating new share")
//            let share = try await helper.createShare(for: record, taskName: taskName)
//            
//            await MainActor.run {
//               self.activeShare = share
//               self.activeRecord = record
//               self.isLoading = false
//               completion(.success((share, record)))
//            }
//         } catch {
//            print("❌ Error in shareTask: \(error)")
//            await MainActor.run {
//               self.sharingError = error
//               self.isLoading = false
//               completion(.failure(error))
//            }
//         }
//      }
//   }
//   
//   // MARK: - Stop Sharing
//   
//   func stopSharing(taskId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
//      isLoading = true
//      
//      Task {
//         do {
//            let record = try await helper.fetchRecord(for: taskId)
//            try await helper.stopSharing(record: record)
//            
//            await MainActor.run {
//               self.activeShare = nil
//               self.activeRecord = nil
//               self.isLoading = false
//               completion(.success(()))
//            }
//         } catch {
//            await MainActor.run {
//               self.sharingError = error
//               self.isLoading = false
//               completion(.failure(error))
//            }
//         }
//      }
//   }
//   
//   // MARK: - Accept Share
//   
//   func acceptShare(metadata: CKShare.Metadata) async throws {
//      try await helper.acceptShare(metadata: metadata)
//   }
//   
//   // MARK: - Fetch Participants
//   
//   func fetchParticipants(for share: CKShare) -> [String] {
//      var names: [String] = []
//      
//      for participant in share.participants where participant != share.owner {
//         if let name = participant.userIdentity.nameComponents?.formatted() {
//            names.append(name)
//         } else {
//            names.append("Unknown User")
//         }
//      }
//      
//      return names
//   }
//}
