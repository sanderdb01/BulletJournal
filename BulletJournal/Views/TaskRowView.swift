import SwiftUI
import SwiftData

struct TaskRowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditTask = false
    @State private var showingDeleteOptions = false
    @State private var showingCopyDatePicker = false
    @State private var copyTargetDate = Date()
    @State private var isPressed = false
   @State private var showingMenu = false
    
    let task: TaskItem
    let dayLog: DayLog
    
    var body: some View {
        HStack(spacing: 16) {
            // Interactive color dot with checkmark overlay
            interactiveColorDot
            
            // Task content
            VStack(alignment: .leading, spacing: 8) {
                // Task name and status
                HStack(spacing: 12) {
                    Text(task.name ?? "")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                        .strikethrough(task.status == .complete)
                    
                    Spacer()
                    
                    // Status badge
                    statusBadge
                }
                
                // Custom tags display
                if !task.customTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(task.customTags, id: \.id) { tag in
                                Text(tag.name ?? "")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
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
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Reminder indicator
                    if let reminderTime = task.reminderTime {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.caption)
                            Text(reminderTime, style: .time)
                                .font(.subheadline)
                        }
                        .foregroundColor(.orange)
                    }
                    
                    // Recurring indicator
                    if task.isRecurring == true || task.isRecurringInstance {
                        Image(systemName: "repeat")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
//        .scaleEffect(isPressed ? 0.97 : 1.0)//1.03
        .scaleEffect(isPressed || showingMenu ? 0.97 : 1.0)
        .cornerRadius(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(taskRowBackground)
                RoundedRectangle(cornerRadius: 12)
//                    .fill(isPressed ? Color.blue.opacity(0.1) : Color.clear)
                    .fill(isPressed || showingMenu ? Color.blue.opacity(0.1) : Color.clear)
            }
//               .scaleEffect(isPressed ? 0.97 : 1.0) //1.03
               .scaleEffect(isPressed || showingMenu ? 0.97 : 1.0)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .shadow(color: isPressed ? .black.opacity(0.1) : .clear, radius: 4, y: 2)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            // Tap on the row itself cycles through all statuses
            withAnimation(.easeInOut(duration: 0.2)) {
                task.cycleStatus()
#if os(iOS)
                HapticManager.shared.impact(style: .light)
#endif
                try? modelContext.save()
            }
        }
        .onLongPressGesture(minimumDuration: 0.4) {
#if os(iOS)
            HapticManager.shared.impact(style: .heavy) //when blue goes away
#endif
//            showingEditTask = true
           showingMenu = true
        } onPressingChanged: { pressing in
            if pressing {
#if os(iOS)
                HapticManager.shared.impact(style: .heavy)
#endif
            }
            isPressed = pressing
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
               deleteThisInstance()
           } label: {
               Label("Delete", systemImage: "trash")
           }
        }
        .confirmationDialog("", isPresented: $showingMenu, titleVisibility: .hidden) {
            Button("Edit") {
                showingEditTask = true
            }
            Button("Copy") {
                copyTargetDate = Date()
                showingCopyDatePicker = true
            }
            if task.isRecurring == true || task.isRecurringInstance {
                Button("Delete", role: .destructive) {
                    showingDeleteOptions = true
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: showingMenu, { oldValue, newValue in
           print("showingMenu changed: \(oldValue) -> \(newValue)")
        })
//        .contextMenu {
//            // Edit option
//            Button {
//                showingEditTask = true
//            } label: {
//                Label("Edit", systemImage: "pencil")
//            }
//            
//            // Copy option - NEW!
//            Button {
//                copyTargetDate = Date()
//                showingCopyDatePicker = true
//            } label: {
//                Label("Copy", systemImage: "doc.on.doc")
//            }
//            
//            // Delete option - shows dialog for recurring tasks
//            if task.isRecurring == true || task.isRecurringInstance {
//                Divider()
//                
//                Button(role: .destructive) {
//                    showingDeleteOptions = true
//                } label: {
//                    Label("Delete", systemImage: "trash")
//                }
//            }
//        }
        .sheet(isPresented: $showingEditTask) {
            AddEditTaskView(dayLog: dayLog, taskToEdit: task, isPresented: $showingEditTask)
        }
        .sheet(isPresented: $showingCopyDatePicker) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Copy task to which date?")
                        .font(.headline)
                        .padding(.top)
                    
                    DatePicker(
                        "Select Date",
                        selection: $copyTargetDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    
                    Spacer()
                }
                .navigationTitle("Copy Task")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingCopyDatePicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Copy") {
                            copyTaskToDate(copyTargetDate)
                            showingCopyDatePicker = false
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete Recurring Task",
            isPresented: $showingDeleteOptions,
            titleVisibility: .visible
        ) {
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
    
    // MARK: - Interactive Color Dot
    @ViewBuilder
    private var interactiveColorDot: some View {
        ZStack {
            // Base color circle
            Circle()
                .fill(getTaskColor())
                .frame(width: 28, height: 28)  // Slightly larger to accommodate checkmark
            
            // Checkmark overlay when complete
            if task.status == .complete {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .contentShape(Circle())  // Make the entire circle tappable
        .onTapGesture {
            // Tapping the dot toggles complete/normal status
            withAnimation(.easeInOut(duration: 0.2)) {
                toggleCompletion()
#if os(iOS)
                HapticManager.shared.impact(style: .medium)
#endif
                try? modelContext.save()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Get the task's color (from primary tag or legacy color)
    private func getTaskColor() -> Color {
        if let primaryTag = task.primaryTag {
            return Color.fromString(primaryTag.returnColorString())
        } else if let color = task.color {
            return Color.fromString(color)
        } else {
            return .blue  // Default fallback
        }
    }
    
    /// Toggle between complete and normal status (for dot tap)
    private func toggleCompletion() {
        if task.status == .complete {
            task.status = .normal
        } else {
            task.status = .complete
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
            // Default: tertiarySystemGroupedBackground
#if os(iOS)
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
            .foregroundColor(.orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.orange.opacity(0.15))
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
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.red.opacity(0.15))
            .cornerRadius(8)
        default:
            EmptyView()
        }
    }
    
    // MARK: - Delete Handling
    
    private func handleDelete() {
        // Check if this is a recurring task or instance
        if task.isRecurring == true || task.isRecurringInstance {
            showingDeleteOptions = true
        } else {
            // Regular task - delete immediately
            deleteThisInstance()
        }
    }
    
    private func deleteThisInstance() {
        withAnimation {
            // Cancel notification if it exists
            if let notificationId = task.notificationId {
                NotificationManager.shared.cancelTaskNotification(notificationId: notificationId)
            }
            
            dayLog.deleteTask(task)
            
            do {
                try modelContext.save()
#if os(iOS)
                HapticManager.shared.notification(type: .success)
#endif
            } catch {
                print("Error deleting task: \(error)")
            }
        }
    }
    
   private func deleteThisAndFutureInstances() {
       withAnimation {
           // Get the template ID (either this task's ID if it's the original, or its sourceTemplateId)
           guard let templateId = task.sourceTemplateId ?? task.id else {
               print("Error: Unable to get template ID")
               return
           }
           
           // Delete from this day forward
           deleteFutureInstances(templateId: templateId, fromDate: dayLog.date ?? Date())
           
   #if os(iOS)
           HapticManager.shared.notification(type: .success)
   #endif
       }
   }
    
    private func deleteFutureInstances(templateId: UUID, fromDate: Date) {
        // Fetch all day logs from this date forward
        let descriptor = FetchDescriptor<DayLog>()
        
        do {
            let allDayLogs = try modelContext.fetch(descriptor)
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
            
            try modelContext.save()
        } catch {
            print("Error deleting future instances: \(error)")
        }
    }
    
    // MARK: - Copy Task to Date
    
    private func copyTaskToDate(_ targetDate: Date) {
        // Find or create day log for target date
        let descriptor = FetchDescriptor<DayLog>()
        
        do {
            let allLogs = try modelContext.fetch(descriptor)
            let targetLogs = allLogs.filter { log in
                guard let logDate = log.date else { return false }
                return Calendar.current.isDate(logDate, inSameDayAs: targetDate)
            }
            let targetDayLog: DayLog
            
            if let existing = targetLogs.first {
                targetDayLog = existing
            } else {
                targetDayLog = DayLog(date: targetDate)
                modelContext.insert(targetDayLog)
            }
            
            // ✨ Use the makeCopy method
            let copiedTask = task.makeCopy(for: targetDate)
            
            // Add to target date's log and insert into context
            targetDayLog.addTask(copiedTask)
            modelContext.insert(copiedTask)
            
            // Schedule notification if reminder exists
            if let reminderTime = copiedTask.reminderTime {
                Task {
                    let notificationId = await NotificationManager.shared.scheduleTaskNotification(
                        task: copiedTask,
                        date: reminderTime
                    )
                    copiedTask.notificationId = notificationId
                }
            }
            
            try modelContext.save()
            
            // Haptic feedback
#if os(iOS)
            HapticManager.shared.notification(type: .success)
#endif
        } catch {
            print("Error copying task: \(error)")
        }
    }
    
    // MARK: - Move to Tomorrow (Using makeCopy method)
    
    private func moveTaskToTomorrow() {
        guard let currentDate = dayLog.date else { return }
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        
        // Find or create day log for tomorrow
        let descriptor = FetchDescriptor<DayLog>()
        
        do {
            let allLogs = try modelContext.fetch(descriptor)
            let tomorrowLogs = allLogs.filter { log in
                guard let logDate = log.date else { return false }
                return Calendar.current.isDate(logDate, inSameDayAs: tomorrow)
            }
            let tomorrowLog: DayLog
            
            if let existing = tomorrowLogs.first {
                tomorrowLog = existing
            } else {
                tomorrowLog = DayLog(date: tomorrow)
                modelContext.insert(tomorrowLog)
            }
            
            // ✨ Use the new makeCopy method - much cleaner!
            let copiedTask = task.makeCopy(for: tomorrow)
            
            // Add to tomorrow's log and insert into context
            tomorrowLog.addTask(copiedTask)
            modelContext.insert(copiedTask)
            
            // Schedule notification if reminder exists
            if let reminderTime = copiedTask.reminderTime {
                Task {
                    let notificationId = await NotificationManager.shared.scheduleTaskNotification(
                        task: copiedTask,
                        date: reminderTime
                    )
                    copiedTask.notificationId = notificationId
                }
            }
            
            // Delete original task
            if let notificationId = task.notificationId {
                NotificationManager.shared.cancelTaskNotification(notificationId: notificationId)
            }
            dayLog.deleteTask(task)
            
            try modelContext.save()
            
            // Haptic feedback
#if os(iOS)
            HapticManager.shared.notification(type: .success)
#endif
        } catch {
            print("Error moving task to tomorrow: \(error)")
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
    
    // Create a recurring task
    let task3 = TaskItem(name: "Recurring Task", color: "purple")
    task3.isRecurring = true
    
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
