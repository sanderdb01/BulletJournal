import SwiftUI
import MessageUI

/// SwiftUI wrapper for MFMailComposeViewController
struct MailView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    let recipients: [String]
    let subject: String
    let body: String
    let onSent: (() -> Void)?  // ← NEW: Callback when sent
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(recipients)
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, onSent: onSent)  // ← Pass callback
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        let onSent: (() -> Void)?  // ← NEW
        
        init(dismiss: DismissAction, onSent: (() -> Void)?) {
            self.dismiss = dismiss
            self.onSent = onSent
        }
        
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            if let error = error {
                print("❌ Mail error: \(error.localizedDescription)")
            }
            
            switch result {
            case .cancelled:
                print("📧 Mail cancelled")
            case .saved:
                print("📧 Mail saved as draft")
            case .sent:
                print("✅ Mail sent")
                // ✅ Call callback when sent
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.onSent?()
                }
            case .failed:
                print("❌ Mail failed to send")
            @unknown default:
                break
            }
            
            dismiss()
        }
    }
}

// MARK: - Helper to Check if Mail is Available

extension View {
    func feedbackMail(
        isPresented: Binding<Bool>,
        recipient: String = "hello@harbordot.com",
        onSent: (() -> Void)? = nil  // ← NEW: Optional callback
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            if MFMailComposeViewController.canSendMail() {
                MailView(
                    recipients: [recipient],
                    subject: "HarborDot Feedback",
                    body: feedbackEmailBody(),
                    onSent: onSent  // ← Pass callback
                )
            } else {
                MailUnavailableView(recipient: recipient)
            }
        }
    }
    
    private func feedbackEmailBody() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        #if os(iOS)
        let device = UIDevice.current
        let systemVersion = device.systemVersion
        let deviceModel = device.model
        #else
        let systemVersion = "macOS"
        let deviceModel = "Mac"
        #endif
        
        return """
        
        
        ---
        App Version: \(version) (\(build))
        OS Version: \(systemVersion)
        Device: \(deviceModel)
        """
    }
}

// MARK: - Fallback View When Mail Not Available

struct MailUnavailableView: View {
    @Environment(\.dismiss) private var dismiss
    let recipient: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("Mail Not Available")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Please send your feedback to:")
                    .foregroundColor(.secondary)
                
                Text(recipient)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .textSelection(.enabled)
                
                Button {
                    UIPasteboard.general.string = recipient
                } label: {
                    Label("Copy Email", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var showingMail = false
        
        var body: some View {
            Button("Test Feedback Mail") {
                showingMail = true
            }
            .feedbackMail(isPresented: $showingMail)
        }
    }
    
    return PreviewWrapper()
}
