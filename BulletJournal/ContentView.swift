import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self], inMemory: true)
}
