import MapKit
import SwiftUI

private struct ReplayRoute {
    let line: MKPolyline
    let points: [MKMapPoint]
    let cumulativeMeters: [Double]
    var length: Double { cumulativeMeters.last ?? 0 }

    init?() {
        guard let url = Bundle.main.url(forResource: "boyd_to_library", withExtension: "geojson"),
              let data = try? Data(contentsOf: url),
              let objects = try? MKGeoJSONDecoder().decode(data),
              let feature = objects.compactMap({ $0 as? MKGeoJSONFeature }).first(where: { $0.identifier == "route" }),
              let line = feature.geometry.first as? MKPolyline, line.pointCount >= 2 else { return nil }
        self.line = line
        points = Array(UnsafeBufferPointer(start: line.points(), count: line.pointCount))
        var distances = [0.0]
        for (start, end) in zip(points, points.dropFirst()) {
            distances.append(distances[distances.count - 1] + start.distance(to: end))
        }
        guard let total = distances.last, total > 0 else { return nil }
        cumulativeMeters = distances
    }

    func coordinate(at meters: Double) -> CLLocationCoordinate2D {
        guard let end = cumulativeMeters.firstIndex(where: { $0 > meters }), end > 0 else {
            return points[points.count - 1].coordinate
        }
        let start = end - 1
        let fraction = (meters - cumulativeMeters[start]) / (cumulativeMeters[end] - cumulativeMeters[start])
        let a = points[start], b = points[end]
        return MKMapPoint(x: a.x + fraction * (b.x - a.x), y: a.y + fraction * (b.y - a.y)).coordinate
    }
}

struct RouteReplayView: View {
    private static let route = ReplayRoute()
    @State private var meters = 0.0
    @State private var playing = false

    @State private var camera: MapCameraPosition = .automatic
    @State private var pin: CLLocationCoordinate2D?

    var body: some View {
        if let route = Self.route {
            MapReader { proxy in
                Map(position: $camera) {
                    MapPolyline(route.line).stroke(.white, lineWidth: 9)
                    MapPolyline(route.line).stroke(.blue, lineWidth: 5)
                    Marker("Boyd Hall", systemImage: "building.2", coordinate: route.points[0].coordinate)
                        .tint(.teal)
                    Marker("Library", systemImage: "books.vertical.fill", coordinate: route.coordinate(at: route.length))
                        .tint(.indigo)
                    Annotation("Walker", coordinate: route.coordinate(at: meters)) {
                        Image(systemName: "figure.walk.circle.fill")
                            .font(.title).foregroundStyle(.white, .blue)
                            .shadow(radius: 2)
                    }
                    .annotationTitles(.hidden)
                    if let pin { Marker("Dropped pin", coordinate: pin).tint(.red) }
                }
                .mapStyle(.standard(elevation: .flat, emphasis: .muted))
                .onTapGesture { point in
                    pin = proxy.convert(point, from: .local)
                }
                .onAppear { frameRoute(route) }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(alignment: .trailing, spacing: 10) {
                        Button {
                            withAnimation { frameRoute(route) }
                        } label: {
                            Image(systemName: "scope").frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .background(.regularMaterial, in: Circle())
                        .accessibilityLabel("Show entire route")
                        routeCard(route)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                }
            }
            .task(id: playing) {
                guard playing else { return }
                while meters < route.length {
                    do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                    meters = min(route.length, meters + 0.7)
                }
                playing = false
            }
            .onDisappear { playing = false }
        } else {
            ContentUnavailableView("Route unavailable", systemImage: "map")
        }
    }

    private func frameRoute(_ route: ReplayRoute) {
        let bounds = route.line.boundingMapRect
        camera = .rect(bounds.insetBy(dx: -bounds.width * 0.35, dy: -bounds.height * 0.45))
    }

    private func routeCard(_ route: ReplayRoute) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let pin {
                HStack {
                    Label("Dropped pin", systemImage: "mappin")
                    Spacer()
                    Button("Clear") { self.pin = nil }
                }
                Text(String(format: "%.6f, %.6f", pin.latitude, pin.longitude))
                    .font(.subheadline.monospacedDigit())
                Divider()
            }
            Label("Simulated campus walk", systemImage: "figure.walk")
                .font(.subheadline).foregroundStyle(.secondary)
            Text("Boyd Hall to the library").font(.title2.bold())
            Text(meters >= route.length ? "Arrived at the library" : "\(Int(route.length - meters)) m remaining")
                .font(.subheadline.monospacedDigit())
            ProgressView(value: meters, total: route.length)
            HStack {
                Button {
                    if meters >= route.length { meters = 0 }
                    playing.toggle()
                } label: {
                    Label(playing ? "Pause" : meters == 0 ? "Start walk" : "Play", systemImage: playing ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Button { meters = 0; playing = true } label: { Image(systemName: "arrow.counterclockwise") }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Restart walk")
            }
            .controlSize(.large)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }
}
