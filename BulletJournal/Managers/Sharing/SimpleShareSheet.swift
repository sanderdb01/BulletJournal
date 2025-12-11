import SwiftUI
import UIKit

#if os(iOS)
struct SimpleShareSheet: UIViewControllerRepresentable {
    let shareURL: URL
    let taskName: String
    let onDismiss: () -> Void
    let onComplete: (Bool) -> Void  // Reports if actually shared (true) or cancelled (false)
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        print("📱 Presenting native share sheet")
        print("📱 URL: \(shareURL.absoluteString)")
        
        let controller = UIActivityViewController(
            activityItems: [shareURL, "Shared from HarborDot: \(taskName)"],
            applicationActivities: nil
        )
        
        controller.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if let error = error {
                print("❌ Share error: \(error)")
                onComplete(false)
            } else if completed {
                print("✅ Share completed via: \(activityType?.rawValue ?? "unknown")")
                onComplete(true)  // User actually shared it
            } else {
                print("ℹ️ Share cancelled by user")
                onComplete(false)  // User cancelled
            }
            onDismiss()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
