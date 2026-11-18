import Foundation

// Checks the real saved-data models without starting any sensors.
struct WalkModelChecks {
    static func run(sample: URL) throws {
        let walk = try JSONDecoder().decode(WalkData.self, from: Data(contentsOf: sample))
        precondition(!walk.readings.isEmpty, "Existing bundled recording must remain readable")
        precondition(walk.duration >= 0 && walk.measuredDistance >= 0)
        precondition(walk.meanReportedAccuracy != nil)
        var named = walk
        named.name = "Campus accessibility check"
        let roundtrip = try JSONDecoder().decode(WalkData.self, from: JSONEncoder().encode(named))
        precondition(roundtrip.title == named.name)
        precondition(roundtrip.readings.count == walk.readings.count)
        precondition(roundtrip.marks?.count == walk.marks?.count)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var fixture = WalkData(id: UUID(), started: start)
        precondition(fixture.meanReportedAccuracy == nil)
        precondition(fixture.measuredDistance == 0)
        fixture.readings = [
            WalkReading(time: start, latitude: 36, longitude: -86, accuracyMeters: 5),
            WalkReading(time: start.addingTimeInterval(2), latitude: 36.00001, longitude: -86, accuracyMeters: 5),
        ]
        precondition(fixture.measuredDistance > 1 && fixture.measuredDistance < 2, "Keep plausible pedestrian movement")
        fixture.readings.append(
            WalkReading(time: start.addingTimeInterval(3), latitude: 37, longitude: -86, accuracyMeters: 5))
        precondition(fixture.measuredDistance < 2, "Reject impossible GPS jump")
        fixture.readings[1] = WalkReading(
            time: start.addingTimeInterval(2), latitude: 36.00001, longitude: -86, accuracyMeters: 100)
        precondition(fixture.measuredDistance == 0, "Reject distance derived from poor fixes")
        fixture.readings[1] = WalkReading(
            time: start.addingTimeInterval(2), latitude: 36.00001, longitude: -86, accuracyMeters: -1)
        precondition(fixture.measuredDistance == 0, "Negative accuracy means an invalid fix")
        fixture.ended = start.addingTimeInterval(-1)
        precondition(fixture.duration == 0, "Duration cannot be negative")
        print(
            "PASS: legacy recording, named JSON round trip, event preservation, empty metrics, pedestrian movement, GPS jump, poor accuracy and duration"
        )
    }
}
