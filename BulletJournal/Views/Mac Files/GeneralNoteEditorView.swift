#if os(macOS)
import SwiftUI
import SwiftData
import AppKit

struct GeneralNoteEditorView: View {
   let note: GeneralNote
   var onBack: (() -> Void)?
   
   @Environment(\.modelContext) private var modelContext
   
   @FocusState private var isTitleFocused: Bool
   @FocusState private var isContentFocused: Bool
   
   @State private var title: String
   @State private var content: String
   @State private var isEditingTitle = false
   @State private var viewMode: NoteViewMode = .edit
   @State private var showMarkdownTips = true
   
   // For smart text selection
   @State private var textSelection: NSRange = NSRange(location: 0, length: 0)
   
   enum NoteViewMode: String, CaseIterable {
      case edit = "Edit"
      case preview = "Preview"
   }
   
   init(note: GeneralNote, onBack: (() -> Void)? = nil) {
      self.note = note
      self.onBack = onBack
      _title = State(initialValue: note.title ?? "")
      _content = State(initialValue: note.content ?? "")
   }
   
   var body: some View {
      VStack(spacing: 0) {
         // Toolbar
         HStack {
            // Back button (left side)
            if onBack != nil {
               Button(action: { onBack?() }) {
                  HStack(spacing: 4) {
                     Image(systemName: "chevron.left")
                     Text("Pages")
                  }
               }
               .buttonStyle(.plain)
               .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Edit/Preview toggle (center)
            Picker("View Mode", selection: $viewMode) {
               ForEach(NoteViewMode.allCases, id: \.self) { mode in
                  Text(mode.rawValue).tag(mode)
               }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            
            Spacer()
            
            // Action buttons (right side)
            HStack(spacing: 12) {
               Button(action: togglePin) {
                  Image(systemName: (note.isPinned ?? false) ? "pin.fill" : "pin")
               }
               .help((note.isPinned ?? false) ? "Unpin Note" : "Pin Note")
               
               Button(action: toggleFavorite) {
                  Image(systemName: (note.isFavorite ?? false) ? "star.fill" : "star")
               }
               .help((note.isFavorite ?? false) ? "Remove from Favorites" : "Add to Favorites")
               
               Button(role: .destructive, action: deleteNote) {
                  Image(systemName: "trash")
               }
               .help("Delete Note")
            }
            .buttonStyle(.plain)
         }
         .padding()
         
         Divider()
         
         // Content area
         //         ScrollView {
         VStack(alignment: .leading, spacing: 16) {
            // Title section
            if isEditingTitle {
               TextField("Note Title", text: $title, onCommit: {
                  isEditingTitle = false
                  saveTitle()
               })
               .textFieldStyle(.plain)
               .focused($isTitleFocused)
               .clearButton(text: $title, focus: $isTitleFocused)
               .font(.title)
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
            
            //               Divider()
            
            // Content - Edit or Preview based on viewMode
            switch viewMode {
               case .edit:
                  editView
               case .preview:
                  Divider()
                  previewView
            }
         }
         .padding()
      }
   }
   //   }
   
   // MARK: - Edit View
   
   private var editView: some View {
      //      ScrollView {
      VStack(alignment: .leading, spacing: 1) {
         MarkdownFormattingToolbar { format in
            applyMarkdownFormat(format)
         }
         VStack(alignment: .leading, spacing: 12) {
            SmartTextEditor(
               text: Binding(
                  get: { note.content ?? "" },
                  set: { note.updateContent($0) }
               ),
               selectedRange: $textSelection
            )
            .font(.body)
            .frame(maxHeight: .infinity)
            .focused($isContentFocused)
            .onAppear {
               isContentFocused = true
            }
            
            // Markdown helper text for new/empty notes
//                        .overlay(alignment: .bottomLeading){
            //               if (note.content ?? "").isEmpty {
            VStack(alignment: .leading, spacing: 12) {
               HStack{
                  Text("Markdown Tips:")
                     .font(.headline)
                     .foregroundColor(.secondary)
                  Spacer()
                  Button {
                     print("toggle tips")
                     showMarkdownTips.toggle()
                  } label: {
                     Image(systemName: "arrow.up.arrow.down.circle.fill")
                  }
               }
               .frame(maxWidth: 250)
               if showMarkdownTips {
               VStack(alignment: .leading, spacing: 8) {
                  markdownTip(syntax: "**Bold text**", description: "Surround with **")
                  markdownTip(syntax: "*Italic text*", description: "Surround with *")
                  markdownTip(syntax: "# Heading 1", description: "Start line with #")
                  markdownTip(syntax: "## Heading 2", description: "Start line with ##")
                  markdownTip(syntax: "- Bullet list", description: "Start line with -")
                  markdownTip(syntax: "1. Numbered list", description: "Start line with number")
                  markdownTip(syntax: "[Link](url)", description: "Link format")
                  markdownTip(syntax: "`code`", description: "Inline code")
                  markdownTip(syntax: "```\ncode block\n```", description: "Code block")
               }
               .font(.caption)
               .foregroundColor(.secondary)
            }
               }
               .padding()
               .background(Color.secondary.opacity(0.1))
               .cornerRadius(8)
//            }
         }
      }
   }
   
   // MARK: - Preview View
   
   private var previewView: some View {
      ScrollView {
         VStack(alignment: .leading, spacing: 12) {
            if (note.content ?? "").isEmpty {
               Text("No content to preview")
                  .font(.body)
                  .foregroundColor(.secondary)
                  .italic()
                  .frame(maxWidth: .infinity, alignment: .center)
                  .padding(.top, 100)
            } else {
               ForEach(MarkdownHelper.parseMarkdown(note.content ?? "")) { line in
                  MarkdownHelper.renderLine(line)
               }
            }
         }
         .textSelection(.enabled)
         .padding()
         .frame(maxWidth: .infinity, alignment: .leading)
         .onAppear {
            isContentFocused = false
         }
      }
   }
   
   // MARK: - Smart Markdown Formatting Logic
   
   private func applyMarkdownFormat(_ format: MarkdownFormat) {
      let content = note.content ?? ""
      let selection = textSelection
      
      // Check if this is a list format
      if let listType = ListType.from(format) {
         // Use smart list formatting
         let (newText, newCursor) = MarkdownHelper.addListToCurrentLine(
            text: content,
            cursorPosition: selection.location,
            listType: listType
         )
         note.updateContent(newText)
         textSelection = NSRange(location: newCursor, length: 0)
         isContentFocused = true
         return
      }
      
      // Non-list formatting - use existing logic
      let selectedText = (content as NSString).substring(with: selection)
      let (prefix, suffix, placeholder) = format.markdownComponents
      
      if selectedText.isEmpty {
         // No selection - insert with placeholder and auto-select it
         let insertion = prefix + placeholder + suffix
         let newContent = (content as NSString).replacingCharacters(in: selection, with: insertion)
         note.updateContent(newContent)
         
         // Calculate where to select the placeholder
         let placeholderStart = selection.location + prefix.count
         let placeholderLength = placeholder.count
         textSelection = NSRange(location: placeholderStart, length: placeholderLength)
         
      } else {
         // Has selection - wrap it with markdown
         let wrappedText = prefix + selectedText + suffix
         let newContent = (content as NSString).replacingCharacters(in: selection, with: wrappedText)
         note.updateContent(newContent)
         
         // Move cursor to end of wrapped text
         let newPosition = selection.location + wrappedText.count
         textSelection = NSRange(location: newPosition, length: 0)
      }
      
      isContentFocused = true
   }
   
   // MARK: - Helper Views
   
   private func markdownTip(syntax: String, description: String) -> some View {
      HStack(spacing: 8) {
         Text(syntax)
            .fontWeight(.medium)
            .foregroundColor(.primary)
         Text("—")
            .foregroundColor(.secondary)
         Text(description)
            .foregroundColor(.secondary)
      }
   }
   
   // MARK: - Computed Properties
   
   private var wordCount: Int {
      let words = content.split(separator: " ").filter { !$0.isEmpty }
      return words.count
   }
   
   private var characterCount: Int {
      return content.count
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
      let currentValue = note.isPinned ?? false
      note.isPinned = !currentValue
      note.modifiedAt = Date()
      try? modelContext.save()
   }
   
   private func toggleFavorite() {
      let currentValue = note.isFavorite ?? false
      note.isFavorite = !currentValue
      note.modifiedAt = Date()
      try? modelContext.save()
   }
   
   private func deleteNote() {
      //      modelContext.delete(note)
      //      try? modelContext.save()
      let success = GeneralNoteManager.deleteNote(note, from: modelContext)
      if success {
         print("Deletion of Notebook page successful in iPadSplitView")
      } else {
         // Handle failure
         print("Deletion failed")
      }
      onBack?()
   }
}

// MARK: - Smart Text Editor with Selection Tracking

struct SmartTextEditor: NSViewRepresentable {
   @Binding var text: String
   @Binding var selectedRange: NSRange
   
   func makeNSView(context: Context) -> NSScrollView {
      let scrollView = NSTextView.scrollableTextView()
      guard let textView = scrollView.documentView as? NSTextView else {
         return scrollView
      }
      
      textView.delegate = context.coordinator
      textView.backgroundColor = .clear
      textView.font = NSFont.preferredFont(forTextStyle: .body)
      textView.isRichText = false
      textView.isAutomaticQuoteSubstitutionEnabled = false
      textView.isAutomaticDashSubstitutionEnabled = false
      textView.isAutomaticTextReplacementEnabled = false
      textView.isAutomaticSpellingCorrectionEnabled = true
      textView.textContainerInset = NSSize(width: 8, height: 8)
      
      return scrollView
   }
   
   func updateNSView(_ scrollView: NSScrollView, context: Context) {
      guard let textView = scrollView.documentView as? NSTextView else { return }
      
      // Update text if different
      if textView.string != text {
         let oldSelectedRange = textView.selectedRange()
         textView.string = text
         
         // Restore selection if valid
         if oldSelectedRange.location + oldSelectedRange.length <= text.count {
            textView.setSelectedRange(oldSelectedRange)
         }
      }
      
      // Update selection if different and valid
      if textView.selectedRange() != selectedRange &&
            selectedRange.location + selectedRange.length <= text.count {
         textView.setSelectedRange(selectedRange)
      }
   }
   
   func makeCoordinator() -> Coordinator {
      Coordinator(self)
   }
   
   class Coordinator: NSObject, NSTextViewDelegate {
      var parent: SmartTextEditor
      
      init(_ parent: SmartTextEditor) {
         self.parent = parent
      }
      
      // NSTextViewDelegate method for text changes
      func textDidChange(_ notification: Notification) {
         guard let textView = notification.object as? NSTextView else { return }
         parent.text = textView.string
         parent.selectedRange = textView.selectedRange()
      }
      
      // NSTextViewDelegate method for selection changes
      func textViewDidChangeSelection(_ notification: Notification) {
         guard let textView = notification.object as? NSTextView else { return }
         parent.selectedRange = textView.selectedRange()
      }
      
      // Intercept text changes to handle Return key for smart lists
      func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
         // Check if user pressed Return
         if replacementString == "\n" {
            // Try to handle smart list continuation
            if let (newText, newCursor) = MarkdownHelper.handleReturnKey(
               text: textView.string,
               cursorPosition: affectedCharRange.location
            ) {
               // Update the text and cursor position
               textView.string = newText
               textView.setSelectedRange(NSRange(location: newCursor, length: 0))
               
               // Scroll to cursor
               textView.scrollRangeToVisible(NSRange(location: newCursor, length: 0))
               
               // Notify parent of changes
               parent.text = newText
               parent.selectedRange = NSRange(location: newCursor, length: 0)
               
               // Return false to prevent default newline behavior
               return false
            }
         }
         
         // Allow default behavior for non-list lines or other keys
         return true
      }
   }
}

#Preview {
   let config = ModelConfiguration(isStoredInMemoryOnly: true)
   let container = try! ModelContainer(for: GeneralNote.self, configurations: config)
   let context = container.mainContext
   
   let note = GeneralNote()
   note.title = "Sample Note"
   note.content = """
   # Welcome to Markdown
   
   This is a **bold** statement and this is *italic*.
   
   ## Lists
   
   - Item 1
   - Item 2
   - Item 3
   
   ## Code
   
   Here's some `inline code` and a code block:
   
   ```
   func hello() {
       print("Hello, World!")
   }
   ```
   
   ## Links
   
   Check out [Apple](https://apple.com) for more info.
   """
   context.insert(note)
   
   return GeneralNoteEditorView(note: note, onBack: {
      print("Back tapped")
   })
   .modelContainer(container)
   .frame(width: 700, height: 800)
}
#endif
