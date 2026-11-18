import CoreLocation
import Foundation

/// Hardware adapter only: Core Location callbacks become the same input used by replay.
final class LiveLocationProvider: NSObject, CLLocationManagerDelegate {
    var onPosition: ((NavigationPosition) -> Void)?
    var onUnavailable: ((String) -> Void)?
    private let manager = CLLocationManager()
    private var running = false
    override init() {
        super.init()
        manager.delegate = self
        // Navigation accuracy enables Apple's sensor-fused positioning; never auto-pause while the
        // walker waits at a crossing or the top of the stairs.
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .fitness
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
    }
    func start() {
        running = true
        updatePermission()
    }
    func stop() {
        running = false
        manager.stopUpdatingLocation()
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { if running { updatePermission() } }
    private func updatePermission() {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: manager.startUpdatingLocation()
        case .notDetermined: manager.requestWhenInUseAuthorization()
        default: onUnavailable?("Location permission is unavailable. Enable it in Settings to continue.")
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard running else { return }
        for position in NavigationInputs.live(locations) { onPosition?(position) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if running { onUnavailable?("Location updates are unavailable. Precise guidance is paused.") }
    }
}
