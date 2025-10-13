#if os(macOS)
import SwiftUI
import SwiftData

struct MacMainView: View {
    @State private var currentDate = Date()
    @State private var displayedMonth = Date()  // ADD THIS LINE
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with navigation
            List(selection: $selectedTab) {
                Label("Day", systemImage: "calendar.day.timeline.left")
                    .tag(0)
                
                Label("Calendar", systemImage: "calendar")
                    .tag(1)
                
                Label("Search", systemImage: "magnifyingglass")
                    .tag(2)
                
                Label("Settings", systemImage: "gear")
                    .tag(3)
               // TEMPORARY TEST BUTTON
                           Button("Test Note Model") {
                               testNoteCreation()
                           }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 200)
        } detail: {
            // Main content area
            Group {
                switch selectedTab {
                case 0:
                    DayView(currentDate: $currentDate)
                case 1:
                    CalendarView(currentDate: $currentDate, selectedTab: $selectedTab, displayedMonth: $displayedMonth)  // FIX THIS LINE
                case 2:
                    SearchView(currentDate: $currentDate, selectedTab: $selectedTab)
                case 3:
                    SettingsView()
                default:
                    DayView(currentDate: $currentDate)
                }
            }
            .frame(minWidth: 600, minHeight: 400)
        }
    }
   // TEMPORARY TEST METHOD
   @Environment(\.modelContext) private var modelContext

   private func testNoteCreation() {
       let note = GeneralNoteManager.createNote(
           title: "Test Note",
           content: "This is a test note with some content.",
           in: modelContext
       )
       
       let allNotes = GeneralNoteManager.getAllNotes(in: modelContext)
       print("✅ Created note: \(note.displayTitle)")
       print("✅ Total notes: \(allNotes.count)")
       
       // Test search
       let searchResults = GeneralNoteManager.searchNotes(query: "test", in: modelContext)
       print("✅ Search results: \(searchResults.count)")
   }
}

#Preview {
    MacMainView()
      .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self, Tag.self, GeneralNote.self], inMemory: true)
}
#endif
