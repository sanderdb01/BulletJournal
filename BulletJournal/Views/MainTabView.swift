import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State private var selectedTab = 0
    @State private var currentDate = Date()
    @State private var displayedMonth = Date()  // Add this line
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad layout
                iPadMainView()
                    .environmentObject(deepLinkManager)
            } else {
                // iPhone layout
                iPhoneTabView
            }
        }
        .onChange(of: deepLinkManager.activeLink) { oldValue, newValue in
            if horizontalSizeClass != .regular {
                handleDeepLink(newValue)
            }
        }
    }
    
    // MARK: - iPhone Tab View
    
    private var iPhoneTabView: some View {
        TabView(selection: $selectedTab) {
            DayView(currentDate: $currentDate)
                .tabItem {
                    Label("Day", systemImage: "calendar.day.timeline.left")
                }
                .tag(0)
            
            CalendarView(
                currentDate: $currentDate,
                selectedTab: $selectedTab,
                displayedMonth: $displayedMonth  // Add this parameter
            )
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
    }
    
    private func handleDeepLink(_ link: DeepLink?) {
        guard let link = link else { return }
        
        switch link {
        case .today:
            currentDate = Date()
            displayedMonth = Date()  // Also update this
            selectedTab = 0
        case .date(let date):
            currentDate = date
            displayedMonth = date  // And this
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
