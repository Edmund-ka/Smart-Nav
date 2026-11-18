# TSU candidate map data

Downloaded November 16, 2026 through the public Overpass API. The query is preserved in `tsu.overpassql`; bounding box south/west/north/east is 36.160, -86.837, 36.173, -86.819. This is an acquisition envelope, not an advisor-approved study boundary.

- `osm-source.json`: unchanged OSM response including pedestrian ways, building outlines, entrances, crossings, and supporting nodes.
- `tsu_candidate_graph.json`: internal Argus graph.
- `tsu_candidate_graph.geojson`: standard Point/LineString representation with graph metadata.
- 3,158 graph nodes, 3,323 graph edges; all candidate. The production validator reports zero structural errors, 36 disconnected components, and isolated records. No proximity connections were fabricated.
- Building outlines remain in the raw inventory; they are not converted to walkable edges. Missing ramps, widths, slopes and entrance/access attributes are unknown. No imagery or GPS walk has been promoted to a verified path.

© OpenStreetMap contributors. Source and attribution: https://www.openstreetmap.org/copyright. OSM data and this derived graph are made available under ODbL 1.0: https://opendatacommons.org/licenses/odbl/1-0/. Preserve this notice and source metadata when distributing the data. The iPhone data inspector displays source attribution for imported graphs.

Public TSU map reference: https://www.tnstate.edu/about/campus-map/. The public parking map at https://www.tnstate.edu/contact_us/documents/ParkingMap_2017.pdf is an older reference, not accessibility evidence. No reuse license was established for TSU map artwork; it was not copied into the graph or redistributed here.

The separate bundled Boyd Hall trace came from existing project imagery and is for demonstration. Its source imagery rights have not been independently established; do not treat it as OSM-derived or surveyed.

## Reproduce

```sh
python3 scripts/prepare_campus_map.py --fetch
python3 scripts/prepare_campus_map.py --osm data/campus/osm-source.json
python3 scripts/prepare_campus_map.py --trace
python3 scripts/validate_campus_map.py data/campus/tsu_candidate_graph.geojson
```

The importer uses Python's standard library. Network failure leaves the local trace/import paths usable. Validation uses the same Swift code as the iPhone rather than a separate permissive implementation.
