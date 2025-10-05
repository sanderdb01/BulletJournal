import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environmentObject(DeepLinkManager())
        .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self], inMemory: true)
}
