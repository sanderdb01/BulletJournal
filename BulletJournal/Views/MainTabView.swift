import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var currentDate = Date()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DayView(currentDate: $currentDate)
                .tabItem {
                    Label("Day", systemImage: "calendar.day.timeline.left")
                }
                .tag(0)
            
            CalendarView(currentDate: $currentDate, selectedTab: $selectedTab)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(1)
            
            SearchView(currentDate: $currentDate, selectedTab: $selectedTab)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self], inMemory: true)
}
