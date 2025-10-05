import Foundation
import SwiftData

@Model
class TaskItem {
   var id: UUID?
   var name: String?
   var color: String?
   var notes: String?
   var status: TaskStatus?
   var createdAt: Date?
   var modifiedAt: Date?
   
   // Reminder
   var reminderTime: Date?
   var notificationId: String?
   
   // NEW: Recurrence
   var isRecurring: Bool?
   var recurrenceRule: String? // Stored as JSON string
   var recurrenceEndDate: Date?
   var isTemplate: Bool? // Whether this is a template
   var sourceTemplateId: UUID? // NEW: Link to the original recurring task
   
   
   // Relationship to DayLog - OPTIONAL for CloudKit
   var dayLog: DayLog?
   
   init(name: String, color: String, notes: String = "", status: TaskStatus = .normal, reminderTime: Date? = nil, isTemplate: Bool = false) {
      self.id = UUID()
      self.name = name
      self.color = color
      self.notes = notes
      self.status = status
      self.createdAt = Date()
      self.modifiedAt = Date()
      self.reminderTime = reminderTime
      self.notificationId = nil
      self.isRecurring = false
      self.recurrenceRule = nil
      self.recurrenceEndDate = nil
      self.isTemplate = isTemplate
      self.sourceTemplateId = nil
   }
   
   // Method to cycle through task states
   func cycleStatus() {
      guard let currentStatus = status else { return }
      
      switch currentStatus {
         case .normal:
            status = .inProgress
         case .inProgress:
            status = .complete
         case .complete:
            status = .notCompleted
         case .notCompleted:
            status = .normal
      }
      modifiedAt = Date()
   }
   
   // Helper to check if this task is part of a recurring series
   var isRecurringInstance: Bool {
      return sourceTemplateId != nil
   }
}

// Enum for task status
enum TaskStatus: String, Codable {
   case normal
   case inProgress
   case complete
   case notCompleted
}
