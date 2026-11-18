import Foundation
import MapKit

/// Runs deterministic checks on production models, without permissions, network calls, or sensors.
@main
struct ModelChecks {
    static func main() throws {
        let resources = URL(fileURLWithPath: CommandLine.arguments[1])
        try NavigationChecks.run(resources: resources)
        try NavigationEvaluationChecks.run(
            resources: resources,
            output: CommandLine.arguments.count > 2 ? URL(fileURLWithPath: CommandLine.arguments[2]) : nil)
        try WalkModelChecks.run(sample: resources.appending(path: "Recordings/BoydWalkSample.json"))
        checkGreeting()
        checkSavedPlaces()
        try checkDestinationRequests()
        checkRoute(resources.appending(path: "Routes/boyd_to_library.geojson"))
        print(
            "PASS: greeting boundaries, exact saved IDs, voice parsing, route bounds, turns, and simulation scenarios")
    }

    private static func checkGreeting() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        for (hour, expected) in [
            (0, "evening"), (4, "evening"), (5, "morning"), (11, "morning"),
            (12, "afternoon"), (16, "afternoon"), (17, "evening"), (23, "evening"),
        ] {
            let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 13, hour: hour))!
            precondition(HomeGreeting.text(at: date, calendar: calendar) == "Good \(expected), Edmund")
        }
        // The same instant must use the local time zone, not an assumed UTC hour.
        let midnightUTC = calendar.date(from: DateComponents(year: 2026, month: 11, day: 13, hour: 0))!
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        precondition(HomeGreeting.text(at: midnightUTC, calendar: calendar) == "Good morning, Edmund")
    }

    private static func checkSavedPlaces() {
        let saved = SavedPlaces.updating("boyd", saved: true, in: "library")
        precondition(SavedPlaces.contains("boyd", in: saved))
        precondition(!SavedPlaces.contains("boy", in: saved), "IDs must not match substrings")
        precondition(
            SavedPlaces.updating("boyd", saved: true, in: saved) == saved, "Saving twice must not duplicate IDs")
        precondition(SavedPlaces.updating("boyd", saved: false, in: saved) == "library")
    }

    private static func checkDestinationRequests() throws {
        let request = try VoiceDestinationParser.parse("From Boyd Hall to the library").get()
        precondition(request.destination.id == "library")
        guard case .place(let origin) = request.origin else { preconditionFailure("Expected an explicit origin") }
        precondition(origin.id == "boyd")
        let reverse = try VoiceDestinationParser.parse("Take me to Boyd Hall from the library").get()
        precondition(reverse.destination.id == "boyd")
        guard case .place(let library) = reverse.origin else { preconditionFailure("Expected library origin") }
        precondition(library.id == "library")
        let current = try VoiceDestinationParser.parse("From here to Boyd Hall").get()
        guard case .currentLocation = current.origin else { preconditionFailure("Expected current location") }
        let destinationOnly = try VoiceDestinationParser.parse("Library").get()
        precondition(destinationOnly.origin == nil)
        for invalid in ["Boyd or library", "Take me to the stadium", "From nowhere to library", "Libraryish"] {
            guard case .failure = VoiceDestinationParser.parse(invalid) else {
                preconditionFailure("An ambiguous or unsupported phrase must not silently select a route")
            }
        }
    }

    private static func checkRoute(_ url: URL) {
        guard let route = SimulationRoute(url: url) else {
            preconditionFailure("Bundled route must load after moving resources")
        }
        precondition(route.turnCues.count == 2, "Keep both turns in the reference route")
        precondition(route.turnCues.allSatisfy { $0.direction == "right" })
        precondition(MKMapPoint(route.coordinate(at: -10)).distance(to: route.points[0]) < 0.01)
        precondition(MKMapPoint(route.coordinate(at: route.length + 10)).distance(to: route.points.last!) < 0.01)
        for scenario in WalkScenario.allCases {
            var detector = OffRouteDetector()
            var events: [String] = []
            var previous = 0.0
            var cues = 0
            // Enough steps for the route plus the scripted 60 m out-and-back detour.
            for step in 0...Int(ceil((route.length + 61) / 0.7)) {
                let sample = route.sample(step, scenario)
                if let event = detector.update(distance: route.distanceFromPath(sample.position)) {
                    events.append(event)
                }
                cues += route.turnCues.filter { $0.crossesTrigger(from: previous, to: sample.progress) }.count
                previous = sample.progress
            }
            precondition(cues == 2, "Each turn should be announced once")
            if scenario == .missedTurn {
                precondition(events == ["You appear to be off route.", "You’re back on the route."])
            } else {
                precondition(
                    events.isEmpty, "Normal travel and one stray GPS sample must not trigger an off-route warning")
            }
        }
    }
}
