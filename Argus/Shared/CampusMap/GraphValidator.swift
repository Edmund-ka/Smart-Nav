import Foundation

struct GraphValidationReport {
    var errors: [String] = []
    var warnings: [String] = []
    var summary: String {
        (["\(errors.count) errors · \(warnings.count) warnings"] + errors + warnings).joined(separator: "\n")
    }
}

/// Reject structural corruption before routing; disconnected coverage remains a visible warning.
enum GraphValidator {
    static func validate(_ graph: CampusGraph) -> GraphValidationReport {
        var result = GraphValidationReport()
        if graph.schemaVersion != 1 { result.errors.append("Unsupported graph schema.") }
        if graph.id.isEmpty || graph.version.isEmpty || graph.nodes.isEmpty || graph.edges.isEmpty {
            result.errors.append("Graph identity, version, nodes, and edges are required.")
        }
        if graph.sources.isEmpty
            || graph.sources.contains(where: {
                $0.name.isEmpty || $0.url.isEmpty || $0.license.isEmpty || $0.retrieved.isEmpty
            })
        {
            result.errors.append("Every dataset needs source, URL, license, and retrieval date.")
        }
        var ids = Set<String>()
        var placeIDs = Set<String>()
        for node in graph.nodes {
            if node.id.isEmpty || !ids.insert(node.id).inserted {
                result.errors.append("Duplicate/empty node ID: \(node.id)")
            }
            if !node.coordinate.isValid { result.errors.append("Invalid coordinate: \(node.id)") }
            if let place = node.placeID, !placeIDs.insert(place).inserted {
                result.errors.append("Duplicate place ID: \(place)")
            }
            if node.verification == .verified && ((node.checkedBy ?? "").isEmpty || (node.checkedOn ?? "").isEmpty) {
                result.errors.append("Verified node lacks survey evidence: \(node.id)")
            }
        }
        var edgeIDs = Set<String>()
        var neighbors: [String: Set<String>] = [:]
        for edge in graph.edges {
            if edge.id.isEmpty || !edgeIDs.insert(edge.id).inserted {
                result.errors.append("Duplicate/empty edge ID: \(edge.id)")
            }
            guard let from = graph.node(edge.from), let to = graph.node(edge.to) else {
                result.errors.append("Missing node reference: \(edge.id)")
                continue
            }
            if edge.geometry.count < 2 || !edge.geometry.allSatisfy(\.isValid) {
                result.errors.append("Invalid geometry: \(edge.id)")
                continue
            }
            let measured = MapGeometry.length(edge.geometry)
            if !edge.lengthMeters.isFinite || edge.lengthMeters <= 0 || measured <= 0 || edge.from == edge.to {
                result.errors.append("Invalid/zero length: \(edge.id)")
            }
            if abs(measured - edge.lengthMeters) > max(1, measured * 0.05) {
                result.errors.append("Stored length disagrees with geometry: \(edge.id)")
            }
            if edge.geometry.first!.distance(to: from.coordinate) > 1
                || edge.geometry.last!.distance(to: to.coordinate) > 1
            {
                result.errors.append("Geometry does not meet its nodes: \(edge.id)")
            }
            if let slope = edge.slopePercent, !slope.isFinite || abs(slope) > 100 {
                result.errors.append("Invalid slope: \(edge.id)")
            }
            if let width = edge.widthMeters, !width.isFinite || width <= 0 {
                result.errors.append("Invalid path width: \(edge.id)")
            }
            if edge.source.isEmpty { result.errors.append("Missing edge source: \(edge.id)") }
            if edge.verification == .verified && ((edge.checkedBy ?? "").isEmpty || (edge.checkedOn ?? "").isEmpty) {
                result.errors.append("Verified edge lacks survey evidence: \(edge.id)")
            }
            neighbors[edge.from, default: []].insert(edge.to)
            neighbors[edge.to, default: []].insert(edge.from)
        }
        for node in graph.nodes where neighbors[node.id, default: []].isEmpty {
            result.warnings.append("Isolated \(node.isEntrance ? "entrance" : "node"): \(node.id)")
        }
        // Count components without fabricating links between nearby but separate paths.
        var remaining = Set(graph.nodes.map(\.id))
        var components = 0
        while let first = remaining.sorted().first {
            components += 1
            var stack = [first]
            while let current = stack.popLast() {
                guard remaining.remove(current) != nil else { continue }
                stack.append(contentsOf: neighbors[current, default: []])
            }
        }
        if components > 1 {
            result.warnings.append("\(components) disconnected components; no proximity links were added.")
        }
        let unverified = graph.edges.filter { $0.verification != .verified }.count
        if unverified > 0 { result.warnings.append("\(unverified) edges require field verification.") }
        if graph.isDemonstration { result.warnings.append("Demonstration dataset; unavailable for live guidance.") }
        return result
    }
}
