import SwiftUI
import SwiftData

struct GeneralNoteEditorView: View {
   @Environment(\.modelContext) private var modelContext
   @Bindable var note: GeneralNote
   
   let onBack: (() -> Void)?
   
   @State private var title: String
   @State private var content: String
   @State private var isEditingTitle = false
   
   init(note: GeneralNote, onBack: (() -> Void)? = nil) {
      self.note = note
      self.onBack = onBack
      _title = State(initialValue: note.title ?? "")
      _content = State(initialValue: note.content ?? "")
   }
   
   var body: some View {
      // FIXED: Wrap in VStack with own toolbar to scope buttons to pane
      VStack(spacing: 0) {
         // Custom toolbar within the pane
         HStack {
            // Back button (if provided)
            if onBack != nil {
               Button(action: { onBack?() }) {
                  HStack(spacing: 4) {
                     Image(systemName: "chevron.left")
                     Text("Notes")
                  }
               }
               .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
               // Pin button
               Button(action: togglePin) {
                  Image(systemName: (note.isPinned ?? false) ? "pin.fill" : "pin")
                     .foregroundColor((note.isPinned ?? false) ? .blue : .secondary)
               }
               .buttonStyle(.plain)
               .help("Pin note")
               
               // Favorite button
               Button(action: toggleFavorite) {
                  Image(systemName: (note.isFavorite ?? false) ? "star.fill" : "star")
                     .foregroundColor((note.isFavorite ?? false) ? .yellow : .secondary)
               }
               .buttonStyle(.plain)
               .help("Favorite note")
               
               Divider()
                  .frame(height: 20)
               
               // Delete button
               Button(action: deleteNote) {
                  Image(systemName: "trash")
                     .foregroundColor(.red)
               }
               .buttonStyle(.plain)
               .help("Delete note")
            }
         }
         .padding()
         .background(Color(NSColor.controlBackgroundColor))
         
         Divider()
         
         // Main editor content
         ScrollView {
            VStack(alignment: .leading, spacing: 16) {
               // Title section
               if isEditingTitle {
                  TextField("Note Title", text: $title)
                     .font(.title)
                     .textFieldStyle(.plain)
                     .onSubmit {
                        saveTitle()
                        isEditingTitle = false
                     }
               } else {
                  Text(title.isEmpty ? "Untitled Note" : title)
                     .font(.title)
                     .foregroundColor(title.isEmpty ? .secondary : .primary)
                     .onTapGesture {
                        isEditingTitle = true
                     }
               }
               
               // Metadata bar
               HStack(spacing: 16) {
                  Label("\(wordCount) words", systemImage: "doc.text")
                  Label("\(characterCount) characters", systemImage: "textformat.abc")
                  if let modifiedAt = note.modifiedAt {
                     Label("Modified \(modifiedAt, style: .relative)", systemImage: "clock")
                  }
               }
               .font(.caption)
               .foregroundColor(.secondary)
               
               Divider()
               
               // Content editor
               TextEditor(text: $content)
                  .font(.body)
                  .frame(minHeight: 400)
                  .onChange(of: content) { oldValue, newValue in
                     saveContent()
                  }
               
               // Markdown helper text for new notes
               if content.isEmpty {
                  VStack(alignment: .leading, spacing: 12) {
                     Text("Markdown Tips:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                     
                     Group {
                        Text("**Bold text** - Surround with **")
                        Text("*Italic text* - Surround with *")
                        Text("# Heading 1")
                        Text("## Heading 2")
                        Text("- Bullet list")
                        Text("1. Numbered list")
                        Text("[Link](url)")
                     }
                     .font(.caption)
                     .foregroundColor(.secondary)
                  }
                  .padding()
                  .background(Color.secondary.opacity(0.1))
                  .cornerRadius(8)
               }
            }
            .padding()
         }
      }
   }
   
   // MARK: - Computed Properties
   
   private var wordCount: Int {
      content.split(separator: " ").filter { !$0.isEmpty }.count
   }
   
   private var characterCount: Int {
      content.count
   }
   
   // MARK: - Actions
   
   private func saveTitle() {
      note.title = title.isEmpty ? nil : title
      note.modifiedAt = Date()
      try? modelContext.save()
   }
   
   private func saveContent() {
      note.content = content
      note.modifiedAt = Date()
      try? modelContext.save()
   }
   
   private func togglePin() {
      let current = note.isPinned ?? false
      note.isPinned = !current
      note.modifiedAt = Date()
      try? modelContext.save()
   }
   
   private func toggleFavorite() {
      let current = note.isFavorite ?? false
      note.isFavorite = !current
      note.modifiedAt = Date()
      try? modelContext.save()
   }
   
   private func deleteNote() {
      modelContext.delete(note)
      try? modelContext.save()
      onBack?()
   }
}

#Preview {
   let config = ModelConfiguration(isStoredInMemoryOnly: true)
   let container = try! ModelContainer(for: GeneralNote.self, configurations: config)
   let context = container.mainContext
   
   let note = GeneralNote()
   note.title = "Sample Note"
   note.content = "This is a sample note with some content."
   context.insert(note)
   
   return GeneralNoteEditorView(note: note, onBack: {
      print("Back tapped")
   })
   .modelContainer(container)
   .frame(width: 600, height: 800)
}
