import Combine
import CoreLocation
import CoreMotion
import Foundation

/// Records real sensor readings and saves explicit user-approved walks on this iPhone.
final class WalkRecorder: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var walks: [WalkData] = []
    @Published private(set) var draft: WalkData?
    @Published private(set) var recording = false
    @Published private(set) var message: String?
    private let motion = CMMotionManager()
    private var motionSamples: [MotionReading] = []
    private var compassSamples: [CompassReading] = []
    private let gps = CLLocationManager()
    private let folder = URL.applicationSupportDirectory.appending(path: "RecordedWalks")

    // Reload saved JSON and any stopped draft without starting sensors.
    override init() {
        super.init()
        gps.delegate = self
        gps.desiredAccuracy = kCLLocationAccuracyBest
        gps.activityType = .fitness
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for url in try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            where url.pathExtension == "json" {
                do {
                    walks.append(try JSONDecoder().decode(WalkData.self, from: Data(contentsOf: url)))
                } catch { message = "A saved walk could not be opened." }
            }
            walks.sort { $0.started > $1.started }
            let draftURL = folder.appending(path: "unfinished.draft")
            if FileManager.default.fileExists(atPath: draftURL.path) {
                draft = try JSONDecoder().decode(WalkData.self, from: Data(contentsOf: draftURL))
                motionSamples = draft?.motion ?? []
                compassSamples = draft?.compass ?? []
                message = "An unfinished walk was recovered. Review it, then save or discard."
            }
        } catch { message = error.localizedDescription }
    }

    /// Begin a fresh draft only when the previous draft has been saved or discarded.
    func start(graph: CampusGraph? = nil) {
        guard draft == nil else { return }
        motionSamples.removeAll()
        compassSamples.removeAll()
        draft = WalkData(id: UUID(), started: Date())
        draft?.schemaVersion = 2
        if let graph, let origin = graph.entrance(for: "boyd"), let destination = graph.entrance(for: "library") {
            draft?.graphSnapshot = graph
            draft?.originNodeID = origin.id
            draft?.destinationNodeID = destination.id
            draft?.routeID = "\(graph.id):\(graph.version):\(origin.id):\(destination.id)"
        }
        recording = true
        message = nil
        updatePermission()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if recording { updatePermission() }
    }

    private func updatePermission() {
        switch gps.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: startSensors()
        case .notDetermined: gps.requestWhenInUseAuthorization()
        default: interrupt("Allow location access in Settings to record a walk.")
        }
    }

    /// GPS and compass retain their own timestamps; motion is sampled at a configured 10 Hz.
    private func startSensors() {
        gps.startUpdatingLocation()
        if CLLocationManager.headingAvailable() { gps.startUpdatingHeading() }
        guard motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }
        motion.deviceMotionUpdateInterval = 0.1
        // Motion time counts from phone startup. Put it on the same clock as GPS and manual marks.
        let boot = Date().addingTimeInterval(-ProcessInfo.processInfo.systemUptime)
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] data, _ in
            guard let self, self.recording, let data, let started = self.draft?.started else { return }
            let time = boot.addingTimeInterval(data.timestamp)
            guard time >= started else { return }
            let a = data.userAcceleration
            let g = data.gravity
            let r = data.rotationRate
            let q = data.attitude.quaternion
            self.motionSamples.append(
                MotionReading(
                    time: time, accelerationG: [a.x, a.y, a.z],
                    gravityG: [g.x, g.y, g.z], rotationRadiansPerSecond: [r.x, r.y, r.z],
                    attitudeQuaternionXYZW: [q.x, q.y, q.z, q.w]))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        guard recording, let started = draft?.started, heading.timestamp >= started,
            heading.headingAccuracy >= 0
        else { return }
        compassSamples.append(
            CompassReading(
                time: heading.timestamp, magneticDegrees: heading.magneticHeading,
                trueDegrees: heading.trueHeading >= 0 ? heading.trueHeading : nil,
                accuracyDegrees: heading.headingAccuracy))
    }

    /// Add a user-observed event without altering the original sensor readings.
    func mark(_ label: String) {
        guard recording else { return }
        if draft?.marks == nil { draft?.marks = [] }
        draft?.marks?.append(WalkMark(time: Date(), label: label))
    }

    func fileURL(for walk: WalkData) -> URL {
        folder.appending(path: walk.id.uuidString + ".json")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard recording, let started = draft?.started else { return }
        // GPS can send an older fix first, or several readings together.
        for fix in NavigationInputs.orderedLocations(locations)
        where fix.horizontalAccuracy >= 0 && fix.timestamp >= started {
            if let last = draft?.readings.last, fix.timestamp <= last.time { continue }
            draft?.readings.append(
                WalkReading(
                    time: fix.timestamp, latitude: fix.coordinate.latitude,
                    longitude: fix.coordinate.longitude, accuracyMeters: fix.horizontalAccuracy,
                    altitudeMeters: fix.verticalAccuracy >= 0 ? fix.altitude : nil,
                    verticalAccuracyMeters: fix.verticalAccuracy >= 0 ? fix.verticalAccuracy : nil,
                    speedMetersPerSecond: fix.speed >= 0 ? fix.speed : nil,
                    speedAccuracyMetersPerSecond: fix.speedAccuracy >= 0 ? fix.speedAccuracy : nil,
                    courseDegrees: fix.course >= 0 ? fix.course : nil,
                    courseAccuracyDegrees: fix.courseAccuracy >= 0 ? fix.courseAccuracy : nil,
                    simulatedBySoftware: fix.sourceInformation?.isSimulatedBySoftware))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard recording else { return }
        if (error as? CLError)?.code == .locationUnknown { return }
        interrupt(error.localizedDescription)
    }

    // All stop paths release the hardware. Temporary GPS uncertainty alone does not end a walk.
    private func interrupt(_ reason: String) {
        if recording { draft?.ended = Date() }
        motion.stopDeviceMotionUpdates()
        gps.stopUpdatingHeading()
        gps.stopUpdatingLocation()
        recording = false
        if draft?.readings.isEmpty == true { draft = nil }
        message = reason
    }

    /// A stopped draft is recoverable after relaunch, but is not yet a named saved walk.
    func stop() {
        interrupt("")
        draft?.motion = motionSamples
        draft?.compass = compassSamples
        if let draft {
            do {
                try JSONEncoder().encode(draft).write(to: folder.appending(path: "unfinished.draft"), options: .atomic)
            } catch { message = "This draft is still in memory, but could not be backed up. Try saving it now." }
        }
    }

    /// Remove only the unsaved draft after the screen’s confirmation.
    func discard() {
        stop()
        draft = nil
        motionSamples.removeAll()
        compassSamples.removeAll()
        message = nil
        try? FileManager.default.removeItem(at: folder.appending(path: "unfinished.draft"))
    }

    /// Update the displayed list only after deletion on disk succeeds.
    func delete(_ walk: WalkData) {
        do {
            try FileManager.default.removeItem(at: fileURL(for: walk))
            walks.removeAll { $0.id == walk.id }
        } catch { message = "The walk could not be deleted. Please try again." }
    }

    /// Preserve the walk’s ID, timestamps, and measurements while changing its display name.
    func rename(_ walk: WalkData, to name: String) {
        var updated = walk
        updated.name = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
        do {
            try JSONEncoder().encode(updated).write(to: fileURL(for: walk), options: .atomic)
            if let index = walks.firstIndex(where: { $0.id == walk.id }) { walks[index] = updated }
        } catch { message = "The name could not be saved." }
    }

    /// Atomically write a complete walk before clearing the draft. Failures keep the draft available.
    func save(name: String = "") {
        interrupt("")
        guard var walk = draft else {
            message = "No GPS readings were received."
            return
        }
        walk.motion = motionSamples
        walk.compass = compassSamples
        walk.name = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
        guard !walk.readings.isEmpty else {
            message = "No GPS readings were received."
            return
        }
        do {
            // Write the complete file before adding the walk to the saved list.
            let url = fileURL(for: walk)
            try JSONEncoder().encode(walk).write(to: url, options: .atomic)
            walks.insert(walk, at: 0)
            draft = nil
            try? FileManager.default.removeItem(at: folder.appending(path: "unfinished.draft"))
            message = "Walk saved."
        } catch { message = "Could not save the walk. Try saving again." }
    }
}
