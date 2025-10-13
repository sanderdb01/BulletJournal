import SwiftUI
import SwiftData

enum ViewModeMac {
   case splitView
   case singleView
}

enum PaneView {
   case day
   case calendar
   case notes
   case search
}

struct MacMainView: View {
   @Environment(\.modelContext) private var modelContext
   @Query private var notes: [GeneralNote]
   
   @State private var viewMode: ViewModeMac = .splitView
   @State private var leftPaneView: PaneView = .calendar
   @State private var rightPaneView: PaneView = .day
   @State private var singlePaneView: PaneView = .calendar
   @State private var currentDate = Date()
   @State private var selectedNote: GeneralNote?
   @State private var isCreatingNote = false
   
   var body: some View {
      VStack(spacing: 0) {
         // Top toolbar
         toolbar
         
         Divider()
         
         // Main content
         if viewMode == .splitView {
            splitView
         } else {
            singleView
         }
      }
      .onChange(of: leftPaneView) { oldValue, newValue in
         singlePaneView = newValue
      }
      .onChange(of: viewMode) { oldValue, newValue in
         if newValue == .singleView {
            singlePaneView = leftPaneView
         }
      }
      .onChange(of: singlePaneView) { oldValue, newValue in
         leftPaneView = newValue
      }
   }
   
   // MARK: - Toolbar
   
   private var toolbar: some View {
      HStack {
         Spacer()
         
         Picker("", selection: $viewMode) {
            Text("Split View").tag(ViewModeMac.splitView)
            Text("Single View").tag(ViewModeMac.singleView)
         }
         .pickerStyle(.segmented)
         .frame(width: 220)
         .labelsHidden()
         
         Spacer()
      }
      .padding()
      .background(Color(NSColor.windowBackgroundColor))
   }
   
   // MARK: - Split View
   
   private var splitView: some View {
      HSplitView {
         // Left Pane
         paneContainer(
            selectedView: $leftPaneView,
            isLeftPane: true
         )
         
         // Right Pane
         paneContainer(
            selectedView: $rightPaneView,
            isLeftPane: false
         )
      }
   }
   
   // MARK: - Single View
   
   private var singleView: some View {
      paneContainer(
         selectedView: $singlePaneView,
         isLeftPane: true
      )
   }
   
   // MARK: - Pane Container
   
   @ViewBuilder
   private func paneContainer(selectedView: Binding<PaneView>, isLeftPane: Bool) -> some View {
      VStack(spacing: 0) {
         // Pane selector
         Picker("", selection: selectedView) {
            Text("Day").tag(PaneView.day)
            Text("Calendar").tag(PaneView.calendar)
            Text("Notes").tag(PaneView.notes)
            Text("Search").tag(PaneView.search)
         }
         .pickerStyle(.segmented)
         .labelsHidden()
         .padding()
         
         Divider()
         
         // Pane content
         paneContent(for: selectedView.wrappedValue, isLeftPane: isLeftPane)
      }
   }
   
   // MARK: - Pane Content
   
   @ViewBuilder
   private func paneContent(for pane: PaneView, isLeftPane: Bool) -> some View {
      switch pane {
      case .day:
         DayView(currentDate: $currentDate)
         
      case .calendar:
         CalendarView(
            currentDate: $currentDate,
            selectedTab: .constant(1),
            displayedMonth: .constant(Date()),
            onDateSelected: { date in
               currentDate = date
               if viewMode == .splitView {
                  if isLeftPane {
                     rightPaneView = .day
                  } else {
                     leftPaneView = .day
                  }
               } else {
                  singlePaneView = .day
               }
            }
         )
         
      case .notes:
         notesView(isLeftPane: isLeftPane)
         
      case .search:
         SearchView(
            currentDate: $currentDate,
            selectedTab: .constant(2)
         )
      }
   }
   
   // MARK: - Notes View
   
   @ViewBuilder
   private func notesView(isLeftPane: Bool) -> some View {
      HSplitView {
         // Notes sidebar
         notesSidebar
            .frame(minWidth: 200, idealWidth: 250, maxWidth: 350)
         
         // Notes content
         Group {
            if let note = selectedNote {
               GeneralNoteEditorView(
                  note: note,
                  onBack: {
                     selectedNote = nil
                  }
               )
            } else if isCreatingNote {
               if let newNote = notes.first(where: { $0.title == nil || $0.title?.isEmpty == true }) {
                  GeneralNoteEditorView(
                     note: newNote,
                     onBack: {
                        isCreatingNote = false
                        selectedNote = nil
                     }
                  )
               }
            } else {
               emptyNotesState
            }
         }
      }
   }
   
   // MARK: - Notes Sidebar
   
   private var notesSidebar: some View {
      VStack(spacing: 0) {
         // Header
         HStack {
            Text("Notes")
               .font(.headline)
            
            Spacer()
            
            Button(action: createNewNote) {
               Image(systemName: "plus")
            }
            .buttonStyle(.plain)
         }
         .padding()
         
         Divider()
         
         // Notes list
         if notes.isEmpty {
            emptyNotesListState
         } else {
            notesList
         }
      }
      .background(Color(NSColor.controlBackgroundColor))
   }
   
   private var notesList: some View {
      ScrollView {
         LazyVStack(spacing: 0) {
            // Pinned notes
            let pinnedNotes = notes.filter { $0.isPinned }.sorted { $0.modifiedAt > $1.modifiedAt }
            if !pinnedNotes.isEmpty {
               Section {
                  ForEach(pinnedNotes) { note in
                     noteRow(for: note)
                  }
               } header: {
                  HStack {
                     Image(systemName: "pin.fill")
                        .font(.caption)
                     Text("Pinned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                     Spacer()
                  }
                  .padding(.horizontal)
                  .padding(.top, 8)
                  .padding(.bottom, 4)
               }
               
               Divider()
                  .padding(.vertical, 8)
            }
            
            // Regular notes
            let regularNotes = notes.filter { !$0.isPinned }.sorted { $0.modifiedAt > $1.modifiedAt }
            ForEach(regularNotes) { note in
               noteRow(for: note)
            }
         }
      }
   }
   
   @ViewBuilder
   private func noteRow(for note: GeneralNote) -> some View {
      Button(action: {
         selectedNote = note
         isCreatingNote = false
      }) {
         HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
               HStack {
                  Text(note.title ?? "Untitled")
                     .font(.headline)
                     .lineLimit(1)
                  
                  if note.isFavorite {
                     Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                  }
               }
               
               Text(note.content.prefix(100))
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .lineLimit(2)
               
               Text(note.modifiedAt, style: .relative)
                  .font(.caption2)
                  .foregroundColor(.secondary)
            }
            
            Spacer()
         }
         .padding()
         .background(selectedNote?.id == note.id ? Color.accentColor.opacity(0.1) : Color.clear)
         .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
   }
   
   private var emptyNotesListState: some View {
      VStack(spacing: 12) {
         Image(systemName: "note.text")
            .font(.system(size: 32))
            .foregroundColor(.secondary)
         
         Text("No notes yet")
            .font(.subheadline)
            .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
   }
   
   private var emptyNotesState: some View {
      VStack(spacing: 16) {
         Image(systemName: "note.text")
            .font(.system(size: 48))
            .foregroundColor(.secondary)
         
         Text("Select a note to view")
            .font(.title2)
            .foregroundColor(.secondary)
         
         Text("or create a new one")
            .font(.subheadline)
            .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
   }
   
   // MARK: - Helper Methods
   
   private func createNewNote() {
      let newNote = GeneralNote()
      newNote.content = """
      # Note Title
      
      Start typing your note here...
      
      ## Formatting Tips
      - Use **bold** for emphasis
      - Use *italic* for subtle emphasis
      - Create lists with - or 1.
      - Add [links](https://example.com)
      """
      
      modelContext.insert(newNote)
      try? modelContext.save()
      
      selectedNote = newNote
      isCreatingNote = true
   }
}

#Preview {
   MacMainView()
      .modelContainer(for: [DayLog.self, TaskItem.self, Tag.self, GeneralNote.self], inMemory: true)
      .frame(width: 1200, height: 800)
}
