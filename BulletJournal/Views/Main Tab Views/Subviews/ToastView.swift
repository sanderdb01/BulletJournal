import SwiftUI

// MARK: - Toast View

/// A notification banner that appears temporarily at the top of the screen
///
/// `ToastView` displays a message with an icon in a frosted glass container.
/// It's typically used for brief confirmations like "Email sent" or "Task completed".
///
/// The view automatically includes:
/// - Material background with blur effect
/// - Colored icon and border
/// - Smooth spring animation
/// - Shadow for depth
///
/// - Important: This view should be presented via the ``toast(isPresented:message:icon:color:duration:)`` modifier,
///   not instantiated directly.
///
/// ## Example Appearance
/// ```
/// ┌─────────────────────────────┐
/// │  ✓  Thank you for feedback! │
/// └─────────

struct ToastView: View {
    let message: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let icon: String
    let color: Color
    let duration: TimeInterval
    
    @State private var workItem: DispatchWorkItem?
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = -20
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isPresented {
                    ToastView(message: message, icon: icon, color: color)
                        .padding(.top, 8)
                        .opacity(opacity)
                        .offset(y: offset)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                opacity = 1
                                offset = 0
                            }
                            
                            // Haptic feedback
                            #if os(iOS)
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            #endif
                            
                            // Auto-dismiss
                            let task = DispatchWorkItem {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    opacity = 0
                                    offset = -20
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    isPresented = false
                                }
                            }
                            
                            workItem = task
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
                        }
                        .onDisappear {
                            workItem?.cancel()
                            workItem = nil
                            opacity = 0
                            offset = -20
                        }
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Shows a toast notification
    func toast(
        isPresented: Binding<Bool>,
        message: String,
        icon: String = "checkmark.circle.fill",
        color: Color = .green,
        duration: TimeInterval = 2.0
    ) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            icon: icon,
            color: color,
            duration: duration
        ))
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var showToast = false
        
        var body: some View {
            NavigationStack {
                VStack(spacing: 20) {
                    Button("Show Success Toast") {
                        showToast = true
                    }
                    
                    Button("Show Error Toast") {
                        // Could add different toast types
                    }
                }
                .navigationTitle("Toast Demo")
            }
            .toast(
                isPresented: $showToast,
                message: "Email sent successfully!",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
    }
    
    return PreviewWrapper()
}

//
// Other ways to use the .toast
//// Success (green checkmark)
//.toast(
//    isPresented: $showSuccess,
//    message: "Task completed!",
//    icon: "checkmark.circle.fill",
//    color: .green
//)
//
//// Error (red X)
//.toast(
//    isPresented: $showError,
//    message: "Something went wrong",
//    icon: "xmark.circle.fill",
//    color: .red
//)
//
//// Info (blue info)
//.toast(
//    isPresented: $showInfo,
//    message: "Syncing with iCloud...",
//    icon: "arrow.triangle.2.circlepath",
//    color: .blue
//)
//
//// Warning (orange exclamation)
//.toast(
//    isPresented: $showWarning,
//    message: "No internet connection",
//    icon: "exclamationmark.triangle.fill",
//    color: .orange
//)
