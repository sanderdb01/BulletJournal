//#if os(watchOS)
//import SwiftUI
//import SwiftData
//
//struct WatchDayView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Query private var dayLogs: [DayLog]
//    
//    @State private var showingVoiceRecording = false
//    
//    // Always show today
//    private let currentDate = Date()
//    
//    // Computed property to get current day log
//    private var currentDayLog: DayLog? {
//        let today = Calendar.current.startOfDay(for: currentDate)
//        return dayLogs.first { dayLog in
//            guard let date = dayLog.date else { return false }
//            return Calendar.current.isDate(date, inSameDayAs: today)
//        }
//    }
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 0) {
//                // Header with date and voice button
//                headerSection
//                
//                // Tasks list
//                if let dayLog = currentDayLog, let tasks = dayLog.tasks, !tasks.isEmpty {
//                    List {
//                        ForEach(tasks) { task in
//                            WatchTaskRow(task: task, dayLog: dayLog)
//                                .listRowBackground(Color.clear)
//                        }
//                    }
//                    .listStyle(.carousel)
//                } else {
//                    // Empty state
//                    VStack(spacing: 12) {
//                        Image(systemName: "checkmark.circle")
//                            .font(.system(size: 40))
//                            .foregroundColor(.secondary.opacity(0.5))
//                        
//                        Text("No tasks")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                        
//                        Text("Tap mic to add")
//                            .font(.caption2)
//                            .foregroundColor(.secondary)
//                    }
//                    .frame(maxHeight: .infinity)
//                }
//            }
//            .sheet(isPresented: $showingVoiceRecording) {
//                WatchVoiceRecordingView(isPresented: $showingVoiceRecording)
//            }
//        }
//    }
//    
//    // MARK: - Header Section
//    
//    private var headerSection: some View {
//        VStack(spacing: 4) {
//            // Date
//            Text(currentDate, style: .date)
//                .font(.caption)
//                .foregroundColor(.secondary)
//            
//            // Day of week
//            Text(currentDate.formatted(.dateTime.weekday(.wide)))
//                .font(.headline)
//            
//            // Voice button
//            Button {
//                showingVoiceRecording = true
//            } label: {
//                HStack {
//                    Image(systemName: "waveform.circle.fill")
//                        .font(.body)
//                    Text("Add Task")
//                        .font(.caption)
//                }
//                .foregroundColor(.purple)
//                .padding(.vertical, 6)
//                .padding(.horizontal, 12)
//                .background(Color.purple.opacity(0.15))
//                .cornerRadius(20)
//            }
//            .buttonStyle(.plain)
//            .padding(.top, 4)
//        }
//        .padding(.vertical, 8)
//        .frame(maxWidth: .infinity)
//        .background(Color(.lightGray))
//        .ignoresSafeArea()
//    }
//}
//
//// MARK: - Watch Task Row
//
//struct WatchTaskRow: View {
//    @Environment(\.modelContext) private var modelContext
//    let task: TaskItem
//    let dayLog: DayLog
//    
//    var body: some View {
//        HStack(spacing: 8) {
//            // Status indicator
//            Button {
//                task.cycleStatus()
//                try? modelContext.save()
//               
//               // Cancel reminder if all tasks complete
//               checkDailyReminderStatus()
//            } label: {
//                statusIcon
//                    .font(.title3)
//            }
//            .buttonStyle(.plain)
//            
//            // Task name
//            VStack(alignment: .leading, spacing: 2) {
//                Text(task.name ?? "")
//                    .font(.caption)
//                    .strikethrough(task.status == .complete)
//                    .foregroundColor(task.status == .complete ? .secondary : .primary)
//                
//                // Show color tag if present
//                if let tag = task.primaryTag, let tagName = tag.name {
//                    Text(tagName)
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                }
//            }
//            
//            Spacer()
//        }
//        .padding(.vertical, 4)
//    }
//    
//    @ViewBuilder
//    private var statusIcon: some View {
//        switch task.status {
//        case .normal:
//            Circle()
//                .strokeBorder(Color.fromString(task.color ?? "blue"), lineWidth: 2)
//                .frame(width: 20, height: 20)
//        case .inProgress:
//            Image(systemName: "circle.lefthalf.filled")
//                .foregroundColor(Color.fromString(task.color ?? "blue"))
//        case .complete:
//            Image(systemName: "checkmark.circle.fill")
//                .foregroundColor(.green)
//        case .notCompleted:
//            Image(systemName: "xmark.circle.fill")
//                .foregroundColor(.red)
//           case .none:
//              Circle()
//                  .strokeBorder(Color.fromString(task.color ?? "blue"), lineWidth: 2)
//                  .frame(width: 20, height: 20)
//        }
//    }
//   
//   // MARK: Task Status Notification Helper function
//   private func checkDailyReminderStatus() {
//       // Only check for today's tasks
//       guard Calendar.current.isDateInToday(dayLog.date ?? Date()) else {
//           return
//       }
//       
//       // Check if any tasks are still incomplete
//       let hasIncompleteTasks = dayLog.tasks?.contains { $0.status == .normal } ?? false
//       
//       if !hasIncompleteTasks {
//           // All done! Cancel today's reminder
//           Task {
//               await NotificationManager.shared.cancelDailyReminder()
//           }
//       }
//   }
//}
//
//#Preview {
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: DayLog.self, TaskItem.self, Tag.self, configurations: config)
//    let context = container.mainContext
//    
//    // Create sample data
//    let today = Calendar.current.startOfDay(for: Date())
//    let dayLog = DayLog(date: today)
//    context.insert(dayLog)
//    
//    let task1 = TaskItem(name: "Sample Task", color: "blue", status: .normal)
//    let task2 = TaskItem(name: "Completed Task", color: "green", status: .complete)
//    dayLog.addTask(task1)
//    dayLog.addTask(task2)
//    context.insert(task1)
//    context.insert(task2)
//    
//    return WatchDayView()
//        .modelContainer(container)
//}
//#endif
