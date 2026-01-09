import Foundation
import SwiftData

@Model
class GeneralNote {
   // CloudKit requirement: All properties must be optional or have defaults
   var id: UUID?
   var title: String?
   var content: String? // Changed to optional
   var createdAt: Date?
   var modifiedAt: Date?
   
   // CloudKit requirement: Relationships must be optional
   // Don't specify inverse here - it's specified on Tag side
   var primaryTag: Tag?
   var customTags: [Tag]?
   
   // CloudKit requirement: Bool must be optional or have defaults
   var isPinned: Bool?
   var isFavorite: Bool?
   
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
      guard let content = content else { return "No content" }
      let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty {
         return "No content"
      }
      return String(trimmed.prefix(100))
   }
   
   /// Word count
   var wordCount: Int {
      guard let content = content else { return 0 }
      let words = content.components(separatedBy: .whitespacesAndNewlines)
         .filter { !$0.isEmpty }
      return words.count
   }
   
   /// Character count
   var characterCount: Int {
      return content?.count ?? 0
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
      let current = isPinned ?? false
      self.isPinned = !current
      self.modifiedAt = Date()
   }
   
   /// Toggle favorite status
   func toggleFavorite() {
      let current = isFavorite ?? false
      self.isFavorite = !current
      self.modifiedAt = Date()
   }
   
   /// Add a custom tag
   func addCustomTag(_ tag: Tag) {
      if customTags == nil {
         customTags = []
      }
      if !(customTags?.contains(where: { $0.id == tag.id }) ?? false) {
         customTags?.append(tag)
         modifiedAt = Date()
      }
   }
   
   /// Remove a custom tag
   func removeCustomTag(_ tag: Tag) {
      customTags?.removeAll { $0.id == tag.id }
      modifiedAt = Date()
   }
   
   /// Set the primary tag
   func setPrimaryTag(_ tag: Tag?) {
      self.primaryTag = tag
      self.modifiedAt = Date()
   }
   
   /// Return searched snippet of content
   //   func returnSearchSnippet(searchTerm: String) -> String? {
   //      guard let content else { return "No content" }
   //      let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
   //      if let range = trimmed.lowercased().range(of: searchTerm.lowercased()) {
   //         let index = range.lowerBound
   //         let truncatedString = String(trimmed.suffix(from: index))
   //         return String(truncatedString.prefix(100))
   //      } else {
   //         return previewText
   //      }
   //   }
   
   func returnSearchSnippet(searchTerm: String, maxLength: Int = 100) -> String? {
      guard let content else { return "No content" }
      
      // Find the search term (case-insensitive)
      guard let range = content.trimmingCharacters(in: .whitespacesAndNewlines).range(of: searchTerm, options: .caseInsensitive) else {
         return previewText
      }
      
      // Find word boundaries around the match
      let wordStartIndex = findWordStart(in: content, from: range.lowerBound)
      let wordEndIndex = findWordEnd(in: content, from: range.upperBound)
      
      // Calculate how much context to show before and after
      let contextBefore = 30  // characters to show before the word
      let contextAfter = maxLength - contextBefore
      
      // Find the start of the truncated string
      var startIndex = wordStartIndex
      if startIndex > content.startIndex {
         // Move back to show some context
         let targetIndex = content.index(wordStartIndex, offsetBy: -contextBefore, limitedBy: content.startIndex) ?? content.startIndex
         
         // Find the nearest word boundary before our target
         startIndex = findWordStart(in: content, from: targetIndex)
      }
      
      // Find the end of the truncated string
      var endIndex = wordEndIndex
      let remainingLength = maxLength - content.distance(from: startIndex, to: wordEndIndex)
      if remainingLength > 0, endIndex < content.endIndex {
         // Move forward to show some context
         let targetIndex = content.index(endIndex, offsetBy: remainingLength, limitedBy: content.endIndex) ?? content.endIndex
         
         // Find the nearest word boundary after our target
         endIndex = findWordEnd(in: content, from: targetIndex)
      }
      
      // Build the result string with ellipsis where appropriate
      var result = ""
      
      if startIndex > content.startIndex {
         result += "..."
      }
      
      result += String(content [startIndex..<endIndex])
      
      if endIndex < content.endIndex {
         result += "..."
      }
      
      return result.trimmingCharacters(in: .whitespacesAndNewlines)
   }
   
   // Helper: Find the start of a word (move backward to word boundary)
   private func findWordStart(in string: String, from index: String.Index) -> String.Index {
      var currentIndex = index
      
      // Move backward until we hit a non-word character or the start
      while currentIndex > string.startIndex {
         let previousIndex = string.index(before: currentIndex)
         let char = string[previousIndex]
         
         // Check if it's a word character (letter, number, or underscore)
         if char.isWhitespace || char.isPunctuation {
            break
         }
         
         currentIndex = previousIndex
      }
      
      return currentIndex
   }
   
   // Helper: Find the end of a word (move forward to word boundary)
   private func findWordEnd(in string: String, from index: String.Index) -> String.Index {
      var currentIndex = index
      
      // Move forward until we hit a non-word character or the end
      while currentIndex < string.endIndex {
         let char = string[currentIndex]
         
         // Check if it's a word character (letter, number, or underscore)
         if char.isWhitespace || char.isPunctuation {
            break
         }
         
         currentIndex = string.index(after: currentIndex)
      }
      
      return currentIndex
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
      do {
         try context.save()
         print("✅ Note created: \(note.displayTitle)")
      } catch {
         print("❌ Error creating note: \(error)")
      }
      
      return note
   }
   
   // MARK: - Copy passed General Note
   static func copyNote(_ note: GeneralNote, in context: ModelContext) -> Bool {
      //      let copiedNote = createNote(title: note.title, content: (note.content ?? ""), primaryTag: note.primaryTag, customTags: (note.customTags ?? []), in: context)
      //      if copiedNote.title != note.title { return false } else { return true }
      let newNote = GeneralNote(
         title: note.title,
         content: (note.content ?? ""),
         primaryTag: note.primaryTag,
         customTags: (note.customTags ?? [])
      )
      context.insert(newNote)
      do {
         try context.save()
         print("✅ Note copied: \(newNote.displayTitle)")
         return true
      } catch {
         print("❌ Error copying note: \(error)")
         return false
      }
   }
   
   // MARK: - Delete with Safety Checks
   
   /// Delete a note with proper cleanup and safety checks
   @discardableResult
   static func deleteNote(_ note: GeneralNote, from context: ModelContext) -> Bool {
      // Log what we're deleting (this is the REAL value!)
      print("🗑️ Deleting: \(note.displayTitle) (ID: \(note.id?.uuidString ?? "unknown"))")
      
      // Just delete - SwiftData will handle if already deleted
      context.delete(note)
      
      do {
         try context.save()
         print("✅ Deleted successfully")
         return true
      } catch {
         print("❌ Delete error: \(error.localizedDescription)")
         return false
      }
   }
   
   /// Delete multiple notes at once
   static func deleteNotes(_ notes: [GeneralNote], from context: ModelContext) -> Int {
      var deletedCount = 0
      
      for note in notes {
         if deleteNote(note, from: context) {
            deletedCount += 1
         }
      }
      
      return deletedCount
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
         (note.content?.lowercased().contains(lowercaseQuery) ?? false)
      }
   }
   
   /// Get notes with a specific tag
   static func getNotes(withTag tag: Tag, in context: ModelContext) -> [GeneralNote] {
      let allNotes = getAllNotes(in: context)
      
      return allNotes.filter { note in
         note.primaryTag?.id == tag.id ||
         (note.customTags?.contains(where: { $0.id == tag.id }) ?? false)
      }
   }
}
