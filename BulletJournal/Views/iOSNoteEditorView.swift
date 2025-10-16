#if !os(macOS)
import SwiftUI
import SwiftData

struct iOSNoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var note: GeneralNote
    
    @State private var isEditingTitle = false
    @State private var showingMarkdownPreview = false
    @State private var showingTagPicker = false
    
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    var body: some View {
        VStack(spacing: 0) {
            // Title Section
            if isEditingTitle {
                TextField("Title", text: Binding(
                    get: { note.title ?? "" },
                    set: { note.updateTitle($0.isEmpty ? nil : $0) }
                ))
                .font(.title2)
                .fontWeight(.bold)
                .textFieldStyle(.plain)
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
                        ForEach(parseMarkdown(note.content ?? ""), id: \.id) { line in
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 16) {
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
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            deleteNote()
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
    }
    
    private func deleteNote() {
        modelContext.delete(note)
        try? modelContext.save()
        dismiss()
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
            
            if line.hasPrefix("# ") {
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

#endif
