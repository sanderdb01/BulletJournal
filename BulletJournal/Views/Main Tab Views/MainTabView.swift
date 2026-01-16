#if os(iOS)
import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.scenePhase) var scenePhase
   @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab = 0
    @State private var currentDate = Date()
    @State private var displayedMonth = Date()
    @State private var backgroundTimestamp: Date?
   
   @AppStorage("lastAnchorCheckTimestamp") private var lastAnchorCheckTimestamp: Double = 0
    
    var body: some View {
        Group {
//            if horizontalSizeClass == .regular {
//                // iPad layout
//                iPadMainView()
//                    .environmentObject(deepLinkManager)
//            } else {
//                // iPhone layout
//                iPhoneTabView
//            }
           if DeviceInfo.isiPhone {
               // iPad layout
               iPhoneTabView
           } else {
               // iPhone layout
              iPadMainView()
                  .environmentObject(deepLinkManager)
           }
        }
        .onChange(of: deepLinkManager.activeLink) { oldValue, newValue in
            if horizontalSizeClass != .regular {
                handleDeepLink(newValue)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
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
                displayedMonth: $displayedMonth
            )
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(1)
            
           iOSNotesListView()
               .tabItem {
                   Label("Notebook", systemImage: "note.text")
               }
               .tag(2)
           
//           SearchView(currentDate: $currentDate, selectedTab: $selectedTab)
//               .tabItem {
//                   Label("Search", systemImage: "magnifyingglass")
//               }
//               .tag(3)
        }
        .background(AppTheme.primaryBackground.ignoresSafeArea())
    }
    
    // MARK: - Scene Phase Handling
    
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            // App went to background - store timestamp
            backgroundTimestamp = Date()
            print("📱 App went to background at \(backgroundTimestamp!)")
            
        case .active:
              // Process anchors when becoming active
                      Task {
                          await processAnchorsIfNeeded()
                      }
            // App came back to foreground - check if we should reset date
            if let backgroundTime = backgroundTimestamp {
                let timeInBackground = Date().timeIntervalSince(backgroundTime)
                let tenMinutes: TimeInterval = 10 * 60 // 10 minutes in seconds
                
                if timeInBackground >= tenMinutes {
                    // Been in background for 10+ minutes - reset to today
                    let today = Date()
                    if !Calendar.current.isDate(currentDate, inSameDayAs: today) {
                        print("📅 Resetting to today (was in background for \(Int(timeInBackground/60)) minutes)")
                        currentDate = today
                        displayedMonth = today
                        selectedTab = 0  // Go to Day view
                    }
                }
                
                // Clear the timestamp
                backgroundTimestamp = nil
            }
            
        case .inactive:
            // App is transitioning - no action needed
            break
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Deep Link Handling
    
    private func handleDeepLink(_ link: DeepLink?) {
        guard let link = link else { return }
        
        switch link {
        case .today:
            currentDate = Date()
            displayedMonth = Date()
            selectedTab = 0
        case .date(let date):
            currentDate = date
            displayedMonth = date
            selectedTab = 0
        case .search:
            selectedTab = 3
        case .settings:
            selectedTab = 3
        }
        
        // Clear the link after handling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            deepLinkManager.activeLink = nil
        }
    }
   
   // MARK: - Anchor Processing

   /// Processes anchor tasks when crossing into a new day
   ///
   /// Called every time the app becomes active. Checks if we've crossed
   /// midnight since the last check and processes incomplete anchors.
   private func processAnchorsIfNeeded() async {
       let now = Date()
       let lastCheck = Date(timeIntervalSince1970: lastAnchorCheckTimestamp)
       
       print("\n" + String(repeating: "=", count: 60))
       print("🚢 ANCHOR CHECK")
       print(String(repeating: "=", count: 60))
       print("📅 Last check: \(formatDate(lastCheck)) (\(lastAnchorCheckTimestamp == 0 ? "never" : "stored"))")
       print("📅 Current:    \(formatDate(now))")
       
       // First launch check
       if lastAnchorCheckTimestamp == 0 {
           print("🚢 First launch - setting baseline")
           lastAnchorCheckTimestamp = now.timeIntervalSince1970
           print(String(repeating: "=", count: 60) + "\n")
           return
       }
       
       // Check if same day
       let isSameDay = Calendar.current.isDate(lastCheck, inSameDayAs: now)
       print("📅 Same day? \(isSameDay ? "YES" : "NO")")
       
       if isSameDay {
           print("🚢 Same day - skipping anchor processing")
           print(String(repeating: "=", count: 60) + "\n")
           return
       }
       
       print("🚢 NEW DAY DETECTED - Processing anchors!")
       print(String(repeating: "-", count: 60))
       
       // Update timestamp
       lastAnchorCheckTimestamp = now.timeIntervalSince1970
       print("💾 Updated timestamp: \(now.timeIntervalSince1970)")
       
       // Process anchors
       await AnchorManager.shared.processAnchors(context: modelContext)
       
       print(String(repeating: "=", count: 60) + "\n")
   }

   /// Formats a date for logging
   private func formatDate(_ date: Date) -> String {
       let formatter = DateFormatter()
       formatter.dateStyle = .medium
       formatter.timeStyle = .short
       return formatter.string(from: date)
   }
}

#Preview {
    MainTabView()
        .environmentObject(DeepLinkManager())
        .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self, Tag.self, GeneralNote.self], inMemory: true)
}
#endif
