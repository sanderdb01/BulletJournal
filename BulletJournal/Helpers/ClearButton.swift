import SwiftUI

struct ClearButton: ViewModifier {
    @Binding var text: String
    var focusState: FocusState<Bool>.Binding?
    
    func body(content: Content) -> some View {
        HStack {
            content
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    focusState?.wrappedValue = true  // Set focus after clearing
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }
        }
    }
}

extension View {
    func clearButton(text: Binding<String>, focus: FocusState<Bool>.Binding? = nil) -> some View {
        modifier(ClearButton(text: text, focusState: focus))
    }
}
