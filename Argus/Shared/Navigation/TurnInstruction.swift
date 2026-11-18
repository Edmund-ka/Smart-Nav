import Foundation

// Represents a turn along the walking route and determines when to give directions.
struct TurnInstruction {

    // Distance from the starting point to where the turn occurs.
    let turnMeters: Double

    // The direction of the turn, either "left" or "right".
    let direction: String

    // Warn the walker 35 meters before reaching a turn.
    let leadMeters = 35.0

    // Analyzes route coordinates to identify turns.
    // CGPoint stores x and y coordinates, while cumulativeMeters stores
    // the distance traveled from the starting point to each coordinate.
    static func turns(points: [CGPoint], cumulativeMeters: [Double]) -> [Self] {

        // A turn requires at least 3 points (A, B, C).
        // Also make sure each point has a corresponding distance.
        guard points.count >= 3, points.count == cumulativeMeters.count else { return [] }

        // Create an empty array to store detected turns.
        // Self refers to TurnInstruction.
        var cues: [Self] = []

        // Loop through the route, excluding the first and last points.
        // Those endpoints cannot have both an incoming and outgoing segment.
        for index in 1..<(points.count - 1) {

            // Get 3 consecutive points:
            // A = previous point, B = possible turn, C = next point.
            let a = points[index - 1]
            let b = points[index]
            let c = points[index + 1]

            // Calculate the direction of travel from A to B.
            let dx = b.x - a.x
            let dy = b.y - a.y

            // Calculate the direction of travel from B to C.
            let ex = c.x - b.x
            let ey = c.y - b.y

            // Calculate the signed angle between the two segments.
            // atan2 uses the cross product and dot product to find the angle.
            // Positive angle = right turn; negative angle = left turn
            // because the map's y-coordinate increases toward the south.
            let angle = atan2(dx * ey - dy * ex, dx * ex + dy * ey)

            // Only recognize bends of at least 45 degrees.
            // Also ignore turns within the first 35 meters because
            // there would not be enough distance for an early warning.
            // abs() checks the angle's size regardless of its sign.
            guard abs(angle) >= .pi / 4, cumulativeMeters[index] >= 35 else { continue }

            // Save the turn's distance and its direction.
            // The ternary operator chooses "right" or "left" based on the angle.
            cues.append(
                Self(
                    turnMeters: cumulativeMeters[index],
                    direction: angle > 0 ? "right" : "left"
                )
            )
        }

        // Return all the turns identified along the route.
        return cues
    }

    // Generate the navigation instruction using the detected direction.
    // Example: "In about 35 meters, turn right."
    var instruction: String {
        "In about 35 meters, turn \(direction)."
    }

    // Determines whether the walker has reached the point where
    // the application should give the upcoming turn instruction.
    func crossesTrigger(from previous: Double, to current: Double) -> Bool {

        // Calculate where the warning should happen.
        // Example: Turn at 90m - 35m warning distance = trigger at 55m.
        let trigger = turnMeters - leadMeters

        // Give the instruction only when the walker crosses the trigger.
        // previous < trigger: walker was before the warning point.
        // trigger == 0 && previous == 0: allows a warning at the start.
        // current >= trigger: walker has reached or passed the warning point.
        // current > previous: walker is moving forward along the route.
        // current < turnMeters: walker has not passed the actual turn.
        // This prevents repeated instructions after crossing the trigger.
        return (previous < trigger || (trigger == 0 && previous == 0))
            && current >= trigger
            && current > previous
            && current < turnMeters
    }
}
