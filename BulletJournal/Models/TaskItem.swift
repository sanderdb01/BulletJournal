import Foundation
import SwiftData

@Model
class TaskItem {
    var id: UUID?
    var name: String?
    var color: String?  // Legacy color field - will map to primary tag
    var notes: String?
    var status: TaskStatus?
    var createdAt: Date?
    var modifiedAt: Date?
    
    // Reminder
    var reminderTime: Date?
    var notificationId: String?
    
    // Recurrence
    var isRecurring: Bool?
    var recurrenceRule: String? // Stored as JSON string
    var recurrenceEndDate: Date?
    var isTemplate: Bool? // Whether this is a template
    var sourceTemplateId: UUID? // Link to the original recurring task
    
    // New fields for future features
    var isFavorite: Bool?
    var isPinned: Bool?
    var category: TaskCategory?
    
    // Relationship to DayLog - OPTIONAL for CloudKit
    var dayLog: DayLog?
    
    // Tag relationships
    @Relationship
    var tags: [Tag]?
    
    // MARK: - Computed Properties
    
    // Get the primary (color) tag
    var primaryTag: Tag? {
        return tags?.first(where: { $0.isPrimary == true })
    }
    
    // Get custom tags only
    var customTags: [Tag] {
        return tags?.filter { $0.isPrimary == false } ?? []
    }
    
    // Helper to check if this task is part of a recurring series
    var isRecurringInstance: Bool {
        return sourceTemplateId != nil
    }
    
    // MARK: - Initializer
    
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
        self.isFavorite = false
        self.isPinned = false
        self.category = TaskCategory.none
        self.tags = []
    }
    
    // MARK: - Task Status Methods
    
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
    
    // MARK: - Tag Management Methods
    
    func setPrimaryTag(_ tag: Tag) {
        // Remove existing primary tag
        tags?.removeAll(where: { $0.isPrimary == true })
        
        // Add new primary tag
        if tags == nil {
            tags = []
        }
        tags?.append(tag)
        
        // Update legacy color field for backward compatibility
//        color = tag.name?.lowercased()
       color = tag.returnColorString().lowercased()
        modifiedAt = Date()
    }
    
    func addCustomTag(_ tag: Tag) {
        guard tag.isPrimary == false else { return }
        
        if tags == nil {
            tags = []
        }
        
        // Only add if not already present
        if !tags!.contains(where: { $0.id == tag.id }) {
            tags?.append(tag)
            modifiedAt = Date()
        }
    }
    
    func removeCustomTag(_ tag: Tag) {
        tags?.removeAll(where: { $0.id == tag.id && $0.isPrimary == false })
        modifiedAt = Date()
    }
    
    func hasTag(_ tag: Tag) -> Bool {
        return tags?.contains(where: { $0.id == tag.id }) ?? false
    }
    
    // Clear all custom tags
    func clearCustomTags() {
        tags?.removeAll(where: { $0.isPrimary == false })
        modifiedAt = Date()
    }
}

// MARK: - Task Status Enum
enum TaskStatus: String, Codable {
    case normal
    case inProgress
    case complete
    case notCompleted
}

// MARK: - Task Category Enum (for future implementation)
enum TaskCategory: String, Codable {
    case none
    case work
    case personal
    case health
    case shopping
    case social
    case other
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .work: return "Work"
        case .personal: return "Personal"
        case .health: return "Health"
        case .shopping: return "Shopping"
        case .social: return "Social"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "circle"
        case .work: return "briefcase"
        case .personal: return "person"
        case .health: return "heart"
        case .shopping: return "cart"
        case .social: return "person.2"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Copy Task Method

extension TaskItem {
    /// Creates a copy of this task for a specific target date
    /// - Parameter targetDate: The date for the new task
    /// - Returns: A new TaskItem with all properties copied (except UUID, status, and recurrence)
    func makeCopy(for targetDate: Date) -> TaskItem {
        // Create new task with basic properties
        let copiedTask = TaskItem(
            name: self.name ?? "",
            color: self.color ?? "blue",
            notes: self.notes ?? "",
            status: .normal,  // Always start fresh as normal (not completed)
            reminderTime: nil  // We'll set this below if needed
        )
        
        // Copy metadata
        copiedTask.createdAt = Date()
        copiedTask.modifiedAt = Date()
        
        // Copy tags using the proper methods
        if let primaryTag = self.primaryTag {
            copiedTask.setPrimaryTag(primaryTag)
        }
        for customTag in self.customTags {
            copiedTask.addCustomTag(customTag)
        }
        
        // Copy and adjust reminder time to target date if it exists
        if let originalReminderTime = self.reminderTime {
            // Keep the same time of day, but on the target date
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: originalReminderTime)
            
            if let newReminderTime = calendar.date(
                bySettingHour: timeComponents.hour ?? 0,
                minute: timeComponents.minute ?? 0,
                second: 0,
                of: targetDate
            ) {
                copiedTask.reminderTime = newReminderTime
                
                // Note: Notification will be scheduled by the caller after inserting into context
                copiedTask.notificationId = UUID().uuidString
            }
        }
        
        // Explicitly do NOT copy recurrence settings - this is a one-time copy
        copiedTask.isRecurring = false
        copiedTask.sourceTemplateId = nil
        copiedTask.recurrenceRule = nil
        copiedTask.recurrenceEndDate = nil
        copiedTask.isTemplate = false
        
        return copiedTask
    }
}
