import SwiftUI
import SwiftData

@main
struct HarborDotApp: App {
    @StateObject private var deepLinkManager = DeepLinkManager()
    
    init() {
        // Request notification permission on launch
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deepLinkManager)
                .onOpenURL { url in
                    deepLinkManager.handle(url: url)
                }
                .onAppear {
                    cleanupDuplicateTags()  // RUN CLEANUP FIRST
                    initializeDefaultTags()
                    generateRecurringTasks()
//                   resetCloudKitTags()  //Run this to clear out all the tags from cloudkit if needed
                }
        }
        .modelContainer(SharedModelContainer.shared)
    }
    
    // CLEANUP DUPLICATE TAGS (run this once, then can be removed)
    private func cleanupDuplicateTags() {
        let context = SharedModelContainer.shared.mainContext
        
        do {
            let allTagsDescriptor = FetchDescriptor<Tag>()
            let allTags = try context.fetch(allTagsDescriptor)
            
            print("🧹 Starting cleanup - found \(allTags.count) total tags")
            
            // Group tags by name and isPrimary
            var seenTags: [String: Tag] = [:]
            var duplicatesToDelete: [Tag] = []
            
            for tag in allTags {
                guard let name = tag.name, let isPrimary = tag.isPrimary else { continue }
                
                let key = "\(name)-\(isPrimary)"
                
                if let existing = seenTags[key] {
                    // This is a duplicate - mark for deletion
                    duplicatesToDelete.append(tag)
                    print("🗑️ Marking duplicate tag for deletion: \(name) (isPrimary: \(isPrimary))")
                } else {
                    // First occurrence - keep it
                    seenTags[key] = tag
                }
            }
            
            // Delete duplicates
            for duplicate in duplicatesToDelete {
                context.delete(duplicate)
            }
            
            if !duplicatesToDelete.isEmpty {
                try context.save()
                print("✅ Deleted \(duplicatesToDelete.count) duplicate tags")
            } else {
                print("✅ No duplicate tags found")
            }
        } catch {
            print("❌ Error cleaning up duplicate tags: \(error)")
        }
    }
   
    private func initializeDefaultTags() {
        let context = SharedModelContainer.shared.mainContext
        TagManager.createDefaultTags(in: context)
    }
    
    private func generateRecurringTasks() {
        let modelContext = SharedModelContainer.shared.mainContext
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: today)!
        
        RecurrenceManager.shared.generateRecurringTasks(
            from: today,
            to: futureDate,
            modelContext: modelContext
        )
    }
   
   private func resetCloudKitTags() {
       let context = SharedModelContainer.shared.mainContext
       
       do {
           // Delete ALL tags from local database
           let allTagsDescriptor = FetchDescriptor<Tag>()
           let allTags = try context.fetch(allTagsDescriptor)
           
           print("🗑️ Deleting ALL \(allTags.count) tags from local database")
           
           for tag in allTags {
               context.delete(tag)
           }
           
           try context.save()
           print("✅ All tags deleted locally - CloudKit will sync this deletion")
           
           // Wait for CloudKit sync, then restart app
           print("⏳ Wait 30 seconds for CloudKit sync, then force-quit and restart the app")
       } catch {
           print("❌ Error deleting tags: \(error)")
       }
   }
}
