import Foundation
import SwiftData

@Model
class GeneralNote {
    var id: UUID
    var title: String?
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    
    // Tags (same system as tasks)
    var primaryTag: Tag?
    var customTags: [Tag]
    
    // Future features
    var isPinned: Bool
    var isFavorite: Bool
    
    init(
        title: String? = nil,
        content: String = "",
        primaryTag: Tag? = nil,
        customTags: [Tag] = [],
        isPinned: Bool = false,
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.primaryTag = primaryTag
        self.customTags = customTags
        self.isPinned = isPinned
        self.isFavorite = isFavorite
    }
    
    // MARK: - Computed Properties
    
    /// Display title - returns title if set, otherwise "Untitled Note"
    var displayTitle: String {
        if let title = title, !title.trimmingCharacters(in: .whitespaces).isEmpty {
            return title
        }
        return "Untitled Note"
    }
    
    /// Preview text - first 100 characters of content
    var previewText: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "No content"
        }
        return String(trimmed.prefix(100))
    }
    
    /// Word count
    var wordCount: Int {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }
    
    /// Character count
    var characterCount: Int {
        return content.count
    }
    
    // MARK: - Methods
    
    /// Update the note content and modified date
    func updateContent(_ newContent: String) {
        self.content = newContent
        self.modifiedAt = Date()
    }
    
    /// Update the note title and modified date
    func updateTitle(_ newTitle: String?) {
        self.title = newTitle
        self.modifiedAt = Date()
    }
    
    /// Toggle pinned status
    func togglePin() {
        self.isPinned.toggle()
        self.modifiedAt = Date()
    }
    
    /// Toggle favorite status
    func toggleFavorite() {
        self.isFavorite.toggle()
        self.modifiedAt = Date()
    }
    
    /// Add a custom tag
    func addCustomTag(_ tag: Tag) {
        if !customTags.contains(where: { $0.id == tag.id }) {
            customTags.append(tag)
            modifiedAt = Date()
        }
    }
    
    /// Remove a custom tag
    func removeCustomTag(_ tag: Tag) {
        customTags.removeAll { $0.id == tag.id }
        modifiedAt = Date()
    }
    
    /// Set the primary tag
    func setPrimaryTag(_ tag: Tag?) {
        self.primaryTag = tag
        self.modifiedAt = Date()
    }
}

// MARK: - GeneralNote Manager

class GeneralNoteManager {
    
    /// Create a new general note
    static func createNote(
        title: String? = nil,
        content: String = "",
        primaryTag: Tag? = nil,
        customTags: [Tag] = [],
        in context: ModelContext
    ) -> GeneralNote {
        let note = GeneralNote(
            title: title,
            content: content,
            primaryTag: primaryTag,
            customTags: customTags
        )
        context.insert(note)
        try? context.save()
        return note
    }
    
    /// Delete a note
    static func deleteNote(_ note: GeneralNote, from context: ModelContext) {
        context.delete(note)
        try? context.save()
    }
    
    /// Get all notes sorted by modified date (newest first)
    static func getAllNotes(in context: ModelContext) -> [GeneralNote] {
        let descriptor = FetchDescriptor<GeneralNote>(
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Error fetching notes: \(error)")
            return []
        }
    }
    
    /// Get pinned notes only
    static func getPinnedNotes(in context: ModelContext) -> [GeneralNote] {
        let descriptor = FetchDescriptor<GeneralNote>(
            predicate: #Predicate { $0.isPinned == true },
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Error fetching pinned notes: \(error)")
            return []
        }
    }
    
    /// Get favorite notes only
    static func getFavoriteNotes(in context: ModelContext) -> [GeneralNote] {
        let descriptor = FetchDescriptor<GeneralNote>(
            predicate: #Predicate { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Error fetching favorite notes: \(error)")
            return []
        }
    }
    
    /// Search notes by title or content
    static func searchNotes(query: String, in context: ModelContext) -> [GeneralNote] {
        let allNotes = getAllNotes(in: context)
        let lowercaseQuery = query.lowercased()
        
        return allNotes.filter { note in
            note.displayTitle.lowercased().contains(lowercaseQuery) ||
            note.content.lowercased().contains(lowercaseQuery)
        }
    }
    
    /// Get notes with a specific tag
    static func getNotes(withTag tag: Tag, in context: ModelContext) -> [GeneralNote] {
        let allNotes = getAllNotes(in: context)
        
        return allNotes.filter { note in
            note.primaryTag?.id == tag.id ||
            note.customTags.contains(where: { $0.id == tag.id })
        }
    }
}
