import SwiftUI

extension Color {
    // Task color palette (primary and secondary colors)
    static let taskRed = Color.red
    static let taskBlue = Color.blue
    static let taskYellow = Color.yellow
    static let taskGreen = Color.green
    static let taskOrange = Color.orange
    static let taskPurple = Color.purple
    
    // Array of available task colors
    static let taskColors: [(name: String, color: Color)] = [
        ("red", taskRed),
        ("blue", taskBlue),
        ("yellow", taskYellow),
        ("green", taskGreen),
        ("orange", taskOrange),
        ("purple", taskPurple)
    ]
    
    // Convert string to Color
    static func fromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return taskRed
        case "blue": return taskBlue
        case "yellow": return taskYellow
        case "green": return taskGreen
        case "orange": return taskOrange
        case "purple": return taskPurple
        default: return taskBlue
        }
    }
}
