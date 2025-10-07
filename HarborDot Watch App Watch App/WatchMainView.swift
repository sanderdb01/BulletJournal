import SwiftUI
import SwiftData

struct WatchMainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dayLogs: [DayLog]
    
    @State private var currentDate = Date()
    
    private var currentDayLog: DayLog? {
        dayLogs.first { $0.date?.isSameDay(as: currentDate) ?? false }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact date header
            dateHeader
              .background(Color(uiColor: .lightGray))
            
            Divider()
            
            // Task list
            if let dayLog = currentDayLog, let tasks = dayLog.tasks, !tasks.isEmpty {
                List {
                    ForEach(dayLog.tasks ?? []) { task in
                        WatchTaskRow(task: task, dayLog: dayLog)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    }
                }
                .listStyle(.plain)
            } else {
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.blue.opacity(0.5))
                    
                    Text("No Tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var dateHeader: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Button(action: {
                    currentDate = currentDate.adding(days: -1)
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                
                VStack(spacing: 0) {
                    Text(currentDate.dayOfWeek)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text(currentDate, style: .date)
                        .font(.system(size: 11, weight: .medium))
                }
                
                Button(action: {
                    currentDate = currentDate.adding(days: 1)
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    currentDate = Date()
                }) {
                    Text("Today")
                        .font(.system(size: 9, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled(currentDate.isSameDay(as: Date()))
            }
            .padding(.horizontal, 6)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WatchMainView()
        .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self], inMemory: true)
}
