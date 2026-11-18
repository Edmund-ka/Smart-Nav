import Foundation

/// Keeps the existing comma-separated preference format, with exact ID matching.
enum SavedPlaces {
    static func contains(_ id: String, in value: String) -> Bool {
        value.split(separator: ",").contains(Substring(id))
    }

    static func updating(_ id: String, saved: Bool, in value: String) -> String {
        var ids = Set(value.split(separator: ",").map(String.init))
        if saved { ids.insert(id) } else { ids.remove(id) }
        return ids.sorted().joined(separator: ",")
    }
}
