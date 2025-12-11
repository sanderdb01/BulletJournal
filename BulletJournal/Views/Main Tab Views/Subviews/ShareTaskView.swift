import SwiftUI
import CloudKit

struct ShareTaskView: View {
   let task: TaskItem
   @Environment(\.dismiss) private var dismiss
   @StateObject private var sharingManager = CloudKitSharingManager.shared
   @State private var showNativeShareSheet = false
   @State private var showErrorAlert = false
   @State private var errorMessage = ""
   
   var body: some View {
      NavigationView {
         ScrollView {
            VStack(spacing: 24) {
               // Task Preview
               taskPreviewSection
               
               // Loading indicator
               if sharingManager.isLoading {
                  loadingView
               } else {
                  // Share Status
                  if task.isShared == true {
                     sharedStatusSection
                  } else {
                     notSharedSection
                  }
               }
            }
            .padding()
         }
         .navigationTitle("Share Task")
         .navigationBarTitleDisplayMode(.inline)
         .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
               Button("Done") {
                  dismiss()
               }
            }
         }
         .sheet(isPresented: $showNativeShareSheet) {
             if let share = sharingManager.activeShare,
                let shareURL = share.url {
                 #if os(iOS)
                 SimpleShareSheet(
                     shareURL: shareURL,
                     taskName: task.name ?? "Task",
                     onDismiss: {
                         showNativeShareSheet = false
                     },
                     onComplete: { wasActuallyShared in
                         if wasActuallyShared {
                             // User successfully shared it - keep the share
                             print("✅ Task was shared successfully")
                         } else {
                             // User cancelled - delete the share and clear properties
                             print("🚫 User cancelled sharing - cleaning up")
                             sharingManager.cancelShare(
                                 taskId: task.id!,
                                 share: share
                             ) { result in
                                 switch result {
                                 case .success:
                                     print("✅ Share cleaned up")
                                 case .failure(let error):
                                     print("⚠️ Cleanup error: \(error)")
                                 }
                             }
                         }
                     }
                 )
                 #endif
             }
         }
         .alert("Sharing Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
         } message: {
            Text(errorMessage)
         }
      }
   }
   
   // MARK: - Loading View
   
   private var loadingView: some View {
      VStack(spacing: 20) {
         ProgressView()
            .scaleEffect(1.5)
         
         Text("Preparing to share...")
            .font(.headline)
            .foregroundColor(.secondary)
         
         Text("This may take a few seconds")
            .font(.caption)
            .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 60)
   }
   
   // MARK: - Task Preview Section
   
   private var taskPreviewSection: some View {
      VStack(alignment: .leading, spacing: 12) {
         HStack {
            // Color indicator
            Circle()
               .fill(Color.blue)
               .frame(width: 12, height: 12)
            
            Text(task.name ?? "Untitled Task")
               .font(.title3)
               .fontWeight(.semibold)
            
            Spacer()
         }
         
         if let notes = task.notes, !notes.isEmpty {
            Text(notes)
               .font(.body)
               .foregroundColor(.secondary)
               .lineLimit(3)
         }
         
         // Tags
         if let primaryTag = task.primaryTag {
            HStack {
               Image(systemName: "tag.fill")
                  .font(.caption)
               Text(primaryTag.name ?? "")
                  .font(.caption)
            }
            .foregroundColor(.secondary)
         }
         
         // Date info
         if let createdAt = task.createdAt {
            HStack {
               Image(systemName: "calendar")
                  .font(.caption)
               Text("Created \(createdAt, style: .relative)")
                  .font(.caption)
            }
            .foregroundColor(.secondary)
         }
      }
      .padding()
      .background(Color.secondary.opacity(0.1))
      .cornerRadius(12)
   }
   
   // MARK: - Not Shared Section
   
   private var notSharedSection: some View {
      VStack(spacing: 20) {
         // Icon
         ZStack {
            Circle()
               .fill(Color.blue.opacity(0.1))
               .frame(width: 100, height: 100)
            
            Image(systemName: "person.2.circle.fill")
               .font(.system(size: 50))
               .foregroundColor(.blue)
         }
         
         // Title and description
         VStack(spacing: 8) {
            Text("Share this task")
               .font(.title3)
               .fontWeight(.semibold)
            
            Text("Collaborate with others in real-time. Changes sync automatically across all devices.")
               .font(.subheadline)
               .foregroundColor(.secondary)
               .multilineTextAlignment(.center)
               .padding(.horizontal)
         }
         
         // Share button
         Button(action: startSharing) {
            HStack {
               Image(systemName: "square.and.arrow.up")
               Text("Share Task")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
         }
         .padding(.horizontal)
         
         // Info boxes
         VStack(spacing: 12) {
            infoBox(
               icon: "lock.shield.fill",
               title: "Private Sharing",
               description: "Only people you invite can see this task"
            )
            
            infoBox(
               icon: "arrow.triangle.2.circlepath",
               title: "Real-time Sync",
               description: "Everyone sees updates instantly"
            )
            
            infoBox(
               icon: "icloud.fill",
               title: "iCloud Required",
               description: "Both you and recipients must be signed into iCloud"
            )
            
            infoBox(
               icon: "clock.fill",
               title: "Sync Delay",
               description: "Please wait 5-10 seconds after creating a task before sharing"
            )
         }
         .padding(.horizontal)
      }
      .padding(.vertical)
   }
   
   // MARK: - Shared Status Section
   
   private var sharedStatusSection: some View {
      VStack(alignment: .leading, spacing: 20) {
         // Status Header
         HStack {
            Image(systemName: "checkmark.circle.fill")
               .foregroundColor(.green)
               .font(.title3)
            
            Text("This task is shared")
               .font(.headline)
            
            Spacer()
         }
         
         Divider()
         
         // Shared by
         if let ownerName = task.shareOwnerName {
            VStack(alignment: .leading, spacing: 8) {
               Text("Shared by")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
               
               HStack {
                  Image(systemName: "person.crop.circle.fill")
                     .foregroundColor(.blue)
                     .font(.title2)
                  
                  Text(ownerName)
                     .font(.body)
               }
            }
         }
         
         // Participants
         if let participants = task.shareParticipantNames, !participants.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
               Text("Shared with (\(participants.count))")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
               
               ForEach(participants, id: \.self) { name in
                  HStack {
                     Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                     
                     Text(name)
                        .font(.body)
                     
                     Spacer()
                     
                     Text("Can Edit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                  }
                  .padding(.vertical, 4)
               }
            }
         }
         
         Divider()
         
         // Manage sharing button
         Button(action: {
            // Re-fetch share to manage it
            startSharing()
         }) {
            HStack {
               Image(systemName: "person.badge.plus")
               Text("Manage Sharing")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(10)
         }
         
         // Stop sharing button
         Button(role: .destructive, action: stopSharing) {
            HStack {
               Image(systemName: "xmark.circle")
               Text("Stop Sharing")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .foregroundColor(.red)
            .cornerRadius(10)
         }
      }
      .padding()
      .background(Color.green.opacity(0.05))
      .cornerRadius(12)
      .overlay(
         RoundedRectangle(cornerRadius: 12)
            .stroke(Color.green.opacity(0.3), lineWidth: 1)
      )
   }
   
   // MARK: - Helper Views
   
   private func infoBox(icon: String, title: String, description: String) -> some View {
      HStack(alignment: .top, spacing: 12) {
         Image(systemName: icon)
            .foregroundColor(.blue)
            .frame(width: 24, height: 24)
         
         VStack(alignment: .leading, spacing: 4) {
            Text(title)
               .font(.subheadline)
               .fontWeight(.semibold)
            
            Text(description)
               .font(.caption)
               .foregroundColor(.secondary)
         }
         
         Spacer()
      }
      .padding()
      .background(Color.secondary.opacity(0.05))
      .cornerRadius(10)
   }
   
   // MARK: - Actions
   
   private func startSharing() {
      guard let taskId = task.id, let taskName = task.name else {
         errorMessage = "Cannot share: Task has no ID or name"
         showErrorAlert = true
         return
      }
      
      print("\n" + String(repeating: "=", count: 60))
      print("🚀 USER TAPPED SHARE")
      print("📋 Task: \(taskName)")
      print("🆔 ID: \(taskId)")
      print(String(repeating: "=", count: 60) + "\n")
      
      sharingManager.shareTask(taskId, taskName: taskName) { result in
         switch result {
            case .success(let (share, _)):
               print("\n✅ Share ready! Opening native share sheet...")
               print("📱 Share URL: \(share.url?.absoluteString ?? "none")")
               showNativeShareSheet = true
               
            case .failure(let error):
               print("\n❌ Share failed!")
               print("❌ Error: \(error.localizedDescription)")
               
               if let ckError = error as? CloudKitError {
                  if ckError == .recordNotFoundAfterRetry {
                     errorMessage = "This task hasn't synced to iCloud yet. Please wait 30-60 seconds after creating a task before sharing it."
                  } else {
                     errorMessage = ckError.localizedDescription
                  }
               } else if let ckError = error as? CKError {
                  errorMessage = "CloudKit Error: \(ckError.localizedDescription)"
               } else {
                  errorMessage = error.localizedDescription
               }
               
               showErrorAlert = true
         }
      }
   }
   
   private func stopSharing() {
      guard let taskId = task.id else { return }
      
      sharingManager.stopSharing(taskId: taskId) { result in
         switch result {
            case .success():
               print("✅ Sharing stopped")
               dismiss()
               
            case .failure(let error):
               print("❌ Error stopping share: \(error)")
               errorMessage = error.localizedDescription
               showErrorAlert = true
         }
      }
   }
}

// MARK: - Preview

#Preview {
   let task = TaskItem(name: "Example Task", color: "blue", notes: "This is a sample task for testing")
   task.isShared = false
   
   return ShareTaskView(task: task)
}

#Preview("Shared Task") {
   let task = TaskItem(name: "Shared Task", color: "green", notes: "This task is already shared with others")
   task.isShared = true
   task.shareOwnerName = "John Doe"
   task.shareParticipantNames = ["Jane Smith", "Bob Johnson"]
   
   return ShareTaskView(task: task)
}
