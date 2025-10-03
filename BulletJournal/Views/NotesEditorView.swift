import SwiftUI
import SwiftData

struct NotesEditorView: View {
    @Environment(\.modelContext) private var modelContext
    let dayLog: DayLog
    
    @State private var notesText: String
    @FocusState private var isFocused: Bool
    
    init(dayLog: DayLog) {
        self.dayLog = dayLog
        _notesText = State(initialValue: dayLog.notes!)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            TextEditor(text: $notesText)
                .frame(minHeight: 150)
                .padding(8)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(8)
                .focused($isFocused)
                .onChange(of: notesText) { oldValue, newValue in
                    dayLog.updateNotes(newValue)
                    try? modelContext.save()
                }
                .padding(.horizontal)
                .padding(.bottom)
            
            if isFocused {
                HStack {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
    }
}
