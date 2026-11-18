import Foundation

struct RouteInstruction {
    let id: String
    let meters: Double
    let kind: NavigationEvent.Kind
    let message: String
}

/// Build direction and mapped-feature instructions once per route, not once per GPS fix.
enum RouteInstructions {
    static func make(for route: PlannedRoute) -> [RouteInstruction] {
        let points = route.coordinates
        var result: [RouteInstruction] = []
        var distance = 0.0
        for i in 1..<max(1, points.count - 1) {
            let a = points[i - 1]
            let b = points[i]
            let c = points[i + 1]
            distance += a.distance(to: b)
            let xScale = cos(b.latitude * .pi / 180)
            let dx = (b.longitude - a.longitude) * xScale
            let dy = b.latitude - a.latitude
            let ex = (c.longitude - b.longitude) * xScale
            let ey = c.latitude - b.latitude
            let angle = atan2(dx * ey - dy * ex, dx * ex + dy * ey)
            // 40° keeps the walked route's two confirmed right turns (62° and 42°) and ignores its 37° bend.
            if abs(angle) >= 40 * .pi / 180 {
                // Local y points north, so a positive signed angle is a left turn.
                let left = angle > 0
                result.append(
                    RouteInstruction(
                        id: "turn-\(i)", meters: distance,
                        kind: left ? .turnLeft : .turnRight, message: "turn \(left ? "left" : "right")"))
            }
        }
        var start = 0.0
        for step in route.steps {
            // Candidate map facts can be shown in the data inspector, but cannot become real-world warnings.
            if step.edge.verification == .verified {
                if step.edge.crossing == .yes {
                    result.append(
                        RouteInstruction(
                            id: "crossing-\(step.edge.id)", meters: start, kind: .crossing,
                            message: "Mapped crossing ahead. Check conditions before crossing."))
                }
                if step.edge.stairs == .yes {
                    result.append(
                        RouteInstruction(
                            id: "stairs-\(step.edge.id)", meters: start, kind: .accessibility,
                            message: "Mapped stairs ahead."))
                }
            }
            start += step.edge.lengthMeters
        }
        return result.sorted { $0.meters == $1.meters ? $0.id < $1.id : $0.meters < $1.meters }
    }
}
