import CoreLocation
import Foundation
import Observation

/// Frame-rate presentation state for guidance. The engine updates about once per GPS fix;
/// this eases the on-screen position, heading and route reveal between fixes so the map glides.
/// It never feeds back into guidance decisions.
@Observable
final class GuidanceDisplay {
    /// Metres along the route shown on screen.
    var progress = 0.0
    /// Map heading in degrees clockwise from north.
    var heading = 0.0
    /// Fraction of the previewed route drawn so far (0...1).
    var reveal = 1.0
    @ObservationIgnored private var followTask: Task<Void, Never>?
    @ObservationIgnored private var revealTask: Task<Void, Never>?

    /// Starts easing toward the controller's estimate, extrapolating with the smoothed walking speed.
    func follow(_ controller: NavigationController) {
        followTask?.cancel()
        if let session = controller.session {
            progress = session.progress
            heading = MapGeometry.bearing(at: progress + 6, on: session.route.coordinates)
        }
        followTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
                guard let self, let session = controller.session else { continue }
                self.advance(toward: session)
            }
        }
    }

    func stopFollowing() {
        followTask?.cancel()
        followTask = nil
    }

    /// Draws a newly planned route from its start to its destination.
    func revealRoute() {
        revealTask?.cancel()
        reveal = 0
        revealTask = Task { [weak self] in
            let start = Date()
            let duration = 1.1
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(16)) } catch { return }
                guard let self else { return }
                let t = min(1, Date().timeIntervalSince(start) / duration)
                self.reveal = 1 - pow(1 - t, 3)  // ease-out cubic
                if t >= 1 { return }
            }
        }
    }

    private func advance(toward session: NavigationSession) {
        let path = session.route.coordinates
        var target = session.progress
        if session.status == .following, let last = session.lastProgressTime {
            // Dead reckoning between fixes: keep walking at the estimated pace for up to two seconds.
            let elapsed = min(2, max(0, Date().timeIntervalSince(last)))
            target = min(session.route.distance, session.progress + session.speed * elapsed)
        }
        if session.status == .arrived { target = session.route.distance }
        progress += (target - progress) * 0.12
        // Look slightly ahead so the camera starts rotating into a turn before the corner.
        let targetHeading = MapGeometry.bearing(at: progress + 6, on: path)
        let delta = (targetHeading - heading + 540).truncatingRemainder(dividingBy: 360) - 180
        heading = (heading + delta * 0.06 + 360).truncatingRemainder(dividingBy: 360)
    }
}

extension MapCoordinate {
    var clCoordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}
