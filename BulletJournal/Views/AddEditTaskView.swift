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
//   @State private var saveAsTemplate: Bool
   
   // NEW: Tag states
   @State private var selectedPrimaryTag: Tag?
   @State private var selectedCustomTags: [Tag] = []
   
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
//      _saveAsTemplate = State(initialValue: taskToEdit?.isTemplate ?? false)
      
      // Load existing recurrence rule if editing
      if let ruleString = taskToEdit?.recurrenceRule,
         let rule = RecurrenceRule.from(jsonString: ruleString) {
         _recurrenceFrequency = State(initialValue: rule.frequency)
         _recurrenceInterval = State(initialValue: rule.interval)
         _selectedDaysOfWeek = State(initialValue: rule.daysOfWeek ?? [])
         _dayOfMonth = State(initialValue: rule.dayOfMonth ?? 1)
      }
      
      // NEW: Initialize tags
      _selectedPrimaryTag = State(initialValue: taskToEdit?.primaryTag)
      _selectedCustomTags = State(initialValue: taskToEdit?.customTags ?? [])
   }
   
   var body: some View {
      NavigationStack {
         Form {
            Section("Task Details") {
               TextField("Task Name", text: $taskName)
               #if os(iOS)
                  .autocorrectionDisabled()
               #endif
            }
            
            // NEW: Tags Section
            Section("Tags") {
               TagPicker(
                  selectedPrimaryTag: $selectedPrimaryTag,
                  selectedCustomTags: $selectedCustomTags
               )
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
            
//            Section {
//               Toggle("Save as Template", isOn: $saveAsTemplate)
//            } footer: {
//               Text("Templates can be quickly created from the templates menu")
//            }
         }
         .navigationTitle(taskToEdit == nil ? "New Task" : "Edit Task")
         #if os(iOS)
         .navigationBarTitleDisplayMode(.inline)
         #endif
//         .onAppear {
//            // Set default Blue tag for new tasks
//            if taskToEdit == nil && selectedPrimaryTag == nil {
//               if let blueTag = TagManager.findTag(byName: "Blue", in: modelContext) {
////                  selectedPrimaryTag = blueTag
//                  // Find blue tag and select it
//                                 let descriptor = FetchDescriptor<Tag>(
//                                    predicate: #Predicate { tag in
//                                       tag.isPrimary == true && tag.name == "blue"
//                                    }
//                                 )
//                                 if let blueTag = try? modelContext.fetch(descriptor).first {
//                                    selectedPrimaryTag = blueTag
//                                 }
//               }
//            }
//         }
         .onAppear {
            // Set default Blue tag for new tasks
            if taskToEdit == nil && selectedPrimaryTag == nil {
               // Find Blue tag (note: capitalized "Blue" to match the tag name)
               if let blueTag = TagManager.findTag(byName: "Blue", in: modelContext) {
                  DispatchQueue.main.async {
                     selectedPrimaryTag = blueTag
                  }
               }
            }
         }
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
   
   // MARK: - Recurrence Options
   
   @ViewBuilder
   private var recurrenceOptions: some View {
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
      
      // Show recurrence summary
      if let preview = recurrencePreview {
         Text(preview)
            .font(.caption)
            .foregroundColor(.secondary)
      }
   }
   
   @ViewBuilder
   private var weekdaySelector: some View {
      VStack(alignment: .leading, spacing: 8) {
         Text("Repeat on:")
            .font(.caption)
            .foregroundColor(.secondary)
         
         HStack(spacing: 12) {
            ForEach(1...7, id: \.self) { dayNumber in
               DayButton(
                  day: dayNumber,
                  isSelected: selectedDaysOfWeek.contains(dayNumber)
               ) {
                  if selectedDaysOfWeek.contains(dayNumber) {
                     selectedDaysOfWeek.remove(dayNumber)
                  } else {
                     selectedDaysOfWeek.insert(dayNumber)
                  }
               }
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
   
   private var recurrencePreview: String? {
      guard isRecurring else { return nil }
      
      var preview = "Repeats "
      
      switch recurrenceFrequency {
         case .daily:
            preview += recurrenceInterval == 1 ? "daily" : "every \(recurrenceInterval) days"
         case .weekly:
            if selectedDaysOfWeek.isEmpty {
               preview += recurrenceInterval == 1 ? "weekly" : "every \(recurrenceInterval) weeks"
            } else {
               let dayNames = selectedDaysOfWeek.sorted().map { dayNumber in
                  let formatter = DateFormatter()
                  return formatter.shortWeekdaySymbols[dayNumber - 1]
               }
               preview += "on \(dayNames.joined(separator: ", "))"
            }
         case .monthly:
            preview += "on day \(dayOfMonth) of "
            preview += recurrenceInterval == 1 ? "every month" : "every \(recurrenceInterval) months"
      }
      
      if hasEndDate {
         let formatter = DateFormatter()
         formatter.dateStyle = .medium
         preview += " until \(formatter.string(from: recurrenceEndDate))"
      }
      
      return preview
   }
   
   // MARK: - Save Task
   
   private func saveTask() {
      let trimmedName = taskName.trimmingCharacters(in: .whitespaces)
      guard !trimmedName.isEmpty else { return }
      
      var recurrenceRule: RecurrenceRule? = nil
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
      
//      try? modelContext.save()
      do {
              try modelContext.save()
              print("✅ Task saved successfully")
          } catch {
              print("❌ Error saving task: \(error)")
          }
      
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
      task.notes = taskNotes
      task.reminderTime = hasReminder ? combineDateAndTime() : nil
      task.isRecurring = isRecurring
      task.recurrenceRule = recurrenceRule?.toJSONString()
      task.recurrenceEndDate = hasEndDate ? recurrenceEndDate : nil
//      task.isTemplate = saveAsTemplate
      task.modifiedAt = Date()
      
      // NEW: Update tags
      if let primaryTag = selectedPrimaryTag {
         task.setPrimaryTag(primaryTag)
      }
      
      // Clear existing custom tags and add new ones
      task.clearCustomTags()
      for tag in selectedCustomTags {
         task.addCustomTag(tag)
      }
      
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
//         isTemplate: saveAsTemplate
      )
      
      newTask.isRecurring = isRecurring
      newTask.recurrenceRule = recurrenceRule?.toJSONString()
      newTask.recurrenceEndDate = hasEndDate ? recurrenceEndDate : nil
      
      // NEW: Add tags
      if let primaryTag = selectedPrimaryTag {
         newTask.setPrimaryTag(primaryTag)
      }
      for tag in selectedCustomTags {
         newTask.addCustomTag(tag)
      }
      
      // Schedule notification if needed
      if hasReminder, let reminderDate = newTask.reminderTime {
         Task {
            let notificationId = await NotificationManager.shared.scheduleTaskNotification(
               task: newTask,
               date: reminderDate
            )
            newTask.notificationId = notificationId
         }
      }
      
      dayLog.addTask(newTask)
      modelContext.insert(newTask)
   }
   
   private func combineDateAndTime() -> Date? {
      guard let dayLogDate = dayLog.date else { return nil }
      
      let calendar = Calendar.current
      let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
      
      var dateComponents = calendar.dateComponents([.year, .month, .day], from: dayLogDate)
      dateComponents.hour = timeComponents.hour
      dateComponents.minute = timeComponents.minute
      
      return calendar.date(from: dateComponents)
   }
}

// MARK: - Day Button (for weekly recurrence)
struct DayButton: View {
   let day: Int
   let isSelected: Bool
   let action: () -> Void
   
   private var dayLetter: String {
      let formatter = DateFormatter()
      return String(formatter.shortWeekdaySymbols[day - 1].prefix(1))
   }
   
   var body: some View {
      Button(action: action) {
         Text(dayLetter)
            .font(.caption)
            .fontWeight(isSelected ? .bold : .regular)
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 32, height: 32)
            .background(
               Circle()
                  .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
            )
      }
      .buttonStyle(.plain)
   }
}

#Preview {
   @Previewable @State var isPresented = true
   
   let config = ModelConfiguration(isStoredInMemoryOnly: true)
   let container = try! ModelContainer(for: DayLog.self, TaskItem.self, Tag.self, configurations: config)
   let context = container.mainContext
   
   let dayLog = DayLog(date: Date())
   context.insert(dayLog)
   
   // Create some sample tags
   TagManager.createDefaultTags(in: context)
   
   return AddEditTaskView(dayLog: dayLog, isPresented: $isPresented)
      .modelContainer(container)
}
