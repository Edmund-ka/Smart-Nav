import SwiftUI
import UniformTypeIdentifiers

/// Inspect provenance and validation before selecting a dataset. Importing never changes verification flags.
struct CampusDataView: View {
    @EnvironmentObject private var maps: CampusMapStore
    @State private var importing = false
    var body: some View {
        List {
            if let graph = maps.graph {
                Section("Current campus map") {
                    Text(graph.name)
                    Text("Version \(graph.version) · \(graph.nodes.count) nodes · \(graph.edges.count) paths")
                    Text(
                        graph.isDemonstration
                            ? "Demonstration only — approximate trace" : "Imported dataset — inspect verification below"
                    )
                    Text("\(graph.edges.filter { $0.verification == .verified }.count) field-verified paths")
                }
                Section("Sources") {
                    ForEach(Array(graph.sources.enumerated()), id: \.offset) { _, source in
                        VStack(alignment: .leading) {
                            Text(source.name)
                            Text(source.license).font(.caption)
                            if let url = URL(string: source.url), url.scheme == "https" {
                                Link("Source and attribution", destination: url)
                            }
                        }
                    }
                }
                Section("Validation") {
                    Text(GraphValidator.validate(graph).summary).font(.caption).textSelection(.enabled)
                }
                Section("Entrances") {
                    ForEach(graph.nodes.filter(\.isEntrance)) { node in
                        Text("\(node.name) · \(node.verification.rawValue)")
                    }
                }
            }
            Section {
                Button("Import campus graph", systemImage: "square.and.arrow.down") { importing = true }
                Button("Use bundled demonstration map") { maps.useBundledMap() }
                Text(
                    "Import a documented Argus JSON or GeoJSON graph. A field checker and date are required for verified records. Import validation checks structure; it cannot prove a survey happened."
                ).font(.caption)
            }
            if let error = maps.error { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle("Campus map data")
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json, .geoJSON], allowsMultipleSelection: false) {
            result in
            if case .success(let urls) = result, let url = urls.first { maps.importGraph(from: url) }
        }
    }
}
