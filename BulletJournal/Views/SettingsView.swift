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
    
    var body: some View {
        NavigationStack {
            Form {
                // Date Format Section
                Section {
                    Picker("Date Format", selection: Binding(
                     get: { currentSettings.dateFormat ?? .numeric},
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
            .navigationBarTitleDisplayMode(.inline)
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
                Text("Your data has been exported successfully. You can find it in your Files app.")
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
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .fileExporter(
                isPresented: $showingExportShare,
                document: exportFileURL.flatMap { JSONFileDocument(fileURL: $0) },
                contentType: .json,
                defaultFilename: "BulletJournal_Export_\(dateFormatterForFilename.string(from: Date()))"
            ) { result in
                handleExportResult(result: result)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalTasksCount: Int {
        dayLogs.reduce(0) { $0 + ($1.tasks?.count ?? 0) }
    }
    
    // MARK: - Data Management Functions
    
    private func clearAllData() {
        // Delete all day logs (tasks will be cascade deleted)
        for dayLog in dayLogs {
            modelContext.delete(dayLog)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error clearing data: \(error)")
        }
    }
    
    private func exportData() {
        isExporting = true
        
        Task {
            do {
                let exportData = createExportData()
                let jsonData = try JSONEncoder().encode(exportData)
                
                // Create a temporary file
                let tempDirectory = FileManager.default.temporaryDirectory
                let fileName = "BulletJournal_Export_\(dateFormatterForFilename.string(from: Date())).json"
                let fileURL = tempDirectory.appendingPathComponent(fileName)
                
                try jsonData.write(to: fileURL)
                
                await MainActor.run {
                    exportFileURL = fileURL
                    showingExportShare = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    exportErrorMessage = "Failed to export data: \(error.localizedDescription)"
                    showingExportError = true
                    isExporting = false
                }
            }
        }
    }
    
    private func handleExportResult(result: Result<URL, Error>) {
        switch result {
        case .success:
            showingExportSuccess = true
        case .failure(let error):
            exportErrorMessage = "Failed to save export: \(error.localizedDescription)"
            showingExportError = true
        }
    }
    
   private func createExportData() -> ExportData {
       var exportDayLogs: [ExportDayLog] = []
       
       for dayLog in dayLogs {
           // Safely unwrap optional properties
           guard let id = dayLog.id,
                 let date = dayLog.date else {
               continue // Skip if essential data is missing
           }
           
           let exportTasks = (dayLog.tasks ?? []).compactMap { task -> ExportTask? in
               // Ensure all required task properties exist
               guard let taskId = task.id,
                     let name = task.name,
                     let color = task.color,
                     let notes = task.notes,
                     let status = task.status,
                     let createdAt = task.createdAt,
                     let modifiedAt = task.modifiedAt else {
                   return nil
               }
               
               return ExportTask(
                   id: taskId,
                   name: name,
                   color: color,
                   notes: notes,
                   status: status.rawValue,
                   createdAt: createdAt,
                   modifiedAt: modifiedAt
               )
           }
           
           let exportDayLog = ExportDayLog(
               id: id,
               date: date,
               notes: dayLog.notes ?? "",
               tasks: exportTasks
           )
           
           exportDayLogs.append(exportDayLog)
       }
       
       return ExportData(
           version: 1,
           exportDate: Date(),
           dayLogs: exportDayLogs
       )
   }
    
    private func handleImport(result: Result<[URL], Error>) {
        isImporting = true
        
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                importErrorMessage = "No file selected"
                showingImportError = true
                isImporting = false
                return
            }
            
            importData(from: url)
            
        case .failure(let error):
            importErrorMessage = "Failed to access file: \(error.localizedDescription)"
            showingImportError = true
            isImporting = false
        }
    }
    
    private func importData(from url: URL) {
        Task {
            do {
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    throw ImportError.accessDenied
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let jsonData = try Data(contentsOf: url)
                let exportData = try JSONDecoder().decode(ExportData.self, from: jsonData)
                
                await MainActor.run {
                    importExportData(exportData)
                    isImporting = false
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    importErrorMessage = "Failed to import data: \(error.localizedDescription)"
                    showingImportError = true
                    isImporting = false
                }
            }
        }
    }
    
   private func importExportData(_ exportData: ExportData) {
       for exportDayLog in exportData.dayLogs {
           // Check if we already have a day log for this date
           if let existingDayLog = dayLogs.first(where: { $0.date == exportDayLog.date }) {
               // Merge: add tasks that don't exist (by ID)
               let existingTaskIDs = Set((existingDayLog.tasks ?? []).compactMap { $0.id })
               
               for exportTask in exportDayLog.tasks {
                   if !existingTaskIDs.contains(exportTask.id) {
                       let newTask = TaskItem(
                           name: exportTask.name,
                           color: exportTask.color,
                           notes: exportTask.notes,
                           status: TaskStatus(rawValue: exportTask.status) ?? .normal
                       )
                       newTask.id = exportTask.id
                       newTask.createdAt = exportTask.createdAt
                       newTask.modifiedAt = exportTask.modifiedAt
                       
                       existingDayLog.addTask(newTask)
                       modelContext.insert(newTask)
                   }
               }
               
               // Merge notes if the imported day has notes and existing doesn't
               if !exportDayLog.notes.isEmpty && (existingDayLog.notes?.isEmpty ?? true) {
                   existingDayLog.notes = exportDayLog.notes
               }
           } else {
               // Create new day log
               let newDayLog = DayLog(date: exportDayLog.date, notes: exportDayLog.notes)
               newDayLog.id = exportDayLog.id
               
               for exportTask in exportDayLog.tasks {
                   let newTask = TaskItem(
                       name: exportTask.name,
                       color: exportTask.color,
                       notes: exportTask.notes,
                       status: TaskStatus(rawValue: exportTask.status) ?? .normal
                   )
                   newTask.id = exportTask.id
                   newTask.createdAt = exportTask.createdAt
                   newTask.modifiedAt = exportTask.modifiedAt
                   
                   newDayLog.addTask(newTask)
                   modelContext.insert(newTask)
               }
               
               modelContext.insert(newDayLog)
           }
       }
       
       try? modelContext.save()
   }
    
    // Date formatter for export filename
    private var dateFormatterForFilename: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
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

// MARK: - Export Data Structures

struct ExportData: Codable {
    let version: Int
    let exportDate: Date
    let dayLogs: [ExportDayLog]
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
}

// MARK: - Import Error

enum ImportError: Error {
    case accessDenied
}

#Preview {
    SettingsView()
        .modelContainer(for: [DayLog.self, TaskItem.self, AppSettings.self], inMemory: true)
}
