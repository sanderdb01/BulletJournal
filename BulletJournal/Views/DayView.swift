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
   @State private var showingVoiceRecording = false
   @State private var parsedTaskFromVoice: ParsedTask? = nil
   @State private var showingSettings = false
   
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
   
   private var availableTags: [Tag] {
      let descriptor = FetchDescriptor<Tag>()
      return (try? modelContext.fetch(descriptor)) ?? []
   }
   
   // MARK: - Search Functionality and Properties
   @Query(sort: \DayLog.date, order: .reverse) private var dayLogsSearch: [DayLog]
   @FocusState private var isSearchTitleFocused: Bool
   @State private var showingSearch = false
   
   var onTaskSelected: ((Date) -> Void)? = nil
   var onNoteSelected: ((UUID) -> Void)? = nil
   
   @State private var searchText = ""
   @FocusState private var isSearchFocused: Bool
   
   // Computed property to get filtered tasks
   private var filteredTasks: [(task: TaskItem, date: Date)] {
      guard !searchText.isEmpty else { return [] }
      
      let trimmedSearch = searchText.trimmingCharacters(in: .whitespaces)
      guard !trimmedSearch.isEmpty else { return [] }
      
      var results: [(task: TaskItem, date: Date)] = []
      
      for dayLog in dayLogsSearch {
         for task in (dayLog.tasks ?? []) {
            // Search in task name and notes
            if task.name!.localizedCaseInsensitiveContains(trimmedSearch) ||
                  task.notes!.localizedCaseInsensitiveContains(trimmedSearch) {
               results.append((task, dayLog.date!))
            }
         }
      }
      
      // Already sorted by date (reverse) because of @Query sort order
      return results
   }
   
   // MARK: - DayView Main Body
   var body: some View {
      NavigationStack {
         ZStack {
            // Background
            AppTheme.primaryBackground
               .ignoresSafeArea()
            
            VStack(spacing: 0) {
               if !showingSearch{
                  // Date Navigation Header
                  dateNavigationHeader
                     .opacity(showingSearch ? 0.0 : 1.0)
               }
               
               // Search Bar
               searchBar
               
               if !showingSearch {
                  // Tasks List
                  ZStack {
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
                        
                        // Add Task Button and voice button
                        Button(action: {
                           showingAddTask = true
                           print("add task button pressed")
   #if os(iOS)
                              HapticManager.shared.impact(style: .heavy)
   #endif
                        }) {
                           HStack(spacing: 12) {
                              // Plus icon
                              Image(systemName: "plus.circle.fill")
                                 .foregroundColor(.blue)
                                 .font(.title3)
                              
                              Text("Add New Task")
                                 .foregroundColor(.blue)
                                 .font(.headline)
                              
                              Spacer()
   #if os(iOS)
                              // Voice button (tap stops propagation to main button)
                              Button(action: {
                                 showingVoiceRecording = true
                              }) {
                                 Image(systemName: "waveform.circle.fill")
                                    .foregroundColor(.purple)
                                    .font(.title3)
                                    .padding(8)
                              }
                              .buttonStyle(.plain)  // Prevents triggering parent button
   #endif
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
                     .opacity(showingSearch ? 0.0 : 1.0)
                     if isSearchFocused {
                        clearView
                     }
                  }

               } else {
                  // Results List
                  resultsList
                     .opacity(showingSearch ? 1.0 : 0.0)
               }
            }
         }
#if os(iOS)
         .navigationBarTitleDisplayMode(.inline)
         .navigationBarHidden(true)
#endif
         .sheet(isPresented: $showingAddTask) {
            AddEditTaskView(
               dayLog: getOrCreateDayLog(),
               parsedTaskFromVoice: parsedTaskFromVoice,
               isPresented: $showingAddTask
            )
         }
#if os(iOS)
         .sheet(isPresented: $showingVoiceRecording) {
            VoiceRecordingView(
               isPresented: $showingVoiceRecording,
               parsedTask: $parsedTaskFromVoice,
               availableTags: availableTags
            )
         }
         .sheet(isPresented: $showingSettings) {
            SettingsView()
         }
         .animation(.easeInOut(duration: 0.2), value: showingSearch)
         .onChange(of: parsedTaskFromVoice) { oldValue, newValue in
            if let _ = newValue {
               // Voice recording complete, show add task sheet with pre-filled data
               showingVoiceRecording = false
               DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                  showingAddTask = true
               }
            }
         }
         .onChange(of: showingAddTask) { oldValue, newValue in
            if !newValue {
               parsedTaskFromVoice = nil
               print("showingAddTask = \(showingAddTask)")
            }
         }
#endif
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
            
            Spacer()
            
            Button(action: {
               showingSettings = true
            }) {
               Image(systemName: "gearshape")
                  .font(.title2)
            }
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
               Text("Day Notes")
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
   
   // MARK: - Search Bar
   
   private var searchBar: some View {
      HStack(spacing: 12) {
         Image(systemName: "magnifyingglass")
            .foregroundColor(.secondary)
         
         TextField("Search all tasks...", text: $searchText)
            .focused($isSearchFocused)
            .textFieldStyle(.plain)
            .focused($isSearchTitleFocused)
            .clearButton(text: $searchText, focus: $isSearchTitleFocused)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .onSubmit {
               isSearchFocused = false
            }
      }
      .padding(.all, 12.0)
#if os(iOS)
      .background(Color(uiColor: .secondarySystemBackground))
#else
      .background(Color(nsColor: .controlBackgroundColor))
#endif
      .cornerRadius(10)
      //      .padding()
      .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
      .onChange(of: searchText) { oldValue, newValue in
         showingSearch = !newValue.isEmpty
      }
   }
   
   // MARK: - Results List
   
   @ViewBuilder
   private var resultsList: some View {
      if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
         // Initial state - no search yet
         ContentUnavailableView(
            "Search Tasks",
            systemImage: "magnifyingglass",
            description: Text("Enter text to search through all your tasks and your notebook")
         )
      } else if filteredTasks.isEmpty {
         // No results found
         ContentUnavailableView(
            "No Results",
            systemImage: "doc.text.magnifyingglass",
            description: Text("No tasks found matching '\(searchText)'")
         )
      } else {
         // Results found
         List {
            Section {
               Text("\(filteredTasks.count) result\(filteredTasks.count == 1 ? "" : "s") found")
                  .font(.caption)
                  .foregroundColor(.secondary)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
            
            ForEach(filteredTasks, id: \.task.id) { item in
               SearchResultRow(
                  task: item.task,
                  date: item.date,
                  searchText: searchText
               )
               .contentShape(Rectangle())
               .onTapGesture {
                  navigateToTask(date: item.date)
               }
            }
         }
         .listStyle(.plain)
      }
   }
   
   // MARK: - Tappable Clear View
   
   private var clearView: some View {
      Color.clear
         .frame(maxWidth: .infinity, maxHeight: .infinity)
         .contentShape(Rectangle())
         .onTapGesture {
            isSearchFocused = false
            print("clear view tapped.")
         }
   }
   
   // MARK: - Navigation
   
   private func navigateToTask(date: Date) {
      // Dismiss keyboard
      isSearchFocused = false
      
      // Small delay to allow keyboard to dismiss smoothly
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
         currentDate = date
         // Call the callback if provided (Mac), otherwise switch tabs (iOS)
         if let onTaskSelected = onTaskSelected {
            onTaskSelected(date)
         } else {
            //                 selectedTab = 0 //Switch to DayView
            //dismiss the search list view, clear out the search bar, and make the dayview's day the selected day
            showingSearch = false
         }
      }
   }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
   let task: TaskItem
   let date: Date
   let searchText: String
   
   var body: some View {
      HStack(spacing: 12) {
         // Color dot
         Circle()
            .fill(Color.fromString(task.color!))
            .frame(width: 12, height: 12)
         
         // Task info
         VStack(alignment: .leading, spacing: 4) {
            // Task name with highlighted search text
            Text(highlightedText(task.name!))
               .lineLimit(2)
               .font(.body)
            
            // Task notes preview if they contain the search term
            if !task.notes!.isEmpty && task.notes!.localizedCaseInsensitiveContains(searchText) {
               Text(highlightedText(task.notes!))
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .lineLimit(2)
            }
            
            // Date
            HStack(spacing: 4) {
               Image(systemName: "calendar")
                  .font(.caption2)
               Text(date, style: .date)
                  .font(.caption)
            }
            .foregroundColor(.secondary)
         }
         
         Spacer()
         
         // Status indicator
         statusBadge
         
         // Navigation chevron
         Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundColor(.secondary)
      }
      .padding(.vertical, 8)
   }
   
   @ViewBuilder
   private var statusBadge: some View {
      switch task.status {
         case .normal:
            EmptyView()
         case .inProgress:
            Image(systemName: "clock.fill")
               .font(.caption)
               .foregroundColor(.green)
         case .complete:
            Image(systemName: "checkmark.circle.fill")
               .font(.caption)
               .foregroundColor(.green)
         case .notCompleted:
            Image(systemName: "xmark.circle.fill")
               .font(.caption)
               .foregroundColor(.red)
         case .none:
            EmptyView()
      }
   }
   
   // Highlight matching search text (basic implementation)
   private func highlightedText(_ text: String) -> AttributedString {
      var attributedString = AttributedString(text)
      
      // Find the range of the search text (case insensitive)
      if let range = text.range(of: searchText, options: .caseInsensitive) {
         let nsRange = NSRange(range, in: text)
         if let attributedRange = Range<AttributedString.Index>(nsRange, in: attributedString) {
            attributedString[attributedRange].backgroundColor = .yellow.opacity(0.3)
            attributedString[attributedRange].foregroundColor = .primary
         }
      }
      
      return attributedString
   }
}

#Preview {
#if os(iOS)
   MainTabView()
      .environmentObject(DeepLinkManager())
      .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self], inMemory: true)
#elseif os(macOS)
   MacMainView()
      .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self], inMemory: true)
#endif
}
