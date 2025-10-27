import SwiftUI
import SwiftData

struct VoiceRecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var voiceManager = VoiceToTaskManager()
    @Binding var isPresented: Bool
    @Binding var parsedTask: ParsedTask?
    
    let availableTags: [Tag]
    
    @State private var hasRequestedPermissions = false
    @State private var permissionGranted = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Title
                Text(voiceManager.isRecording ? "Listening..." : "Tap to Start")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Soundwave Visualization
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        SoundWaveBar(
                            audioLevel: voiceManager.audioLevel,
                            index: index,
                            isRecording: voiceManager.isRecording
                        )
                    }
                }
                .frame(height: 120)
                
                // Recording Duration
                if voiceManager.isRecording {
                    Text(formatDuration(voiceManager.recordingDuration))
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                
                // Transcribed Text
                if !voiceManager.transcribedText.isEmpty {
                    ScrollView {
                        Text(voiceManager.transcribedText)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .frame(maxHeight: 150)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Processing Indicator
                if voiceManager.isProcessing {
                    ProgressView("Processing...")
                        .padding()
                }
                
                // Error Message
                if let error = voiceManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Buttons
                HStack(spacing: 20) {
                    // Cancel Button
                    Button(action: {
                        voiceManager.stopRecording()
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(width: 120, height: 50)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(25)
                    }
                    
                    // Record/Stop Button
                    if voiceManager.isRecording {
                        Button(action: {
                            stopAndProcess()
                        }) {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Stop")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 50)
                            .background(Color.purple)
                            .cornerRadius(25)
                        }
                    } else if !hasRequestedPermissions || !permissionGranted {
                        Button(action: {
                            requestPermissionsAndStart()
                        }) {
                            HStack {
                                Image(systemName: "mic.fill")
                                Text("Start")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 50)
                            .background(Color.purple)
                            .cornerRadius(25)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .padding()
        }
        .onAppear {
            if !hasRequestedPermissions {
                requestPermissionsAndStart()
            }
           voiceManager.setAvailableTags(availableTags)
        }
    }
    
    // MARK: - Helper Methods
    
    private func requestPermissionsAndStart() {
        hasRequestedPermissions = true
        
        Task {
            let granted = await voiceManager.requestPermissions()
            
            await MainActor.run {
                permissionGranted = granted
                
                if granted {
                    startRecording()
                }
            }
        }
    }
    
    private func startRecording() {
        do {
            try voiceManager.startRecording()
        } catch {
            voiceManager.errorMessage = error.localizedDescription
        }
    }
    
   private func stopAndProcess() {
       voiceManager.stopRecording()
       
       // Wait a moment for AI parsing to complete
       DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
           if let parsed = voiceManager.parsedTask {
               // AI parsing succeeded
               parsedTask = parsed
               isPresented = false
           } else if !voiceManager.transcribedText.isEmpty {
               // Transcription succeeded but parsing failed - use basic fallback
               let basicTask = ParsedTask(taskName: voiceManager.transcribedText)
               parsedTask = basicTask
               isPresented = false
           } else {
               // No speech detected
               voiceManager.errorMessage = "No speech detected. Please try again."
           }
       }
   }
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Sound Wave Bar

struct SoundWaveBar: View {
    let audioLevel: Float
    let index: Int
    let isRecording: Bool
    
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 8)
            .frame(height: barHeight)
            .animation(.easeInOut(duration: 0.1), value: audioLevel)
            .scaleEffect(y: isRecording ? 1.0 : 0.3)
            .animation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.1),
                value: isRecording
            )
    }
    
    private var barHeight: CGFloat {
        if isRecording {
            // Height varies based on audio level and bar index
            let baseHeight: CGFloat = 30
            let maxHeight: CGFloat = 100
            let levelMultiplier = CGFloat(audioLevel) * 3
            let indexOffset = CGFloat(abs(2 - index)) * 10 // Middle bar is tallest
            
            return min(maxHeight, baseHeight + (levelMultiplier * 20) + indexOffset)
        } else {
            return 30
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Tag.self, configurations: config)
    let context = container.mainContext
    
    // Create sample tags
    let blueTag = Tag(name: "Blue", isPrimary: true)
    let redTag = Tag(name: "Red", isPrimary: true)
    context.insert(blueTag)
    context.insert(redTag)
    
    let tags = (try? context.fetch(FetchDescriptor<Tag>())) ?? []
    
    return VoiceRecordingView(
        isPresented: .constant(true),
        parsedTask: .constant(nil),
        availableTags: tags
    )
}
