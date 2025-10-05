import SwiftUI
import SwiftData

@main
struct HarborDotApp: App {
    @StateObject private var deepLinkManager = DeepLinkManager()
    
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
                    generateRecurringTasks()
                }
        }
        .modelContainer(SharedModelContainer.shared)
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
