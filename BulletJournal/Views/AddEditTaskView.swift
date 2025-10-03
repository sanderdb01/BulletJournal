import SwiftUI
import SwiftData

struct AddEditTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    
    let dayLog: DayLog
    let taskToEdit: TaskItem?
    
    @State private var taskName: String
    @State private var selectedColor: String
    @State private var taskNotes: String
    
    init(dayLog: DayLog, taskToEdit: TaskItem? = nil, isPresented: Binding<Bool>) {
        self.dayLog = dayLog
        self.taskToEdit = taskToEdit
        self._isPresented = isPresented
        
        // Initialize state with existing task data or defaults
        _taskName = State(initialValue: taskToEdit?.name ?? "")
        _selectedColor = State(initialValue: taskToEdit?.color ?? "blue")
        _taskNotes = State(initialValue: taskToEdit?.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task Name", text: $taskName)
                        .autocorrectionDisabled()
                    
                    // Color picker with visual preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                            ForEach(Color.taskColors, id: \.name) { colorOption in
                                Button(action: {
                                    selectedColor = colorOption.name
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(colorOption.color)
                                            .frame(width: 40, height: 40)
                                        
                                        if selectedColor == colorOption.name {
                                            Circle()
                                                .stroke(Color.primary, lineWidth: 3)
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.headline)
                                                .shadow(radius: 1)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $taskNotes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(taskToEdit == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(taskName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        let trimmedName = taskName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        if let taskToEdit = taskToEdit {
            // Edit existing task
            taskToEdit.name = trimmedName
            taskToEdit.color = selectedColor
            taskToEdit.notes = taskNotes
            taskToEdit.modifiedAt = Date()
        } else {
            // Create new task
            let newTask = TaskItem(name: trimmedName, color: selectedColor, notes: taskNotes)
            dayLog.addTask(newTask)
            modelContext.insert(newTask)
        }
        
        try? modelContext.save()
        isPresented = false
    }
}

#Preview {
    @Previewable @State var isPresented = true
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DayLog.self, TaskItem.self, configurations: config)
    let context = container.mainContext
    
    let dayLog = DayLog(date: Date())
    context.insert(dayLog)
    
    return AddEditTaskView(dayLog: dayLog, isPresented: $isPresented)
        .modelContainer(container)
}
