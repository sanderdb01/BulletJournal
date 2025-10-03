import Foundation
import SwiftData

@Model
class DayLog {
    var id: UUID?
    var date: Date?
    var notes: String?
    
    // Relationship to tasks - OPTIONAL for CloudKit
    @Relationship(deleteRule: .cascade, inverse: \TaskItem.dayLog)
    var tasks: [TaskItem]?
    
    init(date: Date, notes: String = "") {
        self.id = UUID()
        // Normalize date to start of day
        self.date = Calendar.current.startOfDay(for: date)
        self.notes = notes
        self.tasks = []
    }
    
    // MARK: - Task Management Methods
    
    func addTask(_ task: TaskItem) {
        if tasks == nil {
            tasks = []
        }
        tasks?.append(task)
        task.dayLog = self
    }
    
    func deleteTask(at index: Int) {
        guard let tasks = tasks, index >= 0 && index < tasks.count else { return }
        self.tasks?.remove(at: index)
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks?.removeAll { $0.id == task.id }
    }
    
    func editTask(at index: Int, name: String, color: String, notes: String) {
        guard let tasks = tasks, index >= 0 && index < tasks.count else { return }
        let task = tasks[index]
        task.name = name
        task.color = color
        task.notes = notes
        task.modifiedAt = Date()
    }
    
    func updateNotes(_ newNotes: String) {
        self.notes = newNotes
    }
    
    func getTask(at index: Int) -> TaskItem? {
        guard let tasks = tasks, index >= 0 && index < tasks.count else { return nil }
        return tasks[index]
    }
    
    // Helper to get all tasks
    func getAllTasks() -> [TaskItem] {
        return tasks ?? []
    }
    
    // Helper to get date components
    var dateComponents: DateComponents {
        guard let date = date else { return DateComponents() }
        return Calendar.current.dateComponents([.year, .month, .day], from: date)
    }
}
