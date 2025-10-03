import SwiftUI
import SwiftData

@main
struct BulletJournalApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DayLog.self,
            TaskItem.self,
            AppSettings.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic // This enables iCloud sync
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
