import Foundation
import SwiftData

// MARK: - Tag Model
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
}

// MARK: - Default Color Tags with Predefined UUIDs
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
    
    // Each color tag has a HARDCODED UUID that never changes
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
class TagManager {
    static let shared = TagManager()
    
    // ALWAYS ensure the 8 color tags exist on every launch
    // This is idempotent - safe to call multiple times
    static func createDefaultTags(in context: ModelContext) {
        print("🏷️ Initializing color tags with predefined UUIDs...")
        
        // FIRST: Clean up any duplicate or invalid color tags
        cleanupColorTags(in: context)
        
        // SECOND: Ensure the 8 correct color tags exist
        for colorTag in ColorTag.allCases {
            let predefinedId = colorTag.predefinedUUID
            
            // Check if this specific color tag exists
            let descriptor = FetchDescriptor<Tag>(
                predicate: #Predicate { $0.id == predefinedId }
            )
            
            do {
                let existing = try context.fetch(descriptor)
                
                if existing.isEmpty {
                    // Tag doesn't exist - create it with predefined UUID and default name
                    let newTag = Tag(name: colorTag.rawValue, isPrimary: true, order: 0)
                    newTag.id = predefinedId
                    context.insert(newTag)
                    print("✅ Created \(colorTag.rawValue) tag (UUID: \(predefinedId))")
                } else {
                    // Tag exists - CloudKit will sync any name changes
                    print("✓ \(colorTag.rawValue) tag exists (UUID: \(predefinedId))")
                }
            } catch {
                print("❌ Error checking for tag \(colorTag.rawValue): \(error)")
            }
        }
        
        // Save all changes
        do {
            try context.save()
            print("✅ Color tags initialization complete")
            
            // Verify we have exactly 8 color tags
            let verifyDescriptor = FetchDescriptor<Tag>(
                predicate: #Predicate { $0.isPrimary == true }
            )
            let colorTagCount = (try? context.fetch(verifyDescriptor).count) ?? 0
            print("📊 Total color tags in database: \(colorTagCount)")
            
            if colorTagCount > 8 {
                print("⚠️ WARNING: More than 8 color tags detected! Running cleanup again...")
                cleanupColorTags(in: context)
            }
        } catch {
            print("❌ Error saving color tags: \(error)")
        }
    }
    
    // Clean up duplicate or invalid color tags
    // Keep ONLY the 8 tags with predefined UUIDs
    private static func cleanupColorTags(in context: ModelContext) {
        do {
            // Get ALL color tags
            let allColorTagsDescriptor = FetchDescriptor<Tag>(
                predicate: #Predicate { $0.isPrimary == true }
            )
            let allColorTags = try context.fetch(allColorTagsDescriptor)
            
            print("🧹 Cleanup: Found \(allColorTags.count) color tags")
            
            // Get the set of valid predefined UUIDs
            let validUUIDs = Set(ColorTag.allCases.map { $0.predefinedUUID })
            
            // Delete any color tag that doesn't have a predefined UUID
            var deletedCount = 0
            for tag in allColorTags {
                if let tagId = tag.id, !validUUIDs.contains(tagId) {
                    print("🗑️ Deleting invalid color tag: \(tag.name ?? "unknown") (UUID: \(tagId))")
                    context.delete(tag)
                    deletedCount += 1
                }
            }
            
            if deletedCount > 0 {
                try context.save()
                print("✅ Cleanup: Deleted \(deletedCount) invalid color tags")
            } else {
                print("✅ Cleanup: No invalid color tags found")
            }
        } catch {
            print("❌ Error during color tag cleanup: \(error)")
        }
    }
    
    // Get all primary (color) tags
    static func getColorTags(from context: ModelContext) -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { $0.isPrimary == true },
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching color tags: \(error)")
            return []
        }
    }
    
    // Get all custom tags
    static func getCustomTags(from context: ModelContext) -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { $0.isPrimary == false },
            sortBy: [SortDescriptor(\.order), SortDescriptor(\.name)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching custom tags: \(error)")
            return []
        }
    }
    
    // Get all tags (color + custom)
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
            print("Error fetching all tags: \(error)")
            return []
        }
    }
    
    // Create a new custom tag
    static func createCustomTag(name: String, in context: ModelContext) -> Tag? {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return nil }
        
        // Check if tag already exists
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { tag in
                tag.name == trimmedName && tag.isPrimary == false
            }
        )
        
        do {
            let existing = try context.fetch(descriptor)
            if !existing.isEmpty {
                print("⚠️ Tag '\(trimmedName)' already exists")
                return existing.first
            }
            
            // Get the highest order number
            let allCustomTags = getCustomTags(from: context)
            let maxOrder = allCustomTags.compactMap { $0.order }.max() ?? 0
            
            // Create new tag
            let newTag = Tag(name: trimmedName, isPrimary: false, order: maxOrder + 1)
            context.insert(newTag)
            try context.save()
            
            print("✅ Created custom tag: \(trimmedName)")
            return newTag
        } catch {
            print("❌ Error creating custom tag: \(error)")
            return nil
        }
    }
    
    // Rename a tag
    static func renameTag(_ tag: Tag, newName: String, in context: ModelContext) -> Bool {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return false }
        
        tag.name = trimmedName
        
        do {
            try context.save()
            print("✅ Renamed tag to: \(trimmedName)")
            return true
        } catch {
            print("❌ Error renaming tag: \(error)")
            return false
        }
    }
    
    // Delete a custom tag
    static func deleteCustomTag(_ tag: Tag, from context: ModelContext) -> Bool {
        // Don't allow deleting primary color tags
        guard tag.isPrimary != true else {
            print("⚠️ Cannot delete primary color tags")
            return false
        }
        
        context.delete(tag)
        
        do {
            try context.save()
            print("✅ Deleted tag: \(tag.name ?? "unknown")")
            return true
        } catch {
            print("❌ Error deleting tag: \(error)")
            return false
        }
    }
    
    // Get tag usage count
    static func getTagUsageCount(_ tag: Tag) -> Int {
        return tag.tasks?.count ?? 0
    }
    
    // Find tag by name
    static func findTag(byName name: String, in context: ModelContext) -> Tag? {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { tag in
                tag.name == name
            }
        )
        
        do {
            let tags = try context.fetch(descriptor)
            return tags.first
        } catch {
            print("Error finding tag: \(error)")
            return nil
        }
    }
    
    // Get or create a tag by name (useful for import)
    static func getOrCreateTag(name: String, isPrimary: Bool, in context: ModelContext) -> Tag? {
        if let existing = findTag(byName: name, in: context) {
            return existing
        }
        
        if isPrimary {
            // Don't create new primary tags dynamically
            return nil
        }
        
        return createCustomTag(name: name, in: context)
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
            
            // Recreate the 8 color tags
            print("🔄 Recreating 8 color tags...")
            createDefaultTags(in: context)
            
            print("✅ Reset complete!")
        } catch {
            print("❌ Error during reset: \(error)")
        }
    }
}
