import Foundation

/// Accept the internal JSON format and a GeoJSON FeatureCollection with the same documented attributes.
/// Geometry is standard GeoJSON; graph metadata is a foreign member named `campusGraph`.
enum GraphFileFormat {
    static func decode(_ data: Data) throws -> CampusGraph {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            root["type"] as? String == "FeatureCollection"
        else {
            return try JSONDecoder().decode(CampusGraph.self, from: data)
        }
        guard var metadata = root["campusGraph"] as? [String: Any],
            let features = root["features"] as? [[String: Any]]
        else {
            throw GraphLoadError.invalid("GeoJSON needs campusGraph metadata and features.")
        }
        var nodes: [[String: Any]] = []
        var edges: [[String: Any]] = []
        for feature in features {
            guard var properties = feature["properties"] as? [String: Any],
                let geometry = feature["geometry"] as? [String: Any]
            else {
                throw GraphLoadError.invalid("Every graph feature needs properties and geometry.")
            }
            if geometry["type"] as? String == "Point", let c = geometry["coordinates"] as? [Double], c.count == 2 {
                properties["coordinate"] = ["longitude": c[0], "latitude": c[1]]
                nodes.append(properties)
            } else if geometry["type"] as? String == "LineString", let c = geometry["coordinates"] as? [[Double]],
                c.allSatisfy({ $0.count == 2 })
            {
                properties["geometry"] = c.map { ["longitude": $0[0], "latitude": $0[1]] }
                edges.append(properties)
            } else {
                throw GraphLoadError.invalid("Only Point nodes and LineString edges are supported in a route graph.")
            }
        }
        metadata["nodes"] = nodes
        metadata["edges"] = edges
        return try JSONDecoder().decode(CampusGraph.self, from: JSONSerialization.data(withJSONObject: metadata))
    }
}
