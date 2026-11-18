import SwiftUI

/// Optional hardware diagnostics. Each card controls one sensor; leaving this screen stops them all.
struct SensorDashboardView: View {
    @StateObject private var sensors = SensorService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("iPhone Sensors").font(.poppins(.largeTitle, weight: .bold))
                if let message = sensors.message {
                    Text(message).font(.poppins(.callout)).accessibilityAddTraits(.updatesFrequently)
                }
                sensorCard("Accelerometer · g", start: sensors.startAccelerometer, stop: sensors.stopAccelerometer) {
                    vectorValues(x: sensors.accelerometerX, y: sensors.accelerometerY, z: sensors.accelerometerZ)
                }
                sensorCard("Gyroscope · rad/s", start: sensors.startGyroscope, stop: sensors.stopGyroscope) {
                    vectorValues(x: sensors.gyroscopeX, y: sensors.gyroscopeY, z: sensors.gyroscopeZ)
                }
                sensorCard("Magnetometer · µT", start: sensors.startMagnetometer, stop: sensors.stopMagnetometer) {
                    vectorValues(x: sensors.magnetometerX, y: sensors.magnetometerY, z: sensors.magnetometerZ)
                }
                sensorCard("Device Motion · radians", start: sensors.startDeviceMotion, stop: sensors.stopDeviceMotion)
                {
                    measurement("Pitch", sensors.pitch)
                    measurement("Roll", sensors.roll)
                    measurement("Yaw", sensors.yaw)
                }
                sensorCard("GPS", start: sensors.startLocation, stop: sensors.stopLocation) {
                    measurement("Latitude", sensors.latitude, precision: 6)
                    measurement("Longitude", sensors.longitude, precision: 6)
                    measurement("Speed · m/s", sensors.speed)
                }
                sensorCard("Barometer", start: sensors.startBarometer, stop: sensors.stopBarometer) {
                    measurement("Pressure · kPa", sensors.pressure)
                    measurement("Relative altitude · m", sensors.relativeAltitude)
                }
                sensorCard("Proximity Sensor", start: sensors.startProximitySensor, stop: sensors.stopProximitySensor) {
                    LabeledContent("Object is near", value: sensors.objectIsNear ? "Yes" : "No")
                }
                PrimaryButton(title: "Start all sensors", icon: "waveform.path.ecg", action: sensors.startAllSensors)
                Button("Stop all sensors", action: sensors.stopAllSensors).frame(minHeight: 44)
            }.padding()
        }
        .background(AppColors.mist.opacity(0.35))
        .onDisappear { sensors.stopAllSensors() }
        .onChange(of: scenePhase) {
            if scenePhase != .active { sensors.stopAllSensors() }
        }
    }

    // Only the readings differ. One card definition keeps spacing, buttons, and accessibility consistent.
    private func sensorCard<Readings: View>(
        _ title: String, start: @escaping () -> Void, stop: @escaping () -> Void,
        @ViewBuilder readings: () -> Readings
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.poppins(.title2, weight: .semibold)).accessibilityAddTraits(.isHeader)
            readings()
            HStack {
                Button("Start", action: start).accessibilityLabel("Start \(title)")
                Spacer()
                Button("Stop", action: stop).accessibilityLabel("Stop \(title)")
            }.frame(minHeight: 44)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlassBackground(shape: RoundedRectangle(cornerRadius: 18)))
    }

    private func vectorValues(x: Double, y: Double, z: Double) -> some View {
        Group {
            measurement("X", x)
            measurement("Y", y)
            measurement("Z", z)
        }
    }

    private func measurement(_ label: String, _ value: Double, precision: Int = 3) -> some View {
        LabeledContent(label, value: value.formatted(.number.precision(.fractionLength(precision))))
            .monospacedDigit()
    }
}

#Preview { SensorDashboardView() }
