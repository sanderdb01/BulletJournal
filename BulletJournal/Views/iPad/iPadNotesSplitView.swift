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
    
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
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
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(parseMarkdown(note.content ?? "")) { line in
                            renderLine(line)
                        }
                    }
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                TextEditor(text: Binding(
                    get: { note.content ?? "" },
                    set: { note.updateContent($0) }
                ))
                .padding(.horizontal, 8)
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
    
    // MARK: - Markdown Parsing
    
    private func parseMarkdown(_ text: String) -> [MarkdownLine] {
        let lines = text.components(separatedBy: .newlines)
        var result: [MarkdownLine] = []
        var inCodeBlock = false
        
        for line in lines {
            if line.hasPrefix("```") {
                inCodeBlock.toggle()
                continue
            }
            
            if inCodeBlock {
                result.append(MarkdownLine(type: .code, content: line))
                continue
            }
            
           if line.hasPrefix("> ") {
                           result.append(MarkdownLine(type: .quote, content: String(line.dropFirst(2))))
                       } else if line.hasPrefix("# ") {
                result.append(MarkdownLine(type: .header1, content: String(line.dropFirst(2))))
            } else if line.hasPrefix("## ") {
                result.append(MarkdownLine(type: .header2, content: String(line.dropFirst(3))))
            } else if line.hasPrefix("### ") {
                result.append(MarkdownLine(type: .header3, content: String(line.dropFirst(4))))
            } else if line.hasPrefix("- [ ]") {
                result.append(MarkdownLine(type: .checkbox(false), content: String(line.dropFirst(5).trimmingCharacters(in: .whitespaces))))
            } else if line.hasPrefix("- [x]") || line.hasPrefix("- [X]") {
                result.append(MarkdownLine(type: .checkbox(true), content: String(line.dropFirst(5).trimmingCharacters(in: .whitespaces))))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                result.append(MarkdownLine(type: .bullet, content: String(line.dropFirst(2))))
            } else if let match = line.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let number = Int(line[match].dropLast(2).trimmingCharacters(in: .whitespaces)) ?? 1
                result.append(MarkdownLine(type: .numbered(number), content: String(line[match.upperBound...])))
            } else {
                result.append(MarkdownLine(type: .normal, content: line))
            }
        }
        
        return result
    }
    
    @ViewBuilder
    private func renderLine(_ line: MarkdownLine) -> some View {
        switch line.type {
        case .header1:
            Text(parseInlineMarkdown(line.content))
                .font(.system(size: 28, weight: .bold))
            
        case .header2:
            Text(parseInlineMarkdown(line.content))
                .font(.system(size: 22, weight: .semibold))
            
        case .header3:
            Text(parseInlineMarkdown(line.content))
                .font(.system(size: 18, weight: .semibold))
              
           case .quote:
                       HStack(alignment: .top, spacing: 12) {
                           Rectangle()
                               .fill(Color.blue)
                               .frame(width: 4)
                           Text(parseInlineMarkdown(line.content))
                               .font(.body.italic())
                               .foregroundColor(.secondary)
                       }
                       .padding(.leading, 16)
                       .padding(.vertical, 4)
                       
            
        case .bullet:
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.body)
                Text(parseInlineMarkdown(line.content))
                    .font(.body)
            }
            .padding(.leading, 20)
            
        case .numbered(let number):
            HStack(alignment: .top, spacing: 8) {
                Text("\(number).")
                    .font(.body)
                Text(parseInlineMarkdown(line.content))
                    .font(.body)
            }
            .padding(.leading, 20)
            
        case .checkbox(let checked):
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .foregroundColor(checked ? .blue : .secondary)
                Text(parseInlineMarkdown(line.content))
                    .font(.body)
                    .strikethrough(checked)
                    .foregroundColor(checked ? .secondary : .primary)
            }
            .padding(.leading, 20)
            
        case .code:
            Text(line.content)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
            
        case .normal:
            if line.content.isEmpty {
                Text(" ")
                    .font(.body)
            } else {
                Text(parseInlineMarkdown(line.content))
                    .font(.body)
            }
        }
    }
    
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString(text)
       
       // Links: [text](url) - PROCESS FIRST so other formatting can apply to link text
               let linkPattern = #"\[(.+?)\]\((.+?)\)"#
               if let regex = try? NSRegularExpression(pattern: linkPattern) {
                   let matches = regex.matches(in: result.description, range: NSRange(result.description.startIndex..., in: result.description))
                   for match in matches.reversed() {
                       if let textRange = Range(match.range(at: 1), in: result.description),
                          let urlRange = Range(match.range(at: 2), in: result.description) {
                           let linkText = String(result.description[textRange])
                           let urlString = String(result.description[urlRange])
                           
                           // Find the full markdown link pattern
                           if let resultRange = result.range(of: "[\(linkText)](\(urlString))") {
                               var linkAttr = AttributedString(linkText)
                               
                               // Try to create URL
                               if let url = URL(string: urlString) {
                                   linkAttr.link = url
                               }
                               
                               // Style the link
                               linkAttr.foregroundColor = .blue
                               linkAttr.underlineStyle = .single
                               
                               result.replaceSubrange(resultRange, with: linkAttr)
                           }
                       }
                   }
               }
        
        // Bold: **text**
        let boldPattern = #"\*\*(.+?)\*\*"#
        if let regex = try? NSRegularExpression(pattern: boldPattern) {
            let matches = regex.matches(in: result.description, range: NSRange(result.description.startIndex..., in: result.description))
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: result.description) {
                    let content = String(result.description[range])
                    if let resultRange = result.range(of: "**\(content)**") {
                        result.replaceSubrange(resultRange, with: AttributedString(content))
                        if let boldRange = result.range(of: content) {
                            result[boldRange].font = .body.bold()
                        }
                    }
                }
            }
        }
        
        // Italic: *text*
        let italicPattern = #"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#
        if let regex = try? NSRegularExpression(pattern: italicPattern) {
            let matches = regex.matches(in: result.description, range: NSRange(result.description.startIndex..., in: result.description))
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: result.description) {
                    let content = String(result.description[range])
                    if let resultRange = result.range(of: "*\(content)*") {
                        result.replaceSubrange(resultRange, with: AttributedString(content))
                        if let italicRange = result.range(of: content) {
                            result[italicRange].font = .body.italic()
                        }
                    }
                }
            }
        }
        
        // Inline code: `code`
        let codePattern = #"`(.+?)`"#
        if let regex = try? NSRegularExpression(pattern: codePattern) {
            let matches = regex.matches(in: result.description, range: NSRange(result.description.startIndex..., in: result.description))
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: result.description) {
                    let content = String(result.description[range])
                    if let resultRange = result.range(of: "`\(content)`") {
                        result.replaceSubrange(resultRange, with: AttributedString(content))
                        if let codeRange = result.range(of: content) {
                            result[codeRange].font = .body.monospaced()
                            result[codeRange].backgroundColor = .secondary.opacity(0.1)
                        }
                    }
                }
            }
        }
        
        return result
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
