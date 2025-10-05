import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @Environment(\.colorScheme) var colorScheme
    
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
        .background(AppTheme.primaryBackground.ignoresSafeArea())
        .onChange(of: deepLinkManager.activeLink) { oldValue, newValue in
            handleDeepLink(newValue)
        }
    }
    
    private func handleDeepLink(_ link: DeepLink?) {
        guard let link = link else { return }
        
        switch link {
        case .today:
            currentDate = Date()
            selectedTab = 0
        case .date(let date):
            currentDate = date
            selectedTab = 0
        case .search:
            selectedTab = 2
        case .settings:
            selectedTab = 2
        }
        
        // Clear the link after handling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            deepLinkManager.activeLink = nil
        }
    }
}
