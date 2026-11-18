# Argus

An iPhone campus-navigation project with voice destination selection, a curated route simulation, real walk recording, a local campus graph planner, and shared navigation/replay. The app uses SwiftUI and Apple MapKit. It has no external package dependencies.

## Start here

Open `Smart_nav.xcodeproj` in Xcode and run the `Smart_nav` scheme. The displayed app name is **Argus**. The project currently targets iOS 26.5 or newer. Running on a physical iPhone requires your normal signing setup.

Home opens a clean campus map. Tap the voice Search control, say a supported destination, review it, and tap Start to review native Argus guidance. The menu offers Apple Maps as an explicit unverified fallback. The menu also offers a destination list. The greeting uses the phone's local hour and reads “Good morning/afternoon/evening, Edmund.”

## Project layout

| Folder | Responsibility |
| --- | --- |
| `Argus/App` | App entry point, shared state ownership, and four-tab navigation |
| `Argus/Appearance` | Colors, Poppins typography, glass surfaces, and primary buttons |
| `Argus/Screens/Home` | Home layout, greeting, microphone input, spoken-place parsing, location, and route preview |
| `Argus/Screens/Simulation` | One-page map/image presentation and playback controls |
| `Argus/Screens/WalkRecording` | Saved-data models, sensor capture, recording controls, walk details, and replay |
| `Argus/Screens/Profile` | Profile photo, preferences, saved places, and explanatory content |
| `Argus/Screens/Sensors` | Optional on-demand hardware diagnostics |
| `Argus/Shared` | Spoken output, route calculations, campus places, and saved-place helpers used by multiple features |
| `Argus/Resources` | Bundled route, reference recording, presentation images, and licensed fonts |
| `ReferenceData` | Supporting source material that is not bundled in the app |
| `Tests` | Deterministic checks against the production models |
| `scripts` | Local test runner |
| `docs` | Design, implementation status, and future product plan |

Xcode synchronizes the `Argus` folder, so moving Swift files inside it does not require manual build-phase entries. Bundled resources are loaded by filename; keep filenames unique across the resource folders.

## Checks

```sh
python3 scripts/check_models.py
xcrun swift-format lint --strict --recursive Argus Tests
xcodebuild -quiet build -project Smart_nav.xcodeproj -scheme Smart_nav \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/Argus-build CODE_SIGNING_ALLOWED=NO
```

The tests use actual model files. They do not start sensors, ask for permissions, change preferences, or alter saved recordings. Debug builds accept `--preview-tab home|simulate|record|profile` for simulator inspection.

## Explaining the app

Read [the code walkthrough](docs/CODE_GUIDE.md) for data flow and calculated versus configured behavior. [Implementation status](docs/UI_IMPLEMENTATION.md) separates current features from unverified hardware behavior. [The design specification](docs/TAB_DESIGN.md) describes the approved UI, while [the product plan](docs/PRODUCT_PLAN.md) tracks future work.

Real walk JSON and profile photos stay in the app's Application Support directory. Recording is foreground-only. The simulation route is an approximate screenshot trace; it does not verify accessible entrances, detect obstacles, or establish when a street is safe to cross.

For a plain-language list of source files, see [the file guide](docs/FILE_GUIDE.md).

## Semester-one navigation

Home now plans graph routes with Dijkstra. The native guidance screen supports demonstrations and foreground Core Location guidance on verified datasets. The bundled route is still an approximate demonstration: **no field-verified campus route is supplied**, so live guidance is disabled for it. Simulate and recorded replay use the same navigation engine as live mode.

Start with [the commented-code architecture walkthrough](docs/semester-one/ARCHITECTURE.md), [professor Chapter 3 alignment](docs/CHAPTER3_ALIGNMENT.md), [all 88 detailed requirements](docs/REQUIREMENTS_TRACEABILITY.md), and [the demonstration script](docs/semester-one/DEMONSTRATION.md). See [actual evaluation results](docs/semester-one/EVALUATION.md) and [field work](docs/semester-one/FIELD_VERIFICATION.md).

```sh
python3 scripts/check_models.py --report
python3 -m unittest discover -s Tests -p 'test_*.py'
python3 scripts/validate_campus_map.py data/campus/tsu_candidate_graph.geojson
```

Candidate OSM source and graph exports are in `data/campus`; [source/licensing notes](data/campus/README.md) and [schema](docs/semester-one/MAP_FORMAT.md) explain their limits. Import a checked JSON/GeoJSON dataset through Profile → Campus map data. New recordings preserve optional graph/route context; old recordings remain readable.
