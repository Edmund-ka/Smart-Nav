//
//  SensorView.swift
//  Argus
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


                // Accelerometer Card
                VStack(alignment: .leading, spacing: 10) {

                    Text("Accelerometer")
                        .font(.title2)
                        .bold()

                    Text("X: \(sensors.accelerometerX, specifier: "%.3f")")
                    Text("Y: \(sensors.accelerometerY, specifier: "%.3f")")
                    Text("Z: \(sensors.accelerometerZ, specifier: "%.3f")")

                    HStack {

                        Button("Start") {
                            sensors.startAccelerometer()
                        }

                        Button("Stop") {
                            sensors.stopAccelerometer()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(12)


                // Gyroscope Card
                VStack(alignment: .leading, spacing: 10) {

                    Text("Gyroscope")
                        .font(.title2)
                        .bold()

                    Text("X: \(sensors.gyroscopeX, specifier: "%.3f")")
                    Text("Y: \(sensors.gyroscopeY, specifier: "%.3f")")
                    Text("Z: \(sensors.gyroscopeZ, specifier: "%.3f")")

                    HStack {

                        Button("Start") {
                            sensors.startGyroscope()
                        }

                        Button("Stop") {
                            sensors.stopGyroscope()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(12)


                // Magnetometer Card
                VStack(alignment: .leading, spacing: 10) {

                    Text("Magnetometer")
                        .font(.title2)
                        .bold()

                    Text("X: \(sensors.magnetometerX, specifier: "%.3f")")
                    Text("Y: \(sensors.magnetometerY, specifier: "%.3f")")
                    Text("Z: \(sensors.magnetometerZ, specifier: "%.3f")")

                    HStack {

                        Button("Start") {
                            sensors.startMagnetometer()
                        }

                        Button("Stop") {
                            sensors.stopMagnetometer()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(12)


                // Device Motion Card
                VStack(alignment: .leading, spacing: 10) {

                    Text("Device Motion")
                        .font(.title2)
                        .bold()

                    Text("Pitch: \(sensors.pitch, specifier: "%.3f")")
                    Text("Roll: \(sensors.roll, specifier: "%.3f")")
                    Text("Yaw: \(sensors.yaw, specifier: "%.3f")")

                    HStack {

                        Button("Start") {
                            sensors.startDeviceMotion()
                        }

                        Button("Stop") {
                            sensors.stopDeviceMotion()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(12)


                // GPS Card
                VStack(alignment: .leading, spacing: 10) {

                    Text("GPS")
                        .font(.title2)
                        .bold()

                    Text("Latitude: \(sensors.latitude, specifier: "%.6f")")
                    Text("Longitude: \(sensors.longitude, specifier: "%.6f")")
                    Text("Speed: \(sensors.speed, specifier: "%.2f") m/s")

                    HStack {

                        Button("Start") {
                            sensors.startLocation()
                        }

                        Button("Stop") {
                            sensors.stopLocation()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(12)


                // Barometer Card
                VStack(alignment: .leading, spacing: 10) {

                    Text("Barometer")
                        .font(.title2)
                        .bold()

                    Text("Pressure: \(sensors.pressure, specifier: "%.3f")")
                    Text("Relative Altitude: \(sensors.relativeAltitude, specifier: "%.2f") m")

                    HStack {

                        Button("Start") {
                            sensors.startBarometer()
                        }

                        Button("Stop") {
                            sensors.stopBarometer()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(12)


                // Proximity Card
                VStack(alignment: .leading, spacing: 10) {

                    Text("Proximity Sensor")
                        .font(.title2)
                        .bold()

                    Text(
                        sensors.objectIsNear
                        ? "Object Is Near: Yes"
                        : "Object Is Near: No"
                    )

                    HStack {

                        Button("Start") {
                            sensors.startProximitySensor()
                        }

                        Button("Stop") {
                            sensors.stopProximitySensor()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(12)


                // Start / Stop All
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
