import Foundation
import SwiftData

@Model
class AppSettings {
    var id: UUID?
    var dateFormat: DateFormatStyle?
    
    init(dateFormat: DateFormatStyle = .numeric) {
        self.id = UUID()
        self.dateFormat = dateFormat
    }
}

enum DateFormatStyle: String, Codable {
    case numeric // MM/DD/YYYY
    case written // Month DD, YYYY
}
