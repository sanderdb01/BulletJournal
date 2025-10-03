import SwiftUI
import SwiftData

struct DayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dayLogs: [DayLog]
    @Query private var settings: [AppSettings]
    
    @Binding var currentDate: Date
    @State private var showingAddTask = false
    @State private var isNotesExpanded = false
    
    // Computed property to get current day log
    private var currentDayLog: DayLog? {
        dayLogs.first { $0.date?.isSameDay(as: currentDate) ?? false }
    }
    
    // Get or create day log for current date
    private func getOrCreateDayLog() -> DayLog {
        if let existing = currentDayLog {
            return existing
        } else {
            let newDayLog = DayLog(date: currentDate)
            modelContext.insert(newDayLog)
            try? modelContext.save()
            return newDayLog
        }
    }
    
    // Get date format preference
    private var dateFormat: DateFormatStyle {
        settings.first?.dateFormat ?? .numeric
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date Navigation Header
                dateNavigationHeader
                
                Divider()
                
                // Tasks List
                List {
                   if let dayLog = currentDayLog, let tasks = dayLog.tasks, !tasks.isEmpty {
                        // Task rows
                        ForEach(dayLog.tasks ?? []) { task in
                            TaskRowView(task: task, dayLog: dayLog)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No tasks for today")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Tap below to add your first task")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    
                    // Add Task Button
                    Button(action: {
                        showingAddTask = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("Add New Task")
                                .foregroundColor(.blue)
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowSeparator(.hidden)
                    
                    // Notes Section
                    Section {
                        notesSection
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddTask) {
                AddEditTaskView(dayLog: getOrCreateDayLog(), isPresented: $showingAddTask)
            }
        }
    }
    
    // MARK: - Date Navigation Header
    
    private var dateNavigationHeader: some View {
        VStack(spacing: 8) {
            // Day of week
            Text(currentDate.dayOfWeek)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Date with navigation arrows
            HStack {
                Button(action: {
                    withAnimation {
                        currentDate = currentDate.adding(days: -1)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Text(currentDate.formatted(style: dateFormat))
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        currentDate = currentDate.adding(days: 1)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    isNotesExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Notes")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isNotesExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            if isNotesExpanded {
                NotesEditorView(dayLog: getOrCreateDayLog())
                    .padding(.horizontal)
            } else if let dayLog = currentDayLog, !dayLog.notes!.isEmpty {
                Text(dayLog.notes!)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self], inMemory: true)
}
