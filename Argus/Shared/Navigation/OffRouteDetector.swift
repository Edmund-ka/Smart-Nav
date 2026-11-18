// Detects whether the walker has left or returned to the planned route.

struct OffRouteDetector {
    // Demo settings, not field-calibrated safety thresholds.
    var departureMeters = 12.0
    var returnMeters = 5.0
    var confirmationCount = 3

    // False means the walker is currently considered on-route.
    private(set) var offRoute = false

    // Count consecutive readings before changing the route status.
    private var consecutive = 0

    /// Break a confirmation streak after uncertain or stale observations, without forgetting route state.
    mutating func resetConfirmation() { consecutive = 0 }

    // Returns an alert message or nil if no status change is confirmed.
    // mutating is required because this function changes stored properties.
    mutating func update(distance: Double) -> String? {

        // HYSTERESIS:
        // If on-route, 12+ meters counts toward an off-route warning.
        // If off-route, 5 meters or less counts toward returning.
        // Different thresholds prevent repeated alerts from GPS fluctuations.
        let changed = offRoute ? distance <= returnMeters : distance >= departureMeters

        // Increase the counter if the condition is met; otherwise reset it.
        consecutive = changed ? consecutive + 1 : 0

        // Require three consecutive readings to confirm a status change.
        // This helps prevent false alerts from a single bad GPS reading.
        guard consecutive >= confirmationCount else { return nil }

        // Reset the counter after confirming the change.
        consecutive = 0

        // Switch between on-route and off-route.
        offRoute.toggle()

        // Return the appropriate message for the new route status.
        return offRoute
            ? "You appear to be off route."
            : "You’re back on the route."
    }
}
