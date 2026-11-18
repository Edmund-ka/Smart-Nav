import Foundation

/// Geographic storage stays in latitude/longitude; calculations below explicitly use metres.
struct MapCoordinate: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var isValid: Bool {
        latitude.isFinite && longitude.isFinite && abs(latitude) <= 90 && abs(longitude) <= 180
    }

    /// Haversine distance on a spherical Earth. Suitable for the campus-scale baseline.
    func distance(to other: Self) -> Double {
        let radians = Double.pi / 180
        let a =
            pow(sin((other.latitude - latitude) * radians / 2), 2)
            + cos(latitude * radians) * cos(other.latitude * radians)
            * pow(sin((other.longitude - longitude) * radians / 2), 2)
        return 6_371_000 * 2 * asin(sqrt(min(1, max(0, a))))
    }

    /// Initial great-circle bearing in degrees clockwise from north.
    func bearing(to other: Self) -> Double {
        let radians = Double.pi / 180
        let y = sin((other.longitude - longitude) * radians) * cos(other.latitude * radians)
        let x =
            cos(latitude * radians) * sin(other.latitude * radians)
            - sin(latitude * radians) * cos(other.latitude * radians) * cos((other.longitude - longitude) * radians)
        let degrees = atan2(y, x) / radians
        return degrees < 0 ? degrees + 360 : degrees
    }
}

struct PathProjection {
    let coordinate: MapCoordinate
    let distance: Double
    let progress: Double
    let segment: Int
}

/// Small local tangent-plane calculations avoid treating longitude degrees as metres.
enum MapGeometry {
    static func length(_ points: [MapCoordinate]) -> Double {
        zip(points, points.dropFirst()).reduce(0) { $0 + $1.0.distance(to: $1.1) }
    }

    static func project(_ point: MapCoordinate, onto path: [MapCoordinate]) -> PathProjection? {
        project(point, onto: path, within: nil)
    }

    /// Windowed map matching: only the part of the path between `range` metres is considered.
    /// Restricting the search to where the walker could plausibly be prevents jumps between
    /// distant parts of a route that happen to lie near each other.
    static func project(
        _ point: MapCoordinate, onto path: [MapCoordinate], within range: ClosedRange<Double>?
    ) -> PathProjection? {
        var nearest: PathProjection?
        var cumulative = 0.0
        for index in 0..<max(0, path.count - 1) {
            let a = path[index]
            let b = path[index + 1]
            let length = a.distance(to: b)
            defer { cumulative += length }
            let scaleY = 6_371_000 * Double.pi / 180
            let scaleX = scaleY * cos(a.latitude * Double.pi / 180)
            let bx = (b.longitude - a.longitude) * scaleX
            let by = (b.latitude - a.latitude) * scaleY
            let px = (point.longitude - a.longitude) * scaleX
            let py = (point.latitude - a.latitude) * scaleY
            let squared = bx * bx + by * by
            guard squared > 0 else { continue }
            // Q = A + t(B-A), t = clamp(((P-A)·(B-A))/|B-A|², 0, 1).
            // P is the observation; Q is its closest point on this finite walkway segment.
            var lower = 0.0
            var upper = 1.0
            if let range, length > 0 {
                if cumulative > range.upperBound || cumulative + length < range.lowerBound { continue }
                lower = max(0, (range.lowerBound - cumulative) / length)
                upper = min(1, (range.upperBound - cumulative) / length)
            }
            let t = min(upper, max(lower, (px * bx + py * by) / squared))
            let q = MapCoordinate(
                latitude: a.latitude + t * (b.latitude - a.latitude),
                longitude: a.longitude + t * (b.longitude - a.longitude))
            let candidate = PathProjection(
                coordinate: q, distance: point.distance(to: q),
                progress: cumulative + t * length, segment: index)
            if nearest == nil || candidate.distance < nearest!.distance { nearest = candidate }
        }
        return nearest
    }

    /// The part of a path between two distances, used to draw travelled and remaining route lines.
    static func slice(_ path: [MapCoordinate], from start: Double, to end: Double) -> [MapCoordinate] {
        guard path.count > 1, end > start, let first = coordinate(at: start, on: path),
            let last = coordinate(at: end, on: path)
        else { return [] }
        var result = [first]
        var cumulative = 0.0
        for (a, b) in zip(path, path.dropFirst()) {
            cumulative += a.distance(to: b)
            if cumulative > start && cumulative < end { result.append(b) }
        }
        result.append(last)
        return result
    }

    /// Compass bearing (degrees clockwise from north) of the path at a distance along it.
    static func bearing(at meters: Double, on path: [MapCoordinate]) -> Double {
        guard path.count > 1 else { return 0 }
        var cumulative = 0.0
        for (a, b) in zip(path, path.dropFirst()) {
            let length = a.distance(to: b)
            if meters < cumulative + length { return a.bearing(to: b) }
            cumulative += length
        }
        return path[path.count - 2].bearing(to: path[path.count - 1])
    }

    static func coordinate(at meters: Double, on path: [MapCoordinate]) -> MapCoordinate? {
        guard let first = path.first else { return nil }
        if meters <= 0 { return first }
        var remaining = meters
        for (a, b) in zip(path, path.dropFirst()) {
            let length = a.distance(to: b)
            if remaining <= length, length > 0 {
                let t = remaining / length
                return MapCoordinate(
                    latitude: a.latitude + t * (b.latitude - a.latitude),
                    longitude: a.longitude + t * (b.longitude - a.longitude))
            }
            remaining -= length
        }
        return path.last
    }
}
