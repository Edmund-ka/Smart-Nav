import Foundation

/// A deliberately small command vocabulary. Unrecognized speech never stops or changes a route.
enum NavigationCommand: Equatable {
    case repeatInstruction, currentLocation, stop
    static func parse(_ words: String) -> Self? {
        let normalized = words.lowercased().split { !$0.isLetter }.joined(separator: " ")
        switch normalized {
        case "repeat", "repeat instruction", "repeat the instruction": return .repeatInstruction
        case "where am i", "current location": return .currentLocation
        case "stop", "stop navigation", "end navigation": return .stop
        default: return nil
        }
    }
}
