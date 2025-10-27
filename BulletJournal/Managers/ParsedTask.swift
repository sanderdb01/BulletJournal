import Foundation
import FoundationModels

// Shared data structure for parsed voice input
// Conforms to Codable for Foundation Models structured output
@available(iOS 18.2, macOS 15.2, *)
struct ParsedTask: Codable, Equatable {
    var taskName: String
    var reminderTime: Date?
    var voiceRecurrencePattern: VoiceRecurrencePattern?
    var colorTag: String?  // Store tag name as String for AI
    var notes: String?
    
    // Default initializer
    init(taskName: String = "", reminderTime: Date? = nil, voiceRecurrencePattern: VoiceRecurrencePattern? = nil, colorTag: String? = nil, notes: String? = nil) {
        self.taskName = taskName
        self.reminderTime = reminderTime
        self.voiceRecurrencePattern = voiceRecurrencePattern
        self.colorTag = colorTag
        self.notes = notes
    }
}

@available(iOS 18.2, macOS 15.2, *)
enum VoiceRecurrencePattern: String, Codable, Equatable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
}
