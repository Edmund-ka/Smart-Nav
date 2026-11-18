import Combine
import CoreLocation

/// Requests a single GPS fix when the user asks; this is separate from walk recording.
final class CurrentLocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var location: CLLocation?
    @Published private(set) var status = "Choose a destination to get started."
    private let manager = CLLocationManager()
    private var requested = false
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    /// Request permission only after a location action, then ask for one fresh fix.
    func request() {
        requested = true
        status = "Finding your current location…"
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
        default: status = "Location is off. Choose a starting point or allow access in Settings."
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if requested { request() }
    }
    // Old cached fixes are rejected; reported accuracy describes the estimate, not verified error.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let fix = locations.last, fix.horizontalAccuracy >= 0, abs(fix.timestamp.timeIntervalSinceNow) < 60 else {
            status = "Location is uncertain. Try again or choose a starting point."
            return
        }
        location = fix
        status = "Current location available · reported accuracy \(Int(fix.horizontalAccuracy)) m"
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        status = "Location unavailable. Try again or choose a starting point."
    }
}
