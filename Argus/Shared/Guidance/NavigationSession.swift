import Foundation

/// The common state machine for live GPS, synthetic positions, and recorded GPS.
/// It never starts hardware, speaks, or reads wall-clock time; callers supply the evaluation clock.
struct NavigationSession {
    enum Status: String { case waiting, following, uncertain, offRoute, arrived, stopped }
    private(set) var route: PlannedRoute
    let graph: CampusGraph
    let preferences: RoutePreferences
    let source: PositionSource
    var settings: NavigationSettings
    private(set) var status: Status = .waiting
    private(set) var progress = 0.0
    private(set) var position: NavigationPosition?
    private(set) var matchedPosition: MapCoordinate?
    private(set) var events: [NavigationEvent] = []
    // Read-only audit label for the last fix; does not alter thresholds or guidance decisions.
    private(set) var lastInputDecision = "notReceived"
    private(set) var rejectedReadings = 0
    private(set) var acceptedReadings = 0
    private(set) var recentPositions: [NavigationPosition] = []
    /// Smoothed walking speed along the route (m/s); lets the screen glide between GPS fixes.
    private(set) var speed = 0.0
    /// Sensor time of the last progress estimate.
    private(set) var lastProgressTime: Date?
    private var detector = OffRouteDetector()
    private(set) var instructions: [RouteInstruction]
    private var emitted = Set<String>()
    private var lastInputTime: Date?
    private var lastAccepted: NavigationPosition?
    private var lastConfirmation: Date?
    private var arrivalStart: Date?
    private var arrivalCount = 0
    private var startedNearOrigin = false
    private var lastRerouteAttempt: Date?

    var lastInstruction: String { events.last?.message ?? "Waiting for a reliable position." }
    var nextInstruction: RouteInstruction? { instructions.first { $0.meters >= progress } }
    var distanceToNext: Double? { nextInstruction.map { max(0, $0.meters - progress) } }
    var remaining: Double { max(0, route.distance - progress) }

    init(
        graph: CampusGraph, route: PlannedRoute, source: PositionSource,
        preferences: RoutePreferences = RoutePreferences(), settings: NavigationSettings = NavigationSettings(),
        started: Date
    ) throws {
        guard source != .live || graph.permitsLiveGuidance(for: route) else {
            throw GraphLoadError.invalid(
                "Live guidance requires a verified route or an explicitly reviewed walked route.")
        }
        self.graph = graph
        self.route = route
        self.source = source
        self.preferences = preferences
        self.settings = settings
        detector.departureMeters = settings.departureMeters
        detector.returnMeters = settings.rejoinMeters
        instructions = RouteInstructions.make(for: route)
        emit(
            .started, at: started,
            message: source == .live
                ? (route.steps.first?.edge.stairs == .yes
                    ? "Stairs ahead at Boyd Hall. Descend to the sidewalk when ready. Argus navigation started."
                    : "Argus navigation started. Confirm your position at the route start.")
                : "\(source == .simulation ? "Simulation" : "Recorded replay") started. Map data may be unverified.")
    }

    /// Passing sensor time as `now` makes replay speed irrelevant to decision timing.
    @discardableResult mutating func receive(_ reading: NavigationPosition, now: Date) -> [NavigationEvent] {
        let firstEvent = events.count
        lastInputDecision = "terminalSession"
        guard status != .arrived, status != .stopped else { return [] }
        guard reading.source == source, reading.coordinate.isValid, reading.accuracy.isFinite,
            reading.time.timeIntervalSince1970.isFinite
        else {
            lastInputDecision = "invalidInput"
            rejectedReadings += 1
            markUncertain(at: now)
            return Array(events.dropFirst(firstEvent))
        }
        // Old callbacks never move session time backwards or reset an already confirmed state.
        if let lastInputTime, reading.time <= lastInputTime {
            lastInputDecision = "nonIncreasingTime"
            rejectedReadings += 1
            return []
        }
        // A future-dated corrupt fix must not poison ordering for later valid observations.
        guard reading.time.timeIntervalSince(now) <= 1 else {
            lastInputDecision = "futureTimestamp"
            rejectedReadings += 1
            markUncertain(at: now)
            return Array(events.dropFirst(firstEvent))
        }
        lastInputTime = reading.time
        guard reading.accuracy >= 0, reading.accuracy <= settings.maximumAccuracy,
            now.timeIntervalSince(reading.time) <= settings.maximumAge
        else {
            lastInputDecision =
                reading.accuracy < 0 || reading.accuracy > settings.maximumAccuracy ? "poorAccuracy" : "staleTimestamp"
            rejectedReadings += 1
            degrade(at: reading.time, now: now)
            return Array(events.dropFirst(firstEvent))
        }
        if let last = lastAccepted {
            let dt = reading.time.timeIntervalSince(last.time)
            if dt > settings.maximumGap {
                detector.resetConfirmation()
                lastConfirmation = nil
                arrivalCount = 0
                arrivalStart = nil
            }
            // Allow the reported uncertainty of both fixes, but reject physically implausible jumps.
            if reading.coordinate.distance(to: last.coordinate) > settings.maximumWalkingSpeed * dt + last.accuracy
                + reading.accuracy
            {
                lastInputDecision = "implausibleJump"
                rejectedReadings += 1
                degrade(at: reading.time, now: now)
                return Array(events.dropFirst(firstEvent))
            }
        }
        // Windowed map matching: search only the stretch of route the walker could plausibly have reached
        // since the last estimate. This removes most jumps without discarding moderately accurate fixes.
        var window: ClosedRange<Double>?
        if startedNearOrigin, let lastProgressTime {
            let elapsed = max(0, reading.time.timeIntervalSince(lastProgressTime))
            let ahead = settings.matchAheadMeters + min(settings.maximumRouteSpeed * elapsed, 120)
            window = max(0, progress - settings.matchBehindMeters)...(progress + ahead)
        }
        lastInputDecision = "noProjection"
        guard let projection = MapGeometry.project(reading.coordinate, onto: route.coordinates, within: window)
        else { return [] }
        lastAccepted = reading
        position = reading
        acceptedReadings += 1
        recentPositions.append(reading)
        recentPositions = Array(recentPositions.suffix(8))
        let wasUncertain = status == .uncertain
        // Confirm with time-spaced readings: three callbacks in one burst must not count as three seconds.
        let interval = settings.confirmationSeconds / Double(max(1, settings.confirmationReadings - 1))
        if lastConfirmation == nil || reading.time.timeIntervalSince(lastConfirmation!) >= interval {
            lastConfirmation = reading.time
            detector.confirmationCount = settings.confirmationReadings
            let conservativeDistance =
                detector.offRoute
                ? projection.distance + reading.accuracy : max(0, projection.distance - reading.accuracy)
            if let message = detector.update(distance: conservativeDistance) {
                status = detector.offRoute ? .offRoute : .following
                emit(detector.offRoute ? .offRoute : .rejoined, at: reading.time, message: message)
            }
        }
        if detector.offRoute {
            lastInputDecision = "confirmedOffRoute"
            matchedPosition = nil
            tryReroute(at: reading)
            return Array(events.dropFirst(firstEvent))
        }
        // GPS near buildings is commonly 5–15 m off, so a fix inside the walking corridor is used,
        // weighted by its reported accuracy, instead of pausing guidance.
        guard projection.distance <= settings.matchCorridorMeters else {
            lastInputDecision = "uncertainRouteMatch"
            matchedPosition = nil
            arrivalCount = 0
            arrivalStart = nil
            // Guidance pauses in the gap between the corridor and confirmed departure.
            // Keep the departure streak: these can still be accurate observations of being off path.
            if status != .uncertain {
                emit(
                    .uncertain, at: reading.time,
                    message: "Your position relative to the route is uncertain. Precise guidance is paused.")
            }
            status = .uncertain
            return Array(events.dropFirst(firstEvent))
        }
        if projection.progress <= settings.originMeters { startedNearOrigin = true }
        guard startedNearOrigin else {
            lastInputDecision = "originNotEstablished"
            markUncertain(at: reading.time, message: "Start at the selected route origin before following guidance.")
            return Array(events.dropFirst(firstEvent))
        }
        if wasUncertain { emit(.locationRecovered, at: reading.time, message: "Location readings have recovered.") }
        lastInputDecision = "following"
        status = .following
        updateProgress(measured: projection.progress, accuracy: reading.accuracy, time: reading.time)
        matchedPosition = MapGeometry.coordinate(at: progress, on: route.coordinates)
        for instruction in instructions where !emitted.contains(instruction.id) {
            let distance = instruction.meters - progress
            // A slightly late instruction is still useful; a silently skipped turn is not.
            if distance >= -settings.lateAnnouncementMeters && distance <= settings.turnLeadMeters {
                emitted.insert(instruction.id)
                let isTurn = instruction.kind == .turnLeft || instruction.kind == .turnRight
                let message =
                    !isTurn
                    ? instruction.message
                    : distance <= 4
                        ? "Now \(instruction.message)."
                        : "In about \(Int(distance.rounded())) meters, \(instruction.message)."
                emit(instruction.kind, at: reading.time, message: message, distance: max(0, distance))
            }
        }
        // Arrival requires both path completion and proximity to the intended endpoint, over several fixes.
        if let end = route.coordinates.last,
            remaining <= settings.arrivalRadius,
            end.distance(to: reading.coordinate) <= settings.arrivalRadius + min(reading.accuracy, 10)
        {
            if arrivalStart == nil { arrivalStart = reading.time }
            arrivalCount += 1
            if arrivalCount >= settings.confirmationReadings,
                reading.time.timeIntervalSince(arrivalStart!) >= settings.confirmationSeconds
            {
                status = .arrived
                emit(
                    .arrived, at: reading.time,
                    message: source == .live
                        ? "You have reached the mapped destination."
                        : source == .simulation
                            ? "Simulated arrival at the destination." : "Replayed arrival at the destination.")
            }
        } else {
            arrivalStart = nil
            arrivalCount = 0
        }
        return Array(events.dropFirst(firstEvent))
    }

    /// Called by the live timer even when Core Location stops delivering fixes.
    mutating func checkFreshness(now: Date) {
        guard status != .arrived, status != .stopped else { return }
        if lastAccepted == nil || now.timeIntervalSince(lastAccepted!.time) > settings.maximumAge {
            markUncertain(at: now)
        }
    }

    /// A rejected fix only pauses guidance once good fixes have been missing for a few seconds;
    /// one noisy reading should not interrupt the walker with an announcement.
    private mutating func degrade(at time: Date, now: Date) {
        if let lastAccepted, time.timeIntervalSince(lastAccepted.time) <= settings.uncertainGraceSeconds { return }
        markUncertain(at: min(time, now))
    }

    /// Alpha–beta filter on distance along the route. Accurate fixes move the estimate quickly;
    /// poor fixes nudge it. Speed is estimated so the estimate keeps advancing between fixes.
    private mutating func updateProgress(measured: Double, accuracy: Double, time: Date) {
        guard let last = lastProgressTime else {
            progress = measured
            speed = 0
            lastProgressTime = time
            return
        }
        let dt = max(0.05, time.timeIntervalSince(last))
        let predicted = min(route.distance, progress + speed * min(dt, 3))
        let residual = measured - predicted
        let trust = 1 / (1 + pow(max(accuracy, 1) / 8, 2))
        let alpha = 0.3 + 0.6 * trust
        let beta = 0.15 * trust
        speed = min(settings.maximumRouteSpeed, max(0, speed + beta * residual / dt))
        // Walkers rarely reverse along a guided route; allow only small backward corrections per fix.
        let next = max(predicted + alpha * residual, progress - 3)
        progress = min(route.distance, max(0, next))
        lastProgressTime = time
    }

    mutating func markUncertain(at time: Date, message: String = "Location is uncertain. Precise guidance is paused.") {
        if status != .uncertain { emit(.uncertain, at: time, message: message) }
        status = .uncertain
        matchedPosition = nil
        detector.resetConfirmation()
        lastConfirmation = nil
        arrivalStart = nil
        arrivalCount = 0
    }

    mutating func stop(at time: Date) {
        guard status != .stopped else { return }
        status = .stopped
        emit(.stopped, at: time, message: "Navigation ended.")
    }

    /// Scripted observations are kept separate from verified map warnings and never emitted in live mode.
    mutating func demonstrate(_ message: String, at time: Date) {
        guard source == .simulation else { return }
        emit(.demonstration, at: time, message: message)
    }

    private mutating func tryReroute(at reading: NavigationPosition) {
        if let lastRerouteAttempt, reading.time.timeIntervalSince(lastRerouteAttempt) < settings.rerouteCooldown {
            return
        }
        lastRerouteAttempt = reading.time
        var verifiedPreferences = preferences
        verifiedPreferences.verifiedOnly = true
        guard let node = RoutePlanner.matchedNode(point: reading.coordinate, accuracy: reading.accuracy, graph: graph),
            node.id != route.destination,
            let replacement = try? RoutePlanner.plan(
                graph: graph, from: node.id, to: route.destination, preferences: verifiedPreferences),
            replacement.isVerified
        else {
            if events.last?.kind != .noRoute {
                emit(
                    .noRoute, at: reading.time,
                    message:
                        "A reliable replacement route is unavailable. No verified graph connection could be established."
                )
            }
            return
        }
        route = replacement
        instructions = RouteInstructions.make(for: replacement)
        progress = 0
        speed = 0
        lastProgressTime = nil
        emitted = []
        detector = OffRouteDetector()
        detector.departureMeters = settings.departureMeters
        detector.returnMeters = settings.rejoinMeters
        lastConfirmation = nil
        startedNearOrigin = true
        status = .following
        arrivalCount = 0
        arrivalStart = nil
        emit(
            .rerouted, at: reading.time, message: "A replacement route has been calculated from the verified junction.")
    }

    private mutating func emit(_ kind: NavigationEvent.Kind, at time: Date, message: String, distance: Double? = nil) {
        events.append(
            NavigationEvent(
                id: events.count, kind: kind, time: time, message: message,
                progressMeters: progress, distanceToDecision: distance))
    }
}
