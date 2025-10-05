import Foundation

struct RecurrenceRule: Codable, Equatable {
    var frequency: RecurrenceFrequency
    var interval: Int // e.g., every 2 days, every 3 weeks
    var daysOfWeek: Set<Int>? // 1 = Sunday, 2 = Monday, etc.
    var dayOfMonth: Int? // For monthly recurrence
    var endDate: Date?
    
    enum RecurrenceFrequency: String, Codable {
        case daily
        case weekly
        case monthly
    }
    
    // Convert to JSON string for storage
    func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
    
    // Create from JSON string
    static func from(jsonString: String) -> RecurrenceRule? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(RecurrenceRule.self, from: data)
    }
    
    // Calculate next occurrence from a given date
    func nextOccurrence(after date: Date) -> Date? {
        let calendar = Calendar.current
        
        // Check if we've passed the end date
        if let endDate = endDate, date >= endDate {
            return nil
        }
        
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: interval, to: date)
            
        case .weekly:
            guard let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty else {
                return calendar.date(byAdding: .weekOfYear, value: interval, to: date)
            }
            
            // Find next matching day of week
            var nextDate = calendar.date(byAdding: .day, value: 1, to: date)!
            var weeksAdded = 0
            
            while weeksAdded < interval || !daysOfWeek.contains(calendar.component(.weekday, from: nextDate)) {
                if !daysOfWeek.contains(calendar.component(.weekday, from: nextDate)) {
                    nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
                } else if weeksAdded < interval - 1 {
                    nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDate)!
                    weeksAdded += 1
                } else {
                    break
                }
            }
            
            return nextDate
            
        case .monthly:
            if let dayOfMonth = dayOfMonth {
                var components = calendar.dateComponents([.year, .month], from: date)
                components.day = dayOfMonth
                
                // Add interval months
                if let baseDate = calendar.date(from: components) {
                    return calendar.date(byAdding: .month, value: interval, to: baseDate)
                }
            }
            return calendar.date(byAdding: .month, value: interval, to: date)
        }
    }
    
    // Get all occurrences between two dates
    func occurrences(from startDate: Date, to endDate: Date, limit: Int = 100) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        
        while dates.count < limit {
            if let nextDate = nextOccurrence(after: currentDate) {
                if nextDate > endDate {
                    break
                }
                dates.append(nextDate)
                currentDate = nextDate
            } else {
                break
            }
        }
        
        return dates
    }
    
    // Human-readable description
    var description: String {
        switch frequency {
        case .daily:
            return interval == 1 ? "Daily" : "Every \(interval) days"
        case .weekly:
            if let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty {
                let dayNames = daysOfWeek.sorted().map { dayNumber in
                    let formatter = DateFormatter()
                    return formatter.shortWeekdaySymbols[dayNumber - 1]
                }
                let daysString = dayNames.joined(separator: ", ")
                return interval == 1 ? "Weekly on \(daysString)" : "Every \(interval) weeks on \(daysString)"
            }
            return interval == 1 ? "Weekly" : "Every \(interval) weeks"
        case .monthly:
            if let day = dayOfMonth {
                return interval == 1 ? "Monthly on day \(day)" : "Every \(interval) months on day \(day)"
            }
            return interval == 1 ? "Monthly" : "Every \(interval) months"
        }
    }
}
