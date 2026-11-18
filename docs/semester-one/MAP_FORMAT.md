# Campus graph format, version 1

The internal JSON file contains `schemaVersion`, `id`, `name`, `version`, `isDemonstration`, `sources`, `nodes`, and `edges`. GeoJSON contains the metadata in `campusGraph`, nodes as Point features and edges as LineString features; geographic coordinates are `[longitude, latitude]`. Properties otherwise use the names below. Import accepts either format and rejects unknown schema versions.

| Record | Fields | Meaning |
| --- | --- | --- |
| Source | name, url, license, retrieved | Provenance, reuse terms, retrieval timestamp or documented historical source |
| Node | id, name, coordinate | Unique graph ID, readable name, latitude/longitude |
| Node | isEntrance, placeID | Entrance flag; optional stable destination key used by Home. Add new IDs to extend the touch list. Voice destination aliases currently recognize Boyd/library. |
| Node optional | kind, spokenDescription, doorType, openingHours, accessibleEntrance | Survey attributes; absent means unknown. Door type/signage alone does not prove a working opener. |
| Edge | id, from, to, geometry, lengthMeters | Unique ID; exact referenced endpoint IDs; ordered path; positive metre length within 5% or 1 m of calculated geometry |
| Edge | bidirectional | False permits only from → to |
| Edge | stairs, crossing, accessible | Each is yes/no/unknown. Footway does not imply accessible=yes or stairs=no. |
| Edge optional | surface, slopePercent, widthMeters | Observed characteristics; missing stays unknown. Slope is signed percent, width is metres. |
| Edge | restricted, source | Hard exclusion and specific provenance (e.g. OSM way URL) |
| Node/edge | verification | verified, candidate, unknown |
| Node/edge optional | checkedBy, checkedOn | Required nonempty evidence references when verification is verified; the validator cannot authenticate them |

`isDemonstration=true` prevents live guidance even if someone marks an individual feature verified. Preserve the approximate trace as a demo. Create a separate surveyed dataset with its own version and actual observations instead of relabeling the trace.

Unknown access can be allowed for preview by an explicit setting. Avoid-stairs mode requires stairs=no, so unknown stairs do not become a promise of stair-free travel. Live and replacement routes require verified nodes/edges. Disconnected components are warnings because a dataset may contain separate study areas; the planner still returns no route between them.

After correcting a dataset: increment version, run the validator, retain its report, have a second person check the affected route, then import in Profile → Campus map data. Imports write atomically and preserve the current map on errors. The bundled map can be restored without changing saved walk snapshots.
