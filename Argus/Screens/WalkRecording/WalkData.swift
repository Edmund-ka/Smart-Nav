import CoreLocation
import Foundation

/// Codable models define the saved JSON format. Optional fields keep older walks readable.
struct WalkReading: Codable {
    let time: Date
    let latitude: Double
    let longitude: Double
    let accuracyMeters: Double

    var altitudeMeters, verticalAccuracyMeters: Double?
    var speedMetersPerSecond, speedAccuracyMetersPerSecond: Double?
    var courseDegrees, courseAccuracyDegrees: Double?
    var simulatedBySoftware: Bool?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Compass direction and the uncertainty reported by Core Location.
struct CompassReading: Codable {
    let time: Date
    let magneticDegrees: Double
    let trueDegrees: Double?
    let accuracyDegrees: Double
}

/// Motion samples share wall-clock timestamps with GPS for later replay and comparison.
struct MotionReading: Codable {
    let time: Date
    // Each vector uses the phone’s x, y, z axes. Acceleration and gravity are measured in g.
    let accelerationG, gravityG, rotationRadiansPerSecond: [Double]
    let attitudeQuaternionXYZW: [Double]
}

/// A timestamped event the user marks during a real walk.
struct WalkMark: Codable {
    let time: Date
    let label: String
}

/// One saved walk, including raw fixes and optional measurements introduced in later versions.
struct WalkData: Codable, Identifiable {
    let id: UUID
    let started: Date
    var ended: Date?
    var compass: [CompassReading]?
    var motion: [MotionReading]?
    var marks: [WalkMark]?
    var readings: [WalkReading] = []
    var name: String?
    // Optional metadata preserves compatibility with existing recordings. A snapshot makes replay reproducible after map updates.
    var schemaVersion: Int?
    var routeID: String?
    var graphSnapshot: CampusGraph?
    var originNodeID: String?
    var destinationNodeID: String?

    var title: String {
        if let name, !name.isEmpty { return name }
        return started.formatted(date: .abbreviated, time: .shortened)
    }
    var meanReportedAccuracy: Double? {
        guard !readings.isEmpty else { return nil }
        let total: Double = readings.reduce(0.0) { $0 + $1.accuracyMeters }
        return total / Double(readings.count)
    }
    var duration: TimeInterval { max(0, (ended ?? readings.last?.time ?? started).timeIntervalSince(started)) }
    /// Sum plausible GPS segments. The 25 m accuracy and 4 m/s speed limits are configured filters.
    var measuredDistance: Double {
        zip(readings, readings.dropFirst()).reduce(0) { total, pair in
            // Ignore very poor fixes and impossible jumps rather than inflating the distance.
            let (a, b) = pair
            let elapsed = b.time.timeIntervalSince(a.time)
            let distance = CLLocation(latitude: a.latitude, longitude: a.longitude).distance(
                from: CLLocation(latitude: b.latitude, longitude: b.longitude))
            guard elapsed > 0, (0...25).contains(a.accuracyMeters), (0...25).contains(b.accuracyMeters),
                distance / elapsed <= 4
            else { return total }
            return total + distance
        }
    }
}
