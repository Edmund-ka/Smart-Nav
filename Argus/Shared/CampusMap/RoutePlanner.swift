import Foundation

/// Restrictions remove edges; preference penalties only change the cost of allowed edges.
struct RoutePreferences: Codable, Equatable {
    var avoidStairs = false
    var allowUnknownAccess = true
    var verifiedOnly = false
    var crossingMultiplier = 1.2
    var roughSurfaceMultiplier = 1.3
    var steepSlopeMultiplier = 1.4

    func cost(for edge: CampusEdge) -> Double? {
        guard !edge.restricted, edge.accessible != .no,
            !verifiedOnly || edge.verification == .verified,
            !avoidStairs || edge.stairs == .no,
            allowUnknownAccess || (edge.accessible == .yes && edge.stairs != .unknown)
        else { return nil }
        // Initial engineering preferences, not validated accessibility scores.
        var multiplier = 1.0
        if edge.crossing == .yes { multiplier *= crossingMultiplier }
        if ["gravel", "unpaved", "cobblestone", "ground"].contains(edge.surface ?? "") {
            multiplier *= roughSurfaceMultiplier
        }
        if abs(edge.slopePercent ?? 0) > 5 { multiplier *= steepSlopeMultiplier }
        return edge.lengthMeters * multiplier
    }

    var isValid: Bool {
        [crossingMultiplier, roughSurfaceMultiplier, steepSlopeMultiplier].allSatisfy { $0.isFinite && $0 >= 1 }
    }
}

struct RouteStep {
    let edge: CampusEdge
    let reversed: Bool
    var geometry: [MapCoordinate] { reversed ? Array(edge.geometry.reversed()) : edge.geometry }
    var start: String { reversed ? edge.to : edge.from }
    var end: String { reversed ? edge.from : edge.to }
}

struct PlannedRoute {
    let graphID: String
    let graphVersion: String
    let origin: String
    let destination: String
    let steps: [RouteStep]
    let cost: Double
    let isDemonstration: Bool
    let hasVerifiedNodes: Bool
    var coordinates: [MapCoordinate] {
        guard let first = steps.first else { return [] }
        return first.geometry + steps.dropFirst().flatMap { $0.geometry.dropFirst() }
    }
    var distance: Double { steps.reduce(0) { $0 + $1.edge.lengthMeters } }
    var isVerified: Bool {
        !isDemonstration && hasVerifiedNodes && !steps.isEmpty && steps.allSatisfy { $0.edge.verification == .verified }
    }
    var id: String { graphID + ":" + graphVersion + ":" + origin + ":" + destination }
}

enum RoutePlanningError: LocalizedError {
    case invalidGraph, invalidPreferences, unknownPlace, samePlace, noRoute
    var errorDescription: String? {
        switch self {
        case .invalidGraph: return "The campus graph did not pass validation."
        case .invalidPreferences: return "Route penalties must be finite and at least one."
        case .unknownPlace: return "This origin or destination is not mapped."
        case .samePlace: return "Choose a different starting point."
        case .noRoute:
            return
                "No mapped path satisfies these accessibility settings. Unknown stair information cannot establish a stair-free route."
        }
    }
}

/// Dijkstra's algorithm: repeatedly settle the cheapest reachable node, then relax its edges.
/// O(V² + E) is deliberately simple for the small campus graph; no external routing service is used.
enum RoutePlanner {
    static func plan(
        graph: CampusGraph, from origin: String, to destination: String,
        preferences: RoutePreferences = RoutePreferences()
    ) throws -> PlannedRoute {
        guard GraphValidator.validate(graph).errors.isEmpty else { throw RoutePlanningError.invalidGraph }
        guard preferences.isValid else { throw RoutePlanningError.invalidPreferences }
        guard graph.node(origin) != nil, graph.node(destination) != nil else { throw RoutePlanningError.unknownPlace }
        guard origin != destination else { throw RoutePlanningError.samePlace }
        var adjacency: [String: [RouteStep]] = [:]
        for edge in graph.edges.sorted(by: { $0.id < $1.id }) where preferences.cost(for: edge) != nil {
            adjacency[edge.from, default: []].append(RouteStep(edge: edge, reversed: false))
            if edge.bidirectional { adjacency[edge.to, default: []].append(RouteStep(edge: edge, reversed: true)) }
        }
        var costs = [origin: 0.0]
        var previous: [String: RouteStep] = [:]
        var settled = Set<String>()
        while let current = costs.keys.filter({ !settled.contains($0) }).min(by: {
            costs[$0]! == costs[$1]! ? $0 < $1 : costs[$0]! < costs[$1]!
        }) {
            if current == destination { break }
            settled.insert(current)
            for step in adjacency[current, default: []] {
                guard !settled.contains(step.end), let weight = preferences.cost(for: step.edge) else { continue }
                let nextCost = costs[current]! + weight
                if nextCost < costs[step.end, default: .infinity] {
                    costs[step.end] = nextCost
                    previous[step.end] = step
                }
            }
        }
        guard let cost = costs[destination] else { throw RoutePlanningError.noRoute }
        var steps: [RouteStep] = []
        var cursor = destination
        while cursor != origin {
            guard let step = previous[cursor] else { throw RoutePlanningError.noRoute }
            steps.append(step)
            cursor = step.start
        }
        return PlannedRoute(
            graphID: graph.id, graphVersion: graph.version, origin: origin, destination: destination,
            steps: steps.reversed(), cost: cost, isDemonstration: graph.isDemonstration,
            hasVerifiedNodes: steps.allSatisfy {
                graph.node($0.start)?.verification == .verified && graph.node($0.end)?.verification == .verified
            })
    }

    /// Replanning starts only at a uniquely matched, verified node. No off-graph connector is invented.
    /// This conservative baseline asks the user to reach a known junction rather than snapping across a road.
    static func matchedNode(
        point: MapCoordinate, accuracy: Double, graph: CampusGraph,
        radius: Double = 5
    ) -> CampusNode? {
        guard accuracy >= 0, accuracy <= radius, !graph.isDemonstration else { return nil }
        let candidates = graph.nodes.filter {
            $0.verification == .verified && $0.coordinate.distance(to: point) + accuracy <= radius
        }
        return candidates.count == 1 ? candidates[0] : nil
    }
}
