import CoreLocation
import Foundation

/// Repeatable diagnostics use the production engine and geometry, not a second navigation implementation.
enum NavigationVerificationChecks {
    static func run(resources: URL, output: URL?) throws {
        let walk = try JSONDecoder().decode(
            WalkData.self, from: Data(contentsOf: resources.appending(path: "Recordings/BoydWalkSample.json")))
        let graph = try CampusGraph.load(resources.appending(path: "CampusData/boyd_library_graph.json"))
        let route = try RoutePlanner.plan(graph: graph, from: "trace-0", to: "trace-7")
        var session = try NavigationSession(graph: graph, route: route, source: .recording, started: walk.started)
        var rows = [
            "seconds,latitude,longitude,accuracy_m,cross_track_m,departure_lower_m,match_upper_m,projected_progress_m,endpoint_upper_m,decision,status,engine_progress_m,events"
        ]
        var reasons: [String: Int] = [:]
        for fix in ReplayInputs.positions(for: walk) {
            let p = MapGeometry.project(fix.coordinate, onto: route.coordinates)!
            let events = session.receive(fix, now: fix.time)
            reasons[session.lastInputDecision, default: 0] += 1
            let values = [
                fix.time.timeIntervalSince(walk.started), fix.coordinate.latitude, fix.coordinate.longitude,
                fix.accuracy, p.distance, max(0, p.distance - fix.accuracy), p.distance + fix.accuracy, p.progress,
                fix.coordinate.distance(to: route.coordinates.last!) + fix.accuracy,
            ]
            rows.append(
                values.map { String(format: "%.7f", $0) }.joined(separator: ",")
                    + ",\(session.lastInputDecision),\(session.status.rawValue),\(session.progress),"
                    + events.map { $0.kind.rawValue }.joined(separator: ";"))
        }
        if let output {
            try rows.joined(separator: "\n").write(
                to: output.deletingLastPathComponent().appending(path: "RECORDED_FIX_TRACE.csv"), atomically: true,
                encoding: .utf8)
        }
        print("Recorded fix decisions: \(reasons.sorted { $0.key < $1.key })")
        checkAdapters()
        try checkModes()
        checkMatcher()
        let campus = try CampusGraph.load(
            resources.deletingLastPathComponent().deletingLastPathComponent().appending(
                path: "data/campus/tsu_candidate_graph.json"))
        let candidate = try RoutePlanner.plan(graph: campus, from: "osm-node-6789109257", to: "osm-node-6787527249")
        precondition(candidate.steps.count == 37 && abs(candidate.distance - 209.5) < 0.1 && !candidate.isVerified)
        print("PASS: production planner confirms 37-edge 209.5 m candidate path; not a verified entrance route")
    }

    static func checkAdapters() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let times = [2.0, 0, 1, 1]
        let fixes = times.enumerated().map { i, seconds in
            CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 36 + Double(i) * 0.00001, longitude: -86), altitude: 0,
                horizontalAccuracy: Double(i + 1), verticalAccuracy: 1, timestamp: start.addingTimeInterval(seconds))
        }
        var walk = WalkData(id: UUID(), started: start)
        walk.readings = fixes.map {
            WalkReading(
                time: $0.timestamp, latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude,
                accuracyMeters: $0.horizontalAccuracy)
        }
        let live = NavigationInputs.live(fixes)
        let recorded = ReplayInputs.positions(for: walk)
        precondition(live.map(\.time) == recorded.map(\.time))
        precondition(live.map(\.coordinate) == recorded.map(\.coordinate))
        precondition(live.map(\.accuracy) == recorded.map(\.accuracy))
        precondition(NavigationInputs.orderedLocations(fixes).map(\.horizontalAccuracy) == [2, 3, 4, 1])
        for (a, b) in zip(live, recorded) {
            let synthetic = NavigationInputs.simulated(time: a.time, coordinate: a.coordinate, accuracy: a.accuracy)
            precondition(
                synthetic.time == b.time && synthetic.coordinate == b.coordinate && synthetic.accuracy == b.accuracy)
        }
        print(
            "PASS: actual adapter conversions preserve coordinates, accuracy, sensor time and stable duplicate ordering"
        )
    }

    static func checkModes() throws {
        let graph = NavigationChecks.fixture()  // Verified only inside this synthetic test, never campus data.
        let route = try RoutePlanner.plan(graph: graph, from: "n0", to: "n2")
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        func run(_ source: PositionSource, delay: Double = 0, freshness: Bool = false) throws -> NavigationSession {
            var session = try NavigationSession(graph: graph, route: route, source: source, started: start)
            for i in 0...Int(ceil(route.distance) + 8) {
                let time = start.addingTimeInterval(Double(i))
                var point = MapGeometry.coordinate(at: Double(i), on: route.coordinates)!
                if i == 45 { point.latitude += 0.0005 }
                let fix = NavigationPosition(time: time, coordinate: point, accuracy: i == 55 ? 30 : 1, source: source)
                session.receive(fix, now: time.addingTimeInterval(delay))
                if freshness { session.checkFreshness(now: time.addingTimeInterval(delay)) }
            }
            return session
        }
        let simulation = try run(.simulation)
        for source in [PositionSource.recording, .live] {
            let other = try run(source, freshness: source == .live)
            // Wording identifies the mode; decisions, sensor times and distances must agree.
            precondition(simulation.events.map(\.kind) == other.events.map(\.kind))
            precondition(simulation.events.map(\.time) == other.events.map(\.time))
            precondition(simulation.events.map(\.progressMeters) == other.events.map(\.progressMeters))
            precondition(simulation.events.map(\.distanceToDecision) == other.events.map(\.distanceToDecision))
            precondition(
                simulation.status == other.status && simulation.acceptedReadings == other.acceptedReadings
                    && simulation.rejectedReadings == other.rejectedReadings)
        }
        // Check departure and replacement-route decisions across sources as well as normal progress.
        let alternate = route.steps.first!.end == "n1" ? "n3" : "n1"
        let detour = [graph.node("n0")!.coordinate, graph.node(alternate)!.coordinate]
        var reference: [NavigationEvent]?
        for source in [PositionSource.simulation, .recording, .live] {
            var session = try NavigationSession(graph: graph, route: route, source: source, started: start)
            for i in 0...115 {
                let time = start.addingTimeInterval(Double(i))
                session.receive(
                    NavigationPosition(
                        time: time, coordinate: MapGeometry.coordinate(at: Double(i), on: detour)!, accuracy: 1,
                        source: source), now: time)
            }
            precondition(session.events.contains { $0.kind == .offRoute })
            precondition(session.events.contains { $0.kind == .rerouted })
            if let reference {
                precondition(reference.map(\.kind) == session.events.map(\.kind))
                precondition(reference.map(\.time) == session.events.map(\.time))
                precondition(reference.map(\.progressMeters) == session.events.map(\.progressMeters))
            } else {
                reference = session.events
            }
        }
        let delayed = try run(.live, delay: 11)
        precondition(delayed.acceptedReadings == 0 && delayed.status == .uncertain)
        var silent = try NavigationSession(graph: graph, route: route, source: .live, started: start)
        silent.receive(
            NavigationPosition(time: start, coordinate: route.coordinates[0], accuracy: 1, source: .live), now: start)
        silent.checkFreshness(now: start.addingTimeInterval(11))
        precondition(silent.status == .uncertain)
        print(
            "PASS: simulation/recording/live decision parity with identical clocks, outlier and poor accuracy; delayed live fixes and silence correctly differ"
        )
    }

    static func checkMatcher() {
        let start = Date(timeIntervalSince1970: 0)
        func target(_ a: Double, _ b: Double) -> ExpectedNavigationEvent {
            ExpectedNavigationEvent(
                kind: .offRoute, earliest: start.addingTimeInterval(a), latest: start.addingTimeInterval(b))
        }
        func event(_ t: Double) -> NavigationEvent {
            NavigationEvent(
                id: Int(t), kind: .offRoute, time: start.addingTimeInterval(t), message: "test", progressMeters: 0,
                distanceToDecision: nil)
        }
        let result = NavigationEvaluation.compare(
            expected: [target(0, 10), target(20, 30)], actual: [event(25)], kinds: [.offRoute])
        precondition(result.matched == 1 && result.missing.count == 1 && result.outsideWindow.isEmpty)
        let overlapping = NavigationEvaluation.compare(
            expected: [target(0, 30), target(0, 10)], actual: [event(25), event(5)], kinds: [.offRoute])
        precondition(overlapping.matched == 2 && overlapping.unexpected.isEmpty)
        let boundary = NavigationEvaluation.compare(
            expected: [target(5, 5), target(5, 5)], actual: [event(5)], kinds: [.offRoute])
        precondition(boundary.matched == 1 && boundary.missing.count == 1)
        print(
            "PASS: matcher preserves later valid matches, handles overlapping windows and enforces one-to-one inclusive boundaries"
        )
    }
}
