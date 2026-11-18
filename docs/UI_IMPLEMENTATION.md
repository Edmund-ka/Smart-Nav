# Semester-one implementation update — November 16, 2026

Current code adds JSON/GeoJSON graph loading, validation, Dijkstra routing, native guidance, a shared timestamp-driven session for live/simulation/replay, structured events, haptic mapping, exact voice commands, recording graph snapshots, and evaluation. Home uses local graph routes; Apple Maps is an explicit fallback. Profile provides dataset inspection/import. Live guidance requires a non-demonstration verified route and entrance.

See [architecture](semester-one/ARCHITECTURE.md), [evaluation](semester-one/EVALUATION.md), [phase evidence](semester-one/IMPLEMENTATION_STATUS.md), and [requirements](REQUIREMENTS_TRACEABILITY.md). No field verification or new physical-phone trial is claimed. The historical cleanup notes below describe the previous revision.

# Implementation and verification

## Previous revision behavior

- Home follows the approved sketch with a local-time greeting above “Where to?”, voice-only Search, selected-origin dropdown, profile shortcut, notifications, and tabs inside the bottom card. MapKit walking previews support Boyd Hall and TSU Library; Start opens Apple Maps for guidance.
- Simulate is one page with three authored scenarios, map/image switching, staged photos, playback speed, turn cues, and off-route/rejoin events. It uses scripted positions and approximate route geometry.
- Record uses one shared recorder across tabs. Real fixes retain coordinates and reported accuracy; optional heading, motion, and event marks are stored alongside them. Stopped drafts can be recovered. Users explicitly save, discard, rename, export, replay, or delete recordings.
- Profile saves its photo locally and exposes speech rate, haptics, saved places, diagnostics, and explanatory sections. Sensors are on-demand and stop on screen exit/backgrounding.

## Cleanup delivered

Code is grouped into App, Appearance, screen folders, and shared helpers. Models are separated from sensor capture and UI. All Swift source files have explanatory comments, and formatting is standardized with `.swift-format`.

Removed the unused MapLibre wrapper, style, package dependency, and lockfile; removed a superseded invented route and four byte-identical duplicate screenshots (about 28 MB). The unique original starting-point screenshot remains in `ReferenceData` because the route metadata cites it. Resources have one canonical location under `Argus/Resources`.

Repeated speech output, saved-place parsing, and sensor-card layouts now have shared implementations. Sensor starts avoid duplicate subscriptions, and the proximity observer is explicitly removed on stop. Unchanged presentation images skip rerendering during playback. The redundant Simulate wrapper and duplicate background-recording handler are gone. Negative GPS accuracy is excluded from distance estimates, and route positions requested before the route start clamp to the first point.

The saved JSON schema, UserDefaults keys, app identifier, and on-device storage locations are unchanged. Temporary recovery copies of removed source material are outside the project at `/tmp/argus-cleanup-recovery`.

## Verification for the greeting and cleanup revision

- Fresh simulator build passed without external package dependencies.
- Generic physical-iPhone target compiled with signing disabled; no physical-phone installation or hardware test was performed.
- Model checks passed for legacy JSON, name round trips, preserved event marks, empty metrics, plausible movement, GPS jumps, invalid/poor accuracy, and duration bounds.
- Additional model checks passed for greeting boundaries and time zones, exact saved-place IDs, valid/ambiguous/unsupported voice phrases, route endpoints, both turn cues, and the normal/missed-turn/stray-GPS scenarios.
- Formatting lint and `git diff --check` passed.
- Bundle inspection found all ten expected resources exactly once and no obsolete map framework or map style.
- Simulator inspection confirmed the greeting’s placement, tab navigation, presentation image loading and progression, turn text during playback, the 245-fix recorded-walk reference, profile persistence, and all seven diagnostic card controls.

These checks do not establish end-to-end spoken recognition, physical sensor accuracy, audible cue timing, VoiceOver usability with intended users, or a full real-world record/save/delete cycle. Recording remains foreground-only. Unexpected termination before stopping can still lose an active recording. Continuous wake-word input, surveyed accessible routing, obstacle detection, and native live guidance remain future product work.

## Reproduce

See the commands in the root `README.md`. `scripts/check_models.py` compiles the actual model files into a temporary directory and does not activate sensors or change stored user data.
