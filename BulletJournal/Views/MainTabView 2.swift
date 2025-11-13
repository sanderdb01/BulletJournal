////
//// MainTabView.swift
//// HarborDot
////
//// Main tab view with device detection - Updated with Notes tab
////
//
//#if os(iOS)
//import SwiftUI
//import SwiftData
//
//struct MainTabView: View {
//    @EnvironmentObject var deepLinkManager: DeepLinkManager
//    @Environment(\.colorScheme) var colorScheme
//    @Environment(\.horizontalSizeClass) var horizontalSizeClass
//    
//    @State private var selectedTab = 0
//    @State private var currentDate = Date()
//    @State private var displayedMonth = Date()
//    
//    var body: some View {
//        Group {
//            if horizontalSizeClass == .regular {
//                // iPad layout - uses existing iPadMainView
//                iPadMainView()
//                    .environmentObject(deepLinkManager)
//            } else {
//                // iPhone layout - tab view
//                iPhoneTabView
//            }
//        }
//        .onChange(of: deepLinkManager.activeLink) { oldValue, newValue in
//            if horizontalSizeClass != .regular {
//                handleDeepLink(newValue)
//            }
//        }
//    }
//    
//    // MARK: - iPhone Tab View
//    
//    private var iPhoneTabView: some View {
//        TabView(selection: $selectedTab) {
//            DayView(currentDate: $currentDate)
//                .tabItem {
//                    Label("Day", systemImage: "calendar.day.timeline.left")
//                }
//                .tag(0)
//            
//            CalendarView(
//                currentDate: $currentDate,
//                selectedTab: $selectedTab,
//                displayedMonth: $displayedMonth
//            )
//                .tabItem {
//                    Label("Calendar", systemImage: "calendar")
//                }
//                .tag(1)
//            
//            // NEW: Notes tab for iPhone
//            iOSNotesListView()
//                .tabItem {
//                    Label("Notebook", systemImage: "note.text")
//                }
//                .tag(2)
//            
//            SearchView(currentDate: $currentDate, selectedTab: $selectedTab)
//                .tabItem {
//                    Label("Search", systemImage: "magnifyingglass")
//                }
//                .tag(3)
//        }
//        .background(AppTheme.primaryBackground.ignoresSafeArea())
//    }
//    
//    private func handleDeepLink(_ link: DeepLink?) {
//        guard let link = link else { return }
//        
//        switch link {
//        case .today:
//            currentDate = Date()
//            displayedMonth = Date()
//            selectedTab = 0
//        case .date(let date):
//            currentDate = date
//            displayedMonth = date
//            selectedTab = 0
//        case .search:
//            selectedTab = 3
//        case .settings:
//            selectedTab = 3
//        }
//        
//        // Clear the link after handling
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            deepLinkManager.activeLink = nil
//        }
//    }
//}
//
//#Preview {
//    MainTabView()
//        .environmentObject(DeepLinkManager())
//        .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self, Tag.self, GeneralNote.self], inMemory: true)
//}
//#endif
