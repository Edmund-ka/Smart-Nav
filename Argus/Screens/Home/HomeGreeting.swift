import Foundation

/// Uses the phone's local clock. The explicit date/calendar also make time boundaries testable.
enum HomeGreeting {
    static func text(at date: Date, calendar: Calendar = .current, name: String = "Edmund") -> String {
        let hour = calendar.component(.hour, from: date)
        let timeOfDay: String
        switch hour {
        case 5..<12: timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        default: timeOfDay = "evening"
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Good \(timeOfDay)" : "Good \(timeOfDay), \(trimmed)"
    }
}
