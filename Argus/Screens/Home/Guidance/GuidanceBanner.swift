import SwiftUI

/// What the top banner shows. Derived from the engine state plus the smoothly animated progress,
/// so the distance counts down continuously between GPS fixes.
struct GuidanceStep: Equatable {
    var id: String
    var icon: String
    var title: String
    var detail: String?
    var distance: Int?
    var tint: Color

    static let navy = AppColors.ink
    static let warning = Color(red: 0.93, green: 0.45, blue: 0.13)
    static let success = Color(red: 0.11, green: 0.6, blue: 0.4)

    static func make(session: NavigationSession, progress: Double, destination: String) -> Self {
        switch session.status {
        case .arrived:
            return Self(
                id: "arrived", icon: "flag.checkered", title: "You've arrived", detail: destination, distance: nil,
                tint: success)
        case .stopped:
            return Self(id: "stopped", icon: "stop.circle", title: "Guidance ended", distance: nil, tint: navy)
        case .offRoute:
            return Self(
                id: "off", icon: "arrow.uturn.backward", title: "Off route",
                detail: "Head back to the highlighted path", distance: nil, tint: warning)
        case .waiting:
            return Self(
                id: "waiting", icon: "location.magnifyingglass", title: "Finding your position…",
                detail: "Stand at the start of the route", distance: nil, tint: navy)
        case .uncertain:
            return Self(
                id: "uncertain", icon: "location.slash", title: "Weak GPS signal",
                detail: session.lastInstruction, distance: nil, tint: warning)
        case .following:
            break
        }
        if let first = session.route.steps.first, first.edge.stairs == .yes, progress < first.edge.lengthMeters - 4 {
            return Self(
                id: "stairs", icon: "figure.stairs", title: "Take the stairs down",
                detail: "Then follow the sidewalk", distance: Int(first.edge.lengthMeters - progress), tint: navy)
        }
        let maneuvers: Set<NavigationEvent.Kind> = [.turnLeft, .turnRight, .crossing, .accessibility]
        if let next = session.instructions.first(where: { $0.meters >= progress - 2 && maneuvers.contains($0.kind) }) {
            let meters = max(0, Int((next.meters - progress).rounded()))
            let now = meters <= 5
            let tint = meters <= 12 ? AppColors.accent : navy
            switch next.kind {
            case .turnLeft, .turnRight:
                let side = next.kind == .turnLeft ? "left" : "right"
                return Self(
                    id: next.id, icon: next.kind == .turnLeft ? "arrow.turn.up.left" : "arrow.turn.up.right",
                    title: now ? "Turn \(side) now" : "Turn \(side)",
                    detail: now ? nil : "Then continue toward \(destination)", distance: now ? nil : meters,
                    tint: tint)
            case .crossing:
                return Self(
                    id: next.id, icon: "figure.walk.crossing", title: "Crossing ahead", detail: "Check conditions",
                    distance: meters, tint: tint)
            default:
                return Self(
                    id: next.id, icon: "exclamationmark.triangle.fill", title: next.message, distance: meters,
                    tint: tint)
            }
        }
        let remaining = max(0, Int((session.route.distance - progress).rounded()))
        return Self(
            id: "continue", icon: "arrow.up", title: "Continue to \(destination)",
            detail: remaining <= 25 ? "The entrance is just ahead" : nil, distance: remaining, tint: navy)
    }
}

struct GuidanceBanner: View {
    let session: NavigationSession
    let display: GuidanceDisplay
    let destination: String
    let simulated: Bool

    var body: some View {
        let step = GuidanceStep.make(session: session, progress: display.progress, destination: destination)
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle().fill(.white.opacity(0.18))
                Image(systemName: step.icon).font(.system(size: 30, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: step.id)
            }
            .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 0) {
                if let distance = step.distance {
                    Text("\(distance) m").font(.poppins(.title, weight: .bold)).monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                }
                Text(step.title).font(.poppins(step.distance == nil ? .title3 : .headline, weight: .semibold))
                    .lineLimit(2).minimumScaleFactor(0.8)
                if let detail = step.detail {
                    Text(detail).font(.poppins(.caption)).opacity(0.85).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.trailing, 64)
        .foregroundStyle(.white)
        .padding(16)
        .frame(minHeight: 100)
        .fixedSize(horizontal: false, vertical: true)
        .overlay(alignment: .topTrailing) { ModeTag(simulated: simulated).padding(14) }
        .background(step.tint.gradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 18, y: 8)
        .animation(.snappy(duration: 0.35), value: step.distance)
        .animation(.smooth(duration: 0.45), value: step.id)
        .animation(.smooth(duration: 0.45), value: step.tint)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

private struct ModeTag: View {
    var simulated: Bool
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(simulated ? Color.white : Color.red).frame(width: 7, height: 7)
                .phaseAnimator([1.0, 0.3]) { dot, phase in
                    dot.opacity(phase)
                } animation: { _ in
                    .easeInOut(duration: 0.8)
                }
            Text(simulated ? "SIMULATED" : "LIVE").font(.system(size: 10, weight: .heavy)).tracking(0.8)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(.white.opacity(0.18), in: Capsule())
        .accessibilityLabel(simulated ? "Simulated walk" : "Live GPS guidance")
    }
}

/// Bottom panel while guiding: time and distance remaining, animated progress, and controls.
struct GuidancePanel: View {
    let session: NavigationSession
    let display: GuidanceDisplay
    let destination: String
    let simulated: Bool
    let listening: Bool
    var onRepeat: () -> Void
    var onVoice: () -> Void
    var onEnd: () -> Void
    var onDone: () -> Void
    var onLog: () -> Void

    var body: some View {
        Group {
            if session.status == .arrived {
                arrival.transition(.scale(scale: 0.85).combined(with: .opacity))
            } else {
                active.transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: session.status == .arrived)
    }

    private var remaining: Double { max(0, session.route.distance - display.progress) }

    private var active: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(eta).font(.poppins(.title2, weight: .bold)).contentTransition(.numericText())
                    Text("\(Int(remaining.rounded())) m · arrive \(arrivalTime)")
                        .font(.poppins(.subheadline)).foregroundStyle(AppColors.secondaryInk).monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                }
                Spacer()
                SignalChip(session: session, simulated: simulated)
            }
            RouteProgressBar(fraction: session.route.distance > 0 ? display.progress / session.route.distance : 0)
            HStack(spacing: 12) {
                CircleControl(icon: "speaker.wave.2.fill", label: "Repeat instruction", action: onRepeat)
                CircleControl(
                    icon: listening ? "waveform" : "mic.fill",
                    label: listening ? "Finish voice command" : "Voice command: repeat, where am I, or stop",
                    highlighted: listening, action: onVoice)
                Spacer()
                Button(action: onEnd) {
                    Label("End", systemImage: "xmark").font(.poppins(.headline, weight: .semibold))
                        .foregroundStyle(.white).padding(.horizontal, 28).frame(minHeight: 52)
                        .background(Color.red.gradient, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("End navigation")
            }
        }
        .animation(.snappy, value: Int(remaining))
    }

    private var arrival: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 52))
                .foregroundStyle(GuidanceStep.success).symbolEffect(.bounce, value: session.status == .arrived)
            Text("Arrived at \(destination)").font(.poppins(.title3, weight: .bold)).multilineTextAlignment(.center)
            Text("\(Int(session.route.distance)) m walked in \(duration)").font(.poppins(.subheadline))
                .foregroundStyle(AppColors.secondaryInk)
            HStack(spacing: 12) {
                Button("Event log", systemImage: "list.bullet.rectangle", action: onLog)
                    .font(.poppins(.subheadline, weight: .semibold)).frame(minHeight: 48)
                    .padding(.horizontal, 18).background(AppColors.ink.opacity(0.08), in: Capsule())
                    .buttonStyle(.plain)
                Button(action: onDone) {
                    Text("Done").font(.poppins(.headline, weight: .semibold)).padding(.horizontal, 36)
                        .frame(minHeight: 48).background(AppColors.accent, in: Capsule())
                }.buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var pace: Double { session.speed > 0.6 ? session.speed : 1.25 }
    private var eta: String {
        let minutes = Int((remaining / pace / 60).rounded(.up))
        return remaining < 15 ? "Almost there" : minutes <= 1 ? "1 min" : "\(minutes) min"
    }
    private var arrivalTime: String {
        Date().addingTimeInterval(remaining / pace).formatted(date: .omitted, time: .shortened)
    }
    private var duration: String {
        guard let first = session.events.first?.time, let last = session.events.last?.time else { return "—" }
        let seconds = Int(last.timeIntervalSince(first))
        return "\(seconds / 60):" + String(format: "%02d", seconds % 60)
    }
}

private struct SignalChip: View {
    let session: NavigationSession
    let simulated: Bool
    var body: some View {
        let accuracy = session.position?.accuracy
        let color: Color =
            simulated
            ? .purple
            : accuracy == nil ? .gray : accuracy! <= 10 ? .green : accuracy! <= 20 ? .yellow : .orange
        HStack(spacing: 6) {
            Image(systemName: simulated ? "play.circle.fill" : "location.fill").font(.system(size: 11, weight: .bold))
                .foregroundStyle(color).symbolEffect(.pulse, isActive: !simulated)
            Text(simulated ? "Simulated" : accuracy.map { "GPS ±\(Int($0.rounded())) m" } ?? "Locating…")
                .font(.poppins(.caption, weight: .semibold)).monospacedDigit()
        }
        .padding(.horizontal, 10).frame(minHeight: 30)
        .background(color.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

private struct RouteProgressBar: View {
    var fraction: Double
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let clamped = min(1, max(0, fraction))
            ZStack(alignment: .leading) {
                Capsule().fill(AppColors.ink.opacity(0.1)).frame(height: 8)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accent.opacity(0.55), AppColors.accent], startPoint: .leading,
                            endPoint: .trailing)
                    )
                    .frame(width: max(8, width * clamped), height: 8)
                Image(systemName: "flag.checkered").font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.ink).frame(width: 24, height: 24)
                    .offset(x: width - 24)
                Image(systemName: "figure.walk").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 28, height: 28).background(AppColors.accent, in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2.5)).shadow(color: .black.opacity(0.2), radius: 3)
                    .offset(x: max(0, min(width - 52, width * clamped - 14)))
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 30)
        .accessibilityElement()
        .accessibilityLabel("Route progress")
        .accessibilityValue("\(Int(min(1, max(0, fraction)) * 100)) percent")
    }
}

private struct CircleControl: View {
    let icon: String
    let label: String
    var highlighted = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 19, weight: .semibold))
                .symbolEffect(.variableColor.iterative, isActive: highlighted)
                .foregroundStyle(highlighted ? .white : AppColors.ink)
                .frame(width: 52, height: 52)
                .background(highlighted ? AppColors.accent : AppColors.ink.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
