import Foundation
import CloudKit
import SwiftData

/// Helper class for CloudKit operations
/// Handles fetching CKRecords that SwiftData creates and managing shares
class CloudKitHelper {
    static let shared = CloudKitHelper()
    
    private let container = CKContainer.default()
    private lazy var database = container.privateCloudDatabase
    
    // MARK: - Fetch CKRecord for TaskItem
    
    /// Fetches the CKRecord that SwiftData created for this TaskItem
    /// SwiftData automatically creates CKRecords with the format: "<UUID>"
   func fetchRecord(for taskId: UUID) async throws -> CKRecord {
       let zoneID = CKRecordZone.ID(
           zoneName: "com.apple.coredata.cloudkit.zone",
           ownerName: CKCurrentUserDefaultName
       )
       
       print("🔍 Searching for task with CD_id: \(taskId.uuidString)")
       print("🔍 From zone: \(zoneID.zoneName)")
       
       // Query for a record where CD_id equals our task ID
      let predicate = NSPredicate(format: "CD_id == %@", taskId.uuidString)
       let query = CKQuery(recordType: "CD_TaskItem", predicate: predicate)
       
       do {
           let (results, _) = try await database.records(matching: query, inZoneWith: zoneID)
           
           print("📊 Query returned \(results.count) results")
           
           guard let firstResult = results.first else {
               print("❌ No record found with CD_id: \(taskId.uuidString)")
               throw CloudKitError.recordNotFound
           }
           
           // Destructure the tuple: (CKRecord.ID, Result<CKRecord, Error>)
           let (recordID, result) = firstResult
           
           switch result {
           case .success(let record):
               print("✅ Found CKRecord!")
               print("   CKRecord ID: \(recordID.recordName)")
               if let cdId = record["CD_id"] as? UUID {
                   print("   CD_id field: \(cdId)")
               }
               print("   Type: \(record.recordType)")
               return record
               
           case .failure(let error):
               print("❌ Error fetching record: \(error)")
               throw error
           }
           
       } catch let error as CKError {
           print("❌ CloudKit error: \(error.localizedDescription)")
           print("❌ Error code: \(error.errorCode)")
           
           // Retry once
           print("⏳ Waiting 3 seconds before retry...")
           try await Task.sleep(nanoseconds: 3_000_000_000)
           
           print("🔄 Retrying query...")
           do {
               let (results, _) = try await database.records(matching: query, inZoneWith: zoneID)
               
               guard let firstResult = results.first else {
                   print("❌ Still not found after retry")
                   throw CloudKitError.recordNotFoundAfterRetry
               }
               
               // Destructure again for retry
               let (recordID, result) = firstResult
               
               switch result {
               case .success(let record):
                   print("✅ Found on retry: \(recordID.recordName)")
                   return record
               case .failure(let error):
                   print("❌ Retry failed: \(error)")
                   throw error
               }
           } catch {
               print("❌ Retry error: \(error)")
               throw CloudKitError.recordNotFoundAfterRetry
           }
       }
   }
    
    // MARK: - Create Share
    
    /// Creates a CKShare for a task
    /// This share can then be sent to other users via Messages, Mail, etc.
   func createShare(for record: CKRecord, taskName: String) async throws -> CKShare {
       print("📤 Creating share for: \(taskName)")
       print("📤 Record: \(record.recordID.recordName)")
       
       // Create the share
       let share = CKShare(rootRecord: record)
       share[CKShare.SystemFieldKey.title] = taskName as CKRecordValue
       share.publicPermission = .none
       
       print("💾 Saving share to CloudKit...")
       
       do {
           let (saveResults, _) = try await database.modifyRecords(
               saving: [record, share],
               deleting: []
           )
           
           for (_, result) in saveResults {
               if case .success(let savedRecord) = result,
                  let savedShare = savedRecord as? CKShare {
                   print("✅ Share saved with URL: \(savedShare.url?.absoluteString ?? "none")")
                   return savedShare
               }
           }
           
           throw CloudKitError.shareCreationFailed
       } catch {
           print("❌ Save failed: \(error)")
           throw error
       }
   }
   
   func createShare_old2(for record: CKRecord, taskName: String) async throws -> CKShare {
       print("📤 Creating share for: \(taskName)")
       print("📤 Record: \(record.recordID.recordName)")
       
       // Create the share
       let share = CKShare(rootRecord: record)
       share[CKShare.SystemFieldKey.title] = taskName as CKRecordValue
       share[CKShare.SystemFieldKey.shareType] = "com.sanders.harbordot.task" as CKRecordValue
       
       // Configure permissions
       share.publicPermission = .none
       
       print("💾 Saving share to CloudKit...")
       
       do {
           // Save both record and share together
           let (saveResults, _) = try await database.modifyRecords(
               saving: [record, share],
               deleting: []
           )
           
           print("✅ Save operation completed")
           
           // Find the saved share
           for (recordID, result) in saveResults {
               switch result {
               case .success(let savedRecord):
                   if let savedShare = savedRecord as? CKShare {
                       print("✅ Share created and saved")
                       print("✅ Share URL: \(savedShare.url?.absoluteString ?? "no URL")")
                       return savedShare
                   }
               case .failure(let error):
                   print("❌ Error: \(error)")
                   throw error
               }
           }
           
           throw CloudKitError.shareCreationFailed
           
       } catch let error as CKError {
           print("❌ CloudKit error: \(error.localizedDescription)")
           throw error
       }
   }
   
   func createShare_old(for record: CKRecord, taskName: String) async throws -> CKShare {
       print("📤 Creating share for: \(taskName)")
       print("📤 Record: \(record.recordID.recordName)")
       
       // Create the share
       let share = CKShare(rootRecord: record)
       share[CKShare.SystemFieldKey.title] = taskName as CKRecordValue
       share[CKShare.SystemFieldKey.shareType] = "com.sanders.harbordot.task" as CKRecordValue
       
       // Configure permissions
       share.publicPermission = .none // Private only
       
       print("💾 Saving share to CloudKit...")
       print("💾 Share record ID: \(share.recordID.recordName)")
       
       do {
           // ✅ Save BOTH record and share together (CloudKit requirement)
           let (saveResults, _) = try await database.modifyRecords(
               saving: [record, share],  // ← Include both
               deleting: []
           )
           
           print("✅ Save operation completed")
           print("✅ Saved \(saveResults.count) records")
           
           // Extract the saved share from results
           for (recordID, result) in saveResults {
               print("   - Record ID: \(recordID.recordName)")
               switch result {
               case .success(let savedRecord):
                   print("     ✅ Success - Type: \(savedRecord.recordType)")
                   if let savedShare = savedRecord as? CKShare {
                       print("✅ Share created successfully")
                       print("✅ Share URL: \(savedShare.url?.absoluteString ?? "no URL")")
                       return savedShare
                   }
               case .failure(let error):
                   print("     ❌ Failed: \(error)")
                   throw error
               }
           }
           
           // If we get here, no share was found
           print("❌ No share found in results")
           throw CloudKitError.shareCreationFailed
           
       } catch let error as CKError {
           print("❌ CloudKit error creating share: \(error.localizedDescription)")
           print("❌ Error code: \(error.errorCode)")
           throw error
       } catch {
           print("❌ Unexpected error creating share: \(error)")
           throw error
       }
   }
    
    // MARK: - Fetch Existing Share
    
    /// Gets existing share for a record, if any
    /// Returns nil if the record is not currently shared
    func fetchShare(for record: CKRecord) async throws -> CKShare? {
        // Check if record already has a share
        guard let shareReference = record.share else {
            print("ℹ️ No share exists for this record")
            return nil
        }
        
        print("🔍 Fetching existing share: \(shareReference.recordID.recordName)")
        
        do {
            let share = try await database.record(for: shareReference.recordID) as? CKShare
            
            if let share = share {
                print("✅ Found existing share")
                print("✅ Share URL: \(share.url?.absoluteString ?? "no URL")")
                print("✅ Participants: \(share.participants.count)")
            }
            
            return share
        } catch {
            print("❌ Error fetching share: \(error)")
            throw error
        }
    }
    
    // MARK: - Stop Sharing
    
    /// Removes sharing from a record
    /// This deletes the CKShare, making the task private again
    func stopSharing(record: CKRecord) async throws {
        guard let shareReference = record.share else {
            print("ℹ️ Record is not shared, nothing to stop")
            return
        }
        
        print("🗑️ Stopping sharing for record: \(record.recordID.recordName)")
        print("🗑️ Deleting share: \(shareReference.recordID.recordName)")
        
        do {
            // Delete the share
            try await database.deleteRecord(withID: shareReference.recordID)
            print("✅ Stopped sharing successfully")
        } catch let error as CKError {
            print("❌ CloudKit error stopping share: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ Unexpected error stopping share: \(error)")
            throw error
        }
    }
   
   // MARK: - Delete Share (Clean Up After Cancellation)
       
       /// Deletes a share that was created but never sent
       /// Used when user cancels the share sheet without actually sharing
       func deleteShare(_ share: CKShare) async throws {
           print("🗑️ Deleting unused share...")
           print("🗑️ Share ID: \(share.recordID.recordName)")
           
           do {
               try await database.deleteRecord(withID: share.recordID)
               print("✅ Share deleted successfully")
           } catch let error as CKError {
               // If share doesn't exist, that's fine
               if error.code == .unknownItem {
                   print("ℹ️ Share already deleted or doesn't exist")
                   return
               }
               print("❌ Error deleting share: \(error.localizedDescription)")
               throw error
           }
       }
    
    // MARK: - Accept Share
    
    /// Accepts an incoming share from another user
    /// This is called when a user taps a share link they received
    func acceptShare(metadata: CKShare.Metadata) async throws {
        print("📥 Accepting share...")
        print("📥 Share title: \(metadata.rootRecord?.recordID.recordName ?? "unknown")")
        print("📥 Owner: \(metadata.ownerIdentity.nameComponents?.formatted() ?? "unknown")")
        
        do {
            let share = try await container.accept(metadata)
            print("✅ Share accepted successfully")
            print("✅ Share ID: \(share.recordID.recordName)")
            print("✅ Root record: \(share.recordID.recordName)")
            print("ℹ️ CloudKit will now sync the shared record to this device")
            print("ℹ️ SwiftData should pick it up within 10-30 seconds")
        } catch let error as CKError {
            print("❌ CloudKit error accepting share: \(error.localizedDescription)")
            print("❌ Error code: \(error.errorCode)")
            throw error
        } catch {
            print("❌ Unexpected error accepting share: \(error)")
            throw error
        }
    }
    
    // MARK: - Check iCloud Status
    
    /// Checks if user is signed into iCloud
    func checkiCloudStatus() async -> Bool {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                print("✅ iCloud account available")
                return true
            case .noAccount:
                print("⚠️ No iCloud account signed in")
                return false
            case .restricted:
                print("⚠️ iCloud account restricted")
                return false
            case .couldNotDetermine:
                print("⚠️ Could not determine iCloud status")
                return false
            case .temporarilyUnavailable:
                print("⚠️ iCloud temporarily unavailable")
                return false
            @unknown default:
                print("⚠️ Unknown iCloud status")
                return false
            }
        } catch {
            print("❌ Error checking iCloud status: \(error)")
            return false
        }
    }
   
   func listAllRecords() async {
       print("\n🔍 LISTING ALL RECORDS IN CLOUDKIT - START")
       print(String(repeating: "=", count: 60))
       
       let recordTypes = ["CD_TaskItem", "CD_DayLog", "CD_Tag", "CD_GeneralNote"]
       
       for recordType in recordTypes {
           print("\n📋 Querying record type: '\(recordType)'")
           
           // Simple query with NO sort descriptors
           let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
           // NO SORT - this is key!
           
           do {
               let (matchResults, _) = try await database.records(matching: query)
               
               print("   ✅ Found \(matchResults.count) records")
               
               for (recordID, result) in matchResults.prefix(5) {  // Show first 5
                   switch result {
                   case .success(let record):
                       print("   ✅ ID: \(recordID.recordName)")
                       print("      Zone: \(recordID.zoneID.zoneName)")
                       
                   case .failure(let error):
                       print("   ❌ Error: \(error)")
                   }
               }
           } catch {
               print("   ❌ Query failed: \(error.localizedDescription)")
           }
       }
       
       print(String(repeating: "=", count: 60) + "\n")
   }
   
   func listZones() async {
       print("\n🗂️ LISTING ALL ZONES")
       print(String(repeating: "=", count: 60))
       
       do {
           let zones = try await database.allRecordZones()
           print("📊 Found \(zones.count) zones")
           
           for zone in zones {
               print("   📁 Zone: \(zone.zoneID.zoneName)")
               print("      Owner: \(zone.zoneID.ownerName)")
           }
       } catch {
           print("❌ Error listing zones: \(error)")
       }
       
       print(String(repeating: "=", count: 60) + "\n")
   }
   
   func listRecordsInZone() async {
       print("\n📦 FETCHING ALL RECORDS FROM SWIFTDATA ZONE")
       print(String(repeating: "=", count: 60))
       
       let zoneID = CKRecordZone.ID(
           zoneName: "com.apple.coredata.cloudkit.zone",
           ownerName: CKCurrentUserDefaultName
       )
       
       print("🔍 Zone: \(zoneID.zoneName)")
       
       // Fetch all changes (all records) from the zone
       let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
       configuration.previousServerChangeToken = nil // Get everything
       
       let operation = CKFetchRecordZoneChangesOperation(
           recordZoneIDs: [zoneID],
           configurationsByRecordZoneID: [zoneID: configuration]
       )
       
       var recordCount = 0
       
       operation.recordWasChangedBlock = { recordID, result in
           recordCount += 1
           switch result {
           case .success(let record):
               print("   ✅ Record \(recordCount): \(recordID.recordName)")
               print("      Type: \(record.recordType)")
               
               // Print first few fields
               let keys = record.allKeys().prefix(5)
               for key in keys {
                   if let value = record[key] {
                       print("      \(key): \(value)")
                   }
               }
               print("")
               
           case .failure(let error):
               print("   ❌ Error: \(error)")
           }
       }
       
       operation.recordZoneFetchResultBlock = { zoneID, result in
           switch result {
           case .success:
               print("\n✅ Finished fetching from zone")
               print("📊 Total records: \(recordCount)")
           case .failure(let error):
               print("\n❌ Zone fetch error: \(error)")
           }
       }
       
       await withCheckedContinuation { continuation in
           operation.fetchRecordZoneChangesResultBlock = { result in
               continuation.resume()
           }
           database.add(operation)
       }
       
       print(String(repeating: "=", count: 60) + "\n")
   }
   
   func listRecentTasksInZone() async {
       print("\n📦 FETCHING RECENT TASKS")
       print(String(repeating: "=", count: 60))
       
       let zoneID = CKRecordZone.ID(
           zoneName: "com.apple.coredata.cloudkit.zone",
           ownerName: CKCurrentUserDefaultName
       )
       
       let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
       configuration.previousServerChangeToken = nil
       
       let operation = CKFetchRecordZoneChangesOperation(
           recordZoneIDs: [zoneID],
           configurationsByRecordZoneID: [zoneID: configuration]
       )
       
       var taskRecords: [(String, String?, Date?)] = [] // (ID, name, modifiedAt)
       
       operation.recordWasChangedBlock = { recordID, result in
           switch result {
           case .success(let record):
               if record.recordType == "CD_TaskItem" {
                   let name = record["CD_name"] as? String
                   let modifiedAt = record["CD_modifiedAt"] as? Date
                   taskRecords.append((recordID.recordName, name, modifiedAt))
               }
           case .failure:
               break
           }
       }
       
       operation.recordZoneFetchResultBlock = { zoneID, result in
           switch result {
           case .success:
               // Sort by modified date, newest first
               let sorted = taskRecords.sorted { (a, b) in
                   guard let dateA = a.2, let dateB = b.2 else { return false }
                   return dateA > dateB
               }
               
               print("\n📊 Found \(taskRecords.count) tasks")
               print("\nMost recent 60 tasks:")
               for (index, record) in sorted.prefix(60).enumerated() {
                   print("   \(index + 1). ID: \(record.0)")
                   print("      Name: \(record.1 ?? "No name")")
                   if let date = record.2 {
                       print("      Modified: \(date)")
                   }
                   print("")
               }
           case .failure(let error):
               print("❌ Error: \(error)")
           }
       }
       
       await withCheckedContinuation { continuation in
           operation.fetchRecordZoneChangesResultBlock = { _ in
               continuation.resume()
           }
           database.add(operation)
       }
       
       print(String(repeating: "=", count: 60) + "\n")
   }
}

// MARK: - Custom Errors

enum CloudKitError: LocalizedError {
    case shareCreationFailed
    case recordNotFound
    case recordNotFoundAfterRetry
    case notSignedIntoiCloud
    case shareNotFound
    
    var errorDescription: String? {
        switch self {
        case .shareCreationFailed:
            return "Failed to create share in CloudKit"
        case .recordNotFound:
            return "Task record not found in CloudKit"
        case .recordNotFoundAfterRetry:
            return "Task not synced to CloudKit yet. Please wait a few seconds and try again."
        case .notSignedIntoiCloud:
            return "Please sign into iCloud in Settings"
        case .shareNotFound:
            return "Share not found"
        }
    }
}
