import SwiftUI

extension Color {
    // Task color palette (8 colors for tags)
    static let taskRed = Color.red
    static let taskOrange = Color.orange
    static let taskYellow = Color.yellow
    static let taskGreen = Color.green
    static let taskBlue = Color.blue
    static let taskPurple = Color.purple
    static let taskPink = Color.pink
    static let taskGray = Color.gray
    
    // Array of available task colors (legacy - kept for backward compatibility)
    static let taskColors: [(name: String, color: Color)] = [
        ("red", taskRed),
        ("orange", taskOrange),
        ("yellow", taskYellow),
        ("green", taskGreen),
        ("blue", taskBlue),
        ("purple", taskPurple),
        ("pink", taskPink),
        ("gray", taskGray)
    ]
    
    // Convert string to Color
    static func fromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return taskRed
        case "orange": return taskOrange
        case "yellow": return taskYellow
        case "green": return taskGreen
        case "blue": return taskBlue
        case "purple": return taskPurple
        case "pink": return taskPink
        case "gray", "grey": return taskGray
        default: return taskBlue
        }
    }
    
    // Get hex representation (useful for export/debugging)
    func toHexString() -> String {
        let components = UIColor(self).cgColor.components
        let r = components?[0] ?? 0
        let g = components?[1] ?? 0
        let b = components?[2] ?? 0
        return String(format: "#%02lX%02lX%02lX", lround(Double(r * 255)), lround(Double(g * 255)), lround(Double(b * 255)))
    }
}
