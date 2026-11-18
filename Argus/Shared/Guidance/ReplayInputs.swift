import Foundation

/// Input adapters retain sensor timestamps. Playback speed belongs to the screen, not the engine.
enum ReplayInputs {
    static func demoSession(source: PositionSource, started: Date) throws -> NavigationSession {
        let graph = try CampusGraph.bundled()
        let route = try RoutePlanner.plan(graph: graph, from: "trace-0", to: "trace-7")
        return try NavigationSession(graph: graph, route: route, source: source, started: started)
    }

    static func session(for walk: WalkData) throws -> NavigationSession {
        if let graph = walk.graphSnapshot, let from = walk.originNodeID, let to = walk.destinationNodeID {
            let route = try RoutePlanner.plan(graph: graph, from: from, to: to)
            return try NavigationSession(graph: graph, route: route, source: .recording, started: walk.started)
        }
        return try demoSession(source: .recording, started: walk.started)
    }

    static func positions(for walk: WalkData) -> [NavigationPosition] {
        NavigationInputs.recording(walk)
    }

    static func expectations(for walk: WalkData) -> [ExpectedNavigationEvent] {
        (walk.marks ?? []).compactMap { mark in
            let kind: NavigationEvent.Kind
            switch mark.label.lowercased() {
            case "left route": kind = .offRoute
            case "rejoined route": kind = .rejoined
            case "arrived": kind = .arrived
            default: return nil  // An unqualified "Turn" cannot establish a left/right expected instruction.
            }
            return ExpectedNavigationEvent(
                kind: kind, earliest: mark.time.addingTimeInterval(-10), latest: mark.time.addingTimeInterval(10))
        }
    }
}
