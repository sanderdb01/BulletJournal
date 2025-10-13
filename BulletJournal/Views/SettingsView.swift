import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [AppSettings]
    @Query private var dayLogs: [DayLog]
    
    @State private var showingClearDataAlert = false
    @State private var showingExportSuccess = false
    @State private var showingExportError = false
    @State private var showingImportPicker = false
    @State private var showingImportError = false
    @State private var showingExportShare = false
    @State private var importErrorMessage = ""
    @State private var exportErrorMessage = ""
    @State private var exportFileURL: URL?
    @State private var isExporting = false
    @State private var isImporting = false
   @State private var showingResetTagsAlert = false
    
    private var currentSettings: AppSettings {
        if let existing = settings.first {
            return existing
        } else {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            return newSettings
        }
    }
    
    private var totalTasksCount: Int {
        dayLogs.reduce(0) { $0 + ($1.tasks?.count ?? 0) }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Date Format Section
                Section {
                    Picker("Date Format", selection: Binding(
                        get: { currentSettings.dateFormat ?? .numeric },
                        set: { newValue in
                            currentSettings.dateFormat = newValue
                            try? modelContext.save()
                        }
                    )) {
                        Text("MM/DD/YYYY").tag(DateFormatStyle.numeric)
                        Text("Month DD, YYYY").tag(DateFormatStyle.written)
                    }
                } header: {
                    Text("Display")
                } footer: {
                    Text("Choose how dates are displayed throughout the app")
                }
                
                // NEW: Tags Section
                Section {
                    NavigationLink(destination: TagSettingsView()) {
                        HStack {
                            Label("Manage Tags", systemImage: "tag.fill")
                            Spacer()
                        }
                    }
                } header: {
                    Text("Tags")
                } footer: {
                    Text("Customize color tags and manage custom tags for organizing your tasks.")
                }
                
                // Data Management Section
                Section {
                    // Export Button
                    Button(action: exportData) {
                        HStack {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                            Spacer()
                            if isExporting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isExporting || dayLogs.isEmpty)
                    
                    // Import Button
                    Button(action: { showingImportPicker = true }) {
                        HStack {
                            Label("Import Data", systemImage: "square.and.arrow.down")
                            Spacer()
                            if isImporting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isImporting)
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Export your tasks and logs as JSON or import from a previous export. Current data will be merged with imported data.")
                }
                
                // Danger Zone
                Section {
                    Button(role: .destructive, action: { showingClearDataAlert = true }) {
                        Label("Clear All Data", systemImage: "trash")
                    }
                   Button(role: .destructive, action: { showingResetTagsAlert = true }) {
                           Label("Reset Color Tags", systemImage: "arrow.counterclockwise")
                       }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This will permanently delete all tasks and logs. This action cannot be undone.")
                }
                
                // App Info
                Section {
                    HStack {
                        Text("Total Days")
                        Spacer()
                        Text("\(dayLogs.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Tasks")
                        Spacer()
                        Text("\(totalTasksCount)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Statistics")
                }
            }
            .navigationTitle("Settings")
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
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("Are you sure you want to delete all tasks and logs? This cannot be undone.")
            }
            .alert("Export Successful", isPresented: $showingExportSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your data has been exported successfully.")
            }
            .alert("Export Error", isPresented: $showingExportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(exportErrorMessage)
            }
            .alert("Import Error", isPresented: $showingImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importErrorMessage)
            }
            .alert("Reset Color Tags", isPresented: $showingResetTagsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset & Restart", role: .destructive) {
                    resetColorTags()
                }
            } message: {
                Text("This will delete all color and custom tags. The app will restart and recreate the 8 default color tags. Any custom tags will be lost.")
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
            .fileExporter(
                isPresented: $showingExportShare,
                document: exportFileURL.map { JSONFileDocument(fileURL: $0) },
                contentType: .json,
                defaultFilename: "HarborDot_Export_\(dateFormatterForFilename.string(from: Date())).json"
            ) { result in
                switch result {
                case .success:
                    showingExportSuccess = true
                case .failure(let error):
                    exportErrorMessage = error.localizedDescription
                    showingExportError = true
                }
                isExporting = false
            }
        }
    }
    
    // MARK: - Export Data (UPDATED for Tags)
    
    private func exportData() {
        isExporting = true
        
        do {
            let exportData = createExportData()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(exportData)
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("HarborDot_Export_\(dateFormatterForFilename.string(from: Date())).json")
            
            try data.write(to: tempURL)
            
            exportFileURL = tempURL
            showingExportShare = true
        } catch {
            exportErrorMessage = error.localizedDescription
            showingExportError = true
            isExporting = false
        }
    }
    
    // UPDATED: Include tags in export
    private func createExportData() -> ExportData {
        var exportDayLogs: [ExportDayLog] = []
        var exportTags: [ExportTag] = []
        
        // Export all tags
        let descriptor = FetchDescriptor<Tag>()
        do {
            let allTags = try modelContext.fetch(descriptor)
            for tag in allTags {
                guard let id = tag.id,
                      let name = tag.name,
                      let isPrimary = tag.isPrimary,
                      let order = tag.order else { continue }
                
                let exportTag = ExportTag(
                    id: id,
                    name: name,
                    isPrimary: isPrimary,
                    order: order
                )
                exportTags.append(exportTag)
            }
        } catch {
            print("Error fetching tags for export: \(error)")
        }
        
        // Export day logs and tasks
        for dayLog in dayLogs {
            guard let dayLogId = dayLog.id,
                  let date = dayLog.date else { continue }
            
            let exportTasks = (dayLog.tasks ?? []).compactMap { task -> ExportTask? in
                guard let id = task.id,
                      let name = task.name,
                      let color = task.color,
                      let notes = task.notes,
                      let status = task.status,
                      let createdAt = task.createdAt,
                      let modifiedAt = task.modifiedAt else { return nil }
                
                return ExportTask(
                    id: id,
                    name: name,
                    color: color,
                    notes: notes,
                    status: status.rawValue,
                    createdAt: createdAt,
                    modifiedAt: modifiedAt,
                    reminderTime: task.reminderTime,
                    notificationId: task.notificationId,
                    isRecurring: task.isRecurring,
                    recurrenceRule: task.recurrenceRule,
                    recurrenceEndDate: task.recurrenceEndDate,
                    isTemplate: task.isTemplate,
                    sourceTemplateId: task.sourceTemplateId,
                    isFavorite: task.isFavorite,
                    isPinned: task.isPinned,
                    category: task.category?.rawValue,
                    primaryTagId: task.primaryTag?.id,
                    customTagIds: task.customTags.compactMap { $0.id }
                )
            }
            
            let exportDayLog = ExportDayLog(
                id: dayLogId,
                date: date,
                notes: dayLog.notes ?? "",
                tasks: exportTasks
            )
            
            exportDayLogs.append(exportDayLog)
        }
        
        return ExportData(
            version: 2,  // Incremented version for tags support
            exportDate: Date(),
            dayLogs: exportDayLogs,
            tags: exportTags
        )
    }
    
    // MARK: - Import Data (UPDATED for Tags)
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importData(from: url)
        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showingImportError = true
        }
    }
    
    private func importData(from url: URL) {
        isImporting = true
        
        defer {
            isImporting = false
        }
        
        do {
            guard url.startAccessingSecurityScopedResource() else {
                throw ImportError.accessDenied
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let exportData = try decoder.decode(ExportData.self, from: data)
            
            // UPDATED: First, import all tags
            var tagMapping: [UUID: Tag] = [:]
            
            for exportTag in exportData.tags {
                // Check if tag already exists
                let tagId = exportTag.id
                let descriptor = FetchDescriptor<Tag>(
                    predicate: #Predicate { tag in
                        tag.id == tagId
                    }
                )
                
                let existingTags = try? modelContext.fetch(descriptor)
                
                if let existingTag = existingTags?.first {
                    // Tag exists, update it
                    existingTag.name = exportTag.name
                    existingTag.isPrimary = exportTag.isPrimary
                    existingTag.order = exportTag.order
                    tagMapping[exportTag.id] = existingTag
                } else {
                    // Create new tag
                    let newTag = Tag(
                        name: exportTag.name,
                        isPrimary: exportTag.isPrimary,
                        order: exportTag.order
                    )
                    newTag.id = exportTag.id
                    modelContext.insert(newTag)
                    tagMapping[exportTag.id] = newTag
                }
            }
            
            try? modelContext.save()
            
            // Then import day logs and tasks
            for exportDayLog in exportData.dayLogs {
                if let existingDayLog = dayLogs.first(where: { $0.id == exportDayLog.id }) {
                    // Merge tasks with existing day log
                    let existingTaskIDs = Set((existingDayLog.tasks ?? []).compactMap { $0.id })
                    
                    for exportTask in exportDayLog.tasks {
                        if !existingTaskIDs.contains(exportTask.id) {
                            let newTask = createTaskFromExport(exportTask, tagMapping: tagMapping)
                            existingDayLog.addTask(newTask)
                            modelContext.insert(newTask)
                        }
                    }
                    
                    // Merge notes
                    if !exportDayLog.notes.isEmpty && (existingDayLog.notes?.isEmpty ?? true) {
                        existingDayLog.notes = exportDayLog.notes
                    }
                } else {
                    // Create new day log
                    let newDayLog = DayLog(date: exportDayLog.date, notes: exportDayLog.notes)
                    newDayLog.id = exportDayLog.id
                    
                    for exportTask in exportDayLog.tasks {
                        let newTask = createTaskFromExport(exportTask, tagMapping: tagMapping)
                        newDayLog.addTask(newTask)
                        modelContext.insert(newTask)
                    }
                    
                    modelContext.insert(newDayLog)
                }
            }
            
            try? modelContext.save()
            
        } catch {
            importErrorMessage = error.localizedDescription
            showingImportError = true
        }
    }
    
    // Helper to create task from export with tag restoration
    private func createTaskFromExport(_ exportTask: ExportTask, tagMapping: [UUID: Tag]) -> TaskItem {
        let newTask = TaskItem(
            name: exportTask.name,
            color: exportTask.color,
            notes: exportTask.notes,
            status: TaskStatus(rawValue: exportTask.status) ?? .normal
        )
        newTask.id = exportTask.id
        newTask.createdAt = exportTask.createdAt
        newTask.modifiedAt = exportTask.modifiedAt
        newTask.reminderTime = exportTask.reminderTime
        newTask.notificationId = exportTask.notificationId
        newTask.isRecurring = exportTask.isRecurring
        newTask.recurrenceRule = exportTask.recurrenceRule
        newTask.recurrenceEndDate = exportTask.recurrenceEndDate
        newTask.isTemplate = exportTask.isTemplate
        newTask.sourceTemplateId = exportTask.sourceTemplateId
        newTask.isFavorite = exportTask.isFavorite
        newTask.isPinned = exportTask.isPinned
        if let categoryString = exportTask.category {
            newTask.category = TaskCategory(rawValue: categoryString)
        }
        
        // UPDATED: Restore tag relationships
        if let primaryTagId = exportTask.primaryTagId,
           let primaryTag = tagMapping[primaryTagId] {
            newTask.setPrimaryTag(primaryTag)
        }
        
        if let customTagIds = exportTask.customTagIds {
            for tagId in customTagIds {
                if let customTag = tagMapping[tagId] {
                    newTask.addCustomTag(customTag)
                }
            }
        }
        
        return newTask
    }
    
    // MARK: - Clear All Data
    
    private func clearAllData() {
        for dayLog in dayLogs {
            modelContext.delete(dayLog)
        }
        try? modelContext.save()
    }
    
    // Date formatter for export filename
    private var dateFormatterForFilename: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }
   
   private func resetColorTags() {
       // Delete all tags from database
       let allTagsDescriptor = FetchDescriptor<Tag>()
       
       do {
           let allTags = try modelContext.fetch(allTagsDescriptor)
           
           print("🗑️ Deleting all \(allTags.count) tags")
           
           for tag in allTags {
               modelContext.delete(tag)
           }
           
           try modelContext.save()
           
           // Clear the flag so defaults will be recreated
           UserDefaults.standard.removeObject(forKey: "HasCreatedColorTags")
           
           print("✅ Tags deleted and flag cleared")
           
           // Force app restart
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
               exit(0)
           }
       } catch {
           print("❌ Error resetting tags: \(error)")
       }
   }
}

// MARK: - JSON File Document

struct JSONFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        try data.write(to: tempURL)
        self.fileURL = tempURL
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try Data(contentsOf: fileURL)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Export Data Structures (UPDATED for Tags)

struct ExportData: Codable {
    let version: Int
    let exportDate: Date
    let dayLogs: [ExportDayLog]
    let tags: [ExportTag]  // NEW
}

struct ExportDayLog: Codable {
    let id: UUID
    let date: Date
    let notes: String
    let tasks: [ExportTask]
}

struct ExportTask: Codable {
    let id: UUID
    let name: String
    let color: String
    let notes: String
    let status: String
    let createdAt: Date
    let modifiedAt: Date
    let reminderTime: Date?
    let notificationId: String?
    let isRecurring: Bool?
    let recurrenceRule: String?
    let recurrenceEndDate: Date?
    let isTemplate: Bool?
    let sourceTemplateId: UUID?
    let isFavorite: Bool?
    let isPinned: Bool?
    let category: String?
    let primaryTagId: UUID?      // NEW
    let customTagIds: [UUID]?    // NEW
}

struct ExportTag: Codable {  // NEW
    let id: UUID
    let name: String
    let isPrimary: Bool
    let order: Int
}

// MARK: - Import Error

enum ImportError: Error {
    case accessDenied
}

#Preview {
    SettingsView()
      .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self, Tag.self, GeneralNote.self], inMemory: true)
}
