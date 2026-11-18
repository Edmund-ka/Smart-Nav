# File guide

For one paragraph about every project file, see [Complete file-by-file guide](/Users/edmundafunyah/Documents/Smart_nav/docs/COMPLETE_FILE_GUIDE.md).

Start with the five files below to understand the new navigation pipeline.

1. `Shared/CampusMap/CampusGraph.swift`: what a campus map contains.
2. `Shared/CampusMap/GraphValidator.swift`: checks that map records agree.
3. `Shared/CampusMap/RoutePlanner.swift`: chooses a permitted route using Dijkstra.
4. `Shared/Guidance/NavigationSession.swift`: turns positions into navigation decisions.
5. `Shared/Guidance/NavigationController.swift`: connects live phone input and screen output.

The projection equation, shortest-path loop, confirmation timing, arrival checks, rerouting guard, recording timestamps and atomic saves have comments beside the relevant code.

## Folder meanings

| Folder | Purpose |
| --- | --- |
| App | Launch and four tabs |
| Appearance | Colors, fonts, backgrounds, buttons |
| Screens | Screen-specific code, including native Navigation |
| Shared/CampusMap | Graph, geometry, validation, routing and map storage |
| Shared/Guidance | Shared session, events, input/output adapters and evaluation |
| Shared/Navigation | Existing synthetic input geometry, turn helper, campus places and deviation detector |
| Resources | Bundled demonstration graph/route, reference recording, photos and fonts |
| Tests | Production-model and importer checks |
| scripts | Reproducible import, validation and check commands |
| data/campus | Raw public source and candidate graph exports |
| ReferenceData/Reports | Unmodified supplied report references and diagrams |
| docs/semester-one | Architecture, measured evaluation, field work and demonstration |

## Swift files

| File | Contains |
| --- | --- |
| [AppTab.swift](../Argus/App/AppTab.swift) | Stable identifiers keep tab selection independent of displayed labels. |
| [AppTabBar.swift](../Argus/App/AppTabBar.swift) | Shared bottom navigation. Home embeds it inside its card; other tabs use a bottom inset. |
| [ArgusApp.swift](../Argus/App/ArgusApp.swift) | Application entry point. Register bundled fonts before any screen is created. |
| [MainTabView.swift](../Argus/App/MainTabView.swift) | Owns shared profile and recording state so switching tabs does not lose a walk. |
| [AppColors.swift](../Argus/Appearance/AppColors.swift) | Colors from the approved sketch. Secondary ink keeps smaller text readable. |
| [AppFonts.swift](../Argus/Appearance/AppFonts.swift) | Registers Poppins once and applies it to native navigation and segmented controls. |
| [GlassBackground.swift](../Argus/Appearance/GlassBackground.swift) | A decorative backing. The controls above it retain their native hit targets and labels. |
| [PrimaryButton.swift](../Argus/Appearance/PrimaryButton.swift) | Gives the main action on every page the same type, shape, and touch target. |
| [CampusMapView.swift](../Argus/Screens/Home/CampusMapView.swift) | MapKit renderer for the selected walking preview. No route is drawn until one is selected. |
| [CurrentLocationService.swift](../Argus/Screens/Home/CurrentLocationService.swift) | Requests a single GPS fix when the user asks; this is separate from walk recording. |
| [HomeGreeting.swift](../Argus/Screens/Home/HomeGreeting.swift) | Uses the phone's local clock. The explicit date/calendar also make time boundaries testable. |
| [HomeView.swift](../Argus/Screens/Home/HomeView.swift) | Composes the map, voice destination controls, and integrated bottom navigation. |
| [PlacePickerView.swift](../Argus/Screens/Home/PlacePickerView.swift) | Touch-based fallback for selecting an origin or destination without speech. |
| [VoiceDestinationInput.swift](../Argus/Screens/Home/VoiceDestinationInput.swift) | One explicit listening session. Cancellation also invalidates pending permission requests. |
| [VoiceDestinationParser.swift](../Argus/Screens/Home/VoiceDestinationParser.swift) | A recognized destination and an optional starting-point change. No GPS or microphone work happens here. |
| [CampusDataView.swift](../Argus/Screens/Navigation/CampusDataView.swift) | Inspect provenance and validation before selecting a dataset. Importing never changes verification flags. |
| [NavigationEventsView.swift](../Argus/Screens/Navigation/NavigationEventsView.swift) | The event log always distinguishes observations from an expected-event comparison. |
| [NavigationView.swift](../Argus/Screens/Navigation/NavigationView.swift) | Native journey screen; live mode is gated by verified data, while demos remain explicitly labeled. |
| [ProfilePhotoStore.swift](../Argus/Screens/Profile/ProfilePhotoStore.swift) | Persists one local profile photo. There is no account or remote upload. |
| [ProfilePhotoView.swift](../Argus/Screens/Profile/ProfilePhotoView.swift) | Reuses the same local profile photo (or silhouette) on Home and Profile. |
| [ProfileView.swift](../Argus/Screens/Profile/ProfileView.swift) | User preferences, photo selection, and expandable explanations live together on this tab. |
| [SavedPlacesAndHelpViews.swift](../Argus/Screens/Profile/SavedPlacesAndHelpViews.swift) | Supporting profile content: saved-place switches and inline help text. |
| [SensorDashboardView.swift](../Argus/Screens/Sensors/SensorDashboardView.swift) | Optional hardware diagnostics. Each card controls one sensor; leaving this screen stops them all. |
| [SensorService.swift](../Argus/Screens/Sensors/SensorService.swift) | On-demand hardware diagnostics. WalkRecorder separately owns sensors used for saved walks. |
| [AccessibilityCheckpoint.swift](../Argus/Screens/Simulation/AccessibilityCheckpoint.swift) | Authored presentation observations, not camera detections. Fractions place approximate markers on the demo line. |
| [CampusPhotoView.swift](../Argus/Screens/Simulation/CampusPhotoView.swift) | Load a bundled image only when its name or description changes, not on every playback tick. |
| [SimulationView.swift](../Argus/Screens/Simulation/SimulationView.swift) | Single-page presentation using scripted positions, not live GPS or obstacle detection. |
| [WalkData.swift](../Argus/Screens/WalkRecording/WalkData.swift) | Codable models define the saved JSON format. Optional fields keep older walks readable. |
| [WalkDetailView.swift](../Argus/Screens/WalkRecording/WalkDetailView.swift) | Reads the latest saved walk by ID so renames and deletions update this screen. |
| [WalkRecorder.swift](../Argus/Screens/WalkRecording/WalkRecorder.swift) | Records real sensor readings and saves explicit user-approved walks on this iPhone. |
| [WalkRecordingView.swift](../Argus/Screens/WalkRecording/WalkRecordingView.swift) | Recording controls and saved walks share the recorder owned by MainTabView. |
| [WalkReplayView.swift](../Argus/Screens/WalkRecording/WalkReplayView.swift) | Replays timestamped raw GPS against the approximate demo route, without rewriting the recording. |
| [CampusGraph.swift](../Argus/Shared/CampusMap/CampusGraph.swift) | Verification describes evidence, not an accessibility score. Imported data is always candidate. |
| [CampusMapStore.swift](../Argus/Shared/CampusMap/CampusMapStore.swift) | Owns the selected map. Invalid imports never replace the last usable graph. |
| [GraphFileFormat.swift](../Argus/Shared/CampusMap/GraphFileFormat.swift) | Accept the internal JSON format and a GeoJSON FeatureCollection with the same documented attributes. |
| [GraphValidator.swift](../Argus/Shared/CampusMap/GraphValidator.swift) | Reject structural corruption before routing; disconnected coverage remains a visible warning. |
| [MapGeometry.swift](../Argus/Shared/CampusMap/MapGeometry.swift) | Geographic storage stays in latitude/longitude; calculations below explicitly use metres. |
| [RoutePlanner.swift](../Argus/Shared/CampusMap/RoutePlanner.swift) | Restrictions remove edges; preference penalties only change the cost of allowed edges. |
| [GuidanceOutput.swift](../Argus/Shared/Guidance/GuidanceOutput.swift) | Reuses SpeechOutput. Events map to documented iOS feedback patterns and respect the user's preference. |
| [LiveLocationProvider.swift](../Argus/Shared/Guidance/LiveLocationProvider.swift) | Hardware adapter only: Core Location callbacks become the same input used by replay. |
| [NavigationCommand.swift](../Argus/Shared/Guidance/NavigationCommand.swift) | A deliberately small command vocabulary. Unrecognized speech never stops or changes a route. |
| [NavigationController.swift](../Argus/Shared/Guidance/NavigationController.swift) | SwiftUI adapter around the pure engine. The controller owns the foreground live-location lifecycle. |
| [NavigationEvaluation.swift](../Argus/Shared/Guidance/NavigationEvaluation.swift) | One-to-one matching prevents one actual event from satisfying multiple expected events. |
| [NavigationEvent.swift](../Argus/Shared/Guidance/NavigationEvent.swift) | Events are data, so speech, haptics, UI, replay, and future wearables can consume the same result. |
| [NavigationSession.swift](../Argus/Shared/Guidance/NavigationSession.swift) | The common state machine for live GPS, synthetic positions, and recorded GPS. |
| [ReplayInputs.swift](../Argus/Shared/Guidance/ReplayInputs.swift) | Input adapters retain sensor timestamps. Playback speed belongs to the screen, not the engine. |
| [RouteInstructions.swift](../Argus/Shared/Guidance/RouteInstructions.swift) | Build direction and mapped-feature instructions once per route, not once per GPS fix. |
| [CampusPlace.swift](../Argus/Shared/Navigation/CampusPlace.swift) | A supported campus destination. Coordinates are reference points, not surveyed entrances. |
| [OffRouteDetector.swift](../Argus/Shared/Navigation/OffRouteDetector.swift) | Detects whether the walker has left or returned to the planned route. |
| [SimulationRoute.swift](../Argus/Shared/Navigation/SimulationRoute.swift) | Stores the route data, calculates distances, and provides walking coordinates. |
| [TurnInstruction.swift](../Argus/Shared/Navigation/TurnInstruction.swift) | Represents a turn along the walking route and determines when to give directions. |
| [SavedPlaces.swift](../Argus/Shared/Preferences/SavedPlaces.swift) | Keeps the existing comma-separated preference format, with exact ID matching. |
| [SpeechOutput.swift](../Argus/Shared/Speech/SpeechOutput.swift) | Gives Home and both replay screens the same speech and VoiceOver behavior. |

## Verification evidence

Start with `docs/semester-one/VERIFICATION_REPORT.md`. The per-fix evidence is `RECORDED_FIX_TRACE.csv`; the map and route audit are `BOYD_LIBRARY_SURVEY.svg` and `CAMPUS_GRAPH_REVIEW.md`. Use `BOYD_LIBRARY_FIELD_CHECKLIST.md` on campus and `IPHONE_TEST_PROCEDURE.md` for device checks. `REMAINING_TASKS.md` orders the unfinished work. `Tests/NavigationVerificationChecks.swift` exercises shared input conversion, cross-mode decisions, matching regressions and production candidate routing; `NavigationInputs.swift` contains only transport conversions.
