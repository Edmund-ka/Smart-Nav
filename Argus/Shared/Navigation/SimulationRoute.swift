import MapKit

// Stores the route data, calculates distances, and provides walking coordinates.
struct SimulationRoute {

    // Turn instructions found along the route.
    let turnCues: [TurnInstruction]

    // The complete walking route represented as a line on the map.
    let line: MKPolyline

    // Individual coordinates that make up the route.
    let points: [MKMapPoint]

    // Total distance from the starting location to each route point.
    let cumulativeMeters: [Double]

    // The last cumulative distance represents the total route length.
    var length: Double { cumulativeMeters.last ?? 0 }

    // Loads our Boyd Hall to Library route from a GeoJSON file.
    // init? allows initialization to fail if the route data is invalid.
    init?(url: URL? = Bundle.main.url(forResource: "boyd_to_library", withExtension: "geojson")) {

        // Read and decode the GeoJSON file, find the feature labeled "route",
        // and make sure the route contains at least two points.
        guard let url,
            let data = try? Data(contentsOf: url),
            let objects = try? MKGeoJSONDecoder().decode(data),
            let feature = objects.compactMap({ $0 as? MKGeoJSONFeature }).first(where: { $0.identifier == "route" }),
            let line = feature.geometry.first as? MKPolyline, line.pointCount >= 2
        else { return nil }

        self.line = line

        // Convert the polyline's coordinates into an array for calculations.
        points = Array(UnsafeBufferPointer(start: line.points(), count: line.pointCount))

        // Calculate the cumulative distance between neighboring route points.
        // zip pairs each point with the next point: (A,B), (B,C), (C,D).
        var distances = [0.0]

        for (start, end) in zip(points, points.dropFirst()) {
            distances.append(distances[distances.count - 1] + start.distance(to: end))
        }

        // Make sure the route has a valid distance greater than zero.
        guard let total = distances.last, total > 0 else { return nil }

        cumulativeMeters = distances

        // Identify turns along the route using coordinates and distances.
        turnCues = TurnInstruction.turns(
            points: points.map { CGPoint(x: $0.x, y: $0.y) },
            cumulativeMeters: distances
        )
    }

    // Finds the walker's geographic location based on distance traveled.
    func coordinate(at meters: Double) -> CLLocationCoordinate2D {

        // Clamp requests before the start to the first point, just as requests past the end are clamped below.
        guard meters > 0 else { return points[0].coordinate }

        // Find the first route point farther than the distance traveled.
        // If no point is found, return the destination coordinate.
        guard let end = cumulativeMeters.firstIndex(where: { $0 > meters }), end > 0 else {
            return points[points.count - 1].coordinate
        }

        // Get the point immediately before the ending point.
        let start = end - 1

        // Calculate how far the walker is between the two points.
        // For example, 0.5 means the walker is halfway through the segment.
        let fraction = (meters - cumulativeMeters[start]) / (cumulativeMeters[end] - cumulativeMeters[start])

        let a = points[start]
        let b = points[end]

        // Linear interpolation: calculate the exact position between A and B.
        // This makes the walker move smoothly instead of jumping between points.
        return MKMapPoint(
            x: a.x + fraction * (b.x - a.x),
            y: a.y + fraction * (b.y - a.y)
        ).coordinate
    }
}

// Three scenarios used to test the navigation system.
enum WalkScenario: String, CaseIterable {

    case normal = "Follow the route"

    case missedTurn = "Miss the first turn"

    case noisy = "One stray GPS reading"
}

extension SimulationRoute {

    // Simulates a walker at a particular step under a selected scenario.
    // Returns the progress along the route and the simulated map position.
    func sample(_ step: Int, _ scenario: WalkScenario) -> (progress: Double, position: MKMapPoint) {

        // Each simulation step represents 0.7 meters of travel.
        var traveled = Double(step) * 0.7

        // Find the first turn and check whether the walker has passed it.
        if let bend = turnCues.first?.turnMeters, traveled > bend {

            let pastTurn = traveled - bend

            // MISSED TURN SCENARIO:
            // Simulate walking 30 meters past the turn, then 30 meters back.
            if scenario == .missedTurn && pastTurn <= 60 {

                // Get the turn's location and a point 1 meter before it.
                // These points help determine the direction of the incoming path.
                let corner = MKMapPoint(coordinate(at: bend))
                let approach = MKMapPoint(coordinate(at: bend - 1))

                // Offset increases from 0 to 30, then decreases back to 0.
                // This simulates walking past the turn and returning.
                let offset = min(pastTurn, 60 - pastTurn)

                // Extend the incoming direction beyond the turn.
                // Keep route progress at the turn while the walker is off-route.
                return (
                    bend,
                    MKMapPoint(
                        x: corner.x + offset * (corner.x - approach.x),
                        y: corner.y + offset * (corner.y - approach.y)
                    )
                )
            }

            // Remove the extra 60 meters from route progress after returning.
            if scenario == .missedTurn { traveled -= 60 }

            // NOISY GPS SCENARIO:
            // Introduce one incorrect GPS reading near the first turn.
            if scenario == .noisy && pastTurn <= 0.7 {

                var point = MKMapPoint(coordinate(at: traveled))

                // Shift the reported position approximately 50 meters.
                // Convert meters into MapKit map points using the latitude.
                point.y += 50 * MKMapPointsPerMeterAtLatitude(point.coordinate.latitude)

                // The route progress remains correct, but GPS position is wrong.
                return (traveled, point)
            }
        }

        // NORMAL SCENARIO:
        // Make sure progress never exceeds the total route length.
        let progress = min(traveled, length)

        // Return the simulated position along the actual walking route.
        return (progress, MKMapPoint(coordinate(at: progress)))
    }

    // Calculates the shortest distance from a reported position to the route.
    // This distance is used to determine whether someone is off-route.
    func distanceFromPath(_ position: MKMapPoint) -> Double {

        // Start with infinity because no route segment has been checked yet.
        var nearest = Double.infinity

        // Check every neighboring pair of points along the route.
        for (a, b) in zip(points, points.dropFirst()) {

            // Calculate the direction of the current route segment.
            let dx = b.x - a.x
            let dy = b.y - a.y

            // Calculate the squared length using the Pythagorean formula.
            let squaredLength = dx * dx + dy * dy

            // Skip segments that have no length.
            guard squaredLength > 0 else { continue }

            // Vector projection finds the closest point on the segment's line.
            let fraction = ((position.x - a.x) * dx + (position.y - a.y) * dy) / squaredLength

            // Keep the closest point between the two segment endpoints.
            // 0 = start, 1 = end, 0.5 = halfway.
            let t = max(0, min(1, fraction))

            // Calculate the distance to the closest point on this segment.
            // Keep the smallest distance found across all segments.
            nearest = min(
                nearest,
                position.distance(
                    to: MKMapPoint(
                        x: a.x + dx * t,
                        y: a.y + dy * t
                    )
                )
            )
        }

        // Return the shortest distance from the walker to the route in meters.
        return nearest
    }
}
