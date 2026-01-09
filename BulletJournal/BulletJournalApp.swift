import SwiftUI
import SwiftData
import CloudKit  // ← ADD THIS

@main
struct HarborDotApp: App {
   @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
   @StateObject private var deepLinkManager = DeepLinkManager()
   @State private var hasInitialized = false
   
   // Track what's new screen
   @AppStorage("lastSeenVersion") private var lastSeenVersion: String = ""
   @State private var showWhatsNew = false
   
//   @AppStorage("lastLaunchDate") private var lastLaunchTimestamp: Double = 0
   
   
   init() {
      // Request notification permission on launch
      Task {
         let granted = await NotificationManager.shared.requestAuthorization()
         if granted {
            print("✅ Notification permission granted")
         } else {
            print("⚠️ Notification permission denied")
         }
      }
   }
   
   var body: some Scene {
      WindowGroup {
         ContentView()
            .environmentObject(deepLinkManager)
            .onOpenURL { url in
               // Handle both deep links and CloudKit shares in one place
               if url.scheme == "harbordot" {
                  // HarborDot deep link
                  deepLinkManager.handle(url: url)
               } else if url.scheme == "https" && url.host == "icloud.com" {
                  // CloudKit share link
                  handleIncomingShareURL(url)
               }
            }
            .onAppear {
               // Ensure initialization only happens once per app launch
               guard !hasInitialized else { return }
               hasInitialized = true
               
               initializeDefaultTags()
               generateRecurringTasks()
               initializeTaskPositions()
               let context = SharedModelContainer.shared.mainContext
               
               // Inject ModelContext into sharing manager
               CloudKitSharingManager.shared.modelContext = context
               
               // Start shared tasks monitor
               Task { @MainActor in
                  SharedTasksMonitor.shared.start(with: context)
               }
               
               // Initialize reminder manager
               NotificationManager.shared.modelContext = context
               
               // Refresh reminder (checks tasks and schedules if needed)
               Task {
                  await NotificationManager.shared.refreshDailyReminder()
               }
               
               // Process anchors
//               Task {
//                  await processAnchors(context: context)
//               }
               
               Task { @MainActor in
                  SharedTasksMonitor.shared.start(with: context)
               }
               
#if os(iOS)
               WatchConnectivityHandler.shared.setModelContext(context)
#endif
               // Check if we should show What's New
               checkForWhatsNew()
            }
         // Show What's New sheet
            .sheet(isPresented: $showWhatsNew) {
               WhatsNewView(version: currentAppVersion)
            }
      }
      .modelContainer(SharedModelContainer.shared)
      // ← REMOVE THE .onOpenURL HERE - it was in the wrong place
#if os(macOS)
      .defaultSize(width: 1200, height: 800)
      .commands {
         HarborDotCommands()
      }
#endif
   }
   
   // Initialize color tags using iCloud Key-Value Storage to prevent duplicates
   // This is idempotent and safe to call on every launch
   private func initializeDefaultTags() {
      let context = SharedModelContainer.shared.mainContext
      TagManager.createDefaultTags(in: context)
   }
   
   private func generateRecurringTasks() {
      let modelContext = SharedModelContainer.shared.mainContext
      let today = Date()
      let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: today)!
      
      RecurrenceManager.shared.generateRecurringTasks(
         from: today,
         to: futureDate,
         modelContext: modelContext
      )
   }
   
   private func handleIncomingShareURL(_ url: URL) {
      // This is a CloudKit share URL
      Task {
         do {
            let metadata = try await CKContainer.default().shareMetadata(for: url)
            try await CloudKitSharingManager.shared.acceptShare(metadata: metadata)
            print("✅ Accepted share successfully")
            // Force update shared task properties
            await SharedTasksMonitor.shared.forceUpdate()
         } catch {
            print("❌ Error accepting share: \(error)")
         }
      }
   }
   
   // Call this function to update shared tasks.
   // Needs to be called on App launch, after accepting a share, and periodically (60 sec or so)
   func updateSharedTasksProperties() {
      let context = SharedModelContainer.shared.mainContext
      
      Task { @MainActor in
         // Fetch all tasks marked as shared
         let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.isShared == true }
         )
         
         guard let tasks = try? context.fetch(descriptor) else { return }
         
         for task in tasks {
            guard let taskId = task.id else { continue }
            
            // Try to fetch the share for this task
            do {
               let record = try await CloudKitHelper.shared.fetchRecord(for: taskId)
               if let share = try await CloudKitHelper.shared.fetchShare(for: record) {
                  // Update properties
                  try await SharePropertyUpdater.updateTaskSharingProperties(
                     taskId: taskId,
                     share: share,
                     modelContext: context
                  )
               }
            } catch {
               print("⚠️ Could not update task \(taskId): \(error)")
            }
         }
      }
   }
   
   // Updating old TaskItems to now include the position property as well as populate it
   func initializeTaskPositions() {
      let descriptor = FetchDescriptor<DayLog>()
      let context = SharedModelContainer.shared.mainContext
      
      do {
         let allDayLogs = try context.fetch(descriptor)
         
         for dayLog in allDayLogs {
            guard let tasks = dayLog.tasks else { continue }
            
            // Only update tasks without positions
            let needsUpdate = tasks.contains { $0.position == nil }
            
            if needsUpdate {
               print("📍 Initializing positions for \(tasks.count) tasks")
               for (index, task) in tasks.enumerated() {
                  if task.position == nil {
                     task.position = index
                  }
               }
            }
         }
         
         try context.save()
         print("✅ Task positions initialized")
      } catch {
         print("❌ Error initializing positions: \(error)")
      }
   }
   
   // MARK: What's New Functions
   // Check if we should show What's New
   private func checkForWhatsNew() {
      let currentVersion = currentAppVersion
      
      // If this is a new version, show What's New
      if lastSeenVersion != currentVersion && !lastSeenVersion.isEmpty {
         print("📱 New version detected: \(lastSeenVersion) → \(currentVersion)")
         showWhatsNew = true
      } else if lastSeenVersion.isEmpty {
         // First launch - show What's New and save version. Can also use this to launch tutorial
         print("📱 First launch - version \(currentVersion)")
         showWhatsNew = true
      }
      
      // Save current version
      lastSeenVersion = currentVersion
   }
   
   // Get current app version
   private var currentAppVersion: String {
      let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
      let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
      return "\(version) (\(build))"
   }
}

// MARK: - Check to see if running on iOS device or MacOS
struct DeviceInfo {
    static var isRunningOnMac: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac
        }
        return false
        #endif
    }
   
   static var isMacCatalyst: Bool {
              #if targetEnvironment(macCatalyst)
              return true
              #else
              return false
              #endif
          }
    
    static var isiPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isiPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}

// MARK: - Mac Menu Commands
#if os(macOS)
struct HarborDotCommands: Commands {
   var body: some Commands {
      CommandGroup(replacing: .newItem) {
         Button("New Task...") {
            // Will implement later
         }
         .keyboardShortcut("n", modifiers: .command)
      }
   }
}
#endif
