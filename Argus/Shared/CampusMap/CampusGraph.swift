import Foundation

/// Verification describes evidence, not an accessibility score. Imported data is always candidate.
enum VerificationStatus: String, Codable { case verified, candidate, unknown }
enum MapFact: String, Codable { case yes, no, unknown }

struct MapSource: Codable {
    var name: String
    var url: String
    var license: String
    var retrieved: String
}

struct CampusNode: Codable, Identifiable {
    var id: String
    var name: String
    var coordinate: MapCoordinate
    var kind: String?
    var spokenDescription: String?
    var doorType: String?
    var openingHours: String?
    var accessibleEntrance: MapFact?
    var isEntrance: Bool
    var placeID: String?
    var verification: VerificationStatus
    var checkedBy: String?
    var checkedOn: String?
}

struct CampusEdge: Codable, Identifiable {
    var id: String
    var from: String
    var to: String
    var geometry: [MapCoordinate]
    var lengthMeters: Double
    var bidirectional: Bool
    var stairs: MapFact
    var crossing: MapFact
    var accessible: MapFact
    var widthMeters: Double?
    var surface: String?
    var slopePercent: Double?
    var restricted: Bool
    var verification: VerificationStatus
    var source: String
    var checkedBy: String?
    var checkedOn: String?
}

/// Versioned graph format shared by the Python importer, validator, planner, and iPhone.
struct WalkRouteReview: Codable {
    var origin: String
    var destination: String
    var edgeIDs: [String]
    var observer: String
    var date: String
    var evidence: String
}

struct CampusGraph: Codable {
    var schemaVersion: Int
    var id: String
    var name: String
    var version: String
    var isDemonstration: Bool
    var sources: [MapSource]
    var nodes: [CampusNode]
    var edges: [CampusEdge]
    var walkReview: WalkRouteReview? = nil

    /// A walked route can be tested with live GPS without claiming independently surveyed geometry.
    /// Review authorizes only this direction and exact ordered edge sequence, never other campus paths.
    func permitsLiveGuidance(for route: PlannedRoute) -> Bool {
        guard !isDemonstration, route.graphID == id, route.graphVersion == version else { return false }
        if route.isVerified { return true }
        guard let review = walkReview, !review.observer.isEmpty, !review.date.isEmpty, !review.evidence.isEmpty else {
            return false
        }
        return route.origin == review.origin && route.destination == review.destination
            && route.steps.map { $0.edge.id } == review.edgeIDs
    }

    static func homeMap() throws -> Self {
        guard let url = Bundle.main.url(forResource: "boyd_library_walked", withExtension: "json") else {
            throw GraphLoadError.invalid("Walked campus route is missing.")
        }
        return try load(url)
    }

    func node(_ id: String) -> CampusNode? { nodes.first { $0.id == id } }

    /// The start of the walk-reviewed route that ends at `destination`. Home uses it when the
    /// walker's own position cannot be matched to a verified junction, and tells them how far away it is.
    func reviewedOrigin(endingAt destination: String) -> CampusNode? {
        guard let review = walkReview, review.destination == destination else { return nil }
        return node(review.origin)
    }
    func entrance(for placeID: String) -> CampusNode? { nodes.first { $0.placeID == placeID && $0.isEntrance } }

    static func load(_ url: URL) throws -> Self {
        let graph = try GraphFileFormat.decode(Data(contentsOf: url))
        let report = GraphValidator.validate(graph)
        guard report.errors.isEmpty else { throw GraphLoadError.invalid(report.errors.joined(separator: "\n")) }
        return graph
    }

    static func bundled() throws -> Self {
        guard let url = Bundle.main.url(forResource: "boyd_library_graph", withExtension: "json") else {
            throw GraphLoadError.invalid("Bundled campus graph is missing.")
        }
        return try load(url)
    }
}

enum GraphLoadError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}
