#if os(watchOS)
import Foundation
import WatchKit
import WatchConnectivity
internal import Combine

/// Simplified voice manager for Apple Watch using dictation
@available(watchOS 9.0, *)
class WatchVoiceManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var transcribedText: String = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        // Activate Watch Connectivity session
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // MARK: - Dictation
    
    func startDictation(completion: @escaping (String?) -> Void) {
        isRecording = true
        transcribedText = ""
        errorMessage = nil
        
        print("🎙️ Watch: Starting dictation...")
        
        // Use WKInterfaceController's presentTextInputController for dictation
        // This needs to be called from a WKInterfaceController context
        // We'll expose a method that the view can call
    }
    
    func stopRecording() {
        print("🛑 Watch: Stopping recording...")
        isRecording = false
    }
    
    // MARK: - Send to iPhone for AI Processing
    
    func sendToiPhoneForProcessing() {
        guard !transcribedText.isEmpty else {
            errorMessage = "No speech detected"
            return
        }
        
        guard WCSession.default.isReachable else {
            errorMessage = "iPhone not reachable. Please make sure your iPhone is nearby and unlocked."
            print("❌ Watch: iPhone not reachable")
            return
        }
        
        isProcessing = true
        print("📤 Watch: Sending to iPhone for AI processing: '\(transcribedText)'")
        
        let message: [String: Any] = [
            "action": "createTaskFromVoice",
            "text": transcribedText,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let success = reply["success"] as? Bool, success {
                    print("✅ Watch: Task created successfully on iPhone")
                    self?.transcribedText = ""
                } else if let error = reply["error"] as? String {
                    print("❌ Watch: Error from iPhone: \(error)")
                    self?.errorMessage = "Failed: \(error)"
                }
            }
        }, errorHandler: { [weak self] error in
            DispatchQueue.main.async {
                self?.isProcessing = false
                self?.errorMessage = "Failed to communicate with iPhone"
                print("❌ Watch: Communication error: \(error.localizedDescription)")
            }
        })
    }
}

// MARK: - Watch Connectivity Delegate

extension WatchVoiceManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ Watch: WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("✅ Watch: WCSession activated with state: \(activationState.rawValue)")
        }
    }
}

// MARK: - Errors

enum WatchVoiceError: LocalizedError {
    case dictationFailed
    case iPhoneNotReachable
    
    var errorDescription: String? {
        switch self {
        case .dictationFailed:
            return "Failed to start dictation"
        case .iPhoneNotReachable:
            return "iPhone not reachable. Please make sure it's nearby and unlocked."
        }
    }
}
#endif
