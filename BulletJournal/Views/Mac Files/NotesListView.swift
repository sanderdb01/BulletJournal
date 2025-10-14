//#if os(macOS)
//import SwiftUI
//import SwiftData
//
//struct NotesListView: View {
//   @Environment(\.modelContext) private var modelContext
//   @Query(sort: \GeneralNote.modifiedAt, order: .reverse) private var allNotes: [GeneralNote]
//   
//   var onNoteSelected: (UUID) -> Void
//   @Binding var selectedNoteId: UUID?
//   let isLeftPane: Bool
//   
//   @State private var searchText = ""
//   @State private var showingNewNote = false
//   @State private var filterOption: FilterOption = .all
//   
//   enum FilterOption: String, CaseIterable {
//      case all = "All"
//      case pinned = "Pinned"
//      case favorites = "Favorites"
//   }
//   
//   private var filteredNotes: [GeneralNote] {
//      var notes = allNotes
//      
//      // Apply filter
//      switch filterOption {
//         case .all:
//            break
//         case .pinned:
//            notes = notes.filter { $0.isPinned ?? false}
//         case .favorites:
//            notes = notes.filter { $0.isFavorite ?? false}
//      }
//      
//      // Apply search
//      if !searchText.isEmpty {
//         notes = notes.filter { note in
//            note.displayTitle.localizedCaseInsensitiveContains(searchText) ||
//            (note.content ?? "").localizedCaseInsensitiveContains(searchText)
//         }
//      }
//      
//      return notes
//   }
//   
//   var body: some View {
//      VStack(spacing: 0) {
//         // Header with new note button
//         HStack {
//            Text("Notes")
//               .font(.title2)
//               .fontWeight(.semibold)
//            
//            Spacer()
//            
//            Button(action: { showingNewNote = true }) {
//               Image(systemName: "plus.circle.fill")
//                  .font(.title2)
//            }
//            .buttonStyle(.plain)
//            .help("New Note")
//         }
//         .padding()
//         
//         Divider()
//         
//         // Search bar
//         searchBar
//         
//         Divider()
//         
//         // Filter picker
//         Picker("Filter", selection: $filterOption) {
//            ForEach(FilterOption.allCases, id: \.self) { option in
//               Text(option.rawValue).tag(option)
//            }
//         }
//         .pickerStyle(.segmented)
//         .padding(.horizontal, 12)
//         .padding(.vertical, 8)
//         
//         Divider()
//         
//         // Notes list
//         if filteredNotes.isEmpty {
//            emptyState
//         } else {
//            notesList
//         }
//      }
//      .sheet(isPresented: $showingNewNote) {
//         NewNoteSheet(isPresented: $showingNewNote, onCreate: { note in
//            if let noteId = note.id {
//               selectedNoteId = noteId
//               onNoteSelected(noteId)
//            }
//         })
//      }
//   }
//   
//   // MARK: - Search Bar
//   
//   private var searchBar: some View {
//      HStack {
//         Image(systemName: "magnifyingglass")
//            .foregroundColor(.secondary)
//         
//         TextField("Search notes...", text: $searchText)
//            .textFieldStyle(.plain)
//         
//         if !searchText.isEmpty {
//            Button(action: { searchText = "" }) {
//               Image(systemName: "xmark.circle.fill")
//                  .foregroundColor(.secondary)
//            }
//            .buttonStyle(.plain)
//         }
//      }
//      .padding(8)
//      .background(Color(nsColor: .controlBackgroundColor))
//      .cornerRadius(8)
//      .padding(.horizontal, 12)
//      .padding(.vertical, 8)
//   }
//   
//   // MARK: - Notes List
//   
//   private var notesList: some View {
//      List(filteredNotes, id: \.id, selection: $selectedNoteId) { note in
//         NoteRowView(note: note, isSelected: (selectedNoteId == note.id), onTap: {})
//            .tag(note.id)
//            .contentShape(Rectangle())
//            .onTapGesture {
//               if let noteId = note.id {
//                  selectedNoteId = noteId
//                  onNoteSelected(noteId)
//               }
//            }
//            .contextMenu {
//               Button(action: { note.togglePin() }) {
//                  Label((note.isPinned ?? false) ? "Unpin" : "Pin", systemImage: (note.isPinned ?? false)  ? "pin.slash" : "pin")
//               }
//               
//               Button(action: { note.toggleFavorite() }) {
//                  Label((note.isFavorite ?? false) ? "Remove from Favorites" : "Add to Favorites",
//                        systemImage: (note.isFavorite ?? false) ? "star.slash" : "star")
//               }
//               
//               Divider()
//               
//               Button(role: .destructive, action: {
//                  GeneralNoteManager.deleteNote(note, from: modelContext)
//                  if selectedNoteId == note.id {
//                     selectedNoteId = nil
//                  }
//               }) {
//                  Label("Delete", systemImage: "trash")
//               }
//            }
//      }
//      .listStyle(.sidebar)
//   }
//   
//   // MARK: - Empty State
//   
//   private var emptyState: some View {
//      VStack(spacing: 16) {
//         Image(systemName: "note.text")
//            .font(.system(size: 48))
//            .foregroundColor(.secondary)
//         
//         Text(searchText.isEmpty ? "No Notes" : "No Results")
//            .font(.title2)
//            .fontWeight(.semibold)
//         
//         Text(searchText.isEmpty ? "Create your first note" : "No notes match '\(searchText)'")
//            .foregroundColor(.secondary)
//            .multilineTextAlignment(.center)
//      }
//      .frame(maxWidth: .infinity, maxHeight: .infinity)
//   }
//}
//
//#Preview {
//   let config = ModelConfiguration(isStoredInMemoryOnly: true)
//   let container = try! ModelContainer(for: GeneralNote.self, Tag.self, configurations: config)
//   let context = container.mainContext
//   
//   // Create sample notes
//   let note1 = GeneralNoteManager.createNote(
//      title: "Meeting Notes",
//      content: "Discussed project timeline and deliverables. Need to follow up on budget approval.",
//      in: context
//   )
//   note1.isPinned = true
//   
//   let note2 = GeneralNoteManager.createNote(
//      title: "Ideas",
//      content: "New feature ideas for the app: 1) Markdown support 2) Export to PDF 3) Collaboration",
//      in: context
//   )
//   note2.isFavorite = true
//   
//   return NotesListView(
//      onNoteSelected: { _ in },
//      selectedNoteId: .constant(nil),
//      isLeftPane: true
//   )
//   .modelContainer(container)
//   .frame(width: 300, height: 600)
//}
//#endif
