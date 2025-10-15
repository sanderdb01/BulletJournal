import SwiftUI
import SwiftData

struct TagPicker: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allTags: [Tag]
    
    @Binding var selectedPrimaryTag: Tag?
    @Binding var selectedCustomTags: [Tag]
    
    @State private var showingAddTag = false
    @State private var newTagName = ""
    
    var colorTags: [Tag] {
        allTags.filter { $0.isPrimary == true }.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    var customTags: [Tag] {
        allTags.filter { $0.isPrimary == false }.sorted { ($0.order ?? 0) < ($1.order ?? 0) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Primary Color Tag Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Color Tag")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                   Spacer()
                           .frame(height: 4)
                    HStack(spacing: 12) {
                        ForEach(colorTags, id: \.id) { tag in
                            ColorTagButton(
                                tag: tag,
                                isSelected: selectedPrimaryTag?.id == tag.id
                            ) {
                                selectedPrimaryTag = tag
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            Divider()
            
            // Custom Tags Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Custom Tags")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { showingAddTag = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                if customTags.isEmpty {
                    Text("No custom tags yet. Tap + to create one.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(customTags, id: \.id) { tag in
                            CustomTagChip(
                                tag: tag,
                                isSelected: selectedCustomTags.contains(where: { $0.id == tag.id })
                            ) {
                                toggleCustomTag(tag)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTag) {
            AddCustomTagSheet(
                newTagName: $newTagName,
                isPresented: $showingAddTag,
                onSave: {
                    if !newTagName.trimmingCharacters(in: .whitespaces).isEmpty {
                        if let newTag = TagManager.createCustomTag(name: newTagName, in: modelContext) {
                            selectedCustomTags.append(newTag)
                        }
                        newTagName = ""
                    }
                }
            )
        }
    }
    
    private func toggleCustomTag(_ tag: Tag) {
        if let index = selectedCustomTags.firstIndex(where: { $0.id == tag.id }) {
            selectedCustomTags.remove(at: index)
        } else {
            selectedCustomTags.append(tag)
        }
    }
}

// MARK: - Color Tag Button
struct ColorTagButton: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
//                    .fill(Color.fromString(tag.name?.lowercased() ?? "gray"))
                  .fill(Color.fromString(tag.returnColorString()))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(Color.primary, lineWidth: isSelected ? 3 : 0)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                            .opacity(isSelected ? 1 : 0)
                    )
                
                Text(tag.name ?? "")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Tag Chip
struct CustomTagChip: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(tag.name ?? "")
                    .font(.subheadline)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Custom Tag Sheet
struct AddCustomTagSheet: View {
    @Binding var newTagName: String
    @Binding var isPresented: Bool
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Tag Name", text: $newTagName)
                   #if os(iOS)
                        .autocapitalization(.words)
                   #endif
                }
                
                Section {
                    Text("Custom tags help you organize and filter your tasks. Examples: Work, Urgent, Meeting, Project A")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Tag")
           #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
           #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                        newTagName = ""
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave()
                        isPresented = false
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Flow Layout (for wrapping tags)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    @Previewable @State var selectedPrimary: Tag? = nil
    @Previewable @State var selectedCustom: [Tag] = []
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Tag.self, TaskItem.self, configurations: config)
    
    // Create sample tags
    let context = container.mainContext
    TagManager.createDefaultTags(in: context)
    _ = TagManager.createCustomTag(name: "Work", in: context)
    _ = TagManager.createCustomTag(name: "Urgent", in: context)
    
    return TagPicker(
        selectedPrimaryTag: $selectedPrimary,
        selectedCustomTags: $selectedCustom
    )
    .modelContainer(container)
    .padding()
}
