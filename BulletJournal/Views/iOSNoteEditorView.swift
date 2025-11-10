//
// iOSNoteEditorView.swift
// HarborDot
//
// iOS note editor with markdown support and smart formatting toolbar
// Requires: MarkdownListHelper.swift (shared helper for list formatting)
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
                MarkdownFormattingToolbar { format in
                    applyMarkdownFormat(format)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
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
        }
        .sheet(isPresented: $showingTagPicker) {
            NavigationStack {
                TagPickerSheet(note: note)
            }
        }
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
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
                    ForEach(parseMarkdown(note.content ?? "")) { line in
                        renderLine(line)
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
            let (newText, newCursor) = MarkdownListHelper.addListToCurrentLine(
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
    
    // MARK: - Actions
    
    private func deleteNote() {
        modelContext.delete(note)
        try? modelContext.save()
        dismiss()
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
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        // Update text if different
        if textView.text != text {
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
                if let (newText, newCursor) = MarkdownListHelper.handleReturnKey(
                    text: textView.text,
                    cursorPosition: range.location
                ) {
                    // Update the text and cursor position
                    textView.text = newText
                    textView.selectedRange = NSRange(location: newCursor, length: 0)
                    
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

// MARK: - Markdown Parsing Extension

extension iOSNoteEditorView {
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
                result.append(MarkdownLine(type: .numbered(number), content: String(line[line.index(match.upperBound, offsetBy: 0)...])))
            } else {
                result.append(MarkdownLine(type: .normal, content: line))
            }
        }
        
        return result
    }
    
    private func renderLine(_ line: MarkdownLine) -> some View {
        Group {
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
    }
    
    // MARK: - Inline Markdown Parser
    
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        do {
            let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            return try AttributedString(markdown: text, options: options)
        } catch {
            return AttributedString(text)
        }
    }
}

// MARK: - MarkdownFormat Extension

extension MarkdownFormat {
    var markdownComponents: (prefix: String, suffix: String, placeholder: String) {
        switch self {
        case .bold:
            return ("**", "**", "text")
        case .italic:
            return ("*", "*", "text")
        case .strikethrough:
            return ("~~", "~~", "text")
        case .code:
            return ("`", "`", "code")
        case .header1:
            return ("# ", "", "Heading")
        case .header2:
            return ("## ", "", "Heading")
        case .header3:
            return ("### ", "", "Heading")
        case .bulletList:
            return ("- ", "", "List item")
        case .numberedList:
            return ("1. ", "", "List item")
        case .checklistItem:
            return ("- [ ] ", "", "Task")
        case .quote:
            return ("> ", "", "Quote")
        }
    }
}

#endif
