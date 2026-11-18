# Semester 1 baseline — November 16, 2026

Development branch: `codex/semester-one-navigation`. Existing uncommitted work is preserved.

The four screens, voice parser, MapKit display, local recording, replay, speech output, and sensor tools are reusable. Simulation and recorded replay currently own separate event loops. Home requests Apple Maps routes and opens Apple Maps. There is no graph, Dijkstra planner, common navigation state, or real rerouting. The bundled route is an approximate image trace; the four checkpoints are authored, not detected. There is no verified campus entrance or route dataset. Recording remains foreground-only.

The existing model checks, strict formatting check, whitespace check, and simulator build passed before this work. These checks are not field or accessibility validation.

No Chapter3_Design.tex, report PDF, or companion report diagrams were found in this checkout. Alignment will use the supplied prompt's subsystem list and mark exact report requirement IDs as pending.

Implementation sequence:
1. Define source-aware graph data, a reproducible importer, structural validation, and a survey checklist.
2. Add deterministic Dijkstra routing with explicit unknown-data policy and hard restrictions.
3. Add one timestamp-driven navigation engine and event/evaluation model.
4. Feed simulation, saved recordings, and Core Location through that engine; preserve screens and storage.
5. Add native guidance, dataset inspection/import, conservative rerouting, and explicit Apple Maps fallback.
6. Exercise synthetic failure fixtures and the real reference recording; document measured results separately.
7. Update architecture, requirements alignment, demo instructions, and remaining physical work.

The available files cannot establish a physically verified route. Software will support verified graph data but must not promote existing imagery or downloaded data to verified status.

## Report supplied during implementation

The user subsequently supplied the whole report and revised professor Chapter 3 ZIP. Both TeX files and nine diagrams were parsed and preserved under `ReferenceData/Reports`. The missing-report baseline statement above is historical; exact detailed R1–R13 IDs are now mapped in `docs/REQUIREMENTS_TRACEABILITY.md`. The files are design references, not independent authorization to change scope or edit the report.
