import MapKit
import SwiftUI

/// Replays timestamped raw GPS against the approximate demo route, without rewriting the recording.
struct WalkReplayView: View {
    let walk: WalkData
    let exportURL: URL?
    private static let route = SimulationRoute()
    @State private var elapsed = 0.0
    @State private var count = 0
    @State private var playing = false
    @State private var speed = 4.0
    @State private var session: NavigationSession?
    @State private var showingEvaluation = false
    private var positions: [NavigationPosition] { ReplayInputs.positions(for: walk) }
    @State private var alert: String?
    @StateObject private var speaker = GuidanceOutput()
    @AppStorage("speechRate") private var speechRate = 0.5
    @Environment(\.scenePhase) private var scenePhase

    private var duration: Double {
        max(walk.ended ?? walk.started, positions.last?.time ?? walk.started).timeIntervalSince(walk.started)
    }

    var body: some View {
        Map {
            if let route = session?.route {
                MapPolyline(coordinates: route.coordinates.map(\.clCoordinate)).stroke(.blue, lineWidth: 5)
            }
            // Before playback, show the whole recording so the user can inspect the walk.
            MapPolyline(
                coordinates: positions.prefix(count == 0 && !playing ? positions.count : count).map {
                    $0.coordinate.clCoordinate
                }
            )
            .stroke(.orange, lineWidth: 3)
            if let first = walk.readings.first { Marker("Start", coordinate: first.coordinate).tint(.green) }
            if let last = walk.readings.last { Marker("Finish", coordinate: last.coordinate) }
            if count > 0 {
                Marker(
                    "Recorded position", systemImage: "figure.walk",
                    coordinate: positions[count - 1].coordinate.clCoordinate
                )
                .tint(.orange)
            }
        }
        .navigationTitle("Recorded walk")
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text(
                    walk.graphSnapshot == nil
                        ? "Blue: approximate Boyd Hall reference · Orange: GPS · legacy recording"
                        : "Blue: saved graph route · Orange: recorded GPS"
                ).font(.poppins(.caption))
                Text("\(Int(elapsed)) / \(Int(duration)) seconds · \(count) of \(walk.readings.count) readings")
                    .monospacedDigit()
                if let motion = walk.motion, let compass = walk.compass {
                    Text("\(motion.count) motion · \(compass.count) compass").font(.poppins(.caption))
                }
                if let mark = walk.marks?.last(where: { $0.time.timeIntervalSince(walk.started) <= elapsed }) {
                    Text("Walk mark: \(mark.label)")
                }
                if let alert { Text(alert).font(.poppins(.headline)) }
                Picker("Playback speed", selection: $speed) {
                    Text("1×").tag(1.0)
                    Text("4×").tag(4.0)
                }.pickerStyle(.segmented)
                HStack {
                    Button(playing ? "Pause" : count == 0 ? "Replay recorded walk" : "Play") {
                        if elapsed >= duration { reset() }
                        playing.toggle()
                    }.buttonStyle(.borderedProminent)
                    Button("Restart") {
                        reset()
                        playing = true
                    }
                }
                Button("Navigation evaluation") { showingEvaluation = true }
                if let exportURL { ShareLink("Export walk data", item: exportURL) }
            }
            .padding().frame(maxWidth: .infinity, alignment: .leading).background(
                GlassBackground(shape: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)))
        }
        // Playback advances by elapsed clock time; speed changes never skip detector input fixes.
        .task(id: playing && scenePhase == .active) {
            guard playing, scenePhase == .active else { return }
            let clock = ContinuousClock()
            var previous = clock.now
            repeat {
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                let now = clock.now
                let delta = previous.duration(to: now).components
                previous = now
                elapsed = min(duration, elapsed + speed * (Double(delta.seconds) + Double(delta.attoseconds) / 1e18))
                // Feed every original fix to the detector, even when several are due in one accelerated tick.
                while count < walk.readings.count {
                    let reading = positions[count]
                    guard reading.time.timeIntervalSince(walk.started) <= elapsed else { break }
                    let newEvents = session?.receive(reading, now: reading.time) ?? []
                    if let last = newEvents.last {
                        alert = last.message
                        speaker.announce(newEvents)
                    }
                    count += 1
                }
            } while elapsed < duration
            playing = false
        }
        .onAppear { if session == nil { reset() } }
        .sheet(isPresented: $showingEvaluation) {
            if let session {
                NavigationStack {
                    NavigationEventsView(session: session, expected: ReplayInputs.expectations(for: walk))
                }
            }
        }
        .onDisappear {
            playing = false
            speaker.stop()
        }
        .onChange(of: scenePhase) {
            if scenePhase != .active {
                playing = false
                speaker.stop()
            }
        }
    }

    /// Start again with a fresh detector so previous alerts cannot affect the next playback.
    private func reset() {
        elapsed = 0
        count = 0
        session = try? ReplayInputs.session(for: walk)
        alert = nil
        speaker.stop()
    }
}
