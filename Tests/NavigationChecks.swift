import Foundation

/// Synthetic fixtures test decisions, not campus truth. Verified fixture flags are never shipped as campus data.
enum NavigationChecks {
    static func run(resources: URL) throws {
        let graph = try CampusGraph.load(resources.appending(path: "CampusData/boyd_library_graph.json"))
        let route = try RoutePlanner.plan(graph: graph, from: "trace-0", to: "trace-7")
        precondition(route.steps.count == 7 && !route.isVerified)
        precondition(GraphValidator.validate(graph).errors.isEmpty)
        var strict = RoutePreferences()
        strict.verifiedOnly = true
        precondition((try? RoutePlanner.plan(graph: graph, from: "trace-0", to: "trace-7", preferences: strict)) == nil)
        var stairFree = RoutePreferences()
        stairFree.avoidStairs = true
        precondition(
            (try? RoutePlanner.plan(graph: graph, from: "trace-0", to: "trace-7", preferences: stairFree)) == nil)
        var broken = graph
        broken.edges[0].to = "missing"
        precondition(!GraphValidator.validate(broken).errors.isEmpty)
        broken = graph
        broken.nodes.append(broken.nodes[0])
        precondition(!GraphValidator.validate(broken).errors.isEmpty)
        broken = graph
        broken.edges[0].lengthMeters = -1
        precondition(!GraphValidator.validate(broken).errors.isEmpty)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        precondition((try? NavigationSession(graph: graph, route: route, source: .live, started: start)) == nil)
        func run(speed: Int, noisy: Bool = false) throws -> NavigationSession {
            var session = try NavigationSession(graph: graph, route: route, source: .simulation, started: start)
            let count = Int(ceil(route.distance)) + 5
            // Speed changes delivery batches, never the timestamps or number of observations.
            for batch in stride(from: 0, through: count, by: speed) {
                for i in batch..<min(batch + speed, count + 1) {
                    var point = MapGeometry.coordinate(at: Double(i), on: route.coordinates)!
                    if noisy && i == 45 { point.latitude += 0.0005 }
                    let time = start.addingTimeInterval(Double(i))
                    session.receive(
                        NavigationPosition(time: time, coordinate: point, accuracy: 1, source: .simulation), now: time)
                }
            }
            return session
        }
        let normal = try run(speed: 1)
        let fast = try run(speed: 4)
        precondition(normal.events == fast.events, "Replay speed must not change events")
        precondition(normal.events.filter { $0.kind == .turnRight }.count == 2)
        precondition(normal.events.filter { $0.kind == .arrived }.count == 1)
        let noisy = try run(speed: 1, noisy: true)
        precondition(!noisy.events.contains { $0.kind == .offRoute })
        precondition(noisy.rejectedReadings == 1)
        var bad = try NavigationSession(graph: graph, route: route, source: .simulation, started: start)
        for i in 0..<5 {
            let time = start.addingTimeInterval(Double(i))
            bad.receive(
                NavigationPosition(time: time, coordinate: route.coordinates[0], accuracy: 50, source: .simulation),
                now: time)
        }
        precondition(bad.status == .uncertain && bad.events.filter { $0.kind == .uncertain }.count == 1)
        bad.receive(
            NavigationPosition(time: start, coordinate: route.coordinates[0], accuracy: 1, source: .simulation),
            now: start)
        precondition(bad.acceptedReadings == 0, "Out-of-order fix must be rejected")
        var atEnd = try NavigationSession(graph: graph, route: route, source: .simulation, started: start)
        for i in 0..<5 {
            let t = start.addingTimeInterval(Double(i))
            atEnd.receive(
                NavigationPosition(time: t, coordinate: route.coordinates.last!, accuracy: 1, source: .simulation),
                now: t)
        }
        precondition(
            !atEnd.events.contains { $0.kind == .arrived }, "Starting near another endpoint is not a completed journey")
        let walked = try CampusGraph.load(resources.appending(path: "CampusData/boyd_library_walked.json"))
        let walkedRoute = try RoutePlanner.plan(graph: walked, from: "trace-0", to: "trace-7")
        precondition(!walkedRoute.isVerified && walked.permitsLiveGuidance(for: walkedRoute))
        let live = try NavigationSession(graph: walked, route: walkedRoute, source: .live, started: start)
        precondition(live.events.first!.message.contains("Stairs ahead"))
        precondition(
            (try? RoutePlanner.plan(graph: walked, from: "trace-0", to: "trace-7", preferences: stairFree)) == nil)
        let reversed = try RoutePlanner.plan(graph: walked, from: "trace-7", to: "trace-0")
        precondition(!walked.permitsLiveGuidance(for: reversed))
        var unreviewed = walked
        unreviewed.walkReview = nil
        precondition(!unreviewed.permitsLiveGuidance(for: walkedRoute))
        precondition(
            (try? NavigationSession(graph: unreviewed, route: walkedRoute, source: .live, started: start)) == nil)
        try checkRoutingAndRerouting(start: start)
        try checkRecordedWalk(resources: resources, graph: walked, route: walkedRoute)
        print(
            "PASS: graph validation, unknown-data restrictions, live verification gate, shared guidance, two turns, arrival, bad GPS, out-of-order input, and 1x/4x equivalence"
        )
    }

    /// Replays the real November 16 Boyd → Library walk through the walked graph.
    /// Measures how continuously guidance tracks the walker; it is not a ground-truth accuracy test.
    static func checkRecordedWalk(resources: URL, graph: CampusGraph, route: PlannedRoute) throws {
        let url = resources.deletingLastPathComponent().deletingLastPathComponent().appending(
            path: "ReferenceData/FieldVisits/2026-11-16-boyd-library/9C6FFB3C-2D88-4F64-8704-F2A1EEF0D17D.json")
        let walk = try JSONDecoder().decode(WalkData.self, from: Data(contentsOf: url))
        var session = try NavigationSession(graph: graph, route: route, source: .recording, started: walk.started)
        var following = 0
        var largestBackStep = 0.0
        var largestJump = 0.0
        var previous = 0.0
        for input in ReplayInputs.positions(for: walk) {
            session.receive(input, now: input.time)
            if session.status == .following { following += 1 }
            largestBackStep = max(largestBackStep, previous - session.progress)
            largestJump = max(largestJump, session.progress - previous)
            previous = session.progress
        }
        let kinds = session.events.map(\.kind)
        let summary =
            "Recorded walk: \(walk.readings.count) fixes, \(session.acceptedReadings) accepted, following on \(following), uncertain events \(kinds.filter { $0 == .uncertain }.count), turns \(kinds.filter { $0 == .turnRight }.count), arrived \(kinds.contains(.arrived)), largest jump \(Int(largestJump)) m, largest back-step \(Int(largestBackStep)) m"
        print(summary)
        for event in session.events {
            print(
                "  \(Int(event.time.timeIntervalSince(walk.started)))s \(event.kind.rawValue) @\(Int(event.progressMeters)) m: \(event.message)"
            )
        }
        precondition(kinds.filter { $0 == .turnRight }.count == 2, "Both right turns should be announced")
        precondition(kinds.contains(.arrived), "The recorded walk ends at the library entrance")
        precondition(!kinds.contains(.offRoute), "The walker stayed on the route")
        precondition(largestBackStep <= 3)
    }

    static func fixture() -> CampusGraph {
        let coords = [(0.0, 0.0), (0.0, 0.001), (0.001, 0.001), (0.001, 0.0)]
        let nodes = coords.enumerated().map { i, p in
            CampusNode(
                id: "n\(i)", name: "Synthetic fixture \(i)", coordinate: MapCoordinate(latitude: p.0, longitude: p.1),
                isEntrance: i == 2, verification: .verified, checkedBy: "TEST FIXTURE", checkedOn: "not a field survey")
        }
        let pairs = [(0, 1), (1, 2), (0, 3), (3, 2)]
        let edges = pairs.enumerated().map { i, p in
            CampusEdge(
                id: "e\(i)", from: "n\(p.0)", to: "n\(p.1)", geometry: [nodes[p.0].coordinate, nodes[p.1].coordinate],
                lengthMeters: nodes[p.0].coordinate.distance(to: nodes[p.1].coordinate), bidirectional: true,
                stairs: i == 0 ? .yes : .no, crossing: .no, accessible: .yes, restricted: false,
                verification: .verified, source: "Synthetic test", checkedBy: "TEST FIXTURE",
                checkedOn: "not a field survey")
        }
        return CampusGraph(
            schemaVersion: 1, id: "fixture", name: "Synthetic square", version: "1", isDemonstration: false,
            sources: [MapSource(name: "Synthetic", url: "test:fixture", license: "test only", retrieved: "2026-11-16")],
            nodes: nodes, edges: edges)
    }

    static func checkRoutingAndRerouting(start: Date) throws {
        var graph = fixture()
        var preferences = RoutePreferences()
        preferences.avoidStairs = true
        let accessible = try RoutePlanner.plan(graph: graph, from: "n0", to: "n2", preferences: preferences)
        precondition(accessible.steps.map(\.edge.id) == ["e2", "e3"])
        graph.edges.removeLast()
        precondition((try? RoutePlanner.plan(graph: graph, from: "n0", to: "n2", preferences: preferences)) == nil)
        graph = fixture()
        let initial = try RoutePlanner.plan(graph: graph, from: "n0", to: "n2")
        // Whichever equal-cost side was selected, depart down the other side to its verified junction.
        let alternate = initial.steps.first!.end == "n1" ? "n3" : "n1"
        let path = [graph.node("n0")!.coordinate, graph.node(alternate)!.coordinate]
        var session = try NavigationSession(graph: graph, route: initial, source: .simulation, started: start)
        for i in 0...115 {
            let time = start.addingTimeInterval(Double(i))
            let p = MapGeometry.coordinate(at: Double(i), on: path)!
            session.receive(NavigationPosition(time: time, coordinate: p, accuracy: 1, source: .simulation), now: time)
        }
        precondition(session.events.contains { $0.kind == .offRoute })
        precondition(session.events.contains { $0.kind == .rerouted }, "Verified alternate junction should replan")
        let expected = [
            ExpectedNavigationEvent(kind: .offRoute, earliest: start, latest: start.addingTimeInterval(120))
        ]
        let comparison = NavigationEvaluation.compare(expected: expected, actual: session.events, kinds: [.offRoute])
        precondition(comparison.matched == 1 && comparison.missing.isEmpty)
        let delayed = NavigationEvaluation.compare(
            expected: [ExpectedNavigationEvent(kind: .offRoute, earliest: start, latest: start)],
            actual: session.events, kinds: [.offRoute])
        precondition(delayed.outsideWindow.count == 1)
        print("PASS: stair avoidance, disconnected/no-route graph, verified-junction rerouting, event comparison")
    }
}
