//
//  sensor.swift
//  Smart_nav
//
//  Created by Edmund Afunyah on 9/16/26.
//
/*Foundation
↓
basic Swift functionality

CoreMotion
↓
accelerometer
gyroscope
magnetometer
device motion
barometer

CoreLocation
↓
GPS
location
speed
direction

UIKit
↓
proximity sensor
*/


// MARK: - Framework Imports
import Foundation    // The core Swift library (basic data types, etc.)
import CoreMotion    // Apple's framework for movement sensors (Accelerometer, Gyroscope)
import CoreLocation  // Apple's framework for GPS and location tracking
import UIKit         // Apple's UI framework (used here to access device hardware like the proximity sensor)
import Combine       // Allows us to use @Published to broadcast data changes to the UI

// 'class' is our blueprint.
// NSObject: Base class required to act as a GPS delegate.
// ObservableObject: Protocol allowing SwiftUI to watch this class for updates.
// CLLocationManagerDelegate: Protocol (contract) promising we have the methods to handle GPS data.
class SensorManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    // These are the "managers" that actually talk to the physical hardware chips
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private let altimeter = CMAltimeter()


    // MARK: - Published Variables
    // @Published means: "When this value changes, tell the Main UI thread to redraw the screen!"

    // Accelerometer (Raw acceleration forces including gravity)
    @Published var accelerometerX: Double = 0
    @Published var accelerometerY: Double = 0
    @Published var accelerometerZ: Double = 0


    // Gyroscope (Rate of rotation around the phone's axes)
    @Published var gyroscopeX: Double = 0
    @Published var gyroscopeY: Double = 0
    @Published var gyroscopeZ: Double = 0


    // Magnetometer (Compass / magnetic field)
    @Published var magnetometerX: Double = 0
    @Published var magnetometerY: Double = 0
    @Published var magnetometerZ: Double = 0


    // Device Motion (Processed 3D orientation of the phone)
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    @Published var yaw: Double = 0


    // GPS
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    @Published var speed: Double = 0


    // Barometer (Air pressure and altitude changes)
    @Published var pressure: Double = 0
    @Published var relativeAltitude: Double = 0


    // Proximity (Is the phone held up to an ear/face?)
    @Published var objectIsNear: Bool = false


    // MARK: - Initialization
    // This runs once when the SensorManager is first created in memory
    override init() {
        super.init() // Sets up the parent NSObject class first

        // Delegation: Telling the GPS manager "Send your location updates to ME (self)"
        locationManager.delegate = self
    }


    // MARK: - Accelerometer
    func startAccelerometer() {
        // Safety check: Make sure the hardware actually exists/works before trying to use it
        guard motionManager.isAccelerometerAvailable else {
            print("Accelerometer is not available")
            return // Exit early if broken
        }

        // Get new data 5 times a second
        motionManager.accelerometerUpdateInterval = 0.2

        // to: .main tells the background worker to send data back to the Main UI Thread
        // [weak self] prevents memory leaks by not locking this class in memory forever
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in

            // guard let: Safely opens the "Optional" data box. If it's empty (nil), exit.
            guard let data = data else {
                return
            }

            // Save the unwrapped data to our @Published variables
            self?.accelerometerX = data.acceleration.x
            self?.accelerometerY = data.acceleration.y
            self?.accelerometerZ = data.acceleration.z
        }
    }

    func stopAccelerometer() {
        motionManager.stopAccelerometerUpdates() // Turns off the sensor to save battery
    }


    // MARK: - Gyroscope
    // (Follows the exact same pattern as the Accelerometer)
    func startGyroscope() {
        guard motionManager.isGyroAvailable else {
            print("Gyroscope is not available")
            return
        }

        motionManager.gyroUpdateInterval = 0.2

        motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }

            self?.gyroscopeX = data.rotationRate.x
            self?.gyroscopeY = data.rotationRate.y
            self?.gyroscopeZ = data.rotationRate.z
        }
    }

    func stopGyroscope() {
        motionManager.stopGyroUpdates()
    }


    // MARK: - Magnetometer
    // (Follows the exact same pattern as the Accelerometer)
    func startMagnetometer() {
        guard motionManager.isMagnetometerAvailable else {
            print("Magnetometer is not available")
            return
        }

        motionManager.magnetometerUpdateInterval = 0.2

        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }

            self?.magnetometerX = data.magneticField.x
            self?.magnetometerY = data.magneticField.y
            self?.magnetometerZ = data.magneticField.z
        }
    }

    func stopMagnetometer() {
        motionManager.stopMagnetometerUpdates()
    }


    // MARK: - Device Motion
    // (Follows the exact same pattern as the Accelerometer)
    func startDeviceMotion() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device Motion is not available")
            return
        }

        motionManager.deviceMotionUpdateInterval = 0.2

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }

            self?.pitch = data.attitude.pitch
            self?.roll = data.attitude.roll
            self?.yaw = data.attitude.yaw
        }
    }

    func stopDeviceMotion() {
        motionManager.stopDeviceMotionUpdates()
    }


    // MARK: - GPS (CoreLocation)
    func startLocation() {
        // Triggers the iOS pop-up asking the user for location permission
        locationManager.requestWhenInUseAuthorization()

        // Tells the GPS to use maximum battery for the most accurate location
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        // Turns on the GPS hardware
        locationManager.startUpdatingLocation()
    }

    func stopLocation() {
        locationManager.stopUpdatingLocation()
    }

    // This is a DELEGATE method required by the CLLocationManagerDelegate protocol.
    // The GPS chip calls this function automatically whenever the phone moves.
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        // 'locations' is an array. We grab the most recent one (.last) safely using guard let
        guard let location = locations.last else {
            return
        }

        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude

        // GPS sometimes returns -1 for speed if it's confused. This ensures we only save real speeds.
        if location.speed >= 0 {
            speed = location.speed
        }
    }


    // MARK: - Barometer (CMAltimeter)
    func startBarometer() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            print("Barometer is not available")
            return
        }

        // Starts updates, sending the data back to the main UI thread
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }

            self?.relativeAltitude = data.relativeAltitude.doubleValue
            self?.pressure = data.pressure.doubleValue
        }
    }

    func stopBarometer() {
        altimeter.stopRelativeAltitudeUpdates()
    }


    // MARK: - Proximity Sensor
    func startProximitySensor() {
        // Turns on the physical infrared sensor by the front camera
        UIDevice.current.isProximityMonitoringEnabled = true

        // Listens for a system-wide broadcast that the proximity state has changed
        NotificationCenter.default.addObserver(
            forName: UIDevice.proximityStateDidChangeNotification,
            object: nil,
            queue: .main // Ensures the UI update happens on the Main Thread
        ) { [weak self] notification in
            // Updates our boolean variable to true/false
            self?.objectIsNear = UIDevice.current.proximityState
        }
    }

    func stopProximitySensor() {
        // Turns off the physical sensor
        UIDevice.current.isProximityMonitoringEnabled = false
    }


    // MARK: - Convenience Methods
    // Helper function to turn everything on at once
    func startAllSensors() {
        startAccelerometer()
        startGyroscope()
        startMagnetometer()
        startDeviceMotion()
        startLocation()
        startBarometer()
        startProximitySensor()
    }

    // Helper function to cleanly shut down all hardware to save battery
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
