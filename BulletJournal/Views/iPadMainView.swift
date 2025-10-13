import SwiftUI
import SwiftData

enum ViewMode: Int {
    case split = 0
    case calendarOnly = 1
    case dayOnly = 2
    case search = 3
}

struct iPadMainView: View {
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentDate = Date()
    @State private var selectedTab = 0
    @State private var viewMode: ViewMode = .split
    @State private var displayedMonth = Date()
    @State private var showSidebar = true
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            HStack(spacing: 0) {
                // Sidebar (collapsible in portrait, permanent in landscape)
                if showSidebar || isLandscape {
                    sidebarContent
                        .frame(width: 200)
#if os(iOS)
.background(Color(uiColor: .systemGroupedBackground))
#else
.background(Color(nsColor: .controlBackgroundColor))
#endif
                        .transition(.move(edge: .leading))
                    
                    Divider()
                }
                
                // Main content area
                VStack(spacing: 0) {
                    // Toolbar
                    if !isLandscape {
                        HStack {
                            Button(action: {
                                withAnimation {
                                    showSidebar.toggle()
                                }
                            }) {
                                Image(systemName: "sidebar.left")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .frame(width: 44, height: 44)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .background(AppTheme.secondaryBackground)
                        
                        Divider()
                    }
                    
                    mainContent(isLandscape: isLandscape)
                }
            }
            .background(AppTheme.primaryBackground.ignoresSafeArea())
            .onChange(of: deepLinkManager.activeLink) { oldValue, newValue in
                handleDeepLink(newValue)
            }
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private func mainContent(isLandscape: Bool) -> some View {
        switch viewMode {
        case .split:
            HStack(spacing: 0) {
                CalendarView(
                    currentDate: $currentDate,
                    selectedTab: $selectedTab,
                    displayedMonth: $displayedMonth,
                    isLandscape: isLandscape
                )
                .frame(maxWidth: .infinity)
                
                Divider()
                
                DayView(currentDate: $currentDate)
                    .frame(maxWidth: .infinity)
            }
            
        case .calendarOnly:
            CalendarView(
                currentDate: $currentDate,
                selectedTab: $selectedTab,
                displayedMonth: $displayedMonth,
                isLandscape: isLandscape
            )
            
        case .dayOnly:
            DayView(currentDate: $currentDate)
            
        case .search:
            SearchView(currentDate: $currentDate, selectedTab: $selectedTab)
        }
    }
    
    // MARK: - Sidebar Content
    
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            Text("HarborDot")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            Divider()
            
            List {
                Section("Views") {
                    Button(action: {
                        withAnimation {
                            viewMode = .split
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.split.2x1")
                                .frame(width: 20)
                            Text("Split")
                            Spacer()
                            if viewMode == .split {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .listRowBackground(viewMode == .split ? Color.blue.opacity(0.1) : Color.clear)
                    
                    Button(action: {
                        withAnimation {
                            viewMode = .calendarOnly
                        }
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .frame(width: 20)
                            Text("Calendar")
                            Spacer()
                            if viewMode == .calendarOnly {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .listRowBackground(viewMode == .calendarOnly ? Color.blue.opacity(0.1) : Color.clear)
                    
                    Button(action: {
                        withAnimation {
                            viewMode = .dayOnly
                        }
                    }) {
                        HStack {
                            Image(systemName: "calendar.day.timeline.left")
                                .frame(width: 20)
                            Text("Day")
                            Spacer()
                            if viewMode == .dayOnly {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .listRowBackground(viewMode == .dayOnly ? Color.blue.opacity(0.1) : Color.clear)
                }
                
                Section("Actions") {
                    Button(action: {
                        withAnimation {
                            currentDate = Date()
                            displayedMonth = Date()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                                .frame(width: 20)
                            Text("Today")
                        }
                    }
                    
                    Button(action: {
                        withAnimation {
                            viewMode = .search
                        }
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .frame(width: 20)
                            Text("Search")
                            Spacer()
                            if viewMode == .search {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .listRowBackground(viewMode == .search ? Color.blue.opacity(0.1) : Color.clear)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
    }
    
    private func handleDeepLink(_ link: DeepLink?) {
        guard let link = link else { return }
        
        switch link {
        case .today:
            currentDate = Date()
            displayedMonth = Date()
            viewMode = .split
        case .date(let date):
            currentDate = date
            displayedMonth = date
            viewMode = .split
        case .search:
            viewMode = .search
        case .settings:
            viewMode = .search
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            deepLinkManager.activeLink = nil
        }
    }
}

#Preview {
    iPadMainView()
        .environmentObject(DeepLinkManager())
        .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self], inMemory: true)
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}
