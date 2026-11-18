import MapKit

/// A supported campus destination. Coordinates are reference points, not surveyed entrances.
struct CampusPlace: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
    let latitude: Double
    let longitude: Double
    let icon: String
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var mapItem: MKMapItem {
        let item = MKMapItem(location: CLLocation(latitude: latitude, longitude: longitude), address: nil)
        item.name = name
        return item
    }
    static let places = [
        CampusPlace(
            id: "library", name: "TSU Library", detail: "Campus destination · entrance unverified",
            latitude: 36.1658583, longitude: -86.8283694, icon: "books.vertical.fill"),
        CampusPlace(
            id: "boyd", name: "Boyd Hall", detail: "Campus destination · entrance unverified", latitude: 36.1654389,
            longitude: -86.8275056, icon: "building.2.fill"),
    ]
}

// Imported graphs can add destinations without adding another screen or route algorithm.
extension CampusPlace {
    static func available(in graph: CampusGraph?) -> [CampusPlace] {
        guard let graph else { return places }
        return graph.nodes.filter { $0.isEntrance && $0.placeID != nil }.map { node in
            CampusPlace(
                id: node.placeID!, name: node.name, detail: "Entrance · \(node.verification.rawValue)",
                latitude: node.coordinate.latitude, longitude: node.coordinate.longitude,
                icon: places.first { $0.id == node.placeID }?.icon ?? "building.2.fill")
        }
    }
}
