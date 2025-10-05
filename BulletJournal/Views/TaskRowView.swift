import SwiftUI
import SwiftData

struct TaskRowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditTask = false
    @State private var showingDeleteOptions = false
    
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
            
            // Task name with color indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.fromString(task.color ?? "blue"))
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.name ?? "Untitled")
                        .foregroundColor(textColor)
                        .strikethrough(task.status == .complete)
                    
                    HStack(spacing: 8) {
                        // Show reminder time if set
                        if let reminderTime = task.reminderTime {
                            HStack(spacing: 4) {
                                Image(systemName: "bell.fill")
                                    .font(.caption2)
                                Text(reminderTime, style: .time)
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                        
                        // Show recurrence indicator for both original and instances
                        if task.isRecurring == true || task.isRecurringInstance {
                            Image(systemName: "repeat")
                                .font(.caption2)
                                .foregroundColor(.purple)
                        }
                        
                        // Show notes indicator
                        if let notes = task.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            statusBadge
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .cardStyle()
        .scaleEffect(task.status == .complete ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: task.status)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                task.cycleStatus()
                HapticManager.shared.impact(style: .light)
                try? modelContext.save()
            }
        }
        .if(task.isRecurring == true || task.isRecurringInstance) { view in
            // Use context menu for recurring tasks
            view.contextMenu {
                Button(action: {
                    showingEditTask = true
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Divider()
                
                Button(role: .destructive, action: {
                    showingDeleteOptions = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .if(task.isRecurring != true && !task.isRecurringInstance) { view in
            // Use swipe actions for non-recurring tasks
            view
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteThisInstance()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .onLongPressGesture(minimumDuration: 0.5, perform: {
                    HapticManager.shared.impact(style: .heavy) // Haptic BEFORE showing sheet
                    showingEditTask = true
                }, onPressingChanged: { isPressing in
                    if isPressing {
                        HapticManager.shared.impact(style: .medium) // First haptic when press starts
                    }
                })
        }
        .sheet(isPresented: $showingEditTask) {
            AddEditTaskView(dayLog: dayLog, taskToEdit: task, isPresented: $showingEditTask)
        }
        .alert("Delete Recurring Task", isPresented: $showingDeleteOptions) {
            Button("Delete Only This Instance", role: .destructive) {
                deleteThisInstance()
            }
            
            Button("Delete This and All Future Instances", role: .destructive) {
                deleteThisAndFutureInstances()
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This is a recurring task. What would you like to delete?")
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
    
    // MARK: - Delete Methods
    
    private func deleteThisInstance() {
        // Cancel notification if exists
        if let notificationId = task.notificationId {
            NotificationManager.shared.cancelTaskNotification(notificationId: notificationId)
        }
        
        dayLog.deleteTask(task)
        try? modelContext.save()
        
        HapticManager.shared.notification(type: .success)
    }
    
    private func deleteThisAndFutureInstances() {
        guard let taskDate = dayLog.date else { return }
        
        // If this is an instance, get the template ID
        let templateId = task.sourceTemplateId ?? task.id
        
        // Delete the source template if this is the original
        if task.isRecurring == true {
            // Cancel notification
            if let notificationId = task.notificationId {
                NotificationManager.shared.cancelTaskNotification(notificationId: notificationId)
            }
            
            dayLog.deleteTask(task)
        }
        
        // Delete all future instances
        deleteFutureInstances(templateId: templateId!, fromDate: taskDate)
        
        try? modelContext.save()
        
        HapticManager.shared.notification(type: .success)
    }
    
    private func deleteFutureInstances(templateId: UUID, fromDate: Date) {
        // Fetch all day logs
        let descriptor = FetchDescriptor<DayLog>()
        
        do {
            let allDayLogs = try modelContext.fetch(descriptor)
            
            // Filter to only future day logs
            let futureDayLogs = allDayLogs.filter { dayLog in
                guard let date = dayLog.date else { return false }
                return date >= fromDate
            }
            
            for dayLog in futureDayLogs {
                // Find and delete tasks linked to this template
                let tasksToDelete = (dayLog.tasks ?? []).filter { task in
                    task.sourceTemplateId == templateId || task.id == templateId
                }
                
                for task in tasksToDelete {
                    // Cancel notifications
                    if let notificationId = task.notificationId {
                        NotificationManager.shared.cancelTaskNotification(notificationId: notificationId)
                    }
                    
                    dayLog.deleteTask(task)
                }
            }
        } catch {
            print("Error deleting future instances: \(error)")
        }
    }
}

// MARK: - Conditional View Modifier Helper

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DayLog.self, TaskItem.self, configurations: config)
    let context = container.mainContext
    
    let dayLog = DayLog(date: Date())
    let task1 = TaskItem(name: "Sample Task", color: "blue", notes: "This is a note")
    let task2 = TaskItem(name: "Completed Task", color: "green")
    task2.status = .complete
    
    dayLog.addTask(task1)
    dayLog.addTask(task2)
    
    context.insert(dayLog)
    
    return VStack {
        TaskRowView(task: task1, dayLog: dayLog)
        TaskRowView(task: task2, dayLog: dayLog)
    }
    .modelContainer(container)
}
