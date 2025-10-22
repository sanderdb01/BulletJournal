import Foundation
import Speech
import AVFoundation
import NaturalLanguage
import SwiftData

#if canImport(Combine)
internal import Combine
#endif

/// Manages voice-to-task conversion using Apple's on-device AI
@available(iOS 13.0, macOS 10.15, *)
class VoiceToTaskManager: NSObject, ObservableObject {
   // MARK: - Published Properties
   @Published var isRecording = false
   @Published var recordingDuration: TimeInterval = 0
   @Published var audioLevel: Float = 0
   @Published var transcribedText: String = ""
   @Published var isProcessing = false
   @Published var errorMessage: String?
   @Published var parsedTask: ParsedTask? = nil  // ADDED: This is what DayView watches!
   
   // MARK: - Private Properties
   private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
   private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
   private var recognitionTask: SFSpeechRecognitionTask?
   private let audioEngine = AVAudioEngine()
   private var recordingTimer: Timer?
   private var levelTimer: Timer?
   private var availableTags: [Tag] = []  // ADDED: Store tags
   
   // MARK: - Public Methods
   
   /// Set available tags for color matching
   func setAvailableTags(_ tags: [Tag]) {
      self.availableTags = tags
      print("🏷️ Set \(tags.count) available tags")
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
   
   /// Stop recording and parse the result
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
      
      // CRITICAL FIX: Parse the transcription and assign to parsedTask
      if !transcribedText.isEmpty {
         print("🔍 Starting to parse task...")
         let parsed = parseTask(from: transcribedText, availableTags: availableTags)
         
         // Assign to the published property so DayView can see it
         DispatchQueue.main.async {
            self.parsedTask = parsed
            print("✅ ParsedTask assigned:")
            print("   - Task name: '\(parsed.taskName)'")
            print("   - Has reminder: \(parsed.reminderTime != nil)")
            print("   - Has recurrence: \(parsed.voiceRecurrencePattern != nil)")
            print("   - Has color tag: \(parsed.colorTag != nil)")
            print("   - Has notes: \(parsed.notes != nil)")
         }
      } else {
         print("⚠️ Transcribed text is empty!")
      }
   }
   
   /// Parse transcribed text into task components using Apple's Natural Language framework
   func parseTask(from text: String, availableTags: [Tag]) -> ParsedTask {
      print("🔍 parseTask called with text: '\(text)'")
      isProcessing = true
      defer { isProcessing = false }
      
      var parsedTask = ParsedTask(
         taskName: text,
         reminderTime: nil,
         voiceRecurrencePattern: nil,
         colorTag: nil,
         notes: nil
      )
      
      // Use NLTagger for linguistic analysis
      let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
      tagger.string = text
      
      // Extract task name (this will be refined based on other components)
      var taskName = text
      
      // 1. Extract reminder time
      if let (time, cleanedText) = extractReminderTime(from: text) {
         parsedTask.reminderTime = time
         taskName = cleanedText
         print("⏰ Found reminder time: \(time)")
      }
      
      // 2. Extract recurrence pattern
      if let (pattern, cleanedText) = extractRecurrence(from: taskName) {
         parsedTask.voiceRecurrencePattern = pattern
         taskName = cleanedText
         print("🔁 Found recurrence: \(pattern)")
      }
      
      // 3. Match color tag by custom name
      if let (tag, cleanedText) = matchColorTag(from: taskName, availableTags: availableTags) {
         parsedTask.colorTag = tag
         taskName = cleanedText
         print("🎨 Found color tag: \(tag.name ?? "unknown")")
      }
      
      // 4. Extract notes/description (anything after "note:", "description:", etc.)
      if let (notes, cleanedText) = extractNotes(from: taskName) {
         parsedTask.notes = notes
         taskName = cleanedText
         print("📝 Found notes: \(notes)")
      }
      
      // Clean up task name
      taskName = taskName
         .trimmingCharacters(in: .whitespacesAndNewlines)
         .replacingOccurrences(of: "  +", with: " ", options: .regularExpression) // Remove multiple spaces
      
      // Remove common task prefixes
      let prefixes = ["remind me to ", "remember to ", "I need to ", "don't forget to ", "task "]
      for prefix in prefixes {
         if taskName.lowercased().hasPrefix(prefix) {
            taskName = String(taskName.dropFirst(prefix.count))
            break
         }
      }
      
      // Capitalize first letter
      if let first = taskName.first {
         taskName = first.uppercased() + taskName.dropFirst()
      }
      
      parsedTask.taskName = taskName
      
      // If task name is empty, use original text
      if parsedTask.taskName.isEmpty {
         parsedTask.taskName = text
         print("⚠️ Task name was empty, using original text")
      }
      
      print("✅ Final parsed task name: '\(parsedTask.taskName)'")
      
      return parsedTask
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
   
   /// Extract reminder time from text
   private func extractReminderTime(from text: String) -> (Date, String)? {
      let calendar = Calendar.current
      var cleanedText = text
      var reminderDate: Date?
      
      // Common time patterns
      let timePatterns: [(String, ([String?]) -> Date?)] = [
         // "at 3pm", "at 3:30pm"
         ("at (\\d{1,2}):?(\\d{2})? ?(am|pm)", { matches -> Date? in
            guard let hourStr = matches[1], let hour = Int(hourStr) else { return nil }
            let minute = matches[2].flatMap { Int($0) } ?? 0
            let isPM = matches[3]?.lowercased() == "pm"
            
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            // Break down the ternary operator to avoid type ambiguity
            let calculatedHour: Int
            if isPM && hour != 12 {
               calculatedHour = hour + 12
            } else if hour == 12 && !isPM {
               calculatedHour = 0
            } else {
               calculatedHour = hour
            }
            components.hour = calculatedHour
            components.minute = minute
            
            return calendar.date(from: components)
         }),
         // "tomorrow at 3pm"
         ("tomorrow at (\\d{1,2}):?(\\d{2})? ?(am|pm)?", { matches -> Date? in
            guard let hourStr = matches[1], let hour = Int(hourStr) else { return nil }
            let minute = matches[2].flatMap { Int($0) } ?? 0
            let isPM = matches[3]?.lowercased() == "pm"
            
            var tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = isPM && hour != 12 ? hour + 12 : (hour == 12 && !isPM ? 0 : hour)
            components.minute = minute
            
            return calendar.date(from: components)
         }),
         // "in 30 minutes"
         ("in (\\d+) minutes?", { matches -> Date? in
            guard let minutesStr = matches[1], let minutes = Int(minutesStr) else { return nil }
            return calendar.date(byAdding: .minute, value: minutes, to: Date())
         }),
      ]
      
      for (pattern, handler) in timePatterns {
         if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
            let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            var captures: [String?] = []
            for i in 0..<match.numberOfRanges {
               if let range = Range(match.range(at: i), in: text) {
                  captures.append(String(text[range]))
               } else {
                  captures.append(nil)
               }
            }
            
            if let date = handler(captures) {
               reminderDate = date
               
               // Remove matched text
               if let range = Range(match.range, in: text) {
                  cleanedText.removeSubrange(range)
               }
               break
            }
         }
      }
      
      if let date = reminderDate {
         return (date, cleanedText)
      }
      
      return nil
   }
   
   /// Extract recurrence pattern
   private func extractRecurrence(from text: String) -> (VoiceRecurrencePattern, String)? {
      var cleanedText = text
      var recurrencePattern: VoiceRecurrencePattern?
      
      let patterns: [(String, VoiceRecurrencePattern)] = [
         ("every day|daily", .daily),
         ("every week|weekly", .weekly),
         ("every month|monthly", .monthly),
         ("every year|yearly", .yearly),
         ("every monday", .weekly),
         ("every tuesday", .weekly),
         ("every wednesday", .weekly),
         ("every thursday", .weekly),
         ("every friday", .weekly),
         ("every saturday", .weekly),
         ("every sunday", .weekly),
      ]
      
      for (pattern, rule) in patterns {
         if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
            let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            recurrencePattern = rule
            
            // Remove matched text
            if let range = Range(match.range, in: text) {
               cleanedText.removeSubrange(range)
            }
            break
         }
      }
      
      if let pattern = recurrencePattern {
         return (pattern, cleanedText)
      }
      
      return nil
   }
   
   /// Match color tag by custom name
   private func matchColorTag(from text: String, availableTags: [Tag]) -> (Tag, String)? {
      var cleanedText = text
      let lowercasedText = text.lowercased()
      
      print("🔍 Matching color tag from '\(text)' with \(availableTags.count) available tags")
      
      // Try to find color tags by their custom names
      for tag in availableTags where tag.isPrimary == true {
         guard let tagName = tag.name else { continue }
         let lowercasedTagName = tagName.lowercased()
         
         print("   Checking tag: '\(tagName)'")
         
         // Look for patterns like "tag it as work", "use red tag", "with blue", etc.
         let patterns = [
            "tag it as \(lowercasedTagName)",
            "use \(lowercasedTagName) tag",
            "with \(lowercasedTagName)",
            "\(lowercasedTagName) tag",
         ]
         
         for pattern in patterns {
            if lowercasedText.contains(pattern) {
               cleanedText = cleanedText.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
               print("   ✅ Matched pattern '\(pattern)'")
               return (tag, cleanedText)
            }
         }
         
         // Also check if the tag name appears as a standalone word
         let words = lowercasedText.components(separatedBy: .whitespaces)
         if words.contains(lowercasedTagName) {
            cleanedText = cleanedText.replacingOccurrences(of: tagName, with: "", options: .caseInsensitive)
            print("   ✅ Matched standalone word '\(tagName)'")
            return (tag, cleanedText)
         }
      }
      
      print("   ❌ No color tag matched")
      return nil
   }
   
   /// Extract notes/description
   private func extractNotes(from text: String) -> (String, String)? {
      let patterns = [
         "note:",
         "notes:",
         "description:",
         "details:",
      ]
      
      for pattern in patterns {
         if let range = text.range(of: pattern, options: .caseInsensitive) {
            let notes = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            let taskName = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            return (notes, taskName)
         }
      }
      
      return nil
   }
}

/// Voice-related errors
enum VoiceError: LocalizedError {
   case recognitionFailed
   case permissionDenied
   
   var errorDescription: String? {
      switch self {
         case .recognitionFailed:
            return "Failed to start speech recognition"
         case .permissionDenied:
            return "Please enable microphone and speech recognition in Settings"
      }
   }
}
