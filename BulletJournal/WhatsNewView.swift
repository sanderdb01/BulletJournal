import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    let version: String
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("What's New")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Version \(version)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)
                    
                    // Changes list
                    VStack(alignment: .leading, spacing: 20) {
                        // Get changes for this version
                        ForEach(changesForVersion(version), id: \.title) { change in
                            ChangeRow(
                                icon: change.icon,
                                title: change.title,
                                description: change.description,
                                color: change.color
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Change Row
    
    private struct ChangeRow: View {
        let icon: String
        let title: String
        let description: String
        let color: Color
        
        var body: some View {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    // MARK: - Version Changes
    
    /// Define what's new for each version
    private func changesForVersion(_ version: String) -> [Change] {
        // You can add version-specific logic here
        // For now, return the latest changes
        return latestChanges
    }
    
    /// Latest changes - UPDATE THIS FOR EACH RELEASE
   private var latestChanges: [Change] {
   [
       Change(
           icon: "list.bullet.clipboard",
           title: "Added Features",
           description: """
               - Rename color dots in new/edit task screen
               - Added favorite and pin to notebook swipe actions
               - When searching notebook, highlight the searched words in results (already does this for day view)
               - Swipe actions to copy/duplicate notebook pages
               - Increased the line spacing in notebook pages
               - added small menu button on task rows for Mac version to replace swiping
               - share functionality added to notebook pages (iPad)
               - pin, favorites, and copy added to notebook list swipe (iPad)
               - notebook search highlighting added (iPad)
               - Removed Actions section in sidebar and added Settings (iPad)
               - Added X mark for not completed tasks (All Formats)
               - info button for notebook now works for Mac. Replaced the confirmationDialog with a Menu object
               - Share button on Mac functionality added for notebook pages (NOTE: Task Sharing is currently not implemented on Mac because it is crashing like Notebook pages was.)
               - updated Apple Watch layout and made the entire row tappable instead of just the dot
               """,
           color: .blue
       ),
       
       Change(
           icon: "ladybug.slash.fill",
           title: "Bug Fixes",
           description: """
              - Color dots are still duplicating sometimes on new devices. Added check for color dot duplicates and keep the older one.
              - Fixed issue when updating note title, dismissing the keyboard by pressing done or the minimize button does not work
              - Fixed issue: Don’t auto focus text in notebook page (unless page is blank) so that the keyboard doesn’t automatically come up
              - Fixed issue: notebook “done” and back button do the same thing. Make done dismiss the keyboard and then dismissed view
              - Fixed issue: On iPad and Mac, when in single calendar view, the go to day button does not navigate to the day view. 
              - Fixed issue: selecting notebook page scrolling bug fixed (iPad)
              - Fixed issue: notebook search bar clearing after first character bug fixed (iPad)
              - Fixed issue: Done button on settings screen navigates to most recent previous view (iPad)
              - Fixed issue: landscape mode no longer brings up the Split View for iPhone Max versions
              """,
           color: .purple
       ),
   ]
}
//    private var latestChanges_1.035: [Change] {
//        [
//            Change(
//                icon: "arrow.up.arrow.down",
//                title: "Reorder Tasks",
//                description: "- Long-press and drag to reorder your tasks within the Day View. The order is saved automatically.\n- Task object had to be updated, so first time running the new version, please wait about 20 sec after app launch in order for it to update your tasks.",
//                color: .blue
//            ),
//            Change(
//                icon: "arrow.left.arrow.right.square",
//                title: "New Sub-Menu Access for Tasks",
//                description: "- No longer tap and hold a task to bring up the sub-menu for edit and copy.\n- Slide right to left how shows delete, share, and edit. Slide from left to right will move to tomorrow and share.",
//                color: .purple
//            ),
//            Change(
//                icon: "person.2.fill",
//                title: "Share Tasks",
//                description: "Share tasks with friends and family. Collaborate in real-time with changes syncing instantly across devices.",
//                color: .green
//            ),
//            Change(
//                icon: "square.and.arrow.up",
//                title: "Share Notebook Notes",
//                description: "Can now share notes from notebook, including importing to Apple Notes",
//                color: .green
//            ),
//            Change(
//                icon: "calendar.badge.clock",
//                title: "Reminder to Finsh Tasks",
//                description: "Added a notification on the settings page that fires at a selected time if any of your day’s tasks are marked as “normal” to remind you to set all your tasks for the day. Think of how Dualingo reminds you to practice before the end of the day.",
//                color: .red
//            ),
//            Change(
//                icon: "ferry.fill",
//                title: "Anchor Tasks Added",
//                description: "Added a new option for Tasks called Anchor. When you anchor a task, at the end of the day if it is not completed, it will be automatically be added to the next day. It will continue like this until it is either deleted or completed. It also tracks how many days it has been anchored.",
//                color: .blue
//            ),
//            Change(
//                icon: "info.circle.text.page.fill",
//                title: "What's New and Feedback",
//                description: "Added an “App Info” Section in settings to view the most recent updates, and also email HarborDot to provide feedback",
//                color: .orange
//            ),
//            Change(
//                icon: "ladybug.slash.fill",
//                title: "Various Bug Fixes and Features",
//                description: "- Anchor Tasks now work correctly. Anchors will now be moved to the next day if incomplete after midnight.",
//                color: .purple
//            ),
//        ]
//    }
}

// MARK: - Change Model

private struct Change {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Preview

#Preview {
    WhatsNewView(version: "1.2.0")
}
