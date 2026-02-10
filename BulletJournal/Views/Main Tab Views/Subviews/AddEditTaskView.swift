import SwiftUI
import SwiftData

struct AddEditTaskView: View {
   @Environment(\.modelContext) private var modelContext
   @Binding var isPresented: Bool
   //   @Query private var allTags: [Tag]
   
   @FocusState private var isTitleFocused: Bool
   @FocusState private var isNotesFocused: Bool
   
   let dayLog: DayLog
   let taskToEdit: TaskItem?
   let parsedTaskFromVoice: ParsedTask?
   
   @StateObject private var tutorialManager = TutorialManager.shared
   @State private var taskName: String
   @State private var selectedColor: String
   @State private var taskNotes: String
   @State private var hasReminder: Bool
   @State private var reminderTime: Date
   @State private var isRecurring: Bool
   @State private var isAnchor: Bool
   @State private var recurrenceFrequency: RecurrenceRule.RecurrenceFrequency
   @State private var recurrenceInterval: Int
   @State private var selectedDaysOfWeek: Set<Int>
   @State private var dayOfMonth: Int
   @State private var hasEndDate: Bool
   @State private var recurrenceEndDate: Date
   //   @State private var saveAsTemplate: Bool
   
   //   var colorTags: [Tag] {
   //       allTags.filter { $0.isPrimary == true }.sorted { ($0.name ?? "") < ($1.name ?? "") }
   //   }
   //
   //   var customTags: [Tag] {
   //       allTags.filter { $0.isPrimary == false }.sorted { ($0.order ?? 0) < ($1.order ?? 0) }
   //   }
   
   // NEW: Tag states
   @State private var selectedPrimaryTag: Tag?
   @State private var selectedCustomTags: [Tag] = []
   
   init(dayLog: DayLog, taskToEdit: TaskItem? = nil, parsedTaskFromVoice: ParsedTask? = nil, isPresented: Binding<Bool>) {
      self.dayLog = dayLog
      self.taskToEdit = taskToEdit
      self._isPresented = isPresented
      self.parsedTaskFromVoice = parsedTaskFromVoice
      _taskName = State(initialValue: "")
      _selectedColor = State(initialValue: "blue")
      _taskNotes = State(initialValue: "")
      _hasReminder = State(initialValue: false)
      _reminderTime = State(initialValue: Date())
      _isRecurring = State(initialValue: false)
      _isAnchor = State(initialValue: false)
      _recurrenceFrequency = State(initialValue: .daily)
      _recurrenceInterval = State(initialValue: 1)
      _selectedDaysOfWeek = State(initialValue: [])
      _dayOfMonth = State(initialValue: 1)
      _hasEndDate = State(initialValue: false)
      _recurrenceEndDate = State(initialValue: Date().addingTimeInterval(86400 * 30))
      _selectedPrimaryTag = State(initialValue: nil)
      _selectedCustomTags = State(initialValue: [])
      
      if let task = taskToEdit {
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
         
         // Anchor
         _isAnchor = State(initialValue: taskToEdit?.isAnchor ?? false)
      }
      else if let parsed = parsedTaskFromVoice {
         // Pre-fill from voice (AI-parsed)
         _taskName = State(initialValue: parsed.taskName)
         _taskNotes = State(initialValue: parsed.notes ?? "")
         _selectedCustomTags = State(initialValue: [])
         _recurrenceFrequency = State(initialValue: .daily)
         _recurrenceInterval = State(initialValue: 1)
         
         if let tagName = parsed.colorTag {
            // We'll match this in onAppear
            print("🎨 AI suggested tag: '\(tagName)' - will match in onAppear")
         }
         
         // Handle reminder time from AI
         if let reminderTime = parsed.reminderTime {
            _reminderTime = State(initialValue: reminderTime)
            _hasReminder = State(initialValue: true)
         } else {
            _reminderTime = State(initialValue: Date())
            _hasReminder = State(initialValue: false)
         }
         
         // Handle recurrence from AI
         if let voicePattern = parsed.voiceRecurrencePattern {
            _isRecurring = State(initialValue: true)
            
            // Map voice pattern to your RecurrenceRule
            switch voicePattern {
               case .daily:
                  _recurrenceFrequency = State(initialValue: .daily)
                  _recurrenceInterval = State(initialValue: 1)
               case .weekly:
                  _recurrenceFrequency = State(initialValue: .weekly)
                  _recurrenceInterval = State(initialValue: 1)
               case .monthly:
                  _recurrenceFrequency = State(initialValue: .monthly)
                  _recurrenceInterval = State(initialValue: 1)
               case .yearly:
                  _recurrenceFrequency = State(initialValue: .monthly)
                  _recurrenceInterval = State(initialValue: 12)
            }
         } else {
            _isRecurring = State(initialValue: false)
         }
         
         // Default values for other fields
         _hasEndDate = State(initialValue: false)
         _recurrenceEndDate = State(initialValue: Date())
         _selectedDaysOfWeek = State(initialValue: [])
         _dayOfMonth = State(initialValue: 1)
      }
      else {
         // New task - initialize ALL properties with defaults
         _taskName = State(initialValue: "")
         _selectedColor = State(initialValue: "blue")
         _taskNotes = State(initialValue: "")
         _hasReminder = State(initialValue: false)
         _reminderTime = State(initialValue: Date())
         _isRecurring = State(initialValue: false)
         _recurrenceFrequency = State(initialValue: .daily)
         _recurrenceInterval = State(initialValue: 1)
         _selectedDaysOfWeek = State(initialValue: [])
         _dayOfMonth = State(initialValue: 1)
         _hasEndDate = State(initialValue: false)
         _recurrenceEndDate = State(initialValue: Date().addingTimeInterval(86400 * 30))
         _selectedPrimaryTag = State(initialValue: nil)
         _selectedCustomTags = State(initialValue: [])
      }
   }
   
   var body: some View {
      NavigationStack {
         Form {
            if parsedTaskFromVoice != nil {
               Section {
                  HStack {
                     Image(systemName: "waveform.badge.checkmark")
                        .foregroundColor(.purple)
                     Text("Created from voice - review details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                     Spacer()
                  }
                  .padding(.vertical, 4)
               }
            }
            Section("Task Name") {
               TextField("Task Name", text: $taskName)
                  .focused($isTitleFocused)
                  .clearButton(text: $taskName, focus: $isTitleFocused)
#if os(iOS)
               //                  .autocorrectionDisabled()
                  .autocorrectionDisabled(false)  // Explicitly enable autocorrection
                  .textContentType(.none)          // General text content
                  .keyboardType(.default)          // Standard keyboard
#endif
            }
            
            // Tags Section
            Section("Tags") {
               TagPicker(
                  selectedPrimaryTag: $selectedPrimaryTag,
                  selectedCustomTags: $selectedCustomTags
               )
            }
            
            // Anchor Section
            Section {
               Toggle(isOn: $isAnchor) {
                  HStack {
                     Image(systemName: "ferry.fill")
                        .foregroundColor(.blue)
                     VStack(alignment: .leading, spacing: 2) {
                        Text("Anchor Task")
                           .font(.body)
                        Text("Carries forward until complete")
                           .font(.caption)
                           .foregroundColor(.secondary)
                     }
                  }
               }
               .disabled(isRecurring)  // ← Disable if recurring
               
               // Show explanation when disabled
               if isRecurring {
                  Text("Recurring tasks cannot be anchors")
                     .font(.caption)
                     .foregroundColor(.secondary)
               }
            } header: {
               Text("Behavior")
            } footer: {
               if isAnchor {
                  Text("This task will automatically move to the next day if not completed")
                     .font(.caption)
               }
            }
            
            // Reminder Section
            Section("Reminder") {
               Toggle("Set Reminder", isOn: $hasReminder)
               
               if hasReminder {
                  if DeviceInfo.isRunningOnMac{
                     MacTimePicker(time: $reminderTime)
                  } else {
                     DatePicker(
                        "Time",
                        selection: $reminderTime,
                        displayedComponents: [.hourAndMinute]
                     )
                  }
               }
            }
            
            // Recurrence Section
            Section("Recurrence") {
               Toggle(isOn: $isRecurring) {
                  HStack {
                     Image(systemName: "repeat")
                        .foregroundColor(.purple)
                     Text("Recurring")
                  }
               }
               .disabled(isAnchor)  // ← Disable if anchor
               
               // Show explanation when disabled
               if isAnchor {
                  Text("Anchor tasks cannot be recurring")
                     .font(.caption)
                     .foregroundColor(.secondary)
               }
               
               if isRecurring {
                  recurrenceOptions
               }
            }
            
            // Task Notes Section
            Section("Task Notes (Optional)") {
               TextEditor(text: $taskNotes)
                  .frame(minHeight: 100)
                  .focused($isNotesFocused)
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
         .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
               Spacer()
               Button {
                  isNotesFocused = false  // or isContentFocused
                  isTitleFocused = false
               } label: {
                  HStack {
                     Image(systemName: "keyboard.chevron.compact.down")
                     Text("Done")
                  }
               }
               .fontWeight(.semibold)
            }
         }
#endif
         .overlay(alignment: .center) {
             if tutorialManager.currentTutorialStep == .showTaskNameHint {
                 VStack {
                     Spacer().frame(height: 120)
                     Text("👆 Type a name for your task")
                         .font(.callout)
                         .fontWeight(.medium)
                         .foregroundColor(.white)
                         .padding(.horizontal, 16)
                         .padding(.vertical, 10)
                         .background(Capsule().fill(Color.blue).shadow(radius: 8))
                         .padding(.horizontal, 32)
                     Spacer()
                 }
             } else if tutorialManager.currentTutorialStep == .showColorTagHint {
                 VStack {
                     Spacer().frame(height: 240)
                     Text("🎨 Pick a color tag")
                         .font(.callout)
                         .fontWeight(.medium)
                         .foregroundColor(.white)
                         .padding(.horizontal, 16)
                         .padding(.vertical, 10)
                         .background(Capsule().fill(Color.blue).shadow(radius: 8))
                         .padding(.horizontal, 32)
                     Spacer()
                 }
             }
         }
         .onAppear {
            // Advance through form hints
            if tutorialManager.currentTutorialStep == .showTaskNameHint {
               DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                  tutorialManager.currentTutorialStep = .showColorTagHint
               }
            }
            
            isTitleFocused = true
            // Set default Blue tag for new tasks OR match voice tag
            if taskToEdit == nil && selectedPrimaryTag == nil {
               if let parsed = parsedTaskFromVoice, let aiTagName = parsed.colorTag {
                  // Voice input - match the AI's suggested tag
                  let descriptor = FetchDescriptor<Tag>(
                     predicate: #Predicate { tag in
                        tag.isPrimary == true
                     }
                  )
                  if let allTags = try? modelContext.fetch(descriptor),
                     let matchedTag = allTags.first(where: {
                        $0.name?.lowercased() == aiTagName.lowercased()
                     }) {
                     selectedPrimaryTag = matchedTag
                     print("🎨 Matched AI tag '\(aiTagName)' to '\(matchedTag.name ?? "")'")
                  } else {
                     print("⚠️ Could not match AI tag '\(aiTagName)'")
                     // Fall through to default Blue (default tag)
                     selectedPrimaryTag = TagManager.returnDefaultTag(from: modelContext)
                  }
               } else {
                  // Regular new task - default to Blue (default tag)
                  selectedPrimaryTag = TagManager.returnDefaultTag(from: modelContext)
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
                  if !tutorialManager.hasCreatedFirstTask {
                     tutorialManager.hasCreatedFirstTask = true
                     tutorialManager.currentTutorialStep = .showCompleteTaskHint
                  }
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
      task.isAnchor = isAnchor
            
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
      
      newTask.isAnchor = isAnchor
      
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
      
      // Refresh the Complete Task Nofitication
      if newTask.status == .normal && Calendar.current.isDateInToday(dayLog.date ?? Date()) {
         Task {
            await NotificationManager.shared.refreshDailyReminder()
            print("📋 Added incomplete task - refreshing reminder")
         }
      }
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
