import SwiftUI
import SwiftData

@main
struct HarborDotApp: App {
    @StateObject private var deepLinkManager = DeepLinkManager()
    @State private var hasInitialized = false
    
    init() {
        // Request notification permission on launch
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deepLinkManager)
                .onOpenURL { url in
                    deepLinkManager.handle(url: url)
                }
                .onAppear {
                    // Ensure initialization only happens once per app launch
                    guard !hasInitialized else { return }
                    hasInitialized = true
                    
                    initializeDefaultTags()
                    generateRecurringTasks()
                }
        }
        .modelContainer(SharedModelContainer.shared)
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        .commands {
            HarborDotCommands()
        }
        #endif
    }
    
    // Initialize color tags using iCloud Key-Value Storage to prevent duplicates
    // This is idempotent and safe to call on every launch
    private func initializeDefaultTags() {
        let context = SharedModelContainer.shared.mainContext
        TagManager.createDefaultTags(in: context)
    }
    
    private func generateRecurringTasks() {
        let modelContext = SharedModelContainer.shared.mainContext
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: today)!
        
        RecurrenceManager.shared.generateRecurringTasks(
            from: today,
            to: futureDate,
            modelContext: modelContext
        )
    }
}

// MARK: - Mac Menu Commands
#if os(macOS)
struct HarborDotCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Task...") {
                // Will implement later
            }
            .keyboardShortcut("n", modifiers: .command)
        }
    }
}
#endif
