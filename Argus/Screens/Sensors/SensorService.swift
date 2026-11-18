import Combine
import CoreLocation
import CoreMotion
import Foundation
import UIKit

/// On-demand hardware diagnostics. WalkRecorder separately owns sensors used for saved walks.
final class SensorService: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private let altimeter = CMAltimeter()
    private var proximityObserver: NSObjectProtocol?
    private var locationRequested = false
    private var barometerActive = false
    // Five updates per second is a diagnostic display setting, not a sensor accuracy claim.
    private let sampleInterval = 0.2
    @Published private(set) var message: String?

    // Raw acceleration includes gravity, measured in g.
    @Published var accelerometerX: Double = 0
    @Published var accelerometerY: Double = 0
    @Published var accelerometerZ: Double = 0

    // Rotation is measured in radians per second; magnetic field is measured in microteslas.
    @Published var gyroscopeX: Double = 0
    @Published var gyroscopeY: Double = 0
    @Published var gyroscopeZ: Double = 0

    @Published var magnetometerX: Double = 0
    @Published var magnetometerY: Double = 0
    @Published var magnetometerZ: Double = 0

    // Processed device orientation, in radians.
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    @Published var yaw: Double = 0

    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    @Published var speed: Double = 0

    @Published var pressure: Double = 0
    @Published var relativeAltitude: Double = 0

    @Published var objectIsNear: Bool = false

    override init() {
        super.init()

        locationManager.delegate = self
    }

    /// Display callbacks run on the main queue; weak captures let the screen release this manager.
    func startAccelerometer() {
        guard motionManager.isAccelerometerAvailable else {
            message = "Accelerometer is not available on this device."
            return
        }
        guard !motionManager.isAccelerometerActive else { return }

        motionManager.accelerometerUpdateInterval = sampleInterval

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in

            guard let data = data else {
                return
            }

            self?.accelerometerX = data.acceleration.x
            self?.accelerometerY = data.acceleration.y
            self?.accelerometerZ = data.acceleration.z
        }
    }

    func stopAccelerometer() {
        motionManager.stopAccelerometerUpdates()
    }

    /// Repeated Start actions are ignored while this sensor is already running.
    func startGyroscope() {
        guard motionManager.isGyroAvailable else {
            message = "Gyroscope is not available on this device."
            return
        }
        guard !motionManager.isGyroActive else { return }

        motionManager.gyroUpdateInterval = sampleInterval

        motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
            guard let data = data else { return }

            self?.gyroscopeX = data.rotationRate.x
            self?.gyroscopeY = data.rotationRate.y
            self?.gyroscopeZ = data.rotationRate.z
        }
    }

    func stopGyroscope() {
        motionManager.stopGyroUpdates()
    }

    /// Read the magnetic field along the phone’s three axes.
    func startMagnetometer() {
        guard motionManager.isMagnetometerAvailable else {
            message = "Magnetometer is not available on this device."
            return
        }
        guard !motionManager.isMagnetometerActive else { return }

        motionManager.magnetometerUpdateInterval = sampleInterval

        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, _ in
            guard let data = data else { return }

            self?.magnetometerX = data.magneticField.x
            self?.magnetometerY = data.magneticField.y
            self?.magnetometerZ = data.magneticField.z
        }
    }

    func stopMagnetometer() {
        motionManager.stopMagnetometerUpdates()
    }

    /// Use Apple’s fused motion estimate for pitch, roll, and yaw.
    func startDeviceMotion() {
        guard motionManager.isDeviceMotionAvailable else {
            message = "Device Motion is not available on this device."
            return
        }
        guard !motionManager.isDeviceMotionActive else { return }

        motionManager.deviceMotionUpdateInterval = sampleInterval

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let data = data else { return }

            self?.pitch = data.attitude.pitch
            self?.roll = data.attitude.roll
            self?.yaw = data.attitude.yaw
        }
    }

    func stopDeviceMotion() {
        motionManager.stopDeviceMotionUpdates()
    }

    /// Start only after permission is granted, including the asynchronous first-use response.
    func startLocation() {
        locationRequested = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        updateLocationPermission()
    }

    func stopLocation() {
        locationRequested = false
        locationManager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if locationRequested { updateLocationPermission() }
    }

    private func updateLocationPermission() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: locationManager.startUpdatingLocation()
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        default: message = "Allow location access in Settings to view GPS readings."
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        message = "GPS reading unavailable: \(error.localizedDescription)"
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard locationRequested, let location = locations.last, location.horizontalAccuracy >= 0 else {
            return
        }

        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude

        if location.speed >= 0 {
            speed = location.speed
        }
    }

    /// Altitude is relative to the session’s start, not height above sea level.
    func startBarometer() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            message = "Barometer is not available on this device."
            return
        }

        guard !barometerActive else { return }
        barometerActive = true
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let data = data else { return }

            self?.relativeAltitude = data.relativeAltitude.doubleValue
            self?.pressure = data.pressure.doubleValue
        }
    }

    func stopBarometer() {
        altimeter.stopRelativeAltitudeUpdates()
        barometerActive = false
    }

    /// Keep one observer per session. Repeated Start taps must not create duplicate callbacks.
    func startProximitySensor() {
        guard proximityObserver == nil else { return }
        let device = UIDevice.current
        device.isProximityMonitoringEnabled = true
        guard device.isProximityMonitoringEnabled else {
            message = "Proximity sensing is not available on this device."
            return
        }
        objectIsNear = device.proximityState
        proximityObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.proximityStateDidChangeNotification,
            object: device,
            queue: .main
        ) { [weak self] _ in
            self?.objectIsNear = UIDevice.current.proximityState
        }
    }

    func stopProximitySensor() {
        if let proximityObserver {
            NotificationCenter.default.removeObserver(proximityObserver)
            self.proximityObserver = nil
        }
        UIDevice.current.isProximityMonitoringEnabled = false
    }

    /// These are explicit user actions; opening the diagnostics page starts no hardware.
    func startAllSensors() {
        message = nil
        startAccelerometer()
        startGyroscope()
        startMagnetometer()
        startDeviceMotion()
        startLocation()
        startBarometer()
        startProximitySensor()
    }

    /// Called on exit and backgrounding to release hardware and avoid battery drain.
    func stopAllSensors() {
        stopAccelerometer()
        stopGyroscope()
        stopMagnetometer()
        stopDeviceMotion()
        stopLocation()
        stopBarometer()
        stopProximitySensor()
    }
}
