import Foundation
import SwiftData

class RecurrenceManager {
    static let shared = RecurrenceManager()
    
    private init() {}
    
    // Generate recurring tasks for a date range
    func generateRecurringTasks(
        from startDate: Date,
        to endDate: Date,
        modelContext: ModelContext
    ) {
        let calendar = Calendar.current
        
        // Fetch all tasks with recurrence rules
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                task.isRecurring == true && task.recurrenceRule != nil
            }
        )
        
        do {
            let recurringTasks = try modelContext.fetch(descriptor)
            
            for template in recurringTasks {
                guard let templateId = template.id,
                      let ruleString = template.recurrenceRule,
                      let rule = RecurrenceRule.from(jsonString: ruleString),
                      let templateDate = template.dayLog?.date else {
                    continue
                }
                
                // Get all occurrences in the date range
                let occurrences = rule.occurrences(from: templateDate, to: endDate)
                
                for occurrenceDate in occurrences {
                    // Check if task already exists for this date
                    let dayStart = calendar.startOfDay(for: occurrenceDate)
                    
                    if !taskExists(
                        templateId: templateId,
                        date: dayStart,
                        modelContext: modelContext
                    ) {
                        createTaskInstance(
                            from: template,
                            templateId: templateId,
                            for: dayStart,
                            modelContext: modelContext
                        )
                    }
                }
            }
            
            try modelContext.save()
        } catch {
            print("Error generating recurring tasks: \(error)")
        }
    }
    
    // Check if a task instance already exists
    private func taskExists(
        templateId: UUID,
        date: Date,
        modelContext: ModelContext
    ) -> Bool {
        let descriptor = FetchDescriptor<DayLog>(
            predicate: #Predicate { dayLog in
                dayLog.date == date
            }
        )
        
        do {
            let dayLogs = try modelContext.fetch(descriptor)
            if let dayLog = dayLogs.first {
                // Check if any task is linked to this template
                return (dayLog.tasks ?? []).contains { task in
                    task.sourceTemplateId == templateId
                }
            }
        } catch {
            print("Error checking task existence: \(error)")
        }
        
        return false
    }
    
    // Create a new task instance from template
    private func createTaskInstance(
        from template: TaskItem,
        templateId: UUID,
        for date: Date,
        modelContext: ModelContext
    ) {
        // Get or create day log for the date
        let descriptor = FetchDescriptor<DayLog>(
            predicate: #Predicate { dayLog in
                dayLog.date == date
            }
        )
        
        do {
            let dayLogs = try modelContext.fetch(descriptor)
            let dayLog: DayLog
            
            if let existing = dayLogs.first {
                dayLog = existing
            } else {
                dayLog = DayLog(date: date)
                modelContext.insert(dayLog)
            }
            
            // Create new task from template
            let newTask = TaskItem(
                name: template.name!,
                color: template.color!,
                notes: template.notes ?? "",
                status: .normal
            )
            
            // Link to source template
            newTask.sourceTemplateId = templateId
            
            // Set reminder time if template has one
            if let templateReminderTime = template.reminderTime {
                let calendar = Calendar.current
                let timeComponents = calendar.dateComponents([.hour, .minute], from: templateReminderTime)
                
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                
                newTask.reminderTime = calendar.date(from: dateComponents)
                
                // Schedule notification
                Task {
                    if let reminderDate = newTask.reminderTime {
                        let notificationId = await NotificationManager.shared.scheduleTaskNotification(
                            task: newTask,
                            date: reminderDate
                        )
                        newTask.notificationId = notificationId
                    }
                }
            }
            
            dayLog.addTask(newTask)
            modelContext.insert(newTask)
            
            print("✅ Created recurring task: \(template.name ?? "") for \(date)")
        } catch {
            print("Error creating task instance: \(error)")
        }
    }
}
