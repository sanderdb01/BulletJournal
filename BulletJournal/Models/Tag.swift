import Foundation
import SwiftUI
import SwiftData

@Model
class Tag {
   var id: UUID?
   var name: String?
   var isPrimary: Bool? // If true, this is a color tag
   var order: Int? // For sorting custom tags
   var createdAt: Date?
   
   // Relationships
   @Relationship(inverse: \TaskItem.tags)
   var tasks: [TaskItem]?
   
   // Inverse relationships for GeneralNote
   @Relationship(inverse: \GeneralNote.primaryTag)
   var notesAsPrimary: [GeneralNote]?
   
   @Relationship(inverse: \GeneralNote.customTags)
   var notesAsCustom: [GeneralNote]?
   
   init(name: String, isPrimary: Bool = false, order: Int = 0) {
      self.id = UUID()
      self.name = name
      self.isPrimary = isPrimary
      self.order = order
      self.createdAt = Date()
   }
   
   // Returns the color string for color tag circles
   func returnColorString() -> String {
      switch self.id {
         case UUID(uuidString: "00000000-0000-0000-0000-000000000001"): return "red"
         case UUID(uuidString: "00000000-0000-0000-0000-000000000002"): return "orange"
         case UUID(uuidString: "00000000-0000-0000-0000-000000000003"): return "yellow"
         case UUID(uuidString: "00000000-0000-0000-0000-000000000004"): return "green"
         case UUID(uuidString: "00000000-0000-0000-0000-000000000005"): return "blue"
         case UUID(uuidString: "00000000-0000-0000-0000-000000000006"): return "purple"
         case UUID(uuidString: "00000000-0000-0000-0000-000000000007"): return "pink"
         case UUID(uuidString: "00000000-0000-0000-0000-000000000008"): return "gray"
         case .none:
            return "white"
         case .some(_):
            return "white"
      }
   }
}

// MARK: - Color Tag Enum
enum ColorTag: String, CaseIterable {
   case red = "Red"
   case orange = "Orange"
   case yellow = "Yellow"
   case green = "Green"
   case blue = "Blue"
   case purple = "Purple"
   case pink = "Pink"
   case gray = "Gray"
   
   var colorString: String {
      return self.rawValue.lowercased()
   }
   
   // Predefined UUIDs that NEVER change - same on ALL devices
   var predefinedUUID: UUID {
      switch self {
         case .red:    return UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
         case .orange: return UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
         case .yellow: return UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
         case .green:  return UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
         case .blue:   return UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
         case .purple: return UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
         case .pink:   return UUID(uuidString: "00000000-0000-0000-0000-000000000007")!
         case .gray:   return UUID(uuidString: "00000000-0000-0000-0000-000000000008")!
      }
   }
}

// MARK: - Tag Manager
struct TagManager {
   // Static flags to prevent concurrent calls - using a lock for thread safety
       private static let lock = NSLock()
   private static var isCreatingTags = false
   private static var hasAttemptedCreation = false
   
   // Create default color tags using iCloud Key-Value Storage to prevent duplicates
   static func createDefaultTags(in context: ModelContext) {
//      // Prevent concurrent execution
//      guard !isCreatingTags else {
//         print("⚠️ Tag creation already in progress, skipping")
//         return
//      }
//      
//      // Only attempt once per app launch
//      guard !hasAttemptedCreation else {
//         return
//      }
//      
//      isCreatingTags = true
//      hasAttemptedCreation = true
      
      // Thread-safe check to prevent concurrent execution
             lock.lock()
             let alreadyCreating = isCreatingTags
             let alreadyAttempted = hasAttemptedCreation
             
             if alreadyCreating || alreadyAttempted {
                 lock.unlock()
                 if alreadyCreating {
                     print("⚠️ Tag creation already in progress, skipping")
                 }
                 return
             }
             
             isCreatingTags = true
             hasAttemptedCreation = true
             lock.unlock()
      
      print("⏰ Starting delayed tag initialization after iCloud KV sync...")
      
      // Use iCloud Key-Value Storage for fast cross-device sync
      let store = NSUbiquitousKeyValueStore.default
      
      // Force iCloud to sync down latest values
      store.synchronize()
      
      // Wait 2 seconds for iCloud KV to sync (much faster than CloudKit's 30-60 seconds)
      DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
         defer { isCreatingTags = false }
         
         // STEP 1: Check the fast-syncing iCloud flag
         let tagsCreatedGlobally = store.bool(forKey: "colorTagsCreatedGlobally")
         
         if tagsCreatedGlobally {
            print("ℹ️ Tags created by another device, waiting for CloudKit sync")
            return
         }
         
         // STEP 2: Check local database
         do {
            let descriptor = FetchDescriptor<Tag>(
               predicate: #Predicate { $0.isPrimary == true }
            )
            let existingColorTags = try context.fetch(descriptor)
            
            if !existingColorTags.isEmpty {
               print("ℹ️ Found \(existingColorTags.count) existing color tags in database")
               // Set the flag so other devices don't create tags
               store.set(true, forKey: "colorTagsCreatedGlobally")
               store.synchronize()
               return
            }
            
            // STEP 3: This is the first device - create tags with predefined UUIDs
            print("✅ Creating 8 color tags for the first time...")
            for colorTag in ColorTag.allCases {
               let tag = Tag(name: colorTag.rawValue, isPrimary: true, order: 0)
               tag.id = colorTag.predefinedUUID // Use hardcoded UUID
               context.insert(tag)
            }
            
            try context.save()
            print("✅ Successfully created \(ColorTag.allCases.count) color tags")
            
            // STEP 4: Mark as created globally (prevents other devices)
            store.set(true, forKey: "colorTagsCreatedGlobally")
            store.synchronize()
            print("✅ Marked tags as created globally in iCloud KV")
            
         } catch {
            print("❌ Error creating default tags: \(error)")
         }
      }
   }
   
   // Find a tag by name
   static func findTag(byName name: String, in context: ModelContext) -> Tag? {
      let descriptor = FetchDescriptor<Tag>(
         predicate: #Predicate { $0.name == name }
      )
      return try? context.fetch(descriptor).first
   }
   
   // Get all color tags (isPrimary = true)
   static func getColorTags(from context: ModelContext) -> [Tag] {
      let descriptor = FetchDescriptor<Tag>(
         predicate: #Predicate { $0.isPrimary == true },
         sortBy: [SortDescriptor(\.name)]
      )
      return (try? context.fetch(descriptor)) ?? []
   }
   
   // Get all custom tags (isPrimary = false)
   static func getCustomTags(from context: ModelContext) -> [Tag] {
      let descriptor = FetchDescriptor<Tag>(
         predicate: #Predicate { $0.isPrimary == false },
         sortBy: [SortDescriptor(\.name)]
      )
      return (try? context.fetch(descriptor)) ?? []
   }
   
   // Get all tags sorted (color tags first, then custom)
   static func getAllTags(from context: ModelContext) -> [Tag] {
      let descriptor = FetchDescriptor<Tag>(
         sortBy: [SortDescriptor(\.name)]
      )
      
      do {
         let allTags = try context.fetch(descriptor)
         // Sort manually: primary tags first, then by name
         return allTags.sorted { tag1, tag2 in
            let isPrimary1 = tag1.isPrimary ?? false
            let isPrimary2 = tag2.isPrimary ?? false
            
            if isPrimary1 != isPrimary2 {
               return isPrimary1 // Primary tags first
            }
            return (tag1.name ?? "") < (tag2.name ?? "")
         }
      } catch {
         print("❌ Error fetching all tags: \(error)")
         return []
      }
   }
   
   // Verify and correct color tag if sync fails
   static func validateColorTags(from context: ModelContext) {
      print("Validating Color Tags...")
      let descriptor = FetchDescriptor<Tag>(
         predicate: #Predicate { $0.isPrimary == true },
         sortBy: [SortDescriptor(\.createdAt, order:.forward)]
      )
      
      let allColorTags = try? context.fetch(descriptor)
      
      print("Number of color tags: \(allColorTags?.count ?? 0)")
      if (allColorTags?.count ?? 0) > 8 {
         print("There are too many color tags. Deleting some...")
         var seenUUIDs: Set<UUID> = []
         var toDelete: [Tag] = []
         
         for tag in (allColorTags ?? []) {
            if let uuid = tag.id {
               if seenUUIDs.contains(uuid) {
                  toDelete.append(tag)
               } else {
                  seenUUIDs.insert(uuid)
               }
            }
         }
         
         for tag in toDelete {
            print("Deleting Tag: \(tag.name ?? "")")
            context.delete(tag)
         }
         
         do {
            try context.save()
         } catch {
            print("❌ Error deleting duplicate tags: \(error)")
         }
      }
   }
   
   // Duplicate color tags to test correction (TEST)
   static func duplicateColorTags(from context: ModelContext) {
//      let allColorTags = getColorTags(from: context)
      do {
         print("✅ Duplicating 8 color tags...")
         for colorTag in ColorTag.allCases {
            let tag = Tag(name: colorTag.rawValue, isPrimary: true, order: 0)
            tag.id = colorTag.predefinedUUID // Use hardcoded UUID
            context.insert(tag)
         }
         
         try context.save()
         print("✅ Successfully duplicated \(ColorTag.allCases.count) color tags")
         
      } catch {
         print("❌ Error dupicating default tags: \(error)")
      }
   }
   
   // Return a default color tag of color blue (no matter what the name is)
   static func returnDefaultTag(from context: ModelContext) -> Tag {
      let allTags = getAllTags(from: context)
      let defaultTag = allTags.first(where: {$0.returnColorString() == "blue"}) ?? Tag(name: "default")
      return defaultTag
   }
   
   // Create a custom tag
   static func createCustomTag(name: String, in context: ModelContext) -> Tag? {
      // Check if tag already exists
      if let existing = findTag(byName: name, in: context) {
         return existing
      }
      
      let tag = Tag(name: name, isPrimary: false, order: 0)
      context.insert(tag)
      
      do {
         try context.save()
         return tag
      } catch {
         print("❌ Error creating custom tag: \(error)")
         return nil
      }
   }
   
   // Delete a custom tag
   static func deleteCustomTag(_ tag: Tag, from context: ModelContext) {
      // Don't delete primary (color) tags
      guard tag.isPrimary == false else {
         print("⚠️ Cannot delete primary color tags")
         return
      }
      
      context.delete(tag)
      do {
         try context.save()
      } catch {
         print("❌ Error deleting tag: \(error)")
      }
   }
   
   // Rename a tag
   static func renameTag(_ tag: Tag, newName: String, in context: ModelContext) {
      tag.name = newName
      do {
         try context.save()
      } catch {
         print("❌ Error renaming tag: \(error)")
      }
   }
   
   // Get or create a tag by name
   static func getOrCreateTag(name: String, isPrimary: Bool, in context: ModelContext) -> Tag {
      if let existing = findTag(byName: name, in: context) {
         return existing
      }
      
      let tag = Tag(name: name, isPrimary: isPrimary, order: 0)
      context.insert(tag)
      
      do {
         try context.save()
      } catch {
         print("❌ Error creating tag: \(error)")
      }
      
      return tag
   }
   
   // MARK: - Nuclear Reset (Use with caution!)
   
   /// Delete ALL tags and recreate the 8 color tags
   /// This will clear CloudKit and start fresh
   static func resetAllTags(in context: ModelContext) {
      do {
         print("☢️ NUCLEAR RESET: Deleting all tags...")
         
         // Delete ALL tags
         let allTagsDescriptor = FetchDescriptor<Tag>()
         let allTags = try context.fetch(allTagsDescriptor)
         
         for tag in allTags {
            context.delete(tag)
         }
         
         try context.save()
         print("✅ Deleted \(allTags.count) tags")
         
         // Wait a moment for CloudKit to process
         Thread.sleep(forTimeInterval: 1.0)
         
         // Reset the iCloud KV flag so tags can be recreated
         let store = NSUbiquitousKeyValueStore.default
         store.set(false, forKey: "colorTagsCreatedGlobally")
         store.synchronize()
         print("✅ Reset iCloud KV flag")
         
         // Recreate the 8 color tags
         print("🔄 Recreating 8 color tags...")
         createDefaultTags(in: context)
         
         print("✅ Reset complete!")
      } catch {
         print("❌ Error during reset: \(error)")
      }
   }
}
