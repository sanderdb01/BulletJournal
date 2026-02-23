import SwiftUI

struct ClickableLinksText: View {
    let text: String
    
    var body: some View {
        let components = parseTextWithLinks(text)
        
        // Use HStack with wrapping for clickable links
        ViewThatFits {
            LinksFlowLayout(spacing: 4) {
                ForEach(Array(components.enumerated()), id: \.offset) { _, component in
                    switch component {
                    case .text(let string):
                        Text(string)
                    case .link(let string, let url):
                        if let validURL = URL(string: url) {
                            Link(string, destination: validURL)
                                .foregroundColor(.blue)
                        } else {
                            Text(string)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .textSelection(.enabled)
    }
    
    private func parseTextWithLinks(_ text: String) -> [TextComponent] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return [.text(text)]
        }
        
        let matches = detector.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        
        guard !matches.isEmpty else {
            return [.text(text)]
        }
        
        var components: [TextComponent] = []
        var lastIndex = text.startIndex
        
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            
            // Add text before the URL
            if lastIndex < range.lowerBound {
                let textBefore = String(text[lastIndex..<range.lowerBound])
                components.append(.text(textBefore))
            }
            
            // Add the URL as a link
            let urlString = String(text[range])
            if let url = match.url?.absoluteString ?? URL(string: urlString)?.absoluteString {
                components.append(.link(urlString, url))
            } else {
                components.append(.text(urlString))
            }
            
            lastIndex = range.upperBound
        }
        
        // Add remaining text after the last URL
        if lastIndex < text.endIndex {
            let remainingText = String(text[lastIndex...])
            components.append(.text(remainingText))
        }
        
        return components
    }
    
    private enum TextComponent {
        case text(String)
        case link(String, String)
    }
}

// Simple flow layout for wrapping text/links
struct LinksFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
