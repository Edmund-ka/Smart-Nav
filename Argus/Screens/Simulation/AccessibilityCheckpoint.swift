import Foundation

/// Authored presentation observations, not camera detections. Fractions place approximate markers on the demo line.
struct AccessibilityCheckpoint: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let fraction: Double
    let source: String
    let description: String

    static let examples: [Self] = [
        .init(
            id: "stairs", title: "Stairs outside Boyd Hall", symbol: "stairs", fraction: 0.025,
            source: "User-reported feature · approximate placement",
            description:
                "Stairs ahead. Watch your step."
        ),
        .init(
            id: "people", title: "Group of people", symbol: "person.3.fill", fraction: 0.27,
            source: "Staged obstacle · presentation only",
            description:
                "People ahead. Keep right."
        ),
        .init(
            id: "surface", title: "Uneven pavement", symbol: "exclamationmark.triangle.fill", fraction: 0.72,
            source: "Staged obstacle · presentation only",
            description: "Uneven pavement ahead. Step carefully."),
        .init(
            id: "door", title: "Library accessibility sign", symbol: "door.left.hand.open", fraction: 0.98,
            source: "User-reported feature · approximate placement",
            description:
                "Door accessibility sign on your right."
        ),
    ]
}
