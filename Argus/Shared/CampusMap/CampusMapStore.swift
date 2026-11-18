import Combine
import Foundation

/// Owns the selected map. Invalid imports never replace the last usable graph.
final class CampusMapStore: ObservableObject {
    @Published private(set) var revision = UUID()
    @Published private(set) var graph: CampusGraph? {
        didSet { revision = UUID() }
    }
    @Published private(set) var error: String?
    private let url = URL.applicationSupportDirectory.appending(path: "campus-map.json")
    init() {
        do {
            graph = try FileManager.default.fileExists(atPath: url.path) ? CampusGraph.load(url) : CampusGraph.homeMap()
            // Upgrade the old supplied demo selection while preserving independently imported campus maps.
            if graph?.id == "boyd-library-demo" { graph = try CampusGraph.homeMap() }
        } catch {
            self.error = error.localizedDescription
            graph = try? CampusGraph.homeMap()
        }
    }
    func importGraph(from source: URL) {
        let access = source.startAccessingSecurityScopedResource()
        defer { if access { source.stopAccessingSecurityScopedResource() } }
        do {
            let candidate = try CampusGraph.load(source)
            let data = try JSONEncoder().encode(candidate)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            graph = candidate
            error = nil
        } catch { self.error = error.localizedDescription }
    }
    func useBundledMap() {
        do {
            let bundled = try CampusGraph.homeMap()
            if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
            graph = bundled
            error = nil
        } catch { self.error = error.localizedDescription }
    }
}
