//
// MarkdownHelper.swift
// HarborDot
//
// Shared helper for smart markdown list formatting across all platforms
//

import Foundation
import SwiftUI

struct MarkdownHelper {
   
   // MARK: - Parsing and Rendering
   
   /// Parses the passes markdown test and returns an array of MarkdownLine objects
   static func parseMarkdown(_ text: String) -> [MarkdownLine] {
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
   /// Renders the passed in MarkdownLine object and returns a view
   static func renderLine(_ line: MarkdownLine) -> AnyView {
      AnyView(Group {
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
      })
  }
   /// Parses the passed in string and returns and AttributedString to be added to a Text View in renderLine function
   static func parseInlineMarkdown(_ text: String) -> AttributedString {
      do {
          let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
          return try AttributedString(markdown: text, options: options)
      } catch {
          return AttributedString(text)
      }
  }
    
    // MARK: - List Detection
   
    /// Gets the list prefix for a given line
    static func getListPrefix(from line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if trimmed.hasPrefix("- [ ]") {
            return "- [ ] "
        } else if trimmed.hasPrefix("- [x]") || trimmed.hasPrefix("- [X] ") {
            return "- [ ] " // New items start unchecked
        } else if trimmed.hasPrefix("- ") {
            return "- "
        } else if trimmed.hasPrefix("* ") {
            return "* "
        } else if let match = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
            // Extract the number
            let numberAndDot = String(trimmed[..<match.upperBound])
            if let currentNumber = Int(numberAndDot.dropLast(2).trimmingCharacters(in: .whitespaces)) {
                return "\(currentNumber + 1). "
            }
        }
        
        return nil
    }
    
    /// Checks if a line is empty (only has list prefix, no content)
    static func isEmptyListLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed == "- " ||
               trimmed == "* " ||
               trimmed == "- [ ]" ||
               trimmed == "- [ ] " ||
               trimmed.range(of: #"^\d+\.\s*$"#, options: .regularExpression) != nil
    }
    
    // MARK: - List Continuation (Return Key)
    
    /// Handles Return key press on a list line
    /// Returns: (newText, newCursorPosition) or nil if not on a list
    static func handleReturnKey(text: String, cursorPosition: Int) -> (newText: String, newCursorPosition: Int)? {
        // Find the current line
        guard let (lineStart, lineEnd, lineContent) = getCurrentLine(in: text, at: cursorPosition) else {
            return nil
        }
        
        // Check if we're on a list line
        guard let listPrefix = getListPrefix(from: lineContent) else {
            return nil
        }
        
        // If the line is empty (just the list prefix), remove it and exit list
        if isEmptyListLine(lineContent) {
            let newText = (text as NSString).replacingCharacters(
                in: NSRange(location: lineStart, length: lineEnd - lineStart),
                with: ""
            )
            return (newText, lineStart)
        }
        
        // Split the line at cursor position
        let cursorInLine = cursorPosition - lineStart
        let beforeCursor = String((lineContent as NSString).substring(to: cursorInLine))
        let afterCursor = String((lineContent as NSString).substring(from: cursorInLine))
        
        // Create new line with list prefix
        let newLine = "\n" + listPrefix + afterCursor
        
        // Insert at cursor position
        let newText = (text as NSString).replacingCharacters(
            in: NSRange(location: cursorPosition, length: 0),
            with: newLine
        )
        
        // New cursor position is after the list prefix on the new line
        let newCursorPosition = cursorPosition + 1 + listPrefix.count
        
        return (newText, newCursorPosition)
    }
    
    // MARK: - Add List to Current Line (Toolbar Button)
    
    /// Adds list formatting to the beginning of the current line
    /// Returns: (newText, newCursorPosition)
    static func addListToCurrentLine(text: String, cursorPosition: Int, listType: ListType) -> (newText: String, newCursorPosition: Int) {
        // Find the current line
        guard let (lineStart, lineEnd, lineContent) = getCurrentLine(in: text, at: cursorPosition) else {
            // Shouldn't happen, but fallback to appending
            let prefix = listType.prefix
            return (text + prefix, text.count + prefix.count)
        }
        
        // Get the prefix for this list type
        let prefix = listType.prefix
        
        // Check if line already has a list prefix
        if let existingPrefix = getListPrefix(from: lineContent) {
            // Already a list - replace the prefix
            let trimmed = lineContent.trimmingCharacters(in: .whitespaces)
            let contentAfterPrefix = trimmed.dropFirst(existingPrefix.count)
            let newLine = prefix + contentAfterPrefix
            
            let newText = (text as NSString).replacingCharacters(
                in: NSRange(location: lineStart, length: lineEnd - lineStart),
                with: newLine
            )
            
            // Keep cursor at same relative position
            let cursorOffset = cursorPosition - lineStart
            let prefixDiff = prefix.count - existingPrefix.count
            let newCursorPosition = lineStart + min(cursorOffset + prefixDiff, newLine.count)
            
            return (newText, newCursorPosition)
        } else {
            // Not a list yet - add prefix to beginning
            let trimmed = lineContent.trimmingCharacters(in: .whitespaces)
            let newLine = prefix + trimmed
            
            let newText = (text as NSString).replacingCharacters(
                in: NSRange(location: lineStart, length: lineEnd - lineStart),
                with: newLine
            )
            
            // Move cursor by the prefix length
            let newCursorPosition = cursorPosition + prefix.count
            
            return (newText, newCursorPosition)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Gets the current line's start, end, and content
    private static func getCurrentLine(in text: String, at position: Int) -> (start: Int, end: Int, content: String)? {
        guard position >= 0 && position <= text.count else { return nil }
        
        let nsText = text as NSString
        
        // Find line start (go backwards to find last \n or start of text)
        var lineStart = position
        while lineStart > 0 && nsText.character(at: lineStart - 1) != 10 { // 10 = \n
            lineStart -= 1
        }
        
        // Find line end (go forwards to find next \n or end of text)
        var lineEnd = position
        while lineEnd < nsText.length && nsText.character(at: lineEnd) != 10 {
            lineEnd += 1
        }
        
        // Get line content
        let lineContent = nsText.substring(with: NSRange(location: lineStart, length: lineEnd - lineStart))
        
        return (lineStart, lineEnd, lineContent)
    }
}

// MARK: - List Type Enum

enum ListType {
    case bullet
    case numbered(Int)
    case checklist
    
    var prefix: String {
        switch self {
        case .bullet:
            return "- "
        case .numbered(let num):
            return "\(num). "
        case .checklist:
            return "- [ ] "
        }
    }
    
    // Convert from MarkdownFormat
    static func from(_ format: MarkdownFormat) -> ListType? {
        switch format {
        case .bulletList:
            return .bullet
        case .numberedList:
            return .numbered(1)
        case .checklistItem:
            return .checklist
        default:
            return nil
        }
    }
}
