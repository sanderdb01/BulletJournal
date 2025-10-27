#if !os(macOS)
import SwiftUI
import SwiftData

struct iOSNotesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GeneralNote.modifiedAt, order: .reverse) private var allNotes: [GeneralNote]
    
    @State private var searchText = ""
    @State private var showingNewNoteSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if filteredNotes.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
            .navigationTitle("Notebook")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewNoteSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search Notebook")
            .sheet(isPresented: $showingNewNoteSheet) {
                iOSNewNoteSheet(modelContext: modelContext)
            }
        }
    }
    
    // MARK: - Filtered Notes
    
    private var filteredNotes: [GeneralNote] {
        if searchText.isEmpty {
            return allNotes
        }
        return allNotes.filter { note in
            let title = note.title ?? ""
            let content = note.content ?? ""
            return title.localizedCaseInsensitiveContains(searchText) ||
                   content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var pinnedNotes: [GeneralNote] {
        filteredNotes.filter { ($0.isPinned ?? false) == true }
    }
    
    private var unpinnedNotes: [GeneralNote] {
        filteredNotes.filter { ($0.isPinned ?? false) == false }
    }
    
    // MARK: - Notes List
    
    private var notesList: some View {
        List {
            if !pinnedNotes.isEmpty {
                Section("Pinned") {
                    ForEach(pinnedNotes) { note in
                        NavigationLink(value: note) {
                            NoteRowView(note: note)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteNote(note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            if !unpinnedNotes.isEmpty {
                Section(pinnedNotes.isEmpty ? "All Pages" : "Pages") {
                    ForEach(unpinnedNotes) { note in
                        NavigationLink(value: note) {
                            NoteRowView(note: note)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteNote(note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationDestination(for: GeneralNote.self) { note in
            iOSNoteEditorView(note: note)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Pages")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap + to create your first page")
                .foregroundStyle(.secondary)
            
            Button {
                showingNewNoteSheet = true
            } label: {
                Label("New Page", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func deleteNote(_ note: GeneralNote) {
        withAnimation {
            modelContext.delete(note)
            try? modelContext.save()
        }
    }
}

// MARK: - Note Row View

struct NoteRowView: View {
    let note: GeneralNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(note.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if (note.isFavorite ?? false) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }
            
            Text(note.previewText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack {
                if let modifiedAt = note.modifiedAt {
                    Text(modifiedAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                if let primaryTag = note.primaryTag {
                    TagBadge(tag: primaryTag, size: .small)
                }
                
                let customTags = note.customTags ?? []
                if !customTags.isEmpty {
                    Text("+\(customTags.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tag Badge

struct TagBadge: View {
    let tag: Tag
    let size: BadgeSize
    
    enum BadgeSize {
        case small, medium, large
        
        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            }
        }
    }
    
    var body: some View {
        Text(tag.name ?? "")
            .font(size.font)
            .foregroundStyle(.white)
            .padding(size.padding)
            .background(tagColor)
            .clipShape(Capsule())
    }
    
    private var tagColor: Color {
        let colorString = tag.returnColorString()
        switch colorString {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "gray": return .gray
        default: return .gray
        }
    }
}

#endif
