import SwiftUI
import SwiftData

struct AddEditTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    
    let dayLog: DayLog
    let taskToEdit: TaskItem?
    
    @State private var taskName: String
    @State private var selectedColor: String
    @State private var taskNotes: String
    @State private var hasReminder: Bool
    @State private var reminderTime: Date
    @State private var isRecurring: Bool
    @State private var recurrenceFrequency: RecurrenceRule.RecurrenceFrequency
    @State private var recurrenceInterval: Int
    @State private var selectedDaysOfWeek: Set<Int>
    @State private var dayOfMonth: Int
    @State private var hasEndDate: Bool
    @State private var recurrenceEndDate: Date
    @State private var saveAsTemplate: Bool
    
    init(dayLog: DayLog, taskToEdit: TaskItem? = nil, isPresented: Binding<Bool>) {
        self.dayLog = dayLog
        self.taskToEdit = taskToEdit
        self._isPresented = isPresented
        
        // Initialize state with existing task data or defaults
        _taskName = State(initialValue: taskToEdit?.name ?? "")
        _selectedColor = State(initialValue: taskToEdit?.color ?? "blue")
        _taskNotes = State(initialValue: taskToEdit?.notes ?? "")
        
        // Initialize reminder state
        let hasExistingReminder = taskToEdit?.reminderTime != nil
        _hasReminder = State(initialValue: hasExistingReminder)
        _reminderTime = State(initialValue: taskToEdit?.reminderTime ?? Date())
        
        // Initialize recurrence state
        _isRecurring = State(initialValue: taskToEdit?.isRecurring ?? false)
        _recurrenceFrequency = State(initialValue: .daily)
        _recurrenceInterval = State(initialValue: 1)
        _selectedDaysOfWeek = State(initialValue: [])
        _dayOfMonth = State(initialValue: 1)
        _hasEndDate = State(initialValue: taskToEdit?.recurrenceEndDate != nil)
        _recurrenceEndDate = State(initialValue: taskToEdit?.recurrenceEndDate ?? Date().addingTimeInterval(86400 * 30))
        _saveAsTemplate = State(initialValue: taskToEdit?.isTemplate ?? false)
        
        // Load existing recurrence rule if editing
        if let ruleString = taskToEdit?.recurrenceRule,
           let rule = RecurrenceRule.from(jsonString: ruleString) {
            _recurrenceFrequency = State(initialValue: rule.frequency)
            _recurrenceInterval = State(initialValue: rule.interval)
            _selectedDaysOfWeek = State(initialValue: rule.daysOfWeek ?? [])
            _dayOfMonth = State(initialValue: rule.dayOfMonth ?? 1)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task Name", text: $taskName)
                        .autocorrectionDisabled()
                    
                    // Color picker
                    colorPicker
                }
                
                Section("Reminder") {
                    Toggle("Set Reminder", isOn: $hasReminder)
                    
                    if hasReminder {
                        DatePicker(
                            "Time",
                            selection: $reminderTime,
                            displayedComponents: [.hourAndMinute]
                        )
                    }
                }
                
                Section("Recurrence") {
                    Toggle("Repeat Task", isOn: $isRecurring)
                    
                    if isRecurring {
                        recurrenceOptions
                    }
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $taskNotes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Toggle("Save as Template", isOn: $saveAsTemplate)
                } footer: {
                    Text("Templates can be quickly created from the templates menu")
                }
            }
            .navigationTitle(taskToEdit == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(taskName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    // MARK: - Color Picker
    
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                ForEach(Color.taskColors, id: \.name) { colorOption in
                    Button(action: {
                        selectedColor = colorOption.name
                    }) {
                        ZStack {
                            Circle()
                                .fill(colorOption.color)
                                .frame(width: 40, height: 40)
                            
                            if selectedColor == colorOption.name {
                                Circle()
                                    .stroke(Color.primary, lineWidth: 3)
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .shadow(radius: 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Recurrence Options
    
    private var recurrenceOptions: some View {
        Group {
            Picker("Frequency", selection: $recurrenceFrequency) {
                Text("Daily").tag(RecurrenceRule.RecurrenceFrequency.daily)
                Text("Weekly").tag(RecurrenceRule.RecurrenceFrequency.weekly)
                Text("Monthly").tag(RecurrenceRule.RecurrenceFrequency.monthly)
            }
            
            Stepper("Every \(recurrenceInterval) \(frequencyUnit)", value: $recurrenceInterval, in: 1...30)
            
            if recurrenceFrequency == .weekly {
                weekdaySelector
            }
            
            if recurrenceFrequency == .monthly {
                Stepper("Day \(dayOfMonth) of month", value: $dayOfMonth, in: 1...31)
            }
            
            Toggle("Set End Date", isOn: $hasEndDate)
            
            if hasEndDate {
                DatePicker(
                    "End Date",
                    selection: $recurrenceEndDate,
                    displayedComponents: [.date]
                )
            }
        }
    }
    
   private var weekdaySelector: some View {
       VStack(alignment: .leading, spacing: 8) {
           Text("Repeat on")
               .font(.subheadline)
               .foregroundColor(.secondary)
           
           HStack(spacing: 8) {
               ForEach(1...7, id: \.self) { dayNumber in
                   let isSelected = selectedDaysOfWeek.contains(dayNumber)
                   
                   Button(action: {
                       withAnimation(.easeInOut(duration: 0.15)) {
                           if isSelected {
                               selectedDaysOfWeek.remove(dayNumber)
                           } else {
                               selectedDaysOfWeek.insert(dayNumber)
                           }
                       }
                   }) {
                       Text(dayAbbreviation(for: dayNumber))
                           .font(.caption)
                           .fontWeight(.medium)
                           .frame(width: 36, height: 36)
                           .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                           .foregroundColor(isSelected ? .white : .primary)
                           .cornerRadius(18)
                   }
                   .buttonStyle(.plain) // Add this to prevent default button behavior
               }
           }
       }
   }
    
    private var frequencyUnit: String {
        switch recurrenceFrequency {
        case .daily:
            return recurrenceInterval == 1 ? "day" : "days"
        case .weekly:
            return recurrenceInterval == 1 ? "week" : "weeks"
        case .monthly:
            return recurrenceInterval == 1 ? "month" : "months"
        }
    }
    
    private func dayAbbreviation(for dayNumber: Int) -> String {
        let formatter = DateFormatter()
        return String(formatter.veryShortWeekdaySymbols[dayNumber - 1].prefix(1))
    }
    
    // MARK: - Save Task
    
    private func saveTask() {
        let trimmedName = taskName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        // Create recurrence rule if needed
        var recurrenceRule: RecurrenceRule?
        if isRecurring {
            recurrenceRule = RecurrenceRule(
                frequency: recurrenceFrequency,
                interval: recurrenceInterval,
                daysOfWeek: recurrenceFrequency == .weekly ? selectedDaysOfWeek : nil,
                dayOfMonth: recurrenceFrequency == .monthly ? dayOfMonth : nil,
                endDate: hasEndDate ? recurrenceEndDate : nil
            )
        }
        
        if let taskToEdit = taskToEdit {
            // Cancel old notification if it exists
            if let oldNotificationId = taskToEdit.notificationId {
                NotificationManager.shared.cancelTaskNotification(notificationId: oldNotificationId)
            }
            
            // Edit existing task
            updateTask(taskToEdit, recurrenceRule: recurrenceRule)
        } else {
            // Create new task
            createTask(recurrenceRule: recurrenceRule)
        }
        
        try? modelContext.save()
        
        // Generate future recurring tasks
        if isRecurring {
            let endDate = recurrenceEndDate.addingTimeInterval(86400 * 365) // 1 year ahead
            RecurrenceManager.shared.generateRecurringTasks(
                from: Date(),
                to: endDate,
                modelContext: modelContext
            )
        }
        
        isPresented = false
    }
    
    private func updateTask(_ task: TaskItem, recurrenceRule: RecurrenceRule?) {
        task.name = taskName
        task.color = selectedColor
        task.notes = taskNotes
        task.reminderTime = hasReminder ? combineDateAndTime() : nil
        task.isRecurring = isRecurring
        task.recurrenceRule = recurrenceRule?.toJSONString()
        task.recurrenceEndDate = hasEndDate ? recurrenceEndDate : nil
        task.isTemplate = saveAsTemplate
        task.modifiedAt = Date()
        
        // Schedule new notification if needed
        if hasReminder, let reminderDate = task.reminderTime {
            Task {
                let notificationId = await NotificationManager.shared.scheduleTaskNotification(
                    task: task,
                    date: reminderDate
                )
                task.notificationId = notificationId
            }
        }
    }
    
    private func createTask(recurrenceRule: RecurrenceRule?) {
        let reminderDate = hasReminder ? combineDateAndTime() : nil
        let newTask = TaskItem(
            name: taskName,
            color: selectedColor,
            notes: taskNotes,
            status: .normal,
            reminderTime: reminderDate,
            isTemplate: saveAsTemplate
        )
        
        newTask.isRecurring = isRecurring
        newTask.recurrenceRule = recurrenceRule?.toJSONString()
        newTask.recurrenceEndDate = hasEndDate ? recurrenceEndDate : nil
        
        dayLog.addTask(newTask)
        modelContext.insert(newTask)
        
        // Schedule notification if needed
        if hasReminder, let reminderDate = reminderDate {
            Task {
                let notificationId = await NotificationManager.shared.scheduleTaskNotification(
                    task: newTask,
                    date: reminderDate
                )
                newTask.notificationId = notificationId
            }
        }
    }
    
    private func combineDateAndTime() -> Date {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: dayLog.date!)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        var combined = DateComponents()
        combined.year = dayComponents.year
        combined.month = dayComponents.month
        combined.day = dayComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? reminderTime
    }
}

#Preview {
    @Previewable @State var isPresented = true
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DayLog.self, TaskItem.self, configurations: config)
    let context = container.mainContext
    
    let dayLog = DayLog(date: Date())
    context.insert(dayLog)
    
    return AddEditTaskView(dayLog: dayLog, isPresented: $isPresented)
        .modelContainer(container)
}
