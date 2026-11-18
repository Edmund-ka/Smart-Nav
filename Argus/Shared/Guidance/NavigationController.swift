import Combine
import Foundation
import UIKit

/// SwiftUI adapter around the pure engine. It owns the live-location lifecycle, the simulated
/// walker used for rehearsals, and keeps the screen awake while guidance is active.
final class NavigationController: ObservableObject {
    @Published private(set) var session: NavigationSession?
    @Published private(set) var message: String?
    @Published private(set) var running = false
    let output = GuidanceOutput()
    private let live = LiveLocationProvider()
    private var loop: Task<Void, Never>?
    private var demoMeters = 0.0
    private var demoTime = Date()
    private var demoPath: [MapCoordinate] = []

    var isSimulated: Bool { session?.source == .simulation }
    #if DEBUG
        // Simulator checks can pass --fast-demo to walk the route four times faster.
        private let demoStep = ProcessInfo.processInfo.arguments.contains("--fast-demo") ? 2.6 : 0.65
    #else
        private let demoStep = 0.65
    #endif

    func start(graph: CampusGraph, route: PlannedRoute, preferences: RoutePreferences, source: PositionSource) {
        stop()
        do {
            session = try NavigationSession(
                graph: graph, route: route, source: source, preferences: preferences, started: Date())
            running = true
            message = nil
            UIApplication.shared.isIdleTimerDisabled = true
            output.announce(session?.events ?? [])
            demoMeters = 0
            demoTime = Date()
            demoPath = route.coordinates
            if source == .live {
                live.onPosition = { [weak self] in self?.receive($0, now: Date()) }
                live.onUnavailable = { [weak self] text in self?.uncertain(text) }
                live.start()
            }
            loop = Task { [weak self] in
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
                    guard let self, self.running else { return }
                    self.step()
                }
            }
        } catch { message = error.localizedDescription }
    }

    /// Live mode checks for silent GPS; simulation walks the route at an ordinary 1.3 m/s pace.
    private func step() {
        guard let session else { return }
        if session.source == .live {
            tick()
            return
        }
        demoMeters += demoStep
        demoTime = demoTime.addingTimeInterval(0.5)
        if let point = MapGeometry.coordinate(at: demoMeters, on: demoPath) {
            receive(NavigationInputs.simulated(time: demoTime, coordinate: point, accuracy: 3), now: demoTime)
        }
    }

    func receive(_ reading: NavigationPosition, now: Date) {
        guard running else { return }
        let events = session?.receive(reading, now: now) ?? []
        output.announce(events)
        if session?.status == .arrived { finish() }
    }
    func tick() {
        guard running, session?.source == .live else { return }
        let count = session?.events.count ?? 0
        session?.checkFreshness(now: Date())
        output.announce(Array((session?.events ?? []).dropFirst(count)))
    }
    func uncertain(_ text: String) {
        guard running else { return }
        let count = session?.events.count ?? 0
        session?.markUncertain(at: Date(), message: text)
        output.announce(Array((session?.events ?? []).dropFirst(count)))
    }
    /// Ends active guidance but keeps the session so the summary can still be shown.
    func stop() {
        output.stop()
        if running { session?.stop(at: Date()) }
        finish()
    }
    /// Clears the finished session and returns Home to route preview.
    func dismiss() {
        stop()
        session = nil
        message = nil
    }
    private func finish() {
        live.stop()
        loop?.cancel()
        loop = nil
        running = false
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
