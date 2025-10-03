import Foundation

extension Date {
    // Get start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    // Format date based on user preference
    func formatted(style: DateFormatStyle?) -> String {
        switch style {
        case .numeric:
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            return formatter.string(from: self)
        case .written:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: self)
        case .none:
            // Default to numeric if nil
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            return formatter.string(from: self)
        }
    }
    
    // Get day of week string
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    // Add days to date
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    // Check if two dates are the same day
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
    
    // Get month and year string
    var monthAndYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
}
