import SwiftUI
import SwiftData

struct TagSettingsView: View {
   @Environment(\.modelContext) private var modelContext
   @Environment(\.dismiss) private var dismiss
   @Query private var allTags: [Tag]
   
   @State private var editingTag: Tag?
   @State private var newTagName = ""
   @State private var showingResetAlert = false
   
   var colorTags: [Tag] {
      allTags.filter { $0.isPrimary == true }.sorted { ($0.name ?? "") < ($1.name ?? "") }
   }
   
   var customTags: [Tag] {
      allTags.filter { $0.isPrimary == false }.sorted { ($0.order ?? 0) < ($1.order ?? 0) }
   }
   
   var body: some View {
      NavigationStack {
         Form {
            // Color Tags Section
            Section {
               ForEach(colorTags, id: \.id) { tag in
                  HStack {
                     Circle()
//                        .fill(Color.fromString(tag.name?.lowercased() ?? "gray"))
                        .fill(Color.fromString(tag.returnColorString()))
                        .frame(width: 24, height: 24)
                     
                     Text(tag.name ?? "")
                     
                     Spacer()
                     
                     Button("Rename") {
                        editingTag = tag
                        newTagName = tag.name ?? ""
                     }
                     .font(.caption)
                  }
               }
            } header: {
               Text("Color Tags")
            } footer: {
               Text("Color tags are used as the primary tag for each task. You can rename them but not delete them.")
            }
            
            // Custom Tags Section
            Section {
               if customTags.isEmpty {
                  Text("No custom tags yet. Create them when adding tasks.")
                     .foregroundColor(.secondary)
                     .font(.caption)
               } else {
                  ForEach(customTags, id: \.id) { tag in
                     HStack {
                        Text(tag.name ?? "")
                        
                        Spacer()
                        
                        Button("Rename") {
                           editingTag = tag
                           newTagName = tag.name ?? ""
                        }
                        .font(.caption)
                     }
                  }
                  .onDelete(perform: deleteCustomTags)
               }
            } header: {
               Text("Custom Tags")
            } footer: {
               Text("Custom tags can be used to organize tasks. You can add multiple custom tags to each task. Swipe to delete.")
            }
            
            // Tag Statistics
            Section {
               HStack {
                  Text("Total Color Tags")
                  Spacer()
                  Text("\(colorTags.count)")
                     .foregroundColor(colorTags.count == 8 ? .secondary : .red)
                     .bold(colorTags.count != 8)
               }
               
               HStack {
                  Text("Total Custom Tags")
                  Spacer()
                  Text("\(customTags.count)")
                     .foregroundColor(.secondary)
               }
               
               HStack {
                  Text("Total Tags")
                  Spacer()
                  Text("\(allTags.count)")
                     .foregroundColor(.secondary)
               }
               
               if colorTags.count != 8 {
                  VStack(alignment: .leading, spacing: 4) {
                     Text("⚠️ Warning: Color tag count is incorrect!")
                        .font(.caption)
                        .foregroundColor(.red)
                     Text("Expected: 8, Found: \(colorTags.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                  }
               }
            } header: {
               Text("Statistics")
            }
            
            // Reset Section
            Section {
               Button(role: .destructive) {
                  showingResetAlert = true
               } label: {
                  HStack {
                     Image(systemName: "arrow.counterclockwise.circle.fill")
                     Text("Reset All Tags")
                  }
               }
            } header: {
               Text("Advanced")
            } footer: {
               Text("This will delete ALL tags (including custom tags) and recreate the 8 default color tags. Use this if you have duplicate color tags from CloudKit sync. This action cannot be undone.")
            }
         }
         .navigationTitle("Manage Tags")
#if os(iOS)
         .navigationBarTitleDisplayMode(.inline)
#endif
         .toolbar {
            ToolbarItem(placement: .confirmationAction) {
               Button("Done") {
                  dismiss()
               }
            }
         }
         .sheet(item: $editingTag) { tag in
            RenameTagSheet(
               tag: tag,
               newName: $newTagName,
               isPresented: Binding(
                  get: { editingTag != nil },
                  set: { if !$0 { editingTag = nil } }
               ),
               onSave: {
                  TagManager.renameTag(tag, newName: newTagName, in: modelContext)
                  editingTag = nil
                  newTagName = ""
               }
            )
         }
         .alert("Reset All Tags?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
               TagManager.resetAllTags(in: modelContext)
            }
         } message: {
            Text("This will delete ALL tags and recreate the 8 default color tags. Your tasks will lose their tag associations. This cannot be undone.")
         }
      }
   }
   
   private func deleteCustomTags(at offsets: IndexSet) {
      for index in offsets {
         let tag = customTags[index]
         TagManager.deleteCustomTag(tag, from: modelContext)
      }
   }
}

// MARK: - Rename Tag Sheet
struct RenameTagSheet: View {
   let tag: Tag
   @Binding var newName: String
   @Binding var isPresented: Bool
   
   @FocusState private var isTitleFocused: Bool
   
   let onSave: () -> Void
   
   var body: some View {
      NavigationView {
         Form {
            Section {
               if tag.isPrimary == true {
                  HStack {
                     Text("Current Color:")
                     Spacer()
                     Circle()
//                        .fill(Color.fromString(tag.name?.lowercased() ?? "gray"))
                        .fill(Color.fromString(tag.returnColorString()))
                        .frame(width: 24, height: 24)
                  }
               }
               
               TextField("Tag Name", text: $newName)
                  .focused($isTitleFocused)
                  .clearButton(text: $newName, focus: $isTitleFocused)
#if os(iOS)
                  .autocapitalization(.words)
#endif
            }
            
            Section {
               if tag.isPrimary == true {
                  Text("This is a color tag. You can rename it to anything, and it will keep its color.")
                     .font(.caption)
                     .foregroundColor(.secondary)
               } else {
                  Text("Renaming this tag will update it for all tasks that use it.")
                     .font(.caption)
                     .foregroundColor(.secondary)
               }
            }
         }
         .navigationTitle("Rename Tag")
#if os(iOS)
         .navigationBarTitleDisplayMode(.inline)
#endif
         .toolbar {
            ToolbarItem(placement: .cancellationAction) {
               Button("Cancel") {
                  isPresented = false
               }
            }
            
            ToolbarItem(placement: .confirmationAction) {
               Button("Save") {
                  onSave()
               }
               .disabled(newName.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty)
            }
         }
      }
   }
}

#Preview {
   let config = ModelConfiguration(isStoredInMemoryOnly: true)
   let container = try! ModelContainer(for: Tag.self, TaskItem.self, configurations: config)
   let context = container.mainContext
   
   // Create sample tags
   TagManager.createDefaultTags(in: context)
   _ = TagManager.createCustomTag(name: "Work", in: context)
   _ = TagManager.createCustomTag(name: "Personal", in: context)
   _ = TagManager.createCustomTag(name: "Urgent", in: context)
   
   return TagSettingsView()
      .modelContainer(container)
}
