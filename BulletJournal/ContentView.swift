import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    
    var body: some View {
        #if os(iOS)
        MainTabView()
            .environmentObject(deepLinkManager)
        #elseif os(macOS)
        MacMainView()
            .environmentObject(deepLinkManager)
        #endif
    }
}

#Preview {
    ContentView()
        .environmentObject(DeepLinkManager())
        .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self, Tag.self, GeneralNote.self], inMemory: true)
}
