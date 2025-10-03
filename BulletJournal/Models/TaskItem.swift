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
    
    // Relationship to DayLog - OPTIONAL for CloudKit
    var dayLog: DayLog?
    
    init(name: String, color: String, notes: String = "", status: TaskStatus = .normal) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.notes = notes
        self.status = status
        self.createdAt = Date()
        self.modifiedAt = Date()
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
}

// Enum for task status
enum TaskStatus: String, Codable {
    case normal
    case inProgress
    case complete
    case notCompleted
}
