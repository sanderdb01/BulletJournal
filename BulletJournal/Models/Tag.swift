import Foundation
import SwiftData

//NOTE: Add this code somewhere to reset the color tags
// Add this as a temporary button somewhere, or run in console:
// UserDefaults.standard.removeObject(forKey: "HasCreatedColorTags")

// MARK: - Tag Model
@Model
class Tag {
    var id: UUID?
    var name: String?
    var isPrimary: Bool? // If true, this is the color tag
    var order: Int? // For sorting custom tags
    var createdAt: Date?
    
    // Relationships for TaskItem
    @Relationship(inverse: \TaskItem.tags)
    var tasks: [TaskItem]?
    
    // NEW: Inverse relationships for GeneralNote (CloudKit requirement)
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

// MARK: - Default Color Tags
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
}

// MARK: - Tag Manager
class TagManager {
    static let shared = TagManager()
    
    static func createDefaultTags(in context: ModelContext) {
        // Check if we've ever created tags before
        let hasCreatedTags = UserDefaults.standard.bool(forKey: "HasCreatedColorTags")
        
        if hasCreatedTags {
            print("ℹ️ Tags already created in a previous run, skipping")
            return
        }
        
        do {
            // Check if tags exist in database
            let colorDescriptor = FetchDescriptor<Tag>(
                predicate: #Predicate { $0.isPrimary == true }
            )
            let existingColorTags = try context.fetch(colorDescriptor)
            
            if !existingColorTags.isEmpty {
                print("ℹ️ Found \(existingColorTags.count) existing color tags")
                UserDefaults.standard.set(true, forKey: "HasCreatedColorTags")
                return
            }
            
            // Create tags for the first time ever
            print("✅ Creating 8 color tags for the first time...")
            for colorTag in ColorTag.allCases {
                let tag = Tag(name: colorTag.rawValue, isPrimary: true, order: 0)
                context.insert(tag)
            }
            
            try context.save()
            
            // Mark as created
            UserDefaults.standard.set(true, forKey: "HasCreatedColorTags")
            print("✅ Successfully created \(ColorTag.allCases.count) color tags")
        } catch {
            print("❌ Error in createDefaultTags: \(error)")
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
    
    // Delete a custom tag
    static func deleteCustomTag(_ tag: Tag, from context: ModelContext) {
        guard tag.isPrimary == false else {
            print("⚠️ Cannot delete color tags")
            return
        }
        
        context.delete(tag)
        do {
            try context.save()
            print("✅ Deleted tag: \(tag.name ?? "unknown")")
        } catch {
            print("❌ Error deleting tag: \(error)")
        }
    }
    
    // Rename a tag
    static func renameTag(_ tag: Tag, newName: String, in context: ModelContext) {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        tag.name = trimmedName
        do {
            try context.save()
            print("✅ Renamed tag to: \(trimmedName)")
        } catch {
            print("❌ Error renaming tag: \(error)")
        }
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
}
