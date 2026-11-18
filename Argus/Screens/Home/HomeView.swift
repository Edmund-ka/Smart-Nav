import MapKit
import SwiftUI

/// Composes the map, voice destination controls, route preview, and in-place live guidance.
struct HomeView: View {
    @Binding var selectedTab: AppTab
    @StateObject private var voice = VoiceDestinationInput()
    @StateObject private var location = CurrentLocationService()
    @State private var destination: CampusPlace?
    @State private var start: CampusPlace?
    private enum PlacePicker: String, Identifiable {
        case start, destination
        var id: String { rawValue }
    }
    @State private var placePicker: PlacePicker?
    @State private var showingNotifications = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var route: PlannedRoute?
    @EnvironmentObject private var maps: CampusMapStore
    @StateObject private var guidance = NavigationController()
    @State private var display = GuidanceDisplay()
    @State private var showingEventLog = false
    @State private var originNote: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingRouteSettings = false
    @AppStorage("avoidStairs") private var avoidStairs = false
    @AppStorage("allowUnknownAccess") private var allowUnknownAccess = true
    private var preferences: RoutePreferences {
        RoutePreferences(avoidStairs: avoidStairs, allowUnknownAccess: allowUnknownAccess)
    }
    @State private var routeMessage: String?
    @State private var planning = false
    @StateObject private var speaker = SpeechOutput()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("speechRate") private var speechRate = 0.5
    @AppStorage("profileName") private var profileName = ""
    @EnvironmentObject private var recorder: WalkRecorder

    private var origin: CLLocationCoordinate2D? {
        route?.coordinates.first?.clCoordinate ?? start?.coordinate ?? location.location?.coordinate
    }
    private var guiding: Bool { guidance.session != nil }
    private var routeKey: String {
        "\(destination?.id ?? "")-\(start?.id ?? "current")-\(location.location?.timestamp.timeIntervalSince1970 ?? 0)-\(maps.graph?.id ?? "")-\(maps.graph?.version ?? "")-\(avoidStairs)-\(allowUnknownAccess)-\(maps.revision)"
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let card = cardHeight(in: geometry)
                ZStack(alignment: .bottom) {
                    GuidanceMapView(
                        route: route, destination: destination, origin: destination == nil ? nil : origin,
                        session: guidance.session, display: display,
                        topInset: geometry.safeAreaInsets.top + (guiding ? 112 : 56),
                        bottomInset: card + geometry.safeAreaInsets.bottom - 24
                    )
                    .ignoresSafeArea()
                    bottomCard.frame(height: card)
                }
                .overlay(alignment: .top) {
                    Group {
                        if let session = guidance.session {
                            GuidanceBanner(
                                session: session, display: display, destination: destinationName,
                                simulated: guidance.isSimulated
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        } else {
                            header.transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 8)
                }
                .animation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.85), value: guiding)
                .background(AppColors.mist.ignoresSafeArea())
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $placePicker) { picker in
                PlacePickerView(
                    choosingStart: picker == .start, selectedID: picker == .start ? start?.id : destination?.id
                ) { place in
                    voice.cancel()
                    if picker == .start {
                        start = place
                        if place == nil { location.request() }
                    } else {
                        destination = place
                        if start == nil, location.location == nil { location.request() }
                    }
                }
            }
            .sheet(isPresented: $showingNotifications) { notifications }
            .sheet(isPresented: $showingRouteSettings) {
                NavigationStack {
                    Form {
                        Toggle("Avoid stairs (unknown stairs excluded)", isOn: $avoidStairs)
                        Toggle("Allow unknown access in preview", isOn: $allowUnknownAccess)
                        Text(
                            "Live guidance is available for reviewed walked routes. The Boyd entrance requires stairs."
                        )
                    }.navigationTitle("Route preferences")
                        .toolbar { Button("Done") { showingRouteSettings = false } }
                }
            }
            .sheet(isPresented: $showingEventLog) {
                if let session = guidance.session {
                    NavigationStack { NavigationEventsView(session: session, expected: nil) }
                }
            }
            .task(id: routeKey) { await calculateRoute() }
            .onAppear {
                voice.onResult = resolveVoice
                #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("--preview-route") {
                        start = CampusPlace.places.first { $0.id == "boyd" }
                        destination = CampusPlace.places.first { $0.id == "library" }
                    }
                #endif
            }
            .onChange(of: location.status) { announce(location.status) }
            .onDisappear {
                voice.cancel()
                speaker.stop()
            }
            .onChange(of: scenePhase) { if scenePhase != .active { voice.cancel() } }
            .onChange(of: selectedTab) {
                if selectedTab != .home {
                    voice.cancel()
                    speaker.stop()
                    if guidance.running { endGuidance(announce: false) }
                }
            }
            // While voice input owns the audio session, guidance keeps its event log but stays silent.
            .onChange(of: voice.listening) { guidance.output.isListening = voice.listening || voice.preparing }
            .onChange(of: voice.preparing) { guidance.output.isListening = voice.listening || voice.preparing }
        }
    }

    private func cardHeight(in geometry: GeometryProxy) -> CGFloat {
        // The sketch gives the map 70% and the card (including tabs) 30% of the screen.
        // Larger accessibility text gets more room; its controls remain scrollable.
        let fullHeight = geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
        let fraction = dynamicTypeSize.isAccessibilitySize ? 0.55 : guiding ? 0.25 : route == nil ? 0.36 : 0.44
        return max(guiding ? 210 : 228, fullHeight * fraction - geometry.safeAreaInsets.bottom)
    }

    // The three header controls mirror the sketch: menu, origin selector, notifications.
    private var header: some View {
        HStack(alignment: .top) {
            Menu {
                Button("Route preferences", systemImage: "slider.horizontal.3") { showingRouteSettings = true }
                if destination != nil {
                    Button("Apple Maps fallback (access unverified)", systemImage: "arrow.up.forward.app") {
                        openAppleMaps()
                    }
                }
                Button("Choose destination", systemImage: "map") { placePicker = .destination }
                if route != nil {
                    Button("Preview guidance (simulated walk)", systemImage: "play.circle") {
                        startGuidance(.simulation)
                    }
                }
                Button("Where am I?", systemImage: "location") { location.request() }
                if destination != nil {
                    Button("Clear destination", systemImage: "xmark.circle") {
                        destination = nil
                        route = nil
                        voice.cancel()
                    }
                }
                Divider()
                Button("Simulate", systemImage: "map") { selectedTab = .simulate }
                Button("Record a walk", systemImage: "record.circle") { selectedTab = .record }
                Button("Profile & settings", systemImage: "person.crop.circle") { selectedTab = .profile }
            } label: {
                Image(systemName: "line.3.horizontal").font(.system(size: 20, weight: .medium))
                    .frame(width: 48, height: 48).background(GlassBackground(shape: Circle()))
            }.accessibilityLabel("Menu")
            Spacer(minLength: 8)
            Button {
                placePicker = .start
            } label: {
                VStack(spacing: 0) {
                    Text("From").font(.poppins(.caption)).foregroundStyle(AppColors.secondaryInk)
                    HStack(spacing: 5) {
                        Text(start?.name ?? "Current location")
                            .font(.poppins(.subheadline, weight: .semibold))
                        Image(systemName: "chevron.down").font(.poppins(.caption2, weight: .bold))
                    }
                }
                .padding(.horizontal, 12).frame(minHeight: 48)
                .background(GlassBackground(shape: Capsule()))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Starting location, \(start?.name ?? "current location")")
            .accessibilityHint("Choose where your walk begins")
            Spacer(minLength: 8)
            Button {
                showingNotifications = true
            } label: {
                Image(systemName: "bell").font(.system(size: 20, weight: .medium))
                    .frame(width: 48, height: 48).background(GlassBackground(shape: Circle()))
            }.buttonStyle(.plain).accessibilityLabel("Notifications")
        }
        .foregroundStyle(AppColors.ink)
    }

    private var bottomCard: some View {
        Group {
            if let session = guidance.session {
                GuidancePanel(
                    session: session, display: display, destination: destinationName,
                    simulated: guidance.isSimulated, listening: voice.listening || voice.preparing,
                    onRepeat: { guidance.output.repeatMessage(currentInstruction(session)) },
                    onVoice: toggleListening,
                    onEnd: { endGuidance(announce: true) },
                    onDone: { endGuidance(announce: false) },
                    onLog: { showingEventLog = true }
                )
                .padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 12)
                .frame(maxHeight: .infinity, alignment: .top)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                planningCard.transition(.opacity)
            }
        }
        .background {
            GlassBackground(shape: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var planningCard: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            // Refresh only this small label each minute while Home is visible.
                            TimelineView(.periodic(from: .now, by: 60)) { context in
                                Text(
                                    HomeGreeting.text(
                                        at: context.date, name: profileName.isEmpty ? "Edmund" : profileName)
                                )
                                .font(.poppins(.subheadline))
                                .foregroundStyle(AppColors.secondaryInk)
                            }
                            Text("Where to?").font(.poppins(.title2, weight: .bold)).accessibilityAddTraits(.isHeader)
                        }
                        Spacer()
                        Button {
                            selectedTab = .profile
                        } label: {
                            ProfilePhotoView(size: 44)
                                .overlay(Circle().strokeBorder(AppColors.ink.opacity(0.15), lineWidth: 1))
                        }.buttonStyle(.plain).accessibilityLabel("Open profile")
                    }
                    voiceField
                    if destination == nil && !voice.listening && !voice.preparing {
                        quickDestinations.transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    if let message = voice.message ?? guidance.message {
                        Text(message).font(.poppins(.caption)).accessibilityAddTraits(.updatesFrequently)
                    }
                    if let route, let destination {
                        RouteSummary(
                            route: route, destination: destination, originNote: originNote,
                            liveReady: maps.graph?.permitsLiveGuidance(for: route) == true
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if destination != nil {
                        HStack(spacing: 6) {
                            if planning { ProgressView().controlSize(.small) }
                            Text(routeSummary).font(.poppins(.caption))
                        }.accessibilityElement(children: .combine)
                    }
                    if recorder.recording {
                        Label("A walk is recording", systemImage: "record.circle.fill").font(.poppins(.caption))
                    }
                }
                .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 4)
                .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.85), value: route?.id)
                .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: voice.listening)
            }.scrollBounceBehavior(.basedOnSize)
            if destination != nil {
                HStack(spacing: 10) {
                    Button(action: startWalk) {
                        HStack(spacing: 10) {
                            Text(route == nil ? "Start" : "Start guidance").font(.poppins(.headline, weight: .semibold))
                            Image(systemName: "location.north.fill")
                        }
                        .foregroundStyle(AppColors.ink)
                        .padding(.horizontal, 30).frame(minHeight: 48)
                        .background(AppColors.accent, in: Capsule())
                        .shadow(color: AppColors.accent.opacity(route == nil ? 0 : 0.45), radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(voice.preparing || voice.listening)
                    .accessibilityHint(
                        destination == nil ? "Speak your destination first" : "Starts live guidance on this screen")
                    if route != nil {
                        Button {
                            startGuidance(.simulation)
                        } label: {
                            Image(systemName: "play.fill").font(.system(size: 16, weight: .bold))
                                .frame(width: 48, height: 48)
                                .background(GlassBackground(shape: Circle()))
                                .overlay(Circle().strokeBorder(AppColors.ink.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Preview guidance with a simulated walk")
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .foregroundStyle(AppColors.ink)
                .padding(.vertical, 2)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: route != nil)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            AppTabBar(selection: $selectedTab)
        }
    }

    // This is a button styled like a search field. It never invokes the keyboard.
    // While listening it fills with the accent colour and the microphone animates, so the state
    // is visible as well as spoken.
    private var voiceField: some View {
        let active = voice.listening || voice.preparing
        return HStack(spacing: 0) {
            Button(action: toggleListening) {
                HStack(spacing: 12) {
                    ZStack {
                        if active && !reduceMotion { ListeningPulse() }
                        Image(systemName: active ? "waveform" : "mic.fill")
                            .font(.system(size: 15, weight: .bold))
                            .symbolEffect(.variableColor.iterative, isActive: voice.listening)
                            .foregroundStyle(active ? AppColors.accent : .white)
                            .frame(width: 34, height: 34)
                            .background(active ? AnyShapeStyle(.white) : AnyShapeStyle(AppColors.ink), in: Circle())
                    }
                    Text(
                        voice.preparing
                            ? "Getting ready…"
                            : voice.listening
                                ? (voice.transcript.isEmpty ? "Listening…" : voice.transcript)
                                : destination?.name ?? "Say where you want to go"
                    )
                    .font(.poppins(.body, weight: destination == nil && !active ? .regular : .semibold))
                    .foregroundStyle(
                        active ? .white : destination == nil ? AppColors.secondaryInk : AppColors.ink
                    )
                    .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.leading, 7).padding(.trailing, 16).frame(minHeight: 50).contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                voice.listening
                    ? "Listening. \(voice.transcript)" : "Search by voice, \(destination?.name ?? "choose destination")"
            )
            .accessibilityHint(
                voice.listening ? "Tap to finish listening" : "Tap and say where you want to go. No typing needed")
            if active {
                Button {
                    voice.cancel()
                } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundStyle(.white)
                        .frame(width: 44, height: 50)
                }.buttonStyle(.plain).accessibilityLabel("Cancel listening")
            }
        }
        .background {
            if active {
                Capsule().fill(AppColors.accent.gradient)
            } else {
                GlassBackground(shape: Capsule())
            }
        }
        .overlay(Capsule().strokeBorder(AppColors.ink.opacity(active ? 0 : 0.2), lineWidth: 1))
        .shadow(color: AppColors.accent.opacity(active ? 0.35 : 0), radius: 12, y: 4)
    }

    /// Supported destinations are shown, so nobody has to remember what Argus knows (recognition over recall).
    private var quickDestinations: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Try saying “Take me to the library”, or choose:")
                .font(.poppins(.caption)).foregroundStyle(AppColors.secondaryInk)
            HStack(spacing: 8) {
                ForEach(CampusPlace.available(in: maps.graph)) { place in
                    Button {
                        choose(place)
                    } label: {
                        Label(place.name, systemImage: place.icon)
                            .font(.poppins(.subheadline, weight: .semibold))
                            .padding(.horizontal, 14).frame(minHeight: 44)
                            .background(.white.opacity(0.6), in: Capsule())
                            .overlay(Capsule().strokeBorder(AppColors.ink.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Plans a walking route")
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func choose(_ place: CampusPlace) {
        voice.cancel()
        if start?.id == place.id { start = nil }
        destination = place
        if start == nil, location.location == nil { location.request() }
        announce("Planning a route to \(place.name).")
    }

    private var routeSummary: String {
        if let route {
            return
                "\(Int(route.distance)) m · Argus route · \(route.isVerified ? "verified map" : maps.graph?.permitsLiveGuidance(for: route) == true ? "walk-confirmed route · stairs required" : "demonstration, access unverified")"
        }
        return routeMessage ?? "Choose a mapped origin and destination."
    }

    private func beginListening() {
        speaker.stop()
        guidance.output.stop()
        Task { await voice.start() }
    }

    private func toggleListening() {
        if voice.listening { voice.finish() } else if !voice.preparing { beginListening() }
    }

    private var destinationName: String { destination?.name ?? "your destination" }

    /// Start guides on this screen with live GPS when the route has been walked and reviewed;
    /// otherwise it rehearses with a clearly labelled simulated walk.
    private func startWalk() {
        guard destination != nil else {
            beginListening()
            return
        }
        guard route != nil else {
            announce(routeMessage ?? "Choose a mapped starting point and destination first.")
            return
        }
        startGuidance(.live)
    }

    private func startGuidance(_ requested: PositionSource) {
        guard let graph = maps.graph, let route else { return }
        voice.cancel()
        speaker.stop()
        let source: PositionSource =
            requested == .live && !graph.permitsLiveGuidance(for: route) ? .simulation : requested
        guidance.start(graph: graph, route: route, preferences: preferences, source: source)
        if let message = guidance.message {
            announce(message)
            return
        }
        display.follow(guidance)
    }

    private func endGuidance(announce shouldAnnounce: Bool) {
        voice.cancel()
        display.stopFollowing()
        guidance.dismiss()
        if shouldAnnounce { announce("Guidance ended.") }
    }

    private func currentInstruction(_ session: NavigationSession) -> String {
        let step = GuidanceStep.make(session: session, progress: display.progress, destination: destinationName)
        let distance = step.distance.map { " in \($0) meters" } ?? ""
        return "\(step.title)\(distance)."
    }

    private func openAppleMaps() {
        guard let destination else { return }
        MKMapItem.openMaps(
            with: [start?.mapItem ?? MKMapItem.forCurrentLocation(), destination.mapItem],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }

    private var notifications: some View {
        NavigationStack {
            List {
                Section {
                    if recorder.recording { Label("A walk is recording", systemImage: "record.circle.fill") }
                    if let message = voice.message { Label(message, systemImage: "mic") }
                    if let routeMessage { Label(routeMessage, systemImage: "map") }
                    if location.status != "Choose a destination to get started." {
                        Label(location.status, systemImage: "location")
                    }
                    if !recorder.recording && voice.message == nil && routeMessage == nil
                        && location.status == "Choose a destination to get started."
                    {
                        ContentUnavailableView(
                            "No new notifications", systemImage: "bell",
                            description: Text("Updates from your current walk will appear here."))
                    }
                }.listRowBackground(GlassBackground(shape: Rectangle()))
            }.glassListCanvas().navigationTitle("Notifications")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { Button("Done") { showingNotifications = false } }
                }
        }.presentationDetents([.medium, .large])
    }

    private var routeCoordinates: [CLLocationCoordinate2D] { route?.coordinates.map(\.clCoordinate) ?? [] }

    /// Route planning is local. Current location must match a verified node; no connector is invented.
    private func calculateRoute() async {
        // Never replace the route underneath active guidance.
        guard guidance.session == nil else { return }
        route = nil
        routeMessage = nil
        originNote = nil
        guard let destination, let graph = maps.graph else { return }
        let end = graph.entrance(for: destination.id)
        var originNode: CampusNode?
        if let start {
            originNode = graph.entrance(for: start.id)
        } else if let fix = location.location {
            let point = MapCoordinate(latitude: fix.coordinate.latitude, longitude: fix.coordinate.longitude)
            originNode = RoutePlanner.matchedNode(point: point, accuracy: fix.horizontalAccuracy, graph: graph)
            // Otherwise start from the walked route that reaches this destination, and say how far away it is.
            if originNode == nil, let end, let reviewed = graph.reviewedOrigin(endingAt: end.id) {
                originNode = reviewed
                let away = Int(reviewed.coordinate.distance(to: point).rounded())
                originNote =
                    away <= 40
                    ? "From your location at \(reviewed.name)" : "Starts at \(reviewed.name) · you're \(away) m away"
            }
        } else if let end, let reviewed = graph.reviewedOrigin(endingAt: end.id) {
            originNode = reviewed
            originNote = "Starts at \(reviewed.name)"
        }
        guard let originNode else {
            routeMessage =
                "Choose a mapped starting point. Current-location routing needs a reliable fix at a verified junction."
            return
        }
        guard let end else {
            routeMessage =
                "Destination is outside this graph. Apple Maps is available from the menu as an unverified fallback."
            return
        }
        do {
            route = try RoutePlanner.plan(graph: graph, from: originNode.id, to: end.id, preferences: preferences)
            if originNote == nil, start != nil { originNote = "From \(originNode.name)" }
            if reduceMotion { display.reveal = 1 } else { display.revealRoute() }
        } catch { routeMessage = error.localizedDescription }
        #if DEBUG
            if route != nil && ProcessInfo.processInfo.arguments.contains("--preview-guidance") {
                startGuidance(.simulation)
            }
        #endif
    }

    /// Apply a validated voice request; leave the current origin alone when none was spoken.
    private func resolveVoice(_ text: String) {
        // During guidance the microphone accepts the small navigation command vocabulary.
        if let session = guidance.session {
            switch NavigationCommand.parse(text) {
            case .repeatInstruction: guidance.output.repeatMessage(currentInstruction(session))
            case .currentLocation:
                guidance.output.repeatMessage(
                    "\(Int(display.progress)) meters along the route, \(Int(max(0, session.route.distance - display.progress))) meters to \(destinationName)."
                )
            case .stop: endGuidance(announce: true)
            case nil: voice.message = "Say repeat, where am I, or stop navigation."
            }
            return
        }
        let words = text.lowercased().split { !$0.isLetter }.joined(separator: " ")
        if route != nil, ["start", "go", "lets go", "start guidance", "start navigation", "begin"].contains(words) {
            startWalk()
            return
        }
        switch VoiceDestinationParser.parse(text) {
        case .success(let request):
            if let origin = request.origin {
                switch origin {
                case .currentLocation: start = nil
                case .place(let place): start = place
                }
            }
            destination = request.destination
            if start == nil, location.location == nil { location.request() }
            announce("Planning a route to \(request.destination.name).")
            Task {
                // Speak the route once it is drawn, so the user hears distance and the first step.
                try? await Task.sleep(for: .milliseconds(400))
                if let route {
                    let minutes = max(1, Int((route.distance / 1.25 / 60).rounded()))
                    let stairs =
                        route.steps.first?.edge.stairs == .yes ? " It begins with stairs down from Boyd Hall." : ""
                    announce(
                        "Route ready. \(Int(route.distance)) meters to \(request.destination.name), about \(minutes) minutes.\(stairs) Tap Start guidance, or say start."
                    )
                } else if let routeMessage {
                    announce(routeMessage)
                }
            }
        case .failure(let error):
            voice.message = error.message
            announce(error.message)
        }
    }

    /// Announcements use the same output rules as simulation and recorded replay.
    private func announce(_ text: String) {
        speaker.speak(text, rate: speechRate)
    }
}
