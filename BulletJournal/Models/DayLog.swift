import Foundation
import SwiftData
import SwiftUI

@Model
class DayLog {
   var id: UUID?
   var date: Date?
   var notes: String?
   
   // Relationship to tasks - OPTIONAL for CloudKit
   @Relationship(deleteRule: .cascade, inverse: \TaskItem.dayLog)
   var tasks: [TaskItem]?
   var lastModifiedTasksOrder: Date?
   
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
      
      // Set position to end of list
      task.position = tasks?.count ?? 0

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
   
   func reorderTasks(sortedTasks: [TaskItem], from source: IndexSet, to destination: Int) {
       var taskArray = sortedTasks
       
       print("📋 Before: \(taskArray.map { $0.name ?? "unnamed" })")
       
       taskArray.move(fromOffsets: source, toOffset: destination)
       
       print("📋 After: \(taskArray.map { $0.name ?? "unnamed" })")
       
       // Update positions for ALL tasks
       for (index, task) in taskArray.enumerated() {
           task.position = index
       }
       
       // Update the array
       tasks = taskArray
       
       print("✅ Tasks reordered")
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
