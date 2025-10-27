#if os(watchOS)
import SwiftUI
import SwiftData

struct WatchVoiceRecordingView: View {
    @StateObject private var voiceManager = WatchVoiceManager()
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            if voiceManager.isProcessing {
                // Processing state
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.purple)
                    Text("Creating task...")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            } else {
                // Dictation field
                VStack(spacing: 12) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                    
                    Text("Tap to speak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Say your task", text: $voiceManager.transcribedText)
                        .onChange(of: voiceManager.transcribedText) { oldValue, newValue in
                            // When text changes (dictation completes), automatically send to iPhone
                            if !newValue.isEmpty && oldValue.isEmpty {
                                print("📝 Watch: Got dictation: '\(newValue)'")
                                // Small delay to ensure dictation UI is dismissed
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    voiceManager.sendToiPhoneForProcessing()
                                    
                                    // Auto-dismiss after sending
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        if voiceManager.errorMessage == nil {
                                            isPresented = false
                                        }
                                    }
                                }
                            }
                        }
                }
            }
            
            if let error = voiceManager.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    
    private func stopAndProcess() {
//        timerActive = false
        voiceManager.stopRecording()
        
        // Send to iPhone for AI processing
        voiceManager.sendToiPhoneForProcessing()
        
        // Wait a bit then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if voiceManager.errorMessage == nil {
                // Success - dismiss
                isPresented = false
            }
            // If there's an error, keep sheet open so user can see it
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    @Previewable @State var isPresented = true
    
    WatchVoiceRecordingView(isPresented: $isPresented)
}
#endif
