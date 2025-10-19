import SwiftUI
import SwiftData

struct TaskRowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditTask = false
    
    let task: TaskItem
    let dayLog: DayLog
    
    var body: some View {
        HStack(spacing: 16) {  // Increased from 12 to 16
            // Checkmark for completed tasks
            if task.status == .complete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)  // Larger icon - changed from .title3
            }
            
            // Task content
            VStack(alignment: .leading, spacing: 8) {  // Increased from 6 to 8
                // Task name and status
                HStack(spacing: 12) {  // Increased from 8 to 12
                    // Primary color tag indicator - BIGGER
                    if let primaryTag = task.primaryTag {
                        Circle()
                            .fill(Color.fromString(primaryTag.returnColorString()))
                            .frame(width: 20, height: 20)  // Increased from 12 to 20
                    } else if let color = task.color {
                        // Fallback to legacy color
                        Circle()
                            .fill(Color.fromString(color))
                            .frame(width: 20, height: 20)  // Increased from 12 to 20
                    }
                    
                    Text(task.name ?? "")
                        .font(.body)  // Larger text
                        .fontWeight(.medium)  // Added weight for better readability
                        .foregroundColor(textColor)
                        .strikethrough(task.status == .complete)
                    
                    Spacer()
                    
                    // Status badge
                    statusBadge
                }
                
                // Custom tags display
                if !task.customTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {  // Increased from 6 to 8
                            ForEach(task.customTags, id: \.id) { tag in
                                Text(tag.name ?? "")
                                    .font(.caption)  // Slightly larger than .caption2
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)  // Increased from 8
                                    .padding(.vertical, 5)  // Increased from 3
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
                            .font(.subheadline)  // Slightly larger than .caption
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Reminder indicator
                    if let reminderTime = task.reminderTime {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.caption)  // Slightly larger than .caption2
                            Text(reminderTime, style: .time)
                                .font(.subheadline)  // Slightly larger
                        }
                        .foregroundColor(.orange)
                    }
                    
                    // Recurring indicator
                    if task.isRecurring == true || task.isRecurringInstance {
                        Image(systemName: "repeat")
                            .font(.subheadline)  // Slightly larger
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding(.vertical, 16)  // Increased from 12 to 16
        .padding(.horizontal, 16)
        .background(taskRowBackground)  // Custom background color
        .cornerRadius(12)  // Rounded corners for card effect
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)  // Subtle shadow
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
    
    // MARK: - Background Color
    private var taskRowBackground: Color {
        // Different background colors based on task status
        switch task.status {
        case .complete:
            return Color.green.opacity(0.08)  // Subtle green tint
        case .inProgress:
            return Color.orange.opacity(0.08)  // Subtle orange tint
        case .notCompleted:
            return Color.red.opacity(0.08)  // Subtle red tint
        default:
            // Default: lighter background that stands out from the main background
            #if os(iOS)
//            return Color(uiColor: .secondarySystemGroupedBackground)
              return Color(uiColor: .tertiarySystemGroupedBackground)
            #else
            return Color(nsColor: .controlBackgroundColor)
            #endif
        }
    }
    
    private var textColor: Color {
        switch task.status {
        case .normal:
            return .primary
        case .inProgress:
            return .green
        case .complete:
            return Color.green.opacity(0.8)  // Adjustable green shade
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
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                Text("In Progress")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.orange)  // Changed from .green to .orange for better distinction
            .padding(.horizontal, 10)  // Increased from 8
            .padding(.vertical, 5)  // Increased from 4
            .background(Color.orange.opacity(0.15))  // Changed from .green
            .cornerRadius(8)
        case .complete:
            EmptyView()
        case .notCompleted:
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                Text("Not Completed")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.red)
            .padding(.horizontal, 10)  // Increased from 8
            .padding(.vertical, 5)  // Increased from 4
            .background(Color.red.opacity(0.15))  // Changed from 0.2
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
