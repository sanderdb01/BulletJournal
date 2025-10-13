#if os(macOS)
import SwiftUI
import SwiftData

struct NoteRowView: View {
   let note: GeneralNote
   let isSelected: Bool
   let onTap: () -> Void
   
   var body: some View {
      Button(action: onTap) {
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
         .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
         .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
   }
}
#endif
