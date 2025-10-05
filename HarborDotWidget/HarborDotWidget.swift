import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget Entry

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [TaskItem]
    let dayNotes: String
}

// MARK: - Timeline Provider

struct TaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: [], dayNotes: "")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        let entry = fetchTodaysTasks()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let entry = fetchTodaysTasks()
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func fetchTodaysTasks() -> TaskEntry {
       let modelContext = ModelContext(SharedModelContainer.shared)
        let today = Calendar.current.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<DayLog>(
            predicate: #Predicate { dayLog in
                dayLog.date == today
            }
        )
        
        do {
            let dayLogs = try modelContext.fetch(descriptor)
            if let todayLog = dayLogs.first {
                return TaskEntry(
                    date: Date(),
                    tasks: todayLog.tasks ?? [],
                    dayNotes: todayLog.notes ?? ""
                )
            }
        } catch {
            print("Error fetching tasks for widget: \(error)")
        }
        
        return TaskEntry(date: Date(), tasks: [], dayNotes: "")
    }
}

// MARK: - Widget Views

struct SmallWidgetView: View {
    let entry: TaskEntry
    
    var body: some View {
        Link(destination: URL(string: "harbordot://today")!) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                    Text("Today")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                if entry.tasks.isEmpty {
                    Spacer()
                    Text("No tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(entry.tasks.prefix(3)) { task in
                            TaskRowWidget(task: task, compact: true)
                        }
                    }
                    
                    if entry.tasks.count > 3 {
                        Text("+\(entry.tasks.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct MediumWidgetView: View {
    let entry: TaskEntry
    
    var body: some View {
        Link(destination: URL(string: "harbordot://today")!) {
            HStack(spacing: 0) {
                // Left side - Tasks
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("Today's Tasks")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    if entry.tasks.isEmpty {
                        Spacer()
                        Text("No tasks for today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(entry.tasks.prefix(5)) { task in
                                TaskRowWidget(task: task, compact: false)
                            }
                        }
                        
                        if entry.tasks.count > 5 {
                            Text("+\(entry.tasks.count - 5) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                // Right side - Stats
                VStack(spacing: 12) {
                    StatBadge(
                        count: entry.tasks.filter { $0.status == .complete }.count,
                        total: entry.tasks.count,
                        label: "Done",
                        color: .green
                    )
                    
                    StatBadge(
                        count: entry.tasks.filter { $0.status == .inProgress }.count,
                        total: entry.tasks.count,
                        label: "In Progress",
                        color: .blue
                    )
                    
                    StatBadge(
                        count: entry.tasks.filter { $0.status == .notCompleted }.count,
                        total: entry.tasks.count,
                        label: "Not Done",
                        color: .red
                    )
                }
                .frame(width: 100)
                .padding()
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
    }
}

struct LargeWidgetView: View {
    let entry: TaskEntry
    
    var body: some View {
        Link(destination: URL(string: "harbordot://today")!) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today")
                            .font(.headline)
                        Text(Date(), style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // Task count badge
                    HStack(spacing: 4) {
                        Text("\(entry.tasks.filter { $0.status == .complete }.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("/")
                            .foregroundColor(.secondary)
                        Text("\(entry.tasks.count)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Tasks
                if entry.tasks.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No tasks for today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(entry.tasks.prefix(8)) { task in
                            TaskRowWidget(task: task, compact: false)
                        }
                        
                        if entry.tasks.count > 8 {
                            Text("+\(entry.tasks.count - 8) more tasks")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    
                    Spacer()
                }
                
                // Notes preview
                if !entry.dayNotes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(entry.dayNotes)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }
            }
            .padding()
        }
    }
}
// MARK: - Helper Views

struct TaskRowWidget: View {
    let task: TaskItem
    let compact: Bool
    
    var body: some View {
        HStack(spacing: compact ? 6 : 8) {
            // Status icon
            Group {
                if task.status == .complete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Circle()
                        .fill(Color.fromString(task.color ?? "blue"))
                        .frame(width: compact ? 8 : 10, height: compact ? 8 : 10)
                }
            }
            
            // Task name
            Text(task.name ?? "Untitled")
                .font(compact ? .caption : .subheadline)
                .foregroundColor(textColor)
                .strikethrough(task.status == .complete)
                .lineLimit(1)
            
            Spacer()
            
            // Status badge
            if !compact {
                statusBadge
            }
        }
    }
    
    private var textColor: Color {
        switch task.status {
        case .complete:
            return .green
        case .inProgress:
            return .green
        case .notCompleted:
            return .red
        default:
            return .primary
        }
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch task.status {
        case .inProgress:
            Image(systemName: "clock.fill")
                .font(.caption2)
                .foregroundColor(.blue)
        case .notCompleted:
            Image(systemName: "xmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.red)
        default:
            EmptyView()
        }
    }
}

struct StatBadge: View {
    let count: Int
    let total: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget Configuration

struct HarborDotWidget: Widget {
    let kind: String = "HarborDotWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Tasks")
        .description("View and track your tasks for today")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TaskEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    HarborDotWidget()
} timeline: {
    TaskEntry(date: .now, tasks: [], dayNotes: "")
    TaskEntry(date: .now, tasks: [
        TaskItem(name: "Morning Meeting", color: "red", status: .complete),
        TaskItem(name: "Buy Groceries", color: "blue", status: .normal),
        TaskItem(name: "Exercise", color: "green", status: .inProgress)
    ], dayNotes: "Great day!")
}

#Preview(as: .systemMedium) {
    HarborDotWidget()
} timeline: {
    TaskEntry(date: .now, tasks: [
        TaskItem(name: "Morning Meeting", color: "red", status: .complete),
        TaskItem(name: "Buy Groceries", color: "blue", status: .normal),
        TaskItem(name: "Exercise", color: "green", status: .inProgress),
        TaskItem(name: "Call Mom", color: "purple", status: .normal),
        TaskItem(name: "Read Book", color: "yellow", status: .notCompleted)
    ], dayNotes: "")
}

#Preview(as: .systemLarge) {
    HarborDotWidget()
} timeline: {
    TaskEntry(date: .now, tasks: [
        TaskItem(name: "Morning Meeting", color: "red", status: .complete),
        TaskItem(name: "Buy Groceries", color: "blue", status: .normal),
        TaskItem(name: "Exercise", color: "green", status: .inProgress),
        TaskItem(name: "Call Mom", color: "purple", status: .normal),
        TaskItem(name: "Read Book", color: "yellow", status: .notCompleted),
        TaskItem(name: "Team Standup", color: "orange", status: .complete)
    ], dayNotes: "Remember to review the quarterly report")
}
