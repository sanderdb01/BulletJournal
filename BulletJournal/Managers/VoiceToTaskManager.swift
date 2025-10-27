import Foundation
import Speech
import AVFoundation
import NaturalLanguage
import SwiftData
import FoundationModels

#if canImport(Combine)
internal import Combine
#endif

/// Manages voice-to-task conversion using Apple Foundation Models
@available(iOS 18.2, macOS 15.2, *)
class VoiceToTaskManager: NSObject, ObservableObject {
   // MARK: - Published Properties
   @Published var isRecording = false
   @Published var recordingDuration: TimeInterval = 0
   @Published var audioLevel: Float = 0
   @Published var transcribedText: String = ""
   @Published var isProcessing = false
   @Published var errorMessage: String?
   @Published var parsedTask: ParsedTask? = nil
   
   // MARK: - Private Properties
   private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
   private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
   private var recognitionTask: SFSpeechRecognitionTask?
   private let audioEngine = AVAudioEngine()
   private var recordingTimer: Timer?
   private var levelTimer: Timer?
   private var availableTags: [Tag] = []
   private var aiSession = LanguageModelSession()
   
   // MARK: - Public Methods
   
   /// Set available tags for color matching
   func setAvailableTags(_ tags: [Tag]) {
      self.availableTags = tags
      print("🏷️ Set \(tags.count) available tags for AI parsing")
   }
   
   /// Request speech recognition and microphone permissions
   func requestPermissions() async -> Bool {
      // Request speech recognition
      let speechStatus = await withCheckedContinuation { continuation in
         SFSpeechRecognizer.requestAuthorization { status in
            continuation.resume(returning: status)
         }
      }
      
      guard speechStatus == .authorized else {
         errorMessage = "Speech recognition permission denied"
         return false
      }
      
      // Request microphone
      let micStatus: Bool = await withCheckedContinuation { continuation in
         AVAudioSession.sharedInstance().requestRecordPermission { granted in
            continuation.resume(returning: granted)
         }
      }
      guard micStatus else {
         errorMessage = "Microphone permission denied"
         return false
      }
      
      return true
   }
   
   /// Start recording and transcribing
   func startRecording() throws {
      // Cancel any ongoing task
      stopRecording()
      
      // Reset state
      transcribedText = ""
      parsedTask = nil
      errorMessage = nil
      
      print("🎙️ Starting recording...")
      
      // Configure audio session
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
      
      // Create recognition request
      recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
      guard let recognitionRequest = recognitionRequest else {
         throw VoiceError.recognitionFailed
      }
      
      recognitionRequest.shouldReportPartialResults = true
      
      // Configure audio engine
      let inputNode = audioEngine.inputNode
      let recordingFormat = inputNode.outputFormat(forBus: 0)
      
      inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
         self?.recognitionRequest?.append(buffer)
         
         // Calculate audio level for visualization
         DispatchQueue.main.async {
            self?.updateAudioLevel(buffer: buffer)
         }
      }
      
      // Start audio engine
      audioEngine.prepare()
      try audioEngine.start()
      
      // Start recognition task
      recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
         guard let self = self else { return }
         
         if let result = result {
            DispatchQueue.main.async {
               self.transcribedText = result.bestTranscription.formattedString
               print("📝 Transcription update: '\(self.transcribedText)'")
            }
         }
         
         if error != nil || result?.isFinal == true {
            self.audioEngine.stop()
            inputNode.removeTap(onBus: 0)
            self.recognitionRequest = nil
            self.recognitionTask = nil
         }
      }
      
      // Start recording state
      isRecording = true
      recordingDuration = 0
      
      // Start duration timer
      recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
         self?.recordingDuration += 0.1
      }
   }
   
   /// Stop recording and parse with AI
   func stopRecording() {
      print("🛑 Stopping recording...")
      print("🎤 Final transcribed text: '\(transcribedText)'")
      
      audioEngine.stop()
      recognitionRequest?.endAudio()
      isRecording = false
      recordingTimer?.invalidate()
      recordingTimer = nil
      levelTimer?.invalidate()
      levelTimer = nil
      
      if let inputNode = audioEngine.inputNode as AVAudioInputNode? {
         inputNode.removeTap(onBus: 0)
      }
      
      // Parse with Foundation Models AI
      if !transcribedText.isEmpty {
         Task { @MainActor in
            await parseTaskWithAI(from: transcribedText)
         }
      } else {
         print("⚠️ Transcribed text is empty!")
      }
   }
   
   // MARK: - AI Parsing with Foundation Models
   
   /// Parse transcribed text using Apple's Foundation Models
   @MainActor
   func parseTaskWithAI(from text: String) async {
      print("🤖 Starting AI parsing with Foundation Models...")
      isProcessing = true
      
      do {
         // Create tag list for the AI
         let tagNames = availableTags
            .filter { $0.isPrimary == true }
            .compactMap { $0.name }
         let tagList = tagNames.isEmpty ? "Work, Personal, Home" : tagNames.joined(separator: ", ")
         
         // Create a comprehensive prompt for the AI
         let prompt = """
         Parse this voice input into a structured task. Be intelligent about categorization.
         
         Voice input: "\(text)"
         
         Extract and return ONLY a valid JSON object with these exact fields:
         {
           "taskName": "clean task name without phrases like 'remind me to' or 'I need to'",
           "reminderTime": "ISO 8601 date string if time mentioned (e.g., 'at 3pm', 'tomorrow'), otherwise null",
           "voiceRecurrencePattern": "one of: daily, weekly, monthly, yearly, or null if not repeating",
           "colorTag": "choose from: \(tagList) - be smart: 'groceries'→Personal, 'meeting'→Work, 'workout'→Gym",
           "notes": "any additional details mentioned, or null"
         }
         
         Examples:
         - "Buy groceries tomorrow at 3pm" → taskName: "Buy groceries", reminderTime: tomorrow 3pm, colorTag: "Personal"
         - "Workout every day" → taskName: "Workout", voiceRecurrencePattern: "daily", colorTag: "Gym"
         - "Meeting with John" → taskName: "Meeting with John", colorTag: "Work"
         
         Return ONLY the JSON object, no other text.
         """
         
         print("📤 Sending to Foundation Models AI...")
         
         // Send to the model and get response
         let response = try await aiSession.respond(to: prompt)
         let aiOutput = response.content
         
         print("✅ AI Response received: \(aiOutput)")
         
         // Parse the JSON response
         guard let jsonData = aiOutput.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            // If not valid JSON, try to extract from the response
            print("⚠️ Response is not pure JSON, attempting to extract...")
            
            // Look for JSON object in the response
            if let jsonStart = aiOutput.range(of: "{"),
               let jsonEnd = aiOutput.range(of: "}", options: .backwards) {
               let jsonString = String(aiOutput[jsonStart.lowerBound...jsonEnd.upperBound])
               if let extractedData = jsonString.data(using: .utf8),
                  let extractedJson = try? JSONSerialization.jsonObject(with: extractedData) as? [String: Any] {
                  try await processParsedJSON(extractedJson, originalText: text)
                  return
               }
            }
            
            throw VoiceError.aiParsingFailed
         }
         
         try await processParsedJSON(jsonObject, originalText: text)
         
      } catch {
         print("❌ AI Parsing error: \(error.localizedDescription)")
         self.errorMessage = "Failed to parse with AI: \(error.localizedDescription)"
         self.isProcessing = false
         
         // Fallback to basic parsing
         print("⚠️ Falling back to basic parsing...")
         let basicTask = ParsedTask(taskName: text)
         self.parsedTask = basicTask
      }
   }
   
   /// Process the parsed JSON into a ParsedTask
   @MainActor
   private func processParsedJSON(_ jsonObject: [String: Any], originalText: String) async throws {
      // Extract fields from JSON
      let taskName = jsonObject["taskName"] as? String ?? originalText
      let colorTag = jsonObject["colorTag"] as? String
      let notes = jsonObject["notes"] as? String
      let recurrenceString = jsonObject["voiceRecurrencePattern"] as? String
      
      // Parse recurrence
      let recurrence: VoiceRecurrencePattern? = {
         guard let str = recurrenceString?.lowercased() else { return nil }
         return VoiceRecurrencePattern(rawValue: str)
      }()
      
      // Parse reminder time
      let reminderTime: Date? = {
         guard let timeString = jsonObject["reminderTime"] as? String else { return nil }
         
         // Try ISO 8601 first
         let isoFormatter = ISO8601DateFormatter()
         if let date = isoFormatter.date(from: timeString) {
            return date
         }
         
         // Try to parse relative times from the AI
         let calendar = Calendar.current
         let lowercased = timeString.lowercased()
         
         if lowercased.contains("tomorrow") {
            // Try to extract time
            if let hourMatch = lowercased.range(of: #"(\d{1,2}):?(\d{2})?\s?(am|pm)"#, options: .regularExpression) {
               // Parse the time components
               // This is a simplified version - you may want more robust parsing
               return calendar.date(byAdding: .day, value: 1, to: Date())
            }
            return calendar.date(byAdding: .day, value: 1, to: Date())
         }
         
         return nil
      }()
      
      let finalParsedTask = ParsedTask(
         taskName: taskName,
         reminderTime: reminderTime,
         voiceRecurrencePattern: recurrence,
         colorTag: colorTag,
         notes: notes
      )
      
      print("   - Task name: '\(finalParsedTask.taskName)'")
      print("   - Reminder time: \(finalParsedTask.reminderTime != nil ? "Yes" : "No")")
      print("   - Recurrence: \(finalParsedTask.voiceRecurrencePattern?.rawValue ?? "None")")
      print("   - Color tag: \(finalParsedTask.colorTag ?? "None")")
      print("   - Notes: \(finalParsedTask.notes != nil ? "Yes" : "No")")
      
      self.parsedTask = finalParsedTask
      self.isProcessing = false
      
      print("📦 ParsedTask assigned and ready!")
   }
   
   // MARK: - Private Helper Methods
   
   /// Update audio level for visualization
   private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
      guard let channelData = buffer.floatChannelData else { return }
      
      let channelDataValue = channelData.pointee
      let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
         .map { channelDataValue[$0] }
      
      let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
      let avgPower = 20 * log10(rms)
      let normalizedLevel = max(0, min(1, (avgPower + 50) / 50))
      
      audioLevel = normalizedLevel
   }
}

/// Voice-related errors
enum VoiceError: LocalizedError {
   case recognitionFailed
   case permissionDenied
   case aiParsingFailed
   
   var errorDescription: String? {
      switch self {
         case .recognitionFailed:
            return "Failed to start speech recognition"
         case .permissionDenied:
            return "Please enable microphone and speech recognition in Settings"
         case .aiParsingFailed:
            return "Failed to parse task with AI"
      }
   }
}
