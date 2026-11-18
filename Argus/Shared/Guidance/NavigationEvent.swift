import Foundation

enum PositionSource: String, Codable { case live, simulation, recording }
struct NavigationPosition: Codable {
    var time: Date
    var coordinate: MapCoordinate
    var accuracy: Double
    var source: PositionSource
}

/// Events are data, so speech, haptics, UI, replay, and future wearables can consume the same result.
struct NavigationEvent: Codable, Equatable, Identifiable {
    enum Kind: String, Codable {
        case started, turnLeft, turnRight, crossing, accessibility, offRoute, rejoined
        case rerouted, noRoute, uncertain, locationRecovered, arrived, stopped, demonstration
    }
    let id: Int
    let kind: Kind
    let time: Date
    let message: String
    let progressMeters: Double
    let distanceToDecision: Double?
}

/// Values are prototype parameters, exposed here for calibration rather than hidden in screens.
struct NavigationSettings {
    var turnLeadMeters = 25.0
    var departureMeters = 12.0
    var rejoinMeters = 5.0
    var maximumAccuracy = 30.0
    var maximumAge = 10.0
    var maximumGap = 10.0
    var maximumWalkingSpeed = 4.0
    var arrivalRadius = 8.0
    var confirmationSeconds = 2.0
    var confirmationReadings = 3
    var rerouteCooldown = 10.0
    /// Fixes this far from the route line still count as on the walkway (GPS error near buildings).
    var matchCorridorMeters = 20.0
    /// Map-matching search window behind/ahead of the current estimate.
    var matchBehindMeters = 15.0
    var matchAheadMeters = 30.0
    /// Guidance begins once a fix matches within this distance of the route start.
    var originMeters = 25.0
    /// Turns passed by up to this distance are still announced.
    var lateAnnouncementMeters = 8.0
    /// Seconds of rejected fixes tolerated before guidance announces uncertainty.
    var uncertainGraceSeconds = 6.0
    /// Upper bound for the smoothed along-route walking speed (m/s).
    var maximumRouteSpeed = 2.5
}

/// Future input contract only. No recognizer or wearable producer is implemented or implied.
struct LandmarkObservation: Codable {
    let landmarkID: String
    let confidence: Double
    let time: Date
    let estimatedCoordinate: MapCoordinate?
    let source: String
}
