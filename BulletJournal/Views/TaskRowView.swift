import SwiftUI
import SwiftData

struct TaskRowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditTask = false
    
    let task: TaskItem
    let dayLog: DayLog
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkmark for completed tasks
            if task.status == .complete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
            
            // Task name with color indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.fromString(task.color!))
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.name!)
                        .foregroundColor(textColor)
                        .strikethrough(task.status == .complete)
                    
                    if !task.notes!.isEmpty {
                        Text(task.notes!)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            statusBadge
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                task.cycleStatus()
                try? modelContext.save()
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            showingEditTask = true
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation {
                    dayLog.deleteTask(task)
                    try? modelContext.save()
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditTask) {
            AddEditTaskView(dayLog: dayLog, taskToEdit: task, isPresented: $showingEditTask)
        }
    }
    
    private var textColor: Color {
        switch task.status {
        case .normal:
            return .primary
        case .inProgress:
            return .green
        case .complete:
            return .green
        case .notCompleted:
            return .red
           case .none:
              return .primary
        }
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch task.status {
        case .normal:
            EmptyView()
        case .inProgress:
            Text("In Progress")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(8)
        case .complete:
            EmptyView()
        case .notCompleted:
            Text("Not Completed")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.2))
                .foregroundColor(.red)
                .cornerRadius(8)
           case .none:
              EmptyView()
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DayLog.self, TaskItem.self, configurations: config)
    let context = container.mainContext
    
    let dayLog = DayLog(date: Date())
    let task1 = TaskItem(name: "Sample Task", color: "blue", notes: "This is a note")
    let task2 = TaskItem(name: "Completed Task", color: "green")
    task2.status = .complete
    
    dayLog.addTask(task1)
    dayLog.addTask(task2)
    
    context.insert(dayLog)
    
    return List {
        TaskRowView(task: task1, dayLog: dayLog)
        TaskRowView(task: task2, dayLog: dayLog)
    }
    .listStyle(.plain)
    .modelContainer(container)
}
