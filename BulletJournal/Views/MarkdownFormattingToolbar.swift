//
// MarkdownFormattingToolbar.swift
// HarborDot
//
// Formatting toolbar for markdown editing - inserts markdown syntax
//

import SwiftUI

enum MarkdownFormat: String, CaseIterable {
    case bold = "Bold"
    case italic = "Italic"
    case strikethrough = "Strikethrough"
    
    // Headers
    case header1 = "Header 1"
    case header2 = "Header 2"
    case header3 = "Header 3"
    
    // Lists
    case bulletList = "Bullet List"
    case numberedList = "Numbered List"
    case checklistItem = "Checklist"
    
    // Other
    case quote = "Quote"
    case code = "Code"
    
    var iconName: String {
        switch self {
        case .bold: return "bold"
        case .italic: return "italic"
        case .strikethrough: return "strikethrough"
        case .header1: return "textformat.size.larger"
        case .header2: return "textformat.size"
        case .header3: return "textformat.size.smaller"
        case .bulletList: return "list.bullet"
        case .numberedList: return "list.number"
        case .checklistItem: return "checklist"
        case .quote: return "quote.opening"
        case .code: return "chevron.left.forwardslash.chevron.right"
        }
    }
    
    var markdownSyntax: String {
        switch self {
        case .bold: return "**text**"
        case .italic: return "*text*"
        case .strikethrough: return "~~text~~"
        case .header1: return "# "
        case .header2: return "## "
        case .header3: return "### "
        case .bulletList: return "- "
        case .numberedList: return "1. "
        case .checklistItem: return "- [ ] "
        case .quote: return "> "
        case .code: return "`code`"
        }
    }
}

struct MarkdownFormattingToolbar: View {
    var onFormat: (MarkdownFormat) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Text styling
                formatButton(.bold)
                formatButton(.italic)
                formatButton(.strikethrough)
                
                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 4)
                
                // Headers menu
                Menu {
                    Button {
                        onFormat(.header1)
                    } label: {
                        Label("Large Header", systemImage: "textformat.size.larger")
                    }
                    
                    Button {
                        onFormat(.header2)
                    } label: {
                        Label("Medium Header", systemImage: "textformat.size")
                    }
                    
                    Button {
                        onFormat(.header3)
                    } label: {
                        Label("Small Header", systemImage: "textformat.size.smaller")
                    }
                } label: {
                    formatButtonLabel(.header2, isActive: false)
                }
                
                // Lists menu
                Menu {
                    Button {
                        onFormat(.bulletList)
                    } label: {
                        Label("Bullet List", systemImage: "list.bullet")
                    }
                    
                    Button {
                        onFormat(.numberedList)
                    } label: {
                        Label("Numbered List", systemImage: "list.number")
                    }
                    
                    Button {
                        onFormat(.checklistItem)
                    } label: {
                        Label("Checklist", systemImage: "checklist")
                    }
                } label: {
                    formatButtonLabel(.bulletList, isActive: false)
                }
                
                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 4)
                
                // Quote & Code
                formatButton(.quote)
                formatButton(.code)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .top
        )
    }
    
    // MARK: - Helper Views
    
    private func formatButton(_ format: MarkdownFormat) -> some View {
        Button {
            onFormat(format)
        } label: {
            formatButtonLabel(format, isActive: false)
        }
    }
    
    private func formatButtonLabel(_ format: MarkdownFormat, isActive: Bool) -> some View {
        Image(systemName: format.iconName)
            .font(.system(size: 18))
            .foregroundColor(isActive ? .white : .primary)
            .frame(width: 44, height: 32)
            .background(isActive ? Color.accentColor : Color.clear)
            .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                
                // Sample text area
                ScrollView {
                    Text("Sample markdown text")
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                
                // Toolbar
                MarkdownFormattingToolbar { format in
                    print("Format selected: \(format.rawValue)")
                    print("Would insert: \(format.markdownSyntax)")
                }
            }
        }
    }
    
    return PreviewWrapper()
}
