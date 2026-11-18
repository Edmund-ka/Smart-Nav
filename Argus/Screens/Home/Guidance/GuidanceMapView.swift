import MapKit
import SwiftUI

/// The Home map. Previews a planned route with a draw-in animation, then becomes a tilted,
/// heading-up follow camera with a gliding position marker during guidance.
struct GuidanceMapView: View {
    let route: PlannedRoute?
    let destination: CampusPlace?
    let origin: CLLocationCoordinate2D?
    let session: NavigationSession?
    let display: GuidanceDisplay
    var topInset: CGFloat = 0
    var bottomInset: CGFloat = 0

    private static let campus = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.1670, longitude: -86.8290),
        latitudinalMeters: 780, longitudinalMeters: 780
    )
    // Camera state belongs to the map so unrelated UI updates do not reset a user pan.
    @State private var camera: MapCameraPosition = .region(campus)
    @State private var following = false

    private var guiding: Bool { session != nil }
    private var path: [MapCoordinate] { session?.route.coordinates ?? route?.coordinates ?? [] }
    private var turns: [RouteInstruction] {
        let all = session?.instructions ?? route.map { RouteInstructions.make(for: $0) } ?? []
        return all.filter { $0.kind == .turnLeft || $0.kind == .turnRight }
    }

    var body: some View {
        Map(position: $camera, interactionModes: guiding ? [.zoom] : .all) {
            routeLines
            ForEach(turns, id: \.id) { turn in
                if let point = MapGeometry.coordinate(at: turn.meters, on: path) {
                    Annotation("Turn", coordinate: point.clCoordinate, anchor: .center) {
                        TurnMarker(left: turn.kind == .turnLeft)
                    }.annotationTitles(.hidden)
                }
            }
            if let origin, !guiding {
                Annotation("Start", coordinate: origin, anchor: .center) { StartMarker() }
                    .annotationTitles(.hidden)
            }
            if let end = destination?.coordinate ?? path.last?.clCoordinate {
                Annotation(
                    destination?.name ?? "Destination", coordinate: path.last?.clCoordinate ?? end, anchor: .bottom
                ) {
                    PlacePin(icon: destination?.icon ?? "mappin", pulsing: true)
                }
            }
            if let session, let puck = puckCoordinate(session) {
                Annotation("Your position", coordinate: puck.clCoordinate, anchor: .center) {
                    UserPuck(
                        matched: session.status == .following || session.status == .arrived,
                        tint: puckTint(session))
                }.annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControlVisibility(.hidden)
        .safeAreaPadding(.top, topInset)
        .safeAreaPadding(.bottom, bottomInset)
        .onChange(of: route?.id) { showOverview(animated: true) }
        .onChange(of: guiding) {
            if guiding {
                following = false
                withAnimation(.easeInOut(duration: 1.4)) { camera = followCamera() }
                Task {
                    try? await Task.sleep(for: .seconds(1.4))
                    if session != nil { following = true }
                }
            } else {
                following = false
                showOverview(animated: true)
            }
        }
        .onChange(of: display.progress) { if following { camera = followCamera() } }
        .onChange(of: display.heading) { if following { camera = followCamera() } }
        .accessibilityLabel(guiding ? "Guidance map" : "Campus map")
    }

    @MapContentBuilder private var routeLines: some MapContent {
        let total = MapGeometry.length(path)
        let line = StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
        let casing = StrokeStyle(lineWidth: 13, lineCap: .round, lineJoin: .round)
        if guiding {
            let travelled = MapGeometry.slice(path, from: 0, to: display.progress)
            let ahead = MapGeometry.slice(path, from: display.progress, to: total)
            if travelled.count > 1 {
                MapPolyline(coordinates: travelled.map(\.clCoordinate))
                    .stroke(Color.gray.opacity(0.55), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .mapOverlayLevel(level: .aboveLabels)
            }
            if ahead.count > 1 {
                MapPolyline(coordinates: ahead.map(\.clCoordinate)).stroke(.white, style: casing)
                    .mapOverlayLevel(level: .aboveLabels)
                MapPolyline(coordinates: ahead.map(\.clCoordinate)).stroke(AppColors.accent, style: line)
                    .mapOverlayLevel(level: .aboveLabels)
            }
        } else if path.count > 1 {
            let drawn = MapGeometry.slice(path, from: 0, to: max(0.5, total * display.reveal))
            if drawn.count > 1 {
                MapPolyline(coordinates: drawn.map(\.clCoordinate)).stroke(.white, style: casing)
                    .mapOverlayLevel(level: .aboveLabels)
                MapPolyline(coordinates: drawn.map(\.clCoordinate)).stroke(AppColors.accent, style: line)
                    .mapOverlayLevel(level: .aboveLabels)
            }
        }
    }

    /// Matched positions glide along the route; unmatched fixes are shown where GPS reports them.
    private func puckCoordinate(_ session: NavigationSession) -> MapCoordinate? {
        switch session.status {
        case .following, .arrived, .stopped:
            return session.lastProgressTime == nil
                ? session.position?.coordinate : MapGeometry.coordinate(at: display.progress, on: path)
        default:
            return session.position?.coordinate
        }
    }

    private func puckTint(_ session: NavigationSession) -> Color {
        switch session.status {
        case .offRoute, .uncertain: return .orange
        default: return Color(red: 0.16, green: 0.45, blue: 0.95)
        }
    }

    private func followCamera() -> MapCameraPosition {
        let center = MapGeometry.coordinate(at: display.progress + 14, on: path) ?? path.first
        return .camera(
            MapCamera(
                centerCoordinate: (center ?? MapCoordinate(latitude: 36.167, longitude: -86.829)).clCoordinate,
                distance: 250, heading: display.heading, pitch: 40))
    }

    private func showOverview(animated: Bool) {
        let target: MapCameraPosition
        if path.count > 1 {
            var rect = MKMapRect.null
            for point in path {
                rect = rect.union(
                    MKMapRect(origin: MKMapPoint(point.clCoordinate), size: MKMapSize(width: 1, height: 1)))
            }
            let pad = max(rect.size.width, rect.size.height) * 0.35 + 60
            target = .rect(rect.insetBy(dx: -pad, dy: -pad))
        } else {
            target = .region(Self.campus)
        }
        if animated {
            withAnimation(.easeInOut(duration: 0.9)) { camera = target }
        } else {
            camera = target
        }
    }
}

/// Position marker with a soft pulse; a matched position is solid, an unmatched one is hollow.
private struct UserPuck: View {
    var matched: Bool
    var tint: Color
    @State private var pulse = false
    var body: some View {
        ZStack {
            Circle().fill(tint.opacity(0.25)).frame(width: 74, height: 74)
                .scaleEffect(pulse ? 1 : 0.45).opacity(pulse ? 0 : 0.9)
            Circle().fill(.white).frame(width: 36, height: 36).shadow(color: .black.opacity(0.25), radius: 5, y: 2)
            Circle().fill(matched ? tint : tint.opacity(0.55)).frame(width: 28, height: 28)
            Image(systemName: "location.north.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) { pulse = true }
        }
        .accessibilityHidden(true)
    }
}

private struct StartMarker: View {
    var body: some View {
        Image(systemName: "figure.walk").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
            .frame(width: 30, height: 30).background(AppColors.ink, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 3)).shadow(radius: 3, y: 1)
            .accessibilityHidden(true)
    }
}

private struct TurnMarker: View {
    var left: Bool
    var body: some View {
        Image(systemName: left ? "arrow.turn.up.left" : "arrow.turn.up.right")
            .font(.system(size: 11, weight: .heavy)).foregroundStyle(AppColors.ink)
            .frame(width: 24, height: 24).background(.white, in: Circle())
            .overlay(Circle().stroke(AppColors.ink, lineWidth: 2))
            .accessibilityHidden(true)
    }
}
