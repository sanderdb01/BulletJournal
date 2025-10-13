import Foundation
import SwiftData

class SharedModelContainer {
    static let shared: ModelContainer = {
       let schema = Schema([
           DayLog.self,
           TaskItem.self,
           AppSettings.self,
           Tag.self,
           GeneralNote.self
       ])
        
        // Get shared container URL
        let appGroupID = "group.com.sanders.HarborDot"
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            fatalError("Shared container could not be created.")
        }
        
        let storeURL = containerURL.appendingPathComponent("HarborDot.sqlite")
        
        let modelConfiguration = ModelConfiguration(
            url: storeURL,
            cloudKitDatabase: .automatic
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            print("✅ Shared ModelContainer created at: \(storeURL)")
            return container
        } catch {
            fatalError("Could not create Shared ModelContainer: \(error)")
        }
    }()
}
