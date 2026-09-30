//
//  SensorView.swift
//  Smart_nav
//
//  Created by Edmund Afunyah on 9/30/26.
//

import SwiftUI

struct SensorView: View {

    @StateObject var sensors = SensorManager()

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                Text("iPhone Sensors")
                    .font(.largeTitle)
                    .bold()


                // Accelerometer

                Text("Accelerometer")
                    .font(.title2)
                    .bold()

                Text("X: \(sensors.accelerometerX)")
                Text("Y: \(sensors.accelerometerY)")
                Text("Z: \(sensors.accelerometerZ)")

                Button("Start Accelerometer") {

                    sensors.startAccelerometer()
                }

                Button("Stop Accelerometer") {

                    sensors.stopAccelerometer()
                }


                Divider()


                // Gyroscope

                Text("Gyroscope")
                    .font(.title2)
                    .bold()

                Text("X: \(sensors.gyroscopeX)")
                Text("Y: \(sensors.gyroscopeY)")
                Text("Z: \(sensors.gyroscopeZ)")

                Button("Start Gyroscope") {

                    sensors.startGyroscope()
                }

                Button("Stop Gyroscope") {

                    sensors.stopGyroscope()
                }


                Divider()


                // Magnetometer

                Text("Magnetometer")
                    .font(.title2)
                    .bold()

                Text("X: \(sensors.magnetometerX)")
                Text("Y: \(sensors.magnetometerY)")
                Text("Z: \(sensors.magnetometerZ)")

                Button("Start Magnetometer") {

                    sensors.startMagnetometer()
                }

                Button("Stop Magnetometer") {

                    sensors.stopMagnetometer()
                }


                Divider()


                // Device Motion

                Text("Device Motion")
                    .font(.title2)
                    .bold()

                Text("Pitch: \(sensors.pitch)")
                Text("Roll: \(sensors.roll)")
                Text("Yaw: \(sensors.yaw)")

                Button("Start Device Motion") {

                    sensors.startDeviceMotion()
                }

                Button("Stop Device Motion") {

                    sensors.stopDeviceMotion()
                }


                Divider()


                // GPS

                Text("GPS")
                    .font(.title2)
                    .bold()

                Text("Latitude: \(sensors.latitude)")
                Text("Longitude: \(sensors.longitude)")
                Text("Speed: \(sensors.speed)")

                Button("Start GPS") {

                    sensors.startLocation()
                }

                Button("Stop GPS") {

                    sensors.stopLocation()
                }


                Divider()


                // Barometer

                Text("Barometer")
                    .font(.title2)
                    .bold()

                Text("Pressure: \(sensors.pressure)")
                Text("Relative Altitude: \(sensors.relativeAltitude)")

                Button("Start Barometer") {

                    sensors.startBarometer()
                }

                Button("Stop Barometer") {

                    sensors.stopBarometer()
                }


                Divider()


                // Proximity

                Text("Proximity Sensor")
                    .font(.title2)
                    .bold()

                Text(
                    sensors.objectIsNear
                    ? "Object Is Near: Yes"
                    : "Object Is Near: No"
                )

                Button("Start Proximity Sensor") {

                    sensors.startProximitySensor()
                }

                Button("Stop Proximity Sensor") {

                    sensors.stopProximitySensor()
                }


                Divider()


                // All Sensors

                Button("Start All Sensors") {

                    sensors.startAllSensors()
                }
                .buttonStyle(.borderedProminent)


                Button("Stop All Sensors") {

                    sensors.stopAllSensors()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}

#Preview {
    SensorView()
}
