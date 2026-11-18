import CoreLocation
import Foundation

/// Transport conversion only. No adapter filters accuracy, changes coordinates, or invents sensor time.
enum NavigationInputs {
    static func live(_ locations: [CLLocation]) -> [NavigationPosition] {
        orderedLocations(locations).map {
            NavigationPosition(
                time: $0.timestamp,
                coordinate: MapCoordinate(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude),
                accuracy: $0.horizontalAccuracy, source: .live)
        }
    }

    static func orderedLocations(_ locations: [CLLocation]) -> [CLLocation] {
        locations.enumerated().sorted {
            $0.element.timestamp == $1.element.timestamp
                ? $0.offset < $1.offset : $0.element.timestamp < $1.element.timestamp
        }.map(\.element)
    }

    static func recording(_ walk: WalkData) -> [NavigationPosition] {
        // Equal-time samples retain input order; the engine rejects duplicate timestamps consistently.
        walk.readings.enumerated().sorted {
            $0.element.time == $1.element.time ? $0.offset < $1.offset : $0.element.time < $1.element.time
        }.map { _, reading in
            NavigationPosition(
                time: reading.time, coordinate: MapCoordinate(latitude: reading.latitude, longitude: reading.longitude),
                accuracy: reading.accuracyMeters, source: .recording)
        }
    }

    static func simulated(time: Date, coordinate: MapCoordinate, accuracy: Double = 1) -> NavigationPosition {
        NavigationPosition(time: time, coordinate: coordinate, accuracy: accuracy, source: .simulation)
    }
}
