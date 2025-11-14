#if !os(macOS)
import SwiftUI
import SwiftData

struct iPadNotesSplitView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GeneralNote.modifiedAt, order: .reverse) private var allNotes: [GeneralNote]
    
    @State private var selectedNote: GeneralNote?
    @State private var searchText = ""
    @State private var showingNewNoteSheet = false
    @State private var isFullScreen = false
    var body: some View {
        Group {
            if isFullScreen, let selectedNote = selectedNote {
                // Full-screen editor mode
                NavigationStack {
                    iPadNoteEditorDetailView(
                        note: selectedNote,
                        isFullScreen: $isFullScreen
                    )
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                }
            } else {
                // Normal split view
                splitView
            }
        }
        .sheet(isPresented: $showingNewNoteSheet) {
            iOSNewNoteSheet(modelContext: modelContext, onCreate: { newNote in
                selectedNote = newNote
            })
        }
    }
    
    private var splitView: some View {
        NavigationSplitView {
            // Sidebar - Notes List
            notesList
                .navigationTitle("Notebook")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingNewNoteSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search notebook")
           // Hide the native sidebar toggle button
                .toolbar(removing: .sidebarToggle)
        } detail: {
            // Detail - Note Editor or Empty State
            if let selectedNote = selectedNote {
                iPadNoteEditorDetailView(
                    note: selectedNote,
                    isFullScreen: $isFullScreen
                )
            } else {
                emptyDetailView
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    // MARK: - Filtered Notes
    
    private var filteredNotes: [GeneralNote] {
        if searchText.isEmpty {
            return allNotes
        }
        return allNotes.filter { note in
            let title = note.title ?? ""
            let content = note.content ?? ""
            return title.localizedCaseInsensitiveContains(searchText) ||
                   content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var pinnedNotes: [GeneralNote] {
        filteredNotes.filter { ($0.isPinned ?? false) == true }
    }
    
    private var unpinnedNotes: [GeneralNote] {
        filteredNotes.filter { ($0.isPinned ?? false) == false }
    }
    
    // MARK: - Notes List
    
    private var notesList: some View {
        List(selection: $selectedNote) {
            if !pinnedNotes.isEmpty {
                Section("Pinned") {
                    ForEach(pinnedNotes) { note in
                        noteRow(note)
                    }
                }
            }
            
            if !unpinnedNotes.isEmpty {
                Section(pinnedNotes.isEmpty ? "All Pages" : "Pages") {
                    ForEach(unpinnedNotes) { note in
                        noteRow(note)
                    }
                }
            }
            
            if filteredNotes.isEmpty {
                emptyStateRow
            }
        }
    }
    
    private func noteRow(_ note: GeneralNote) -> some View {
        Button {
            selectedNote = note
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(note.displayTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if (note.isFavorite ?? false) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }
                
                Text(note.previewText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack {
                    if let modifiedAt = note.modifiedAt {
                        Text(modifiedAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                    
                    if let primaryTag = note.primaryTag {
                        TagBadge(tag: primaryTag, size: .small)
                    }
                    
                    let customTags = note.customTags ?? []
                    if !customTags.isEmpty {
                        Text("+\(customTags.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteNote(note)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var emptyStateRow: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("No Pages")
                .font(.headline)
            
            Text("Tap + to create your first note")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Empty Detail View
    
    private var emptyDetailView: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Select a Note")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose a note from the sidebar or create a new one")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func deleteNote(_ note: GeneralNote) {
        if selectedNote?.id == note.id {
            selectedNote = nil
        }
        
        withAnimation {
            modelContext.delete(note)
            try? modelContext.save()
        }
    }
}

// MARK: - iPad Note Editor Detail View

struct iPadNoteEditorDetailView: View {
    @Environment(\.modelContext) private var modelContext
    
   @FocusState private var isTitleFocused: Bool
   
    @Bindable var note: GeneralNote
    @Binding var isFullScreen: Bool
    
    @State private var isEditingTitle = false
    @State private var showingMarkdownPreview = false
    @State private var showingTagPicker = false
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
                .clearButton(text: titleBinding, focus: $isTitleFocused)
                .padding()
                .background(Color(.systemGray6))
                .onSubmit {
                    isEditingTitle = false
                }
            } else {
                Button {
                    isEditingTitle = true
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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 16) {
                    // Full-screen toggle button
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isFullScreen.toggle()
                        }
                    } label: {
                        Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .foregroundStyle(.blue)
                    }
                    
                    Button {
                        let current = note.isPinned ?? false
                        note.isPinned = !current
                        note.modifiedAt = Date()
                        try? modelContext.save()
                    } label: {
                        Image(systemName: (note.isPinned ?? false) ? "pin.fill" : "pin")
                            .foregroundStyle((note.isPinned ?? false) ? .blue : .secondary)
                    }
                    
                    Button {
                        let current = note.isFavorite ?? false
                        note.isFavorite = !current
                        note.modifiedAt = Date()
                        try? modelContext.save()
                    } label: {
                        Image(systemName: (note.isFavorite ?? false) ? "star.fill" : "star")
                            .foregroundStyle((note.isFavorite ?? false) ? .yellow : .secondary)
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showingMarkdownPreview.toggle()
                    } label: {
                        Image(systemName: showingMarkdownPreview ? "pencil" : "eye")
                    }
                    
                    Menu {
                        Button {
                            showingTagPicker = true
                        } label: {
                            Label("Manage Tags", systemImage: "tag")
                        }
                        
                        Section {
                            if let modifiedAt = note.modifiedAt {
                                Label(
                                    "Modified: \(modifiedAt.formatted(date: .abbreviated, time: .shortened))",
                                    systemImage: "clock"
                                )
                            }
                            Label("Words: \(note.wordCount)", systemImage: "textformat")
                            Label("Characters: \(note.characterCount)", systemImage: "textformat.abc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingTagPicker) {
            NavigationStack {
                TagPickerSheet(note: note)
            }
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
           isContentFocused = true
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
}

// MARK: - Tag Picker Sheet

struct TagPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var note: GeneralNote
    
    var body: some View {
        VStack {
            TagPicker(
                selectedPrimaryTag: Binding(
                    get: { note.primaryTag },
                    set: {
                        note.primaryTag = $0
                        note.modifiedAt = Date()
                        try? modelContext.save()
                    }
                ),
                selectedCustomTags: Binding(
                    get: { note.customTags ?? [] },
                    set: {
                        note.customTags = $0
                        note.modifiedAt = Date()
                        try? modelContext.save()
                    }
                )
            )
            .padding()
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#endif
