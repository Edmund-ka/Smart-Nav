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


import Foundation
import CoreMotion
import CoreLocation
import UIKit
import Combine

class SensorManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private let altimeter = CMAltimeter()


    // Accelerometer
    @Published var accelerometerX: Double = 0
    @Published var accelerometerY: Double = 0
    @Published var accelerometerZ: Double = 0


    // Gyroscope
    @Published var gyroscopeX: Double = 0
    @Published var gyroscopeY: Double = 0
    @Published var gyroscopeZ: Double = 0


    // Magnetometer
    @Published var magnetometerX: Double = 0
    @Published var magnetometerY: Double = 0
    @Published var magnetometerZ: Double = 0


    // Device Motion
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    @Published var yaw: Double = 0


    // GPS
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    @Published var speed: Double = 0


    // Barometer
    @Published var pressure: Double = 0
    @Published var relativeAltitude: Double = 0


    // Proximity
    @Published var objectIsNear: Bool = false


    override init() {

        super.init()

        locationManager.delegate = self
    }


    // Accelerometer
    func startAccelerometer() {

        guard motionManager.isAccelerometerAvailable else {
            print("Accelerometer is not available")
            return
        }

        motionManager.accelerometerUpdateInterval = 0.2

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in

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


    // Gyroscope
    func startGyroscope() {

        guard motionManager.isGyroAvailable else {
            print("Gyroscope is not available")
            return
        }

        motionManager.gyroUpdateInterval = 0.2

        motionManager.startGyroUpdates(to: .main) { [weak self] data, error in

            guard let data = data else {
                return
            }

            self?.gyroscopeX = data.rotationRate.x
            self?.gyroscopeY = data.rotationRate.y
            self?.gyroscopeZ = data.rotationRate.z
        }
    }


    func stopGyroscope() {

        motionManager.stopGyroUpdates()
    }


    // Magnetometer
    func startMagnetometer() {

        guard motionManager.isMagnetometerAvailable else {
            print("Magnetometer is not available")
            return
        }

        motionManager.magnetometerUpdateInterval = 0.2

        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, error in

            guard let data = data else {
                return
            }

            self?.magnetometerX = data.magneticField.x
            self?.magnetometerY = data.magneticField.y
            self?.magnetometerZ = data.magneticField.z
        }
    }


    func stopMagnetometer() {

        motionManager.stopMagnetometerUpdates()
    }


    // Device Motion
    func startDeviceMotion() {

        guard motionManager.isDeviceMotionAvailable else {
            print("Device Motion is not available")
            return
        }

        motionManager.deviceMotionUpdateInterval = 0.2

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in

            guard let data = data else {
                return
            }

            self?.pitch = data.attitude.pitch
            self?.roll = data.attitude.roll
            self?.yaw = data.attitude.yaw
        }
    }


    func stopDeviceMotion() {

        motionManager.stopDeviceMotionUpdates()
    }


    // GPS
    func startLocation() {

        locationManager.requestWhenInUseAuthorization()

        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        locationManager.startUpdatingLocation()
    }


    func stopLocation() {

        locationManager.stopUpdatingLocation()
    }


    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {

        guard let location = locations.last else {
            return
        }

        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude

        if location.speed >= 0 {
            speed = location.speed
        }
    }


    // Barometer
    func startBarometer() {

        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            print("Barometer is not available")
            return
        }

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in

            guard let data = data else {
                return
            }

            self?.relativeAltitude = data.relativeAltitude.doubleValue
            self?.pressure = data.pressure.doubleValue
        }
    }


    func stopBarometer() {

        altimeter.stopRelativeAltitudeUpdates()
    }


    // Proximity Sensor
    func startProximitySensor() {

        UIDevice.current.isProximityMonitoringEnabled = true

        NotificationCenter.default.addObserver(
            forName: UIDevice.proximityStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in

            self?.objectIsNear = UIDevice.current.proximityState
        }
    }


    func stopProximitySensor() {

        UIDevice.current.isProximityMonitoringEnabled = false
    }


    // Start All Sensors
    func startAllSensors() {

        startAccelerometer()
        startGyroscope()
        startMagnetometer()
        startDeviceMotion()
        startLocation()
        startBarometer()
        startProximitySensor()
    }


    // Stop All Sensors
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
