import Foundation
import SwiftUI
internal import Combine

enum DeepLink: Equatable {
    case today
    case date(Date)
    case search
    case settings
    
    var url: URL? {
        switch self {
        case .today:
            return URL(string: "harbordot://today")
        case .date(let date):
            let timestamp = date.timeIntervalSince1970
            return URL(string: "harbordot://date/\(timestamp)")
        case .search:
            return URL(string: "harbordot://search")
        case .settings:
            return URL(string: "harbordot://settings")
        }
    }
    
    static func parse(url: URL) -> DeepLink? {
        guard url.scheme == "harbordot" else { return nil }
        
        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        switch host {
        case "today":
            return .today
        case "date":
            if let timestampString = pathComponents.first,
               let timestamp = TimeInterval(timestampString) {
                let date = Date(timeIntervalSince1970: timestamp)
                return .date(date)
            }
            return nil
        case "search":
            return .search
        case "settings":
            return .settings
        default:
            return nil
        }
    }
}

class DeepLinkManager: ObservableObject {
    @Published var activeLink: DeepLink?
    
    func handle(url: URL) {
        activeLink = DeepLink.parse(url: url)
    }
}
