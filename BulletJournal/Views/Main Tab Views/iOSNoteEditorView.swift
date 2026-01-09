//
// iOSNoteEditorView.swift
// HarborDot
//
// iOS note editor with markdown support and smart formatting toolbar
// Requires: MarkdownHelper.swift (shared helper for list formatting)
//

#if os(iOS)
import SwiftUI
import SwiftData
import UIKit

struct iOSNoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var note: GeneralNote
    
    @State private var isEditingTitle = false
    @State private var showingMarkdownPreview = false
    @State private var showingTagPicker = false
    @State private var showingDeleteAlert = false
   @State private var showingShareSheet = false
    
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    // For smart text selection
    @State private var textSelection: NSRange = NSRange(location: 0, length: 0)
    
    var body: some View {
        VStack(spacing: 0) {
            // Title Section
            if isEditingTitle {
                let titleBinding = Binding(
                    get: { note.title ?? "" },
                    set: { note.updateTitle($0.isEmpty ? nil : $0) }
                )
                TextField("Title", text: titleBinding)
                    .font(.title2)
                    .fontWeight(.bold)
                    .textFieldStyle(.plain)
                    .focused($isTitleFocused)
                    .padding()
                    .background(Color(.systemGray6))
                    .onSubmit {
                        isEditingTitle = false
                    }
            } else {
                Button {
                    isEditingTitle = true
                    isTitleFocused = true
                } label: {
                    HStack {
                        Text(note.displayTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
            }
            
            // Content Editor/Preview
            if showingMarkdownPreview {
                previewView
            } else {
                editorView
            }
            
           // Formatting Toolbar (only in edit mode)
           if !showingMarkdownPreview {
               MarkdownFormattingToolbar(
                   onFormat: { format in
                       applyMarkdownFormat(format)
                   },
                   onDismiss: {
                       isContentFocused = false  // Dismiss keyboard
                   },
                   isKeyboardVisible: isContentFocused  // Pass keyboard state
               )
           }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                   if isContentFocused || isTitleFocused{
                      isContentFocused = false
                      isEditingTitle = false
                      isTitleFocused = false
                   } else {
                      dismiss()
                   }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Preview Toggle
                    Button {
                        showingMarkdownPreview.toggle()
                        if !showingMarkdownPreview {
                            isContentFocused = true
                        }
                    } label: {
                        Image(systemName: showingMarkdownPreview ? "pencil" : "eye")
                    }
                    
                    // More Menu
                    Menu {
                        Button {
                            note.togglePin()
                        } label: {
                            Label(note.isPinned ?? false ? "Unpin" : "Pin",
                                  systemImage: note.isPinned ?? false ? "pin.slash" : "pin")
                        }
                        
                        Button {
                            note.toggleFavorite()
                        } label: {
                            Label(note.isFavorite ?? false ? "Remove from Favorites" : "Add to Favorites",
                                  systemImage: note.isFavorite ?? false ? "star.slash" : "star")
                        }
                        
                        Button {
                            showingTagPicker = true
                        } label: {
                            Label("Manage Tags", systemImage: "tag")
                        }
                       
                       Button {
                           showingShareSheet = true
                       } label: {
                           Label("Share", systemImage: "square.and.arrow.up")
                       }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Note", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
           ToolbarItemGroup(placement: .keyboard) {
                   Spacer()
              Button {
                 isContentFocused = false  // or isContentFocused
                 isEditingTitle = false
                 isTitleFocused = false
                  } label: {
                      HStack {
                          Image(systemName: "keyboard.chevron.compact.down")
                          Text("Done")
                      }
                  }
                   .fontWeight(.semibold)
               }
        }
        .sheet(isPresented: $showingTagPicker) {
            NavigationStack {
                TagPickerSheet(note: note)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
                    ShareSheet(items: createShareItems())
                }
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
               if note.isDeleted {
                  print("Note is already deleted")
                  return
               } //note has already been deleted
                deleteNote()
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }
    
    // MARK: - Editor View (with smart text selection tracking)
    private var editorView: some View {
        SmartTextEditor(
            text: Binding(
                get: { note.content ?? "" },
                set: { note.updateContent($0) }
            ),
            selectedRange: $textSelection
        )
        .font(.body)
        .focused($isContentFocused)
        .padding(.horizontal, 8)
        .onAppear {
           if note.content == nil || note.content!.isEmpty {
              isContentFocused = true
           } else {
              isContentFocused = false
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
    
    // MARK: - Delete Actions
    
    private func deleteNote() {
//        modelContext.delete(note)
//        try? modelContext.save()
//        dismiss()
       
       let success = GeneralNoteManager.deleteNote(note, from: modelContext)
          if success {
             print("Deletion of Notebook page successful in iOSNoteEditorView")
          } else {
             // Handle failure
             print("Deletion failed")
          }
       dismiss()
    }
   
   // MARK: - Share Helpers
       
       private func createShareItems() -> [Any] {
           let noteTitle = note.title ?? "Untitled Note"
           let noteContent = note.content ?? ""
           
           // Simple plain text sharing - just combine title and content
           let fullText = "\(noteTitle)\n\n\(noteContent)"
           
           return [fullText]
       }
}

// MARK: - Smart Text Editor with Selection Tracking

struct SmartTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    
   func makeUIView(context: Context) -> UITextView {
      let textView = UITextView()
      textView.delegate = context.coordinator
      textView.backgroundColor = .clear
      textView.font = UIFont.preferredFont(forTextStyle: .body)
      
      // Add line spacing for better readability
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineSpacing = 6.0  // Adjust this value to increase/decrease spacing
      textView.typingAttributes[.paragraphStyle] = paragraphStyle
      
      return textView
   }
   
   func updateUIView(_ textView: UITextView, context: Context) {
//       print("🔍 updateNSView called - textView.string: '\(textView.text ?? "")', binding text: '\(text)'")
        // Update text if different
        if textView.text != text {
//           print("⚠️ Text different! Replacing...")
            let oldSelectedRange = textView.selectedRange
            textView.text = text
            
            // Restore selection if valid
            if oldSelectedRange.location + oldSelectedRange.length <= text.count {
                textView.selectedRange = oldSelectedRange
            }
        }
        
        // Update selection if different and valid
        if textView.selectedRange != selectedRange &&
           selectedRange.location + selectedRange.length <= text.count {
            textView.selectedRange = selectedRange
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SmartTextEditor
        
        init(_ parent: SmartTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.selectedRange = textView.selectedRange
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }
        
        // Intercept text changes to handle Return key for smart lists
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Check if user pressed Return
            if text == "\n" {
                // Try to handle smart list continuation
                if let (newText, newCursor) = MarkdownHelper.handleReturnKey(
                    text: textView.text,
                    cursorPosition: range.location
                ) {
                   // Update the text and cursor position
                   textView.text = newText
                   textView.selectedRange = NSRange(location: newCursor, length: 0)
                   
                   // Re-apply paragraph style with line spacing after smart list update
                   let paragraphStyle = NSMutableParagraphStyle()
                   paragraphStyle.lineSpacing = 6.0
                   textView.typingAttributes[.paragraphStyle] = paragraphStyle
                   
                   // Scroll to cursor instead of auto-scrolling to bottom
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

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

#endif
