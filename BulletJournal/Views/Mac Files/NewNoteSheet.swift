#if os(macOS)
import SwiftUI
import SwiftData

struct NewNoteSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    var onCreate: (GeneralNote) -> Void
    
    @State private var title = ""
    @State private var content = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Note Title (Optional)", text: $title)
                }
                
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let note = GeneralNoteManager.createNote(
                            title: title.isEmpty ? nil : title,
                            content: content,
                            in: modelContext
                        )
                        onCreate(note)
                        isPresented = false
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}
#endif
