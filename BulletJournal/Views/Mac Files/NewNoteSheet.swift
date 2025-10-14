#if os(macOS)
import SwiftUI
import SwiftData

struct NewNoteSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    var onCreate: (GeneralNote) -> Void
    
    @State private var title = ""
    @State private var content = ""
    @State private var includeExampleMarkdown = false
    
    private let exampleMarkdown = """
    # Welcome to Your Note
    
    This is an example note with **markdown formatting**.
    
    ## Text Formatting
    
    You can make text **bold** or *italic* for emphasis.
    
    ## Lists
    
    Unordered lists:
    - Item one
    - Item two
    - Item three
    
    Ordered lists:
    1. First item
    2. Second item
    3. Third item
    
    ## Code
    
    Inline code: `let x = 42`
    
    Code blocks:
    ```
    func greet() {
        print("Hello, World!")
    }
    ```
    
    ## Links
    
    Check out [Apple's website](https://apple.com) for more info.
    
    ## Your Content
    
    Delete this example and start writing your own content!
    """
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("Title") {
                        TextField("Note Title (Optional)", text: $title)
                    }
                    
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Include example markdown")
                                    .font(.body)
                                Text("Create a new note with example markdown formatting")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $includeExampleMarkdown)
                                .labelsHidden()
                        }
                    }
                    
                    if !includeExampleMarkdown {
                        Section("Content") {
                            TextEditor(text: $content)
                                .frame(minHeight: 200)
                                .font(.body)
                        }
                    } else {
                        Section {
                            Text("A note with example markdown will be created")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                    }
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
                        let finalContent = includeExampleMarkdown ? exampleMarkdown : content
                        let note = GeneralNoteManager.createNote(
                            title: title.isEmpty ? nil : title,
                            content: finalContent,
                            in: modelContext
                        )
                        onCreate(note)
                        isPresented = false
                    }
                }
            }
        }
        .frame(width: 500, height: 450)
    }
}

#Preview {
    @Previewable @State var isPresented = true
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: GeneralNote.self, configurations: config)
    
    return NewNoteSheet(isPresented: $isPresented, onCreate: { _ in })
        .modelContainer(container)
}
#endif
