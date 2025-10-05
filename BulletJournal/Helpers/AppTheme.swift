import SwiftUI

struct AppTheme {
    // MARK: - Background Colors
    
    static let primaryBackground = Color("PrimaryBackground")
    static let secondaryBackground = Color("SecondaryBackground")
    static let tertiaryBackground = Color("TertiaryBackground")
    
    // MARK: - Accent Colors
    
    static let accent = Color.blue
    static let accentSecondary = Color.blue.opacity(0.7)
    
    // MARK: - Text Colors
    
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    
    // MARK: - Card Style
    
    static func cardBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }
    
    static func cardShadow(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.1)
    }
}

// MARK: - View Modifiers

struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground(colorScheme: colorScheme))
            .cornerRadius(12)
            .shadow(color: AppTheme.cardShadow(colorScheme: colorScheme), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
