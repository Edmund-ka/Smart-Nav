import MapKit
import SwiftUI

/// Single-page presentation using scripted positions, not live GPS or obstacle detection.
struct SimulationView: View {
    private static let route = SimulationRoute()
    var isTabSelected: Bool
    @State private var scenario: WalkScenario
    @State private var step = 0
    @State private var session: NavigationSession?
    @State private var showingEvaluation = false
    private let sensorStart = Date(timeIntervalSince1970: 1_700_000_000)
    @State private var alert: String?
    @State private var checkpoint: AccessibilityCheckpoint?
    @State private var visitedCheckpoints: Set<String> = []
    @State private var events: [String] = []
    @StateObject private var speaker = GuidanceOutput()
    @State private var playing = false
    @State private var speed = 4.0
    @State private var camera: MapCameraPosition = .automatic
    @State private var showImages = false
    @State private var lastInstruction = "Start the simulation to hear directions."
    @AppStorage("speechRate") private var speechRate = 0.5
    @AppStorage("guidanceHaptics") private var haptics = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(initialScenario: WalkScenario = .normal, isTabSelected: Bool = true) {
        _scenario = State(initialValue: initialScenario)
        self.isTabSelected = isTabSelected
    }
    private var meters: Double { Self.route?.sample(step, scenario).progress ?? 0 }
    // Image changes are tied to route progress, not a separate slideshow timer.
    private var scene: (name: String, description: String) {
        let fraction = meters / max(Self.route?.length ?? 1, 1)
        if fraction < 0.08 { return ("boyd-overview", "Starting near Boyd Hall. Campus imagery, not a live camera.") }
        if fraction < 0.7 {
            return ("route-overhead", "Overhead view of the approximate path between Boyd Hall and the library.")
        }
        if fraction < 0.93 { return ("route-oblique", "Oblique campus view approaching the library area.") }
        return ("library-pin", "Library destination reference pin. The entrance is not field verified.")
    }
    var body: some View {
        Group {
            if let route = Self.route {
                VStack(spacing: 0) {
                    if showImages {
                        CampusPhotoView(name: scene.name, description: scene.description)
                            .equatable()
                            .frame(maxWidth: .infinity).frame(maxHeight: .infinity)
                            .background(GlassBackground(shape: RoundedRectangle(cornerRadius: 18)))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        Text(scene.description).font(.poppins(.caption)).foregroundStyle(AppColors.secondaryInk)
                    } else {
                        Map(position: $camera) {
                            MapPolyline(route.line).stroke(
                                .white, style: StrokeStyle(lineWidth: 13, lineCap: .round, lineJoin: .round))
                            MapPolyline(route.line).stroke(
                                AppColors.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                            Annotation("Boyd Hall", coordinate: route.points[0].coordinate, anchor: .bottom) {
                                PlacePin(icon: "building.2.fill", tint: AppColors.ink)
                            }
                            Annotation("Library", coordinate: route.coordinate(at: route.length), anchor: .bottom) {
                                PlacePin(icon: "books.vertical.fill", pulsing: true)
                            }
                            ForEach(AccessibilityCheckpoint.examples) { point in
                                Annotation(point.title, coordinate: route.coordinate(at: route.length * point.fraction))
                                {
                                    Button {
                                        present(point)
                                    } label: {
                                        Image(systemName: point.symbol)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(AppColors.ink)
                                            .frame(width: 28, height: 28)
                                            .background(AppColors.mist, in: Circle())
                                            .overlay(Circle().stroke(AppColors.ink, lineWidth: 1.5))
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }.accessibilityLabel("\(point.title). \(point.source)")
                                }
                            }
                            Annotation("Simulated walker", coordinate: route.sample(step, scenario).position.coordinate)
                            {
                                Image(systemName: "figure.walk.circle.fill").font(.poppins(.title)).foregroundStyle(
                                    .white, AppColors.accent)
                            }
                        }.mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
                            .mapControlVisibility(.hidden)
                            .accessibilityLabel("Simulation route map. Progress and instructions are below.")
                    }
                    ScrollView { controls(route) }
                        .frame(maxHeight: 380)
                        .scrollBounceBehavior(.basedOnSize)
                        .background(
                            GlassBackground(
                                shape: UnevenRoundedRectangle(
                                    topLeadingRadius: Radius.sheet, topTrailingRadius: Radius.sheet)))
                }
                .onAppear {
                    camera = .rect(route.line.boundingMapRect.insetBy(dx: -200, dy: -200))
                    if session == nil { reset() }
                    #if DEBUG
                        if ProcessInfo.processInfo.arguments.contains("--run-demo") { playing = true }
                    #endif
                }
                .sheet(isPresented: $showingEvaluation) {
                    if let session { NavigationStack { NavigationEventsView(session: session, expected: nil) } }
                }
                .task(id: playing && isTabSelected && scenePhase == .active) {
                    guard playing, isTabSelected, scenePhase == .active else { return }
                    while playing && session?.status != .arrived && step < Int((route.length + 80) / 0.7) {
                        do { try await Task.sleep(for: .milliseconds(Int(500 / speed))) } catch { return }
                        step += 1
                        let sample = route.sample(step, scenario)
                        let time = sensorStart.addingTimeInterval(Double(step) * 0.5)
                        let reading = NavigationInputs.simulated(
                            time: time,
                            coordinate: MapCoordinate(
                                latitude: sample.position.coordinate.latitude,
                                longitude: sample.position.coordinate.longitude),
                            accuracy: 1)
                        let newEvents = session?.receive(reading, now: time) ?? []
                        if let last = newEvents.last {
                            lastInstruction = last.message
                            alert = nil
                            events.append(contentsOf: newEvents.map(\.message))
                            speaker.announce(newEvents)
                        }
                        // Hold the walker briefly while the short cue plays, then continue automatically.
                        // Cancellation on Pause, tab changes, or backgrounding also cancels this wait.
                        if let point = AccessibilityCheckpoint.examples.first(where: {
                            !visitedCheckpoints.contains($0.id) && meters >= route.length * $0.fraction
                        }) {
                            visitedCheckpoints.insert(point.id)
                            present(point)
                            do { try await Task.sleep(for: .seconds(3)) } catch { return }
                            checkpoint = nil
                            continue
                        }
                    }
                    playing = false
                    #if DEBUG
                        if ProcessInfo.processInfo.arguments.contains("--preview-evaluation") {
                            showingEvaluation = true
                        }
                    #endif
                    if session?.status != .arrived {
                        lastInstruction = "Playback ended without confirmed arrival. Review evaluation."
                    }
                }
                .onChange(of: isTabSelected) { if !isTabSelected { speaker.stop() } }
                .onChange(of: scenePhase) { if scenePhase != .active { speaker.stop() } }
                .onDisappear {
                    playing = false
                    speaker.stop()
                }
            } else {
                ContentUnavailableView(
                    "Route unavailable", systemImage: "map",
                    description: Text("The bundled presentation route could not be opened."))
            }
        }.navigationTitle("Campus simulation").navigationBarTitleDisplayMode(.inline)
    }
    // Hierarchy: what is happening (status), how far (progress), the one main action, then settings.
    private func controls(_ route: SimulationRoute) -> some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Boyd Hall → Library").font(.poppins(.title3, weight: .bold))
                        .accessibilityAddTraits(.isHeader)
                    Text("\(Int(route.length)) m · scripted obstacle cues, not live detection")
                        .font(.poppins(.caption)).foregroundStyle(AppColors.secondaryInk)
                }
                Spacer()
                Chip(text: "Demo", symbol: "play.rectangle.fill")
            }
            HStack(alignment: .top, spacing: Spacing.m) {
                IconBadge(
                    symbol: checkpoint?.symbol ?? statusSymbol,
                    tint: checkpoint != nil ? GuidanceStep.warning : AppColors.ink, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(checkpoint?.title ?? statusTitle).font(.poppins(.headline, weight: .semibold))
                    Text(checkpoint?.description ?? alert ?? lastInstruction).font(.poppins(.callout))
                        .foregroundStyle(AppColors.secondaryInk).lineLimit(3)
                    if let checkpoint {
                        Text(checkpoint.source).font(.poppins(.caption2)).foregroundStyle(AppColors.secondaryInk)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.m)
            .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.updatesFrequently)
            .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: checkpoint?.id)
            VStack(spacing: 6) {
                ProgressView(value: meters, total: route.length).tint(AppColors.accent)
                    .accessibilityLabel("Simulated walk progress")
                HStack {
                    Text("\(Int(meters)) m walked")
                    Spacer()
                    Text("\(Int(max(0, route.length - meters))) m to go")
                }
                .font(.poppins(.caption)).foregroundStyle(AppColors.secondaryInk).monospacedDigit()
            }
            HStack(spacing: Spacing.m) {
                RoundIconButton(symbol: "arrow.counterclockwise", label: "Restart") {
                    playing = false
                    reset()
                }
                PrimaryButton(
                    title: playing ? "Pause" : session?.status == .arrived ? "Play again" : "Play",
                    icon: playing ? "pause.fill" : "play.fill"
                ) {
                    if session?.status == .arrived { reset() }
                    checkpoint = nil
                    alert = nil
                    playing.toggle()
                    if playing && step == 0 { speak("Starting the simulated walk from Boyd Hall to the library.") }
                    if !playing { speaker.stop() }
                }
                RoundIconButton(symbol: "speaker.wave.2.fill", label: "Repeat instruction") { speak(lastInstruction) }
            }
            HStack(spacing: Spacing.m) {
                Menu {
                    Picker("Scenario", selection: $scenario) {
                        ForEach(WalkScenario.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    settingLabel("Scenario", scenario.rawValue, "figure.walk.motion")
                }
                .onChange(of: scenario) {
                    playing = false
                    reset()
                }
                Picker("Speed", selection: $speed) {
                    Text("1×").tag(1.0)
                    Text("4×").tag(4.0)
                }
                .pickerStyle(.segmented).frame(width: 96)
                .accessibilityLabel("Playback speed")
            }
            Picker("View", selection: $showImages) {
                Text("Map").tag(false)
                Text("Campus images").tag(true)
            }.pickerStyle(.segmented)
            DisclosureGroup("Accessibility points · \(AccessibilityCheckpoint.examples.count)") {
                ForEach(AccessibilityCheckpoint.examples) { point in
                    Button {
                        present(point)
                    } label: {
                        BadgeLabel(title: point.title, symbol: point.symbol, tint: GuidanceStep.warning)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }.buttonStyle(.plain)
                }
            }
            .font(.poppins(.subheadline, weight: .semibold))
            if !events.isEmpty {
                DisclosureGroup("Scenario results · \(events.count)") {
                    Button("Open navigation evaluation", systemImage: "list.bullet.rectangle") {
                        showingEvaluation = true
                    }.frame(minHeight: 44)
                    ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                        Text(event).font(.poppins(.caption))
                    }
                }
                .font(.poppins(.subheadline, weight: .semibold))
            }
        }
        .tint(AppColors.ink)
        .padding(.horizontal, Spacing.xl).padding(.top, Spacing.xl).padding(.bottom, Spacing.m)
    }

    private var statusTitle: String {
        if session?.status == .arrived { return "Arrived at the library" }
        if playing { return "Walking the route" }
        return step == 0 ? "Ready to start" : "Paused"
    }
    private var statusSymbol: String {
        if session?.status == .arrived { return "flag.checkered" }
        return playing ? "figure.walk" : step == 0 ? "play.fill" : "pause.fill"
    }

    private func settingLabel(_ title: String, _ value: String, _ symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).font(.system(size: 14, weight: .semibold))
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.poppins(.caption2)).foregroundStyle(AppColors.secondaryInk)
                Text(value).font(.poppins(.subheadline, weight: .semibold)).lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.up.chevron.down").font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(AppColors.ink)
        .padding(.horizontal, Spacing.m).frame(minHeight: 48)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
    }

    /// Manual inspection does not mark a checkpoint visited; walking past it still triggers its cue.
    private func present(_ point: AccessibilityCheckpoint) {
        checkpoint = point
        alert = nil
        emit(point.description)
    }

    /// Keep the displayed instruction, event history, haptic, and spoken cue in sync.
    private func emit(_ message: String) {
        lastInstruction = message
        events.append(message)
        let count = session?.events.count ?? 0
        session?.demonstrate(message, at: sensorStart.addingTimeInterval(Double(step) * 0.5))
        speaker.announce(Array((session?.events ?? []).dropFirst(count)))
    }
    private func speak(_ message: String) {
        guard isTabSelected else { return }
        speaker.repeatMessage(message)
    }
    /// Reset both position and detector state for a repeatable presentation.
    private func reset() {
        speaker.stop()
        step = 0
        session = try? ReplayInputs.demoSession(source: .simulation, started: sensorStart)
        alert = nil
        events = []
        checkpoint = nil
        visitedCheckpoints = []
        lastInstruction = "Start the simulation to hear directions."
    }
}
