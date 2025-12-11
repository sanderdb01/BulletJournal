#if !os(macOS)
import SwiftUI
import SwiftData

struct iOSNewNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
   
   @FocusState private var isTitleFocused: Bool
    
    let modelContext: ModelContext
    var onCreate: ((GeneralNote) -> Void)? = nil
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var includeMarkdownExample = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Enter title (optional)", text: $title)
                      .focused($isTitleFocused)
                      .clearButton(text: $title, focus: $isTitleFocused)
                }
                
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
                
                Section {
                    Toggle("Include Markdown Example", isOn: $includeMarkdownExample)
                } footer: {
                    Text("Adds a sample markdown note with formatting examples")
                }
            }
            .navigationTitle("New Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createNote()
                    }
                    .disabled(title.isEmpty && content.isEmpty && !includeMarkdownExample)
                }
            }
        }
    }
    
    private func createNote() {
        let noteContent: String
        let noteTitle: String?
        
        if includeMarkdownExample {
            noteTitle = title.isEmpty ? "Markdown Example" : title
            noteContent = """
            # Welcome to Markdown Notes!
            
            ## Formatting Examples
            
            **Bold text** and *italic text*
            
            ### Lists
            
            - First item
            - Second item
            - Third item
            
            1. Numbered item
            2. Another item
            3. Final item
            
            ### Code
            
            Inline `code` example
            
            ```swift
            func hello() {
                print("Hello, World!")
            }
            ```
            
            ### Links & More
            
            [Link text](https://example.com)
            
            > This is a quote
            
            ---
            
            \(content)
            """
        } else {
            noteTitle = title.isEmpty ? nil : title
            noteContent = content
        }
        
        let newNote = GeneralNote(
            title: noteTitle,
            content: noteContent
        )
        
        modelContext.insert(newNote)
        
        do {
            try modelContext.save()
            onCreate?(newNote)
            dismiss()
        } catch {
            print("Failed to save note: \(error)")
        }
    }
}

#endif
