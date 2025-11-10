//
// MarkdownTypes.swift
// HarborDot
//
// Shared markdown parsing types used across iOS, iPad, and Mac editors
//

import Foundation

/// Represents the type of a markdown line
enum MarkdownLineType {
    case header1, header2, header3
    case bullet, numbered(Int)
    case checkbox(Bool)
    case code
    case quote
    case normal
}

/// Represents a parsed line of markdown with its type and content
struct MarkdownLine: Identifiable {
    let id = UUID()
    let type: MarkdownLineType
    let content: String
}
