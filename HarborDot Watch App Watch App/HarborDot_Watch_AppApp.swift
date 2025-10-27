import SwiftUI
import SwiftData

@main
struct HarborDot_Watch_App: App {
    var body: some Scene {
        WindowGroup {
//            WatchMainView()
           WatchDayView()
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
