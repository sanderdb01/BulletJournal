import SwiftUI
import SwiftData

struct DayView: View {
   @Environment(\.modelContext) private var modelContext
   @Environment(\.colorScheme) var colorScheme
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
         ZStack {
            // Background
            AppTheme.primaryBackground
               .ignoresSafeArea()
            
            VStack(spacing: 0) {
               // Date Navigation Header
               dateNavigationHeader
               
               // Tasks List
               List {
                  if let dayLog = currentDayLog, let tasks = dayLog.tasks, !tasks.isEmpty {
                     // Task rows
                     ForEach(dayLog.tasks ?? []) { task in
                        TaskRowView(task: task, dayLog: dayLog)
                           .listRowInsets(EdgeInsets())
                           .listRowSeparator(.hidden)
                           .listRowBackground(Color.clear)
                           .padding(.horizontal)
                           .padding(.vertical, 4)
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
                     .padding(.vertical, 60)
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
                     .padding()
                     .background(AppTheme.tertiaryBackground)
                     .cornerRadius(12)
                  }
                  .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                  .listRowSeparator(.hidden)
                  .listRowBackground(Color.clear)
                  
                  // Notes Section
                  Section {
                     notesSection
                  }
                  .listRowInsets(EdgeInsets())
                  .listRowSeparator(.hidden)
                  .listRowBackground(Color.clear)
               }
               .listStyle(.plain)
               .scrollContentBackground(.hidden)
            }
         }
#if os(iOS)
         .navigationBarTitleDisplayMode(.inline)
         .navigationBarHidden(true)
#endif
         .sheet(isPresented: $showingAddTask) {
            AddEditTaskView(dayLog: getOrCreateDayLog(), isPresented: $showingAddTask)
         }
      }
   }
   
   // MARK: - Date Navigation Header
   
   private var dateNavigationHeader: some View {
      VStack(spacing: 4) {
         // Date with navigation arrows (combined with day of week)
         HStack(spacing: 0) {
            Button(action: {
               withAnimation(.easeInOut(duration: 0.2)) {
                  currentDate = currentDate.adding(days: -1)
               }
            }) {
               Image(systemName: "chevron.left.circle.fill")
                  .font(.title2)
                  .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
               Text(currentDate.dayOfWeek)
                  .font(.caption)
                  .foregroundColor(.secondary)
               
               Text(currentDate.formatted(style: dateFormat))
                  .font(.title3)
                  .fontWeight(.semibold)
            }
            
            Spacer()
            
            Button(action: {
               withAnimation(.easeInOut(duration: 0.2)) {
                  currentDate = currentDate.adding(days: 1)
               }
            }) {
               Image(systemName: "chevron.right.circle.fill")
                  .font(.title2)
                  .foregroundColor(.blue)
            }
            
            Spacer()
               .frame(width: 40)
            
            // Today button
            Button(action: {
               withAnimation {
                  currentDate = Date()
               }
            }) {
               Text("Today")
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .foregroundColor(.white)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 6)
                  .background(currentDate.isSameDay(as: Date()) ? Color.gray.opacity(0.3) : Color.blue)
                  .cornerRadius(8)
            }
            .disabled(currentDate.isSameDay(as: Date()))
         }
         .padding(.horizontal, 16)
      }
      .padding(.vertical, 12)
      .background(AppTheme.secondaryBackground)
      .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 2, x: 0, y: 2)
   }
   
   // MARK: - Notes Section
   
   private var notesSection: some View {
      VStack(alignment: .leading, spacing: 0) {
         Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
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
            .background(AppTheme.tertiaryBackground)
            .cornerRadius(12)
         }
         .padding(.horizontal, 16)
         .padding(.top, 8)
         
         if isNotesExpanded {
            NotesEditorView(dayLog: getOrCreateDayLog())
               .padding(.horizontal, 16)
               .padding(.top, 8)
         } else if let dayLog = currentDayLog, let notes = dayLog.notes, !notes.isEmpty {
            Text(notes)
               .lineLimit(2)
               .foregroundColor(.secondary)
               .padding(.horizontal, 32)
               .padding(.top, 8)
               .padding(.bottom, 16)
         }
      }
   }
}

#Preview {
   MainTabView()
      .environmentObject(DeepLinkManager())
      .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self], inMemory: true)
}
