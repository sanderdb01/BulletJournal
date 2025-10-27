#if os(macOS)
import SwiftUI
import SwiftData

struct GeneralNoteEditorView: View {
   let note: GeneralNote
   var onBack: (() -> Void)?
   
   @Environment(\.modelContext) private var modelContext
   
   @FocusState private var isTitleFocused: Bool
   
   @State private var title: String
   @State private var content: String
   @State private var isEditingTitle = false
   @State private var viewMode: NoteViewMode = .edit
   
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
         ScrollView {
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
               
               Divider()
               
               // Content - Edit or Preview based on viewMode
               switch viewMode {
               case .edit:
                  editView
               case .preview:
                  previewView
               }
            }
            .padding()
         }
      }
   }
   
   // MARK: - Edit View
   
   private var editView: some View {
      VStack(alignment: .leading, spacing: 12) {
         TextEditor(text: $content)
            .font(.body)
            .frame(minHeight: 400)
            .onChange(of: content) { oldValue, newValue in
               saveContent()
            }
         
         // Markdown helper text for new/empty notes
         if content.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
               Text("Markdown Tips:")
                  .font(.headline)
                  .foregroundColor(.secondary)
               
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
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
         }
      }
   }
   
   // MARK: - Preview View
   
   private var previewView: some View {
      ScrollView {
         VStack(alignment: .leading, spacing: 12) {
            if content.isEmpty {
               Text("No content to preview")
                  .font(.body)
                  .foregroundColor(.secondary)
                  .italic()
                  .frame(maxWidth: .infinity, alignment: .center)
                  .padding(.top, 100)
            } else {
               // Parse and render markdown line by line for better formatting
               ForEach(parseMarkdownLines(content), id: \.id) { line in
                  renderMarkdownLine(line)
               }
            }
         }
         .padding()
         .frame(maxWidth: .infinity, alignment: .leading)
      }
   }
   
   // MARK: - Markdown Parsing
   
   struct MarkdownLine: Identifiable {
      let id = UUID()
      let content: String
      let type: LineType
      
      enum LineType {
         case h1, h2, h3
         case bullet
         case numbered(Int)
         case checkbox(Bool)
         case code
         case normal
      }
   }
   
   private func parseMarkdownLines(_ text: String) -> [MarkdownLine] {
      let lines = text.components(separatedBy: .newlines)
      var result: [MarkdownLine] = []
      
      for line in lines {
         let trimmed = line.trimmingCharacters(in: .whitespaces)
         
         if trimmed.isEmpty {
            result.append(MarkdownLine(content: "", type: .normal))
         } else if trimmed.hasPrefix("# ") {
            result.append(MarkdownLine(content: String(trimmed.dropFirst(2)), type: .h1))
         } else if trimmed.hasPrefix("## ") {
            result.append(MarkdownLine(content: String(trimmed.dropFirst(3)), type: .h2))
         } else if trimmed.hasPrefix("### ") {
            result.append(MarkdownLine(content: String(trimmed.dropFirst(4)), type: .h3))
         } else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
            result.append(MarkdownLine(content: String(trimmed.dropFirst(6)), type: .checkbox(true)))
         } else if trimmed.hasPrefix("- [ ] ") {
            result.append(MarkdownLine(content: String(trimmed.dropFirst(6)), type: .checkbox(false)))
         } else if trimmed.hasPrefix("- ") {
            result.append(MarkdownLine(content: String(trimmed.dropFirst(2)), type: .bullet))
         } else if let match = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
            let num = Int(trimmed[match].dropLast(2)) ?? 1
            result.append(MarkdownLine(content: String(trimmed[match.upperBound...]), type: .numbered(num)))
         } else if trimmed.hasPrefix("```") {
            result.append(MarkdownLine(content: trimmed, type: .code))
         } else {
            result.append(MarkdownLine(content: line, type: .normal))
         }
      }
      
      return result
   }
   
   @ViewBuilder
   private func renderMarkdownLine(_ line: MarkdownLine) -> some View {
      switch line.type {
      case .h1:
         Text(parseInlineMarkdown(line.content))
            .font(.system(size: 28, weight: .bold))
            .padding(.top, 8)
            .padding(.bottom, 4)
         
      case .h2:
         Text(parseInlineMarkdown(line.content))
            .font(.system(size: 22, weight: .semibold))
            .padding(.top, 6)
            .padding(.bottom, 3)
         
      case .h3:
         Text(parseInlineMarkdown(line.content))
            .font(.system(size: 18, weight: .semibold))
            .padding(.top, 4)
            .padding(.bottom, 2)
         
      case .bullet:
         HStack(alignment: .top, spacing: 8) {
            Text("•")
               .font(.body)
            Text(parseInlineMarkdown(line.content))
               .font(.body)
         }
         .padding(.leading, 20)
         
      case .numbered(let num):
         HStack(alignment: .top, spacing: 8) {
            Text("\(num).")
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
         let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
         for match in matches.reversed() {
            if let range = Range(match.range(at: 1), in: text) {
               let content = String(text[range])
               if let attrRange = Range(match.range, in: text) {
                  if let resultRange = Range(attrRange, in: result) {
                     result.replaceSubrange(resultRange, with: AttributedString(content))
                     if let boldRange = result.range(of: content) {
                        result[boldRange].font = .body.bold()
                     }
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
               if let attrRange = Range(match.range, in: result.description) {
                  if let resultRange = result.range(of: "*\(content)*") {
                     result.replaceSubrange(resultRange, with: AttributedString(content))
                     if let italicRange = result.range(of: content) {
                        result[italicRange].font = .body.italic()
                     }
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
