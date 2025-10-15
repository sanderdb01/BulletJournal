import SwiftUI
import SwiftData

struct TaskRowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditTask = false
    
    let task: TaskItem
    let dayLog: DayLog
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkmark for completed tasks
            if task.status == .complete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
            
            // Task content
            VStack(alignment: .leading, spacing: 6) {
                // Task name and status
                HStack(spacing: 8) {
                    // Primary color tag indicator
                    if let primaryTag = task.primaryTag {
                        Circle()
                          .fill(Color.fromString(primaryTag.returnColorString()))
                            .frame(width: 12, height: 12)
                    } else if let color = task.color {
                        // Fallback to legacy color
                        Circle()
                            .fill(Color.fromString(color))
                            .frame(width: 12, height: 12)
                    }
                    
                    Text(task.name ?? "")
                        .foregroundColor(textColor)
                        .strikethrough(task.status == .complete)
                    
                    Spacer()
                    
                    // Status badge
                    statusBadge
                }
                
                // NEW: Custom tags display
                if !task.customTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(task.customTags, id: \.id) { tag in
                                Text(tag.name ?? "")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Bottom row: notes preview, reminder, recurring indicator
                HStack(spacing: 8) {
                    // Notes preview
                    if let notes = task.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Reminder indicator
                    if let reminderTime = task.reminderTime {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                            Text(reminderTime, style: .time)
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                    
                    // Recurring indicator
                    if task.isRecurring == true || task.isRecurringInstance {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                task.cycleStatus()
               #if os(iOS)
                HapticManager.shared.impact(style: .light)
               #endif
                try? modelContext.save()
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
#if os(iOS)
            HapticManager.shared.impact(style: .heavy)
           #endif
            showingEditTask = true
        } onPressingChanged: { isPressing in
            if isPressing {
#if os(iOS)
                HapticManager.shared.impact(style: .medium)
               #endif
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    // Only show "Move to Tomorrow" for non-recurring tasks
                    if task.isRecurring != true && !task.isRecurringInstance {
                        Button {
                            moveTaskToTomorrow()
                        } label: {
                            Label("Tomorrow", systemImage: "arrow.right.circle.fill")
                        }
                        .tint(.blue)
                    }
                }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation {
                    // Cancel notification if it exists
                    if let notificationId = task.notificationId {
                        NotificationManager.shared.cancelTaskNotification(notificationId: notificationId)
                    }
                    
                    dayLog.deleteTask(task)
                    try? modelContext.save()
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditTask) {
            AddEditTaskView(dayLog: dayLog, taskToEdit: task, isPresented: $showingEditTask)
        }
    }
    
    private var textColor: Color {
        switch task.status {
        case .normal:
            return .primary
        case .inProgress:
            return .green
        case .complete:
            return .green
        case .notCompleted:
            return .red
        default:
            return .primary
        }
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch task.status {
        case .normal:
            EmptyView()
        case .inProgress:
            Text("In Progress")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(8)
        case .complete:
            EmptyView()
        case .notCompleted:
            Text("Not Completed")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.2))
                .foregroundColor(.red)
                .cornerRadius(8)
        default:
            EmptyView()
        }
    }
   
   // MARK: - Move to Tomorrow
       private func moveTaskToTomorrow() {
           guard let currentDate = dayLog.date else { return }
           
           let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
           
           // Find or create day log for tomorrow
           let descriptor = FetchDescriptor<DayLog>(
               predicate: #Predicate { log in
                   log.date == tomorrow
               }
           )
           
           do {
               let tomorrowLogs = try modelContext.fetch(descriptor)
               let tomorrowLog: DayLog
               
               if let existing = tomorrowLogs.first {
                   tomorrowLog = existing
               } else {
                   tomorrowLog = DayLog(date: tomorrow)
                   modelContext.insert(tomorrowLog)
               }
               
               // Create a copy of the task for tomorrow
               let newTask = TaskItem(
                   name: task.name!,
                   color: task.color!,
                   notes: task.notes ?? "",
                   status: .normal  // Reset status to normal
               )
               
               // Copy tags
               if let primaryTag = task.primaryTag {
                   newTask.setPrimaryTag(primaryTag)
               }
               for customTag in task.customTags {
                   newTask.addCustomTag(customTag)
               }
               
               // Copy reminder if it exists (adjust to tomorrow)
               if let reminderTime = task.reminderTime {
                   let calendar = Calendar.current
                   let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
                   var tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                   tomorrowComponents.hour = timeComponents.hour
                   tomorrowComponents.minute = timeComponents.minute
                   
                   if let newReminderDate = calendar.date(from: tomorrowComponents) {
                       newTask.reminderTime = newReminderDate
                       
                       // Schedule notification for tomorrow
                       Task {
                           let notificationId = await NotificationManager.shared.scheduleTaskNotification(
                               task: newTask,
                               date: newReminderDate
                           )
                           newTask.notificationId = notificationId
                       }
                   }
               }
               
               tomorrowLog.addTask(newTask)
               modelContext.insert(newTask)
               
               // Delete original task
               if let notificationId = task.notificationId {
                   NotificationManager.shared.cancelTaskNotification(notificationId: notificationId)
               }
               dayLog.deleteTask(task)
               
               try modelContext.save()
               
#if os(iOS)
               // Haptic feedback
               HapticManager.shared.notification(type: .success)
              #endif
           } catch {
               print("Error moving task to tomorrow: \(error)")
           }
       }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DayLog.self, TaskItem.self, Tag.self, configurations: config)
    let context = container.mainContext
    
    let dayLog = DayLog(date: Date())
    let task1 = TaskItem(name: "Sample Task with Tags", color: "blue", notes: "This is a note with some details")
    
    // Create sample tags
    let blueTag = Tag(name: "Blue", isPrimary: true)
    let workTag = Tag(name: "Work", isPrimary: false)
    let urgentTag = Tag(name: "Urgent", isPrimary: false)
    
    context.insert(blueTag)
    context.insert(workTag)
    context.insert(urgentTag)
    
    task1.setPrimaryTag(blueTag)
    task1.addCustomTag(workTag)
    task1.addCustomTag(urgentTag)
    task1.reminderTime = Date()
    task1.isRecurring = true
    
    let task2 = TaskItem(name: "Completed Task", color: "green")
    task2.status = .complete
    
    let task3 = TaskItem(name: "In Progress Task", color: "orange")
    task3.status = .inProgress
    
    dayLog.addTask(task1)
    dayLog.addTask(task2)
    dayLog.addTask(task3)
    
    context.insert(dayLog)
    
    return VStack {
        TaskRowView(task: task1, dayLog: dayLog)
        TaskRowView(task: task2, dayLog: dayLog)
        TaskRowView(task: task3, dayLog: dayLog)
    }
    .modelContainer(container)
}
