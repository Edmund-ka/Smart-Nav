import SwiftUI

/// The planned route on Home before guidance starts: destination, distance, time and route facts.
struct RouteSummary: View {
    let route: PlannedRoute
    let destination: CampusPlace
    let originNote: String?
    let liveReady: Bool

    private var minutes: Int { max(1, Int((route.distance / 1.25 / 60).rounded())) }
    private var turns: Int {
        RouteInstructions.make(for: route).filter { $0.kind == .turnLeft || $0.kind == .turnRight }.count
    }
    private var hasStairs: Bool { route.steps.contains { $0.edge.stairs == .yes } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: destination.icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 44, height: 44).background(AppColors.accent.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 0) {
                    Text(destination.name).font(.poppins(.headline, weight: .semibold))
                    Text("\(Int(route.distance)) m · \(minutes) min walk · \(turns) turn\(turns == 1 ? "" : "s")")
                        .font(.poppins(.subheadline)).foregroundStyle(AppColors.secondaryInk)
                }
                Spacer(minLength: 0)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if let originNote { chip(originNote, "figure.walk") }
                    if hasStairs { chip("Stairs at start", "figure.stairs") }
                    chip(
                        route.isVerified ? "Verified map" : liveReady ? "Walk-confirmed route" : "Unverified map",
                        liveReady ? "checkmark.seal.fill" : "exclamationmark.triangle")
                }
            }
        }
        .padding(12)
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func chip(_ text: String, _ icon: String) -> some View {
        Label(text, systemImage: icon).font(.poppins(.caption, weight: .semibold)).lineLimit(1)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(AppColors.ink.opacity(0.07), in: Capsule())
    }
}

/// Expanding rings behind the microphone while Argus is listening.
struct ListeningPulse: View {
    @State private var expand = false
    var body: some View {
        ZStack {
            ForEach(0..<2) { ring in
                Circle().stroke(.white.opacity(0.7), lineWidth: 2)
                    .frame(width: 34, height: 34)
                    .scaleEffect(expand ? 1.9 : 1)
                    .opacity(expand ? 0 : 0.8)
                    .animation(
                        .easeOut(duration: 1.4).repeatForever(autoreverses: false).delay(Double(ring) * 0.7),
                        value: expand)
            }
        }
        .onAppear { expand = true }
        .accessibilityHidden(true)
    }
}
