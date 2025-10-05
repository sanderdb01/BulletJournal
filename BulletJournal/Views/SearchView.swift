import SwiftUI
import SwiftData

struct SearchView: View {
   @Environment(\.modelContext) private var modelContext
   @Query(sort: \DayLog.date, order: .reverse) private var dayLogs: [DayLog]
   
   @Binding var currentDate: Date
   @Binding var selectedTab: Int
   
   @State private var searchText = ""
   @State private var showingSettings = false
   @FocusState private var isSearchFocused: Bool
   
   // Computed property to get filtered tasks
   private var filteredTasks: [(task: TaskItem, date: Date)] {
      guard !searchText.isEmpty else { return [] }
      
      let trimmedSearch = searchText.trimmingCharacters(in: .whitespaces)
      guard !trimmedSearch.isEmpty else { return [] }
      
      var results: [(task: TaskItem, date: Date)] = []
      
      for dayLog in dayLogs {
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
   
   var body: some View {
      NavigationStack {
         ZStack {
            AppTheme.primaryBackground
               .ignoresSafeArea()
            VStack(spacing: 0) {
               // Search bar
               searchBar
               
               Divider()
               
               // Results list
               resultsList
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
               ToolbarItem(placement: .navigationBarTrailing) {
                  Button(action: {
                     showingSettings = true
                  }) {
                     Image(systemName: "gearshape")
                  }
               }
            }
            .sheet(isPresented: $showingSettings) {
               SettingsView()
            }
         }
      }
   }
   
   // MARK: - Search Bar
   
   private var searchBar: some View {
      HStack(spacing: 12) {
         Image(systemName: "magnifyingglass")
            .foregroundColor(.secondary)
         
         TextField("Search tasks...", text: $searchText)
            .focused($isSearchFocused)
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .onSubmit {
               isSearchFocused = false
            }
         
         if !searchText.isEmpty {
            Button(action: {
               searchText = ""
               isSearchFocused = true
            }) {
               Image(systemName: "xmark.circle.fill")
                  .foregroundColor(.secondary)
            }
            .transition(.scale.combined(with: .opacity))
         }
      }
      .padding()
      .background(Color(uiColor: .secondarySystemBackground))
      .cornerRadius(10)
      .padding()
      .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
   }
   
   // MARK: - Results List
   
   @ViewBuilder
   private var resultsList: some View {
      if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
         // Initial state - no search yet
         ContentUnavailableView(
            "Search Tasks",
            systemImage: "magnifyingglass",
            description: Text("Enter text to search through all your tasks and notes")
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
   
   // MARK: - Navigation
   
   private func navigateToTask(date: Date) {
      // Dismiss keyboard
      isSearchFocused = false
      
      // Small delay to allow keyboard to dismiss smoothly
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
         currentDate = date
         selectedTab = 0 // Switch to Day View
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
   MainTabView()
      .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self], inMemory: true)
}
