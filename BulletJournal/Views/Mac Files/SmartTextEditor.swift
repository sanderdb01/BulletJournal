// MARK: - Smart Text Editor for macOS (NSTextView-based)

#if os(macOS)
import SwiftUI
import AppKit

struct SmartTextEditorMacOS: NSViewRepresentable {
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
       guard !context.coordinator.isEditing else { return }
       
//       print("🔍 updateNSView called - textView.string: '\(textView.string)', binding text: '\(text)'")
//       print("🔍 updateNSView - ScrollView frame: \(scrollView.frame), TextView frame: \(textView.frame)")
//          print("🔍 TextView range: \(textView.selectedRange()), Binding range: \(selectedRange)")
          
        
        // Update text if different
        if textView.string != text {
           print("⚠️ Text different! Replacing...")
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
        var parent: SmartTextEditorMacOS
       var isEditing = false
        
        init(_ parent: SmartTextEditorMacOS) {
            self.parent = parent
        }
        
        // NSTextViewDelegate method for text changes
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
           print("✏️ textDidChange - new text: '\(textView.string)'")
           isEditing = true
            parent.text = textView.string
            parent.selectedRange = textView.selectedRange()
           DispatchQueue.main.async { [weak self] in
                    self?.isEditing = false  // ← UNBLOCK after event completes
                 }

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
#endif
