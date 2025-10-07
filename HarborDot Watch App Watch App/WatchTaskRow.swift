import SwiftUI
import SwiftData

struct WatchTaskRow: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteConfirm = false
    
    let task: TaskItem
    let dayLog: DayLog
    
    var body: some View {
        Button(action: {
            task.cycleStatus()
            try? modelContext.save()
        }) {
            HStack(spacing: 6) {
                // Status indicator
                statusIcon
                
                // Task info
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.name ?? "")
                        .font(.system(size: 13))
                        .foregroundColor(textColor)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        if let reminderTime = task.reminderTime {
                            HStack(spacing: 2) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 8))
                                Text(reminderTime, style: .time)
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(.blue)
                        }
                        
                        if task.isRecurring == true || task.isRecurringInstance {
                            Image(systemName: "repeat")
                                .font(.system(size: 8))
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                Spacer()
                
                // Color indicator
                Circle()
                    .fill(Color.fromString(task.color ?? "blue"))
                    .frame(width: 10, height: 10)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(rowBackgroundColor)
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Task?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("Delete '\(task.name ?? "this task")'?")
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch task.status {
        case .complete:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 14))
        case .inProgress:
            Image(systemName: "clock.fill")
                .foregroundColor(.green)
                .font(.system(size: 12))
        case .notCompleted:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .font(.system(size: 12))
        default:
            Circle()
                .strokeBorder(Color.fromString(task.color ?? "blue"), lineWidth: 2)
                .frame(width: 12, height: 12)
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
    
    private var rowBackgroundColor: Color {
        switch task.status {
        case .complete:
            return Color.green.opacity(0.15)
        case .inProgress:
            return Color.green.opacity(0.1)
        case .notCompleted:
            return Color.red.opacity(0.15)
        default:
            return Color(uiColor: .lightGray)
        }
    }
    
    private func deleteTask() {
        dayLog.deleteTask(task)
        try? modelContext.save()
    }
}
