import WidgetKit
import SwiftUI
import SwiftData

struct WatchWidgetEntry: TimelineEntry {
    let date: Date
    let completedCount: Int
    let normalCount: Int
    let notCompletedCount: Int
}

struct WatchWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchWidgetEntry {
        WatchWidgetEntry(date: Date(), completedCount: 0, normalCount: 0, notCompletedCount: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WatchWidgetEntry) -> Void) {
        let entry = fetchTodayStats()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchWidgetEntry>) -> Void) {
        let entry = fetchTodayStats()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
   private func fetchTodayStats() -> WatchWidgetEntry {
       print("🔄 Watch Widget: Fetching today's stats...")
       
       let container = SharedModelContainer.shared
       let modelContext = ModelContext(container)
       let today = Calendar.current.startOfDay(for: Date())
       
       let descriptor = FetchDescriptor<DayLog>()
       
       do {
           let allDayLogs = try modelContext.fetch(descriptor)
           print("📊 Watch Widget: Found \(allDayLogs.count) day logs")
           
           if let todayLog = allDayLogs.first(where: { dayLog in
               guard let date = dayLog.date else { return false }
               return Calendar.current.isDate(date, inSameDayAs: today)
           }) {
               let tasks = todayLog.tasks ?? []
               let completed = tasks.filter { $0.status == .complete }.count
               let notCompleted = tasks.filter { $0.status == .notCompleted }.count
               let normal = tasks.count - completed - notCompleted
               
               print("✅ Watch Widget: Completed: \(completed), Normal: \(normal), Not Completed: \(notCompleted)")
               
               return WatchWidgetEntry(
                   date: Date(),
                   completedCount: completed,
                   normalCount: normal,
                   notCompletedCount: notCompleted
               )
           } else {
               print("⚠️ Watch Widget: No log found for today")
           }
       } catch {
           print("❌ Watch Widget Error: \(error)")
       }
       
       return WatchWidgetEntry(date: Date(), completedCount: 0, normalCount: 0, notCompletedCount: 0)
   }
}

// Rectangular widget
struct RectangularWidgetView: View {
    let entry: WatchWidgetEntry
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption2)
                    Text("\(entry.completedCount)")
                        .font(.caption)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption2)
                    Text("\(entry.normalCount)")
                        .font(.caption)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption2)
                    Text("\(entry.notCompletedCount)")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Image(systemName: "circle.hexagongrid.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

// Circular widget (small)
struct CircularWidgetView: View {
    let entry: WatchWidgetEntry
    
    private var totalTasks: Int {
        entry.completedCount + entry.normalCount + entry.notCompletedCount
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(entry.completedCount)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.green)
            
            Text("of \(totalTasks)")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .containerBackground(for: .widget) {
            // Background for the widget
            Color.clear
        }
    }
}
//struct CircularWidgetView: View {
//    var body: some View {
//        ZStack {
//            Circle()
//                .fill(Color.blue)
//            
//            Image(systemName: "circle.hexagongrid.fill")
//                .font(.title3)
//                .foregroundColor(.white)
//        }
//    }
//}

//@main
struct HarborDotWatchWidget: Widget {
    let kind: String = "HarborDotWatchWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchWidgetProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("HarborDot")
        .description("View your daily tasks")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
    }
}

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WatchWidgetEntry
    
    var body: some View {
        switch family {
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        case .accessoryCircular:
//            CircularWidgetView()
              CircularWidgetView(entry: entry)
        default:
              CircularWidgetView(entry: entry)
        }
    }
}
