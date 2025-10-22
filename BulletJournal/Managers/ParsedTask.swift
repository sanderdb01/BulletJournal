import Foundation
/// Parsed task components
struct ParsedTask: Equatable {  // Add Equatable conformance
   var taskName: String = ""
   var reminderTime: Date?
   var voiceRecurrencePattern: VoiceRecurrencePattern?
   var colorTag: Tag?
   var notes: String?
   
   // Implement Equatable
   static func == (lhs: ParsedTask, rhs: ParsedTask) -> Bool {
      return lhs.taskName == rhs.taskName &&
      lhs.reminderTime == rhs.reminderTime &&
      lhs.voiceRecurrencePattern == rhs.voiceRecurrencePattern &&
      lhs.colorTag?.id == rhs.colorTag?.id &&
      lhs.notes == rhs.notes
   }
}

/// Voice-detected recurrence pattern (different from your RecurrenceRule struct)
enum VoiceRecurrencePattern: Equatable {  // Add Equatable conformance
   case daily
   case weekly
   case monthly
   case yearly
}
