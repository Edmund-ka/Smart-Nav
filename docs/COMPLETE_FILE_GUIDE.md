# Argus — every project file explained

Reviewed November 17, 2026. Each linked filename has one paragraph explaining what it contains, what uses it and why it exists. This inventory covers 161 project files, including this guide. It excludes Git internals, macOS `.DS_Store`, Python bytecode caches and ignored per-user/build output; those are generated local bookkeeping, not project implementation. No app behavior was changed for this documentation task.

The main flow is: `ArgusApp` → `MainTabView` → `HomeView` → `RoutePlanner` → `NavigationView` → `NavigationController` → `NavigationSession`. Live input comes through `LiveLocationProvider`; recording has its own `WalkRecorder`. The Home walked graph and legacy demonstration graph are deliberately different.

Historical notes: several documents describe earlier checkpoints. For the latest Home route behavior, read `HOME_LIVE_GUIDANCE.md` alongside current Swift code. The sensor dashboard supports more hardware streams than the recorder saves, and recorded motion is not currently fused into navigation.

## Project root

### [.gitignore](/Users/edmundafunyah/Documents/Smart_nav/.gitignore)

This tells Git which generated or machine-specific files to ignore, including build products, Xcode user state and macOS metadata. It keeps source history focused on useful project artifacts rather than local caches and personal workspace settings.

### [.swift-format](/Users/edmundafunyah/Documents/Smart_nav/.swift-format)

This configures Swift formatting, including four-space indentation and a 120-character line limit. Formatting tools use it so source files follow the same readable style across edits.

### [README.md](/Users/edmundafunyah/Documents/Smart_nav/README.md)

This is the project’s front door: it explains Argus, the main folders and how to run or inspect the work. It helps a new reader orient themselves before opening code. Detailed behavior and dated evidence belong in the linked technical documents rather than being inferred from this overview alone.

## .claude

### [launch.json](/Users/edmundafunyah/Documents/Smart_nav/.claude/launch.json)

This defines a local presentation-server launch configuration using Python’s HTTP server on port 8765. It is developer-tool configuration for viewing the deck, not part of the iPhone app or evidence that a server is currently running.

## Argus/App

### [AppTab.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/App/AppTab.swift)

This defines the four stable tab identifiers: Home, Simulate, Record and Profile. Navigation uses these values rather than matching visible text, so changing a tab’s displayed name does not break tab selection.

### [AppTabBar.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/App/AppTabBar.swift)

This draws the reusable bottom navigation bar, including the selected tab, accessibility labels and recording-related state. Home embeds it in its bottom card while other screens can position it separately. It keeps navigation appearance and behavior consistent.

### [ArgusApp.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/App/ArgusApp.swift)

This is the iPhone app’s entry point. It sets up the application scene and shared appearance before showing the main interface. It exists so startup responsibilities have one clear home instead of being repeated inside individual screens.

### [MainTabView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/App/MainTabView.swift)

This builds the four-tab application and owns shared profile, map and walk-recorder objects. It passes those objects to screens and stops recording when the app enters the background. Keeping these objects above the tabs lets screens share state without creating separate recordings or map selections.

## Argus/Appearance

### [AppColors.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Appearance/AppColors.swift)

This defines the shared pale-blue, navy, secondary-text and pink colors. Screens reference these named colors rather than repeating numeric color values, making the visual design consistent and easier to change.

### [AppFonts.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Appearance/AppFonts.swift)

This registers the bundled Poppins fonts and provides font helpers for SwiftUI and native controls, including text scaling. It makes typography available offline and keeps headings, buttons and body text consistent across screens.

### [GlassBackground.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Appearance/GlassBackground.swift)

This provides the rounded glass-style background used behind cards and lists, with adjustments for reduced transparency and increased contrast. It separates decorative styling from the controls placed over it, allowing the same appearance to be reused without duplicating layout code.

### [PrimaryButton.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Appearance/PrimaryButton.swift)

This defines the prominent rounded action button used for actions such as starting navigation or recording. It accepts a title, icon and action closure. Sharing one component keeps main actions visually consistent and gives them a predictable touch target.

## Argus/Assets.xcassets

### [Contents.json](/Users/edmundafunyah/Documents/Smart_nav/Argus/Assets.xcassets/Contents.json)

This is the root metadata for the Xcode asset catalog. It identifies the catalog’s format and authoring tool so Xcode can process its contained color and icon sets. It holds no route or sensor data.

## Argus/Assets.xcassets/AccentColor.colorset

### [Contents.json](/Users/edmundafunyah/Documents/Smart_nav/Argus/Assets.xcassets/AccentColor.colorset/Contents.json)

This asset-catalog entry defines the named accent color available to the app and system controls. Xcode compiles it as a resource. It complements the explicit AppColors palette so controls using the catalog accent can follow the app’s appearance.

## Argus/Assets.xcassets/AppIcon.appiconset

### [Contents.json](/Users/edmundafunyah/Documents/Smart_nav/Argus/Assets.xcassets/AppIcon.appiconset/Contents.json)

This asset-catalog manifest declares app-icon slots for supported appearance variants. It currently describes slots rather than referencing actual icon image files. Xcode reads it during asset compilation, so it is configuration for the app icon rather than an icon drawing or Swift code.

## Argus/Resources/CampusData

### [boyd_library_graph.geojson](/Users/edmundafunyah/Documents/Smart_nav/Argus/Resources/CampusData/boyd_library_graph.geojson)

This represents the original demonstration graph as GeoJSON Point nodes and LineString edges with graph metadata. It supports format compatibility checks and inspection in geographic tools. It is the alternate representation of the old demo graph, not the current walked-route Home dataset.

### [boyd_library_graph.json](/Users/edmundafunyah/Documents/Smart_nav/Argus/Resources/CampusData/boyd_library_graph.json)

This is the original eight-node, seven-edge demonstration graph in the app’s internal format. Legacy replay and model checks use it as their known reference. Keeping it unchanged preserves the meaning of older recordings and test results instead of silently substituting the updated Home route.

### [boyd_library_walked.json](/Users/edmundafunyah/Documents/Smart_nav/Argus/Resources/CampusData/boyd_library_walked.json)

This is Home’s updated Boyd-to-library graph, with eight nodes, seven edges, a stair-containing first segment and a library endpoint estimated from the confirmed door dwell. It includes an explicit user walk review authorizing this exact route for live input. It preserves the distinction between user-confirmed travel and independently surveyed coordinates.

## Argus/Resources/CampusPhotos

### [boyd-overview.png](/Users/edmundafunyah/Documents/Smart_nav/Argus/Resources/CampusPhotos/boyd-overview.png)

This image shows the Boyd area overview and supplies visual context for campus-route demonstrations. It is bundled for offline display by the photo view and retains its source attribution. It helps explain the approximate route but does not independently verify walkability or precise entrance coordinates.

### [library-pin.png](/Users/edmundafunyah/Documents/Smart_nav/Argus/Resources/CampusPhotos/library-pin.png)

This image shows the original library reference pin and supplies visual context for campus-route demonstrations. It is bundled for offline display by the photo view and retains its source attribution. It helps explain the approximate route but does not independently verify walkability or precise entrance coordinates.

### [route-oblique.png](/Users/edmundafunyah/Documents/Smart_nav/Argus/Resources/CampusPhotos/route-oblique.png)

This image shows an oblique view of the reference route and supplies visual context for campus-route demonstrations. It is bundled for offline display by the photo view and retains its source attribution. It helps explain the approximate route but does not independently verify walkability or precise entrance coordinates.

### [route-overhead.png](/Users/edmundafunyah/Documents/Smart_nav/Argus/Resources/CampusPhotos/route-overhead.png)

This image shows an overhead view of the reference route and supplies visual context for campus-route demonstrations. It is bundled for offline display by the photo view and retains its source attribution. It helps explain the approximate route but does not independently verify walkability or precise entrance coordinates.

## Argus/Resources/Fonts

### [OFL.txt](/Users/edmundafunyah/Documents/Smart_nav/Argus/Resources/Fonts/OFL.txt)

This contains the font’s Open Font License text. It accompanies the bundled Poppins files to preserve their licensing terms and attribution requirements. It is retained with the font resources rather than used by the routing engine.

### [Poppins-Bold.ttf](/Users/edmundafunyah/Documents/Smart_nav/Argus/Resources/Fonts/Poppins-Bold.ttf)

This is the Poppins Bold font binary used by the iPhone interface. It supplies the actual letter shapes for that weight, allowing consistent typography without downloading fonts at runtime. It is a visual resource rather than executable navigation code.

### [Poppins-Regular.ttf](/Users/edmundafunyah/Documents/Smart_nav/Argus/Resources/Fonts/Poppins-Regular.ttf)

This is the Poppins Regular font binary used by the iPhone interface. It supplies the actual letter shapes for that weight, allowing consistent typography without downloading fonts at runtime. It is a visual resource rather than executable navigation code.

### [Poppins-SemiBold.ttf](/Users/edmundafunyah/Documents/Smart_nav/Argus/Resources/Fonts/Poppins-SemiBold.ttf)

This is the Poppins SemiBold font binary used by the iPhone interface. It supplies the actual letter shapes for that weight, allowing consistent typography without downloading fonts at runtime. It is a visual resource rather than executable navigation code.

## Argus/Resources/Recordings

### [BoydWalkSample.json](/Users/edmundafunyah/Documents/Smart_nav/Argus/Resources/Recordings/BoydWalkSample.json)

This is the older bundled real-walk sample with sensor readings and manual event marks. The app offers it for replay and tests use it to investigate the original navigation failures. It is preserved evidence, so its uncertainty and missed events are retained rather than edited away.

## Argus/Resources/Routes

### [boyd_to_library.geojson](/Users/edmundafunyah/Documents/Smart_nav/Argus/Resources/Routes/boyd_to_library.geojson)

This contains the original approximate Boyd-to-library line and its source metadata in GeoJSON. The legacy simulation route loader uses it to generate repeatable positions and turns. It remains separate from the newer graph and corrected Home endpoint so earlier demonstrations and evaluations stay reproducible.

## Argus/Screens/Home

### [CampusMapView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Home/CampusMapView.swift)

This renders Home’s route preview using Apple MapKit, supplied coordinates and place markers. It does not calculate the route or decide whether a GPS fix is reliable. Keeping map drawing separate lets Home change routing logic without rewriting its visual map component.

### [CurrentLocationService.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Home/CurrentLocationService.swift)

This requests a location fix when Home needs the current starting position, handles authorization and publishes the result or an explanatory status. It is separate from continuous navigation and walk recording so previewing a route does not automatically start a recording or a live journey.

### [HomeGreeting.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Home/HomeGreeting.swift)

This chooses the greeting from the phone’s local time, using an injectable date and calendar. It keeps time-of-day rules outside the screen and makes morning, afternoon, evening and time-zone behavior easy to test.

### [HomeView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Home/HomeView.swift)

This assembles the Home map, origin/destination controls, voice input, route preferences and Start action. It resolves places against the selected graph, calculates an Argus route and opens the guidance screen; Apple Maps is an explicit fallback. It is the main coordinator for choosing a journey, rather than the implementation of the routing algorithm itself.

### [PlacePickerView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Home/PlacePickerView.swift)

This displays a searchable touch-based origin or destination picker, using entrances from the selected graph and supported fallback places. It gives users a way to select a place without speech and lets imported graphs supply additional destinations without new screen code.

### [VoiceDestinationInput.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Home/VoiceDestinationInput.swift)

This manages a user-initiated microphone and speech-recognition session, including permissions, audio capture, completion and cancellation. It publishes recognized words for other code to interpret. Separating recognition from destination parsing keeps hardware and permission handling out of routing rules.

### [VoiceDestinationParser.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Home/VoiceDestinationParser.swift)

This interprets recognized phrases as a supported destination and optional origin, including current location. It rejects unsupported or ambiguous input rather than silently choosing a route. It contains text interpretation rules, not microphone, GPS or map hardware code.

## Argus/Screens/Navigation

### [CampusDataView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Navigation/CampusDataView.swift)

This is the Profile-accessible map-data inspector and importer. It shows the current graph’s provenance and validation information and lets the user select a local JSON or GeoJSON dataset. It makes map selection explicit and exposes errors without quietly replacing a usable map with invalid data.

### [NavigationEventsView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Navigation/NavigationEventsView.swift)

This displays timestamped navigation events and, when expectations are supplied, their matching results. It also supports sharing the event log. It exists to make the engine’s decisions inspectable instead of relying only on what happened to appear or be spoken during a walk.

### [NavigationView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Navigation/NavigationView.swift)

This displays the selected route and active guidance, including progress, status, repeat/location controls, voice commands and event review. The reviewed Boyd-to-library route offers live GPS guidance and warns about stairs; unreviewed routes can still offer a labeled demonstration. It connects the user interface to the controller while keeping core navigation decisions in the shared engine.

## Argus/Screens/Profile

### [ProfilePhotoStore.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Profile/ProfilePhotoStore.swift)

This loads, updates and persists the local profile image, reporting image errors to the UI. Home and Profile share it so a photo change appears consistently. It exists to keep image decoding and disk storage out of view layout code; it does not upload the photo.

### [ProfilePhotoView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Profile/ProfilePhotoView.swift)

This draws the saved profile image or a fallback silhouette at a requested size. It is reused by Home and Profile, avoiding separate implementations of the same avatar display.

### [ProfileView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Profile/ProfileView.swift)

This assembles the profile photo, local name, speech-rate and vibration preferences, help and supporting tools. Preferences are stored locally rather than through a remote account. It gives users one place to adjust presentation and guidance settings.

### [SavedPlacesAndHelpViews.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Profile/SavedPlacesAndHelpViews.swift)

This contains supporting Profile views for saved-place switches and explanatory information pages. It keeps those smaller reusable sections separate from the main Profile screen so the larger screen remains easier to follow.

## Argus/Screens/Sensors

### [SensorDashboardView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Sensors/SensorDashboardView.swift)

This displays sensor readings in cards and exposes controls for starting and stopping diagnostic streams. It stops them when the screen is left or the app becomes inactive. It exists to inspect phone hardware behavior without mixing that inspection with the saved-walk workflow.

### [SensorService.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Sensors/SensorService.swift)

This manages optional hardware diagnostics for accelerometer, gyroscope, magnetometer, processed device motion, location, barometer and proximity readings. It provides individual start/stop controls and releases sensors when requested. These diagnostic capabilities are broader than what WalkRecorder saves, so their presence does not mean every sensor is recorded or used for navigation.

## Argus/Screens/Simulation

### [AccessibilityCheckpoint.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Simulation/AccessibilityCheckpoint.swift)

This defines the authored stairs, entrance and staged-obstacle checkpoints used by the simulation, including labels, symbols and approximate positions along the route. It provides repeatable presentation cues; it is not camera detection or an independently surveyed obstacle map.

### [CampusPhotoView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Simulation/CampusPhotoView.swift)

This loads a named bundled campus image and presents it with a description, avoiding unnecessary reloads during playback. Simulation uses it to show route context while keeping image loading separate from navigation timing.

### [SimulationView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/Simulation/SimulationView.swift)

This presents the scripted Boyd-to-library scenarios, route display, playback controls, photos and authored checkpoints. Synthetic timestamped positions are sent through the shared navigation engine. It supports repeatable demonstrations and regression investigation without claiming that its movement or obstacle examples came from live sensors.

## Argus/Screens/WalkRecording

### [WalkData.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/WalkRecording/WalkData.swift)

This defines the JSON-compatible structures for GPS fixes, compass readings, motion samples, event marks and complete walks, including optional graph snapshots and route IDs. It also calculates display metrics. These shared structures let saving, viewing, replay and analysis agree on the same format while retaining compatibility with older recordings.

### [WalkDetailView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/WalkRecording/WalkDetailView.swift)

This shows a saved walk’s details, map and associated controls, retrieving the current record by ID so renaming or deletion is reflected. It is the bridge between the saved-walk list and closer inspection, export or replay.

### [WalkRecorder.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/WalkRecording/WalkRecorder.swift)

This starts and stops Core Location and processed Core Motion collection, saves GPS/heading/motion samples and manual marks, and manages drafts and saved JSON files. It also supports naming, deletion and optional graph context. It exists as the single owner of recording hardware and persistence so changing screens does not create competing recorders.

### [WalkRecordingView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/WalkRecording/WalkRecordingView.swift)

This is the Record tab, with start/stop controls, manual event marks, recording metrics, saving and the list of available walks. It uses the shared WalkRecorder rather than owning sensor streams itself. It provides the user-controlled workflow for collecting evidence and accessing earlier recordings.

### [WalkReplayView.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Screens/WalkRecording/WalkReplayView.swift)

This displays and plays back a saved walk, feeding original timestamped GPS samples to the shared engine without skipping samples at faster playback speeds. The session can use a saved graph snapshot, while the screen also retains the legacy reference-map presentation. It exists to investigate recorded behavior without altering the original recording or pretending playback is live input.

## Argus/Shared/CampusMap

### [CampusGraph.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/CampusMap/CampusGraph.swift)

This defines map sources, nodes, edges, verification fields and the graph itself, plus loading helpers and the explicit walked-route review. It distinguishes independently verified routes from a specifically user-reviewed live route and loads the appropriate bundled dataset. It is the data contract used by import, routing, guidance and recording snapshots.

### [CampusMapStore.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/CampusMap/CampusMapStore.swift)

This owns the currently selected map, loads a saved import or the default walked route, validates imports before replacing the selection and publishes changes to screens. It also upgrades the old supplied demo selection for Home. It keeps map persistence and selection consistent across the application.

### [GraphFileFormat.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/CampusMap/GraphFileFormat.swift)

This decodes either the internal graph JSON or a GeoJSON FeatureCollection with graph metadata, Point nodes and LineString edges. It converts both formats into the same CampusGraph structure so routing does not need separate algorithms for each file format.

### [GraphValidator.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/CampusMap/GraphValidator.swift)

This checks graph identifiers, references, coordinates, geometry, lengths, verification metadata and connectivity, returning errors and warnings. Loading and routing use it to reject structurally broken maps. It cannot prove that a sidewalk physically exists or that accessibility claims are true; those need field evidence.

### [MapGeometry.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/CampusMap/MapGeometry.swift)

This provides coordinate validation, haversine distance, route length, interpolation and nearest-point projection onto path segments in metres. Routing, progress estimation and diagnostics reuse these calculations. It prevents different features from implementing conflicting geographic math or treating degrees as metres.

### [RoutePlanner.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/CampusMap/RoutePlanner.swift)

This defines route preferences, edge costs, ordered route steps and Dijkstra’s search. It excludes prohibited paths, applies applicable cost penalties and reconstructs a connected route, with a separate conservative verified-node matching helper for recovery. It supplies the route itself; it does not draw maps or collect GPS.

## Argus/Shared/Guidance

### [GuidanceOutput.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Guidance/GuidanceOutput.swift)

This maps navigation events to spoken messages and iPhone haptics, respects preferences and avoids speaking over active voice input. Same-fix messages are combined and the last event determines the haptic pattern. It keeps output behavior shared across navigation modes rather than embedding it in every screen.

### [LiveLocationProvider.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Guidance/LiveLocationProvider.swift)

This manages Core Location authorization and continuous foreground updates for live guidance, converting callbacks into shared position inputs and reporting unavailable location. It is the hardware input adapter, leaving filtering, route matching and arrival decisions to NavigationSession.

### [NavigationCommand.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Guidance/NavigationCommand.swift)

This recognizes the supported navigation voice commands, such as repeat, current location and stop, using deliberately limited text rules. It separates command interpretation from microphone capture and avoids treating arbitrary phrases as permission to stop or change a journey.

### [NavigationController.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Guidance/NavigationController.swift)

This adapts the navigation engine to SwiftUI, owns the live location lifecycle, forwards fixes, checks freshness and sends new events to speech/haptics. It separates hardware and screen state from the pure navigation rules so model tests can run without starting sensors.

### [NavigationEvaluation.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Guidance/NavigationEvaluation.swift)

This compares expected events with actual engine events within explicit time windows, using one-to-one matching before classifying remaining events. It reports matches, missing events, unexpected events and timing misses. It exists so evaluation measures recorded behavior rather than giving one actual event credit for several expectations.

### [NavigationEvent.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Guidance/NavigationEvent.swift)

This defines timestamped position inputs, their source labels, structured navigation event kinds and configurable prototype thresholds. It also declares a future landmark-observation contract without implementing recognition. These common types let screens, adapters, output and evaluation exchange consistent data.

### [NavigationInputs.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Guidance/NavigationInputs.swift)

This converts live Core Location batches, recorded readings and synthetic coordinates into NavigationPosition values. It preserves sensor times and accuracy and uses stable ordering for equal timestamps. It exists to prevent subtle input-adapter differences from changing otherwise equivalent navigation decisions.

### [NavigationSession.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Guidance/NavigationSession.swift)

This is the shared navigation state machine used by live GPS, recorded replay and simulation. It evaluates timestamps and accuracy, projects positions, tracks progress, emits turns and uncertainty, confirms departures/rejoins, attempts conservative rerouting and checks arrival. Its explicit clock and structured outputs make the same decisions testable without phone hardware.

### [ReplayInputs.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Guidance/ReplayInputs.swift)

This prepares replay sessions from saved graph/endpoints when present or the legacy demonstration fallback, exposes sorted recorded positions and derives expectations from recognized manual marks. Unqualified Turn marks are not assigned a direction. It keeps replay setup and annotation interpretation consistent across the app and diagnostics.

### [RouteInstructions.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Guidance/RouteInstructions.swift)

This derives turn instructions from changes in route direction and adds supported warnings for verified mapped features. It gives each instruction a position along the route and a stable identity. The navigation session uses those values to decide when to announce it without repeating the cue on every fix.

## Argus/Shared/Navigation

### [CampusPlace.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Navigation/CampusPlace.swift)

This defines named selectable places, their display details and MapKit representations, with Boyd/library defaults and graph-derived entrance choices. It connects UI place selection to graph identities. Its fallback reference coordinates are distinct from the selected graph’s updated entrance coordinates.

### [OffRouteDetector.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Navigation/OffRouteDetector.swift)

This implements the small departure/rejoin confirmation mechanism with separate departure and return distances and consecutive-reading counters. The shared engine adds timing and uncertainty handling around it; older synthetic checks also exercise it directly. Hysteresis prevents a position near one boundary from repeatedly switching status.

### [SimulationRoute.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Navigation/SimulationRoute.swift)

This loads the legacy route line, computes distances and positions along it and creates normal, missed-turn and stray-GPS sample sequences. It is the synthetic input generator used by demonstrations and tests, not the graph route finder or live GPS provider.

### [TurnInstruction.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Navigation/TurnInstruction.swift)

This is the earlier geometric turn-cue helper for the legacy simulation route, including turn detection and a 35 m advance trigger. It remains useful for reference-route behavior and legacy checks. The newer shared engine uses RouteInstructions, so these two similarly named files serve different layers.

## Argus/Shared/Preferences

### [SavedPlaces.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Preferences/SavedPlaces.swift)

This provides small helpers for storing and checking favorite place identifiers. It uses exact identifiers rather than partial text matches, preventing one saved name from accidentally matching another. Profile and destination-related UI use it to share favorite-place behavior.

## Argus/Shared/Speech

### [SpeechOutput.swift](/Users/edmundafunyah/Documents/Smart_nav/Argus/Shared/Speech/SpeechOutput.swift)

This wraps the phone’s text-to-speech and audio-session behavior, including speaking at a selected rate and stopping output. Other components use it rather than directly managing speech synthesis in every view, keeping audio behavior centralized.

## ReferenceData

### [README.md](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/README.md)

This explains where the reference screenshots came from, which copies are bundled, and why the original start-pin image is retained. It documents provenance and cleanup decisions so future edits do not discard unique source evidence or mistake approximate tracing for a survey.

### [start-pin.png](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/start-pin.png)

This preserves the original starting-point map screenshot cited by the traced route’s source metadata. It provides provenance for the initial Boyd reference point and is deliberately outside the app bundle. It is historical mapping evidence, not a new field survey.

## ReferenceData/FieldVisits/2026-11-16-boyd-library

### [9C6FFB3C-2D88-4F64-8704-F2A1EEF0D17D.json](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/9C6FFB3C-2D88-4F64-8704-F2A1EEF0D17D.json)

This is the original newer walk exported from the physical iPhone, with 263 GPS readings, compass/motion samples, two Turn marks, an Arrived mark and its saved graph context. It is used to replay actual observations and compare them with the map. Keeping it unchanged preserves evidence independently of later endpoint corrections.

### [IMG_8816-preview.jpg](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/IMG_8816-preview.jpg)

This is a JPEG viewing copy of IMG_8816.HEIC, showing Boyd entrance overview, including the raised landing and stairs. It makes the evidence easier to open in tools that do not handle HEIC well. The original HEIC remains the preserved source, while this derivative exists only for convenient inspection.

### [IMG_8816.HEIC](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/IMG_8816.HEIC)

This is an original user-supplied field photograph showing Boyd entrance overview, including the raised landing and stairs. It is retained unchanged as visual evidence associated with the November 16 walk. It helps establish visible features and context; precise coordinates, measurements and device functionality require additional evidence or the walker’s explicit observations.

### [IMG_8817-preview.jpg](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/IMG_8817-preview.jpg)

This is a JPEG viewing copy of IMG_8817.HEIC, showing a closer view of Boyd’s entrance stairs and handrails. It makes the evidence easier to open in tools that do not handle HEIC well. The original HEIC remains the preserved source, while this derivative exists only for convenient inspection.

### [IMG_8817.HEIC](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/IMG_8817.HEIC)

This is an original user-supplied field photograph showing a closer view of Boyd’s entrance stairs and handrails. It is retained unchanged as visual evidence associated with the November 16 walk. It helps establish visible features and context; precise coordinates, measurements and device functionality require additional evidence or the walker’s explicit observations.

### [IMG_8818-preview.jpg](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/IMG_8818-preview.jpg)

This is a JPEG viewing copy of IMG_8818.HEIC, showing the view outward from Boyd’s stair landing toward the walkway. It makes the evidence easier to open in tools that do not handle HEIC well. The original HEIC remains the preserved source, while this derivative exists only for convenient inspection.

### [IMG_8818.HEIC](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/IMG_8818.HEIC)

This is an original user-supplied field photograph showing the view outward from Boyd’s stair landing toward the walkway. It is retained unchanged as visual evidence associated with the November 16 walk. It helps establish visible features and context; precise coordinates, measurements and device functionality require additional evidence or the walker’s explicit observations.

### [IMG_8819-preview.jpg](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/IMG_8819-preview.jpg)

This is a JPEG viewing copy of IMG_8819.HEIC, showing the library doors and right-side automatic-door actuator. It makes the evidence easier to open in tools that do not handle HEIC well. The original HEIC remains the preserved source, while this derivative exists only for convenient inspection.

### [IMG_8819.HEIC](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/IMG_8819.HEIC)

This is an original user-supplied field photograph showing the library doors and right-side automatic-door actuator. It is retained unchanged as visual evidence associated with the November 16 walk. It helps establish visible features and context; precise coordinates, measurements and device functionality require additional evidence or the walker’s explicit observations.

### [IMG_8820-preview.jpg](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/IMG_8820-preview.jpg)

This is a JPEG viewing copy of IMG_8820.HEIC, showing a closer view of the library’s automatic-door actuator. It makes the evidence easier to open in tools that do not handle HEIC well. The original HEIC remains the preserved source, while this derivative exists only for convenient inspection.

### [IMG_8820.HEIC](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/IMG_8820.HEIC)

This is an original user-supplied field photograph showing a closer view of the library’s automatic-door actuator. It is retained unchanged as visual evidence associated with the November 16 walk. It helps establish visible features and context; precise coordinates, measurements and device functionality require additional evidence or the walker’s explicit observations.

### [library-entrance-estimate.json](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/library-entrance-estimate.json)

This records the library-coordinate estimate derived from nine fixes after the arrival mark, together with their timing coverage and median reported accuracy. It provides an auditable explanation for the updated Home endpoint instead of choosing a coordinate silently. It explicitly distinguishes a GPS estimate from a surveyed door position.

### [manifest.json](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/manifest.json)

This lists the original evidence filenames, source paths and SHA-256 hashes. It allows later checks that the copied recording and HEIC photos still match the supplied originals, making provenance and accidental modification easier to audit.

### [README.md](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/README.md)

This explains the field visit, indexes the photos, records the walker’s clarification and interprets the newer recording’s replay results. It connects raw evidence to conclusions and identifies what remains uncertain, making the folder understandable without opening every JSON or image first.

### [replay-fixes.csv](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/replay-fixes.csv)

This contains the production engine’s per-fix analysis of the newer walk: timestamps, coordinates, accuracy, route/endpoint distances, decisions, progress, state and events. It makes individual failures traceable and supports the field report. It reflects the evaluated saved reference rather than a guarantee about the subsequently updated live route.

### [replay-results.txt](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/replay-results.txt)

This contains the summarized engine output and event times for the newer walk, including the separately scored user-confirmed right turns. It preserves the concrete result—two matching turns and missing arrival—so a readable report can be checked against actual output.

### [walker-confirmation.json](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/FieldVisits/2026-11-16-boyd-library/walker-confirmation.json)

This stores the user’s explicit confirmations: starting above and descending Boyd stairs, making two right turns and successfully using the library door button. It supplies context absent from generic Turn marks and static photos. It is reported field evidence, not an independent survey.

## ReferenceData/Reports

### [Chapter3_Design.tex](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/Reports/Chapter3_Design.tex)

This preserves the professor’s revised Chapter 3 design source and editorial notes. It organizes the proposed subsystems, figures and suggested explanations/equations. The alignment documents compare it with actual code while leaving the professor’s original source intact.

### [SA_P4_CampusNav.png](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/Reports/SA_P4_CampusNav.png)

This professor-supplied diagram illustrates the overall system architecture and device/data-flow boundaries. It supports the Chapter 3 design discussion and is preserved as a reference image. The alignment guide identifies which boxes or labels match current code and which need changes or remain future work; the image itself does not establish implementation.

### [SeniorProjectReport.tex](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/Reports/SeniorProjectReport.tex)

This is the preserved LaTeX source of the supplied full senior-project report, including requirements and broader project context. It is used to trace implementation back to the academic specification. Original template material and future plans are reference content, not proof that those features are implemented.

### [Sub_CampusMapping.png](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/Reports/Sub_CampusMapping.png)

This professor-supplied diagram illustrates campus map collection, graph creation and field checking. It supports the Chapter 3 design discussion and is preserved as a reference image. The alignment guide identifies which boxes or labels match current code and which need changes or remain future work; the image itself does not establish implementation.

### [Sub_GlassesConnection.png](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/Reports/Sub_GlassesConnection.png)

This professor-supplied diagram illustrates the planned glasses connection, media interfaces and phone fallback. It supports the Chapter 3 design discussion and is preserved as a reference image. The alignment guide identifies which boxes or labels match current code and which need changes or remain future work; the image itself does not establish implementation.

### [Sub_Guidance.png](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/Reports/Sub_Guidance.png)

This professor-supplied diagram illustrates destination controls, guidance timing, speech, haptics and optional watch output. It supports the Chapter 3 design discussion and is preserved as a reference image. The alignment guide identifies which boxes or labels match current code and which need changes or remain future work; the image itself does not establish implementation.

### [Sub_LandmarkRecognition.png](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/Reports/Sub_LandmarkRecognition.png)

This professor-supplied diagram illustrates the proposed camera-frame, model, confidence and landmark-event pipeline. It supports the Chapter 3 design discussion and is preserved as a reference image. The alignment guide identifies which boxes or labels match current code and which need changes or remain future work; the image itself does not establish implementation.

### [Sub_ModelTraining.png](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/Reports/Sub_ModelTraining.png)

This professor-supplied diagram illustrates the proposed landmark labeling, training, evaluation and Core ML conversion pipeline. It supports the Chapter 3 design discussion and is preserved as a reference image. The alignment guide identifies which boxes or labels match current code and which need changes or remain future work; the image itself does not establish implementation.

### [Sub_Positioning.png](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/Reports/Sub_Positioning.png)

This professor-supplied diagram illustrates the proposed sensor processing, map matching and uncertainty pipeline. It supports the Chapter 3 design discussion and is preserved as a reference image. The alignment guide identifies which boxes or labels match current code and which need changes or remain future work; the image itself does not establish implementation.

### [Sub_RoutePlanning.png](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/Reports/Sub_RoutePlanning.png)

This professor-supplied diagram illustrates graph loading, validation, path search, steps and rerouting. It supports the Chapter 3 design discussion and is preserved as a reference image. The alignment guide identifies which boxes or labels match current code and which need changes or remain future work; the image itself does not establish implementation.

### [Sub_TestingReplay.png](/Users/edmundafunyah/Documents/Smart_nav/ReferenceData/Reports/Sub_TestingReplay.png)

This professor-supplied diagram illustrates recording, replay, event comparison, walking trials and accessibility review. It supports the Chapter 3 design discussion and is preserved as a reference image. The alignment guide identifies which boxes or labels match current code and which need changes or remain future work; the image itself does not establish implementation.

## Smart_nav.xcodeproj

### [project.pbxproj](/Users/edmundafunyah/Documents/Smart_nav/Smart_nav.xcodeproj/project.pbxproj)

This is Xcode’s project configuration: it defines build targets, source/resource organization, deployment settings, bundle identity, signing configuration and permission-description strings. Xcode uses it to turn the Swift code and assets into the Argus app; incorrect settings here can prevent otherwise valid code from building or accessing requested capabilities.

## Smart_nav.xcodeproj/project.xcworkspace

### [contents.xcworkspacedata](/Users/edmundafunyah/Documents/Smart_nav/Smart_nav.xcodeproj/project.xcworkspace/contents.xcworkspacedata)

This XML file describes the workspace associated with the Xcode project. Xcode uses it to open the project in its workspace context. It is IDE organization metadata, not navigation behavior.

## Tests

### [ModelChecks.swift](/Users/edmundafunyah/Documents/Smart_nav/Tests/ModelChecks.swift)

This is the command-line test entry point that runs the model suites and additional greeting, saved-place, voice parsing and legacy route checks. It gathers assertions against production code into one executable, allowing useful verification without launching the iPhone interface.

### [NavigationChecks.swift](/Users/edmundafunyah/Documents/Smart_nav/Tests/NavigationChecks.swift)

This tests graph validation, route restrictions, shared navigation, GPS rejection, turn/arrival behavior, verified-junction rerouting and the reviewed Boyd live route gate. It includes checks that stair avoidance rejects the route and that review does not authorize unrelated directions. These checks protect navigation rules from accidental changes.

### [NavigationEvaluationChecks.swift](/Users/edmundafunyah/Documents/Smart_nav/Tests/NavigationEvaluationChecks.swift)

This runs synthetic normal, missed-turn and noisy scenarios, evaluates the bundled measured walk and compares replay batching speeds. It can generate the evaluation report from actual engine output. It exists to keep reported results reproducible and to preserve negative field results rather than hiding them.

### [NavigationVerificationChecks.swift](/Users/edmundafunyah/Documents/Smart_nav/Tests/NavigationVerificationChecks.swift)

This adds per-fix diagnostic output, actual input-adapter checks, cross-source decision comparisons, live delay/silence tests, matcher regressions and a production-planner check of the candidate campus path. It documents why input timing can differ and catches bugs that broad happy-path tests would miss.

### [test_map_import.py](/Users/edmundafunyah/Documents/Smart_nav/Tests/test_map_import.py)

This contains Python unit tests for the campus-map preparation code, including importer topology/direction behavior. It checks map-conversion rules separately from Swift navigation, helping catch data preparation errors before exported graphs reach the app.

### [WalkModelChecks.swift](/Users/edmundafunyah/Documents/Smart_nav/Tests/WalkModelChecks.swift)

This tests recording-model compatibility, JSON round trips, names, event preservation and recording metrics under empty, normal, inaccurate or implausible movement data. It protects saved recordings from format changes and misleading distance calculations.

## data/campus

### [osm-source.json](/Users/edmundafunyah/Documents/Smart_nav/data/campus/osm-source.json)

This preserves the raw downloaded OpenStreetMap response used to prepare the campus candidate graph. It retains source elements and tags before conversion so import decisions can be investigated or reproduced. A source feature being present here does not automatically make it a verified traversable edge.

### [README.md](/Users/edmundafunyah/Documents/Smart_nav/data/campus/README.md)

This documents campus-map provenance, acquisition details, attribution and limitations. It explains how to interpret the candidate exports and why structural validation is different from field verification. It belongs beside the data so source and reuse context travel with the datasets.

### [tsu.overpassql](/Users/edmundafunyah/Documents/Smart_nav/data/campus/tsu.overpassql)

This stores the Overpass query used to request the campus mapping inputs. It documents the acquisition area and requested source features, making the original data request inspectable and repeatable rather than relying on an undocumented download.

### [tsu_candidate_graph.geojson](/Users/edmundafunyah/Documents/Smart_nav/data/campus/tsu_candidate_graph.geojson)

This is the GeoJSON representation of the imported campus candidate network. It lets geographic tools inspect nodes and paths and supports comparison with the internal JSON loader. Its alternate format does not change its candidate status or supply missing physical connections.

### [tsu_candidate_graph.json](/Users/edmundafunyah/Documents/Smart_nav/data/campus/tsu_candidate_graph.json)

This is the imported campus graph in the app’s internal format, containing 3,158 nodes and 3,323 candidate edges. It supports validation, connectivity review and future route preparation. It retains disconnected components and unknown attributes instead of claiming the whole campus is ready for live guidance.

## docs

### [CHAPTER3_ALIGNMENT.md](/Users/edmundafunyah/Documents/Smart_nav/docs/CHAPTER3_ALIGNMENT.md)

This compares the professor’s Chapter 3 design with actual components, data flows, Swift files, equations, tests and limitations. It proposes diagram corrections while preserving original report materials. It exists to support accurate academic explanations without presenting future glasses, recognition or field validation as completed work.

### [CODE_GUIDE.md](/Users/edmundafunyah/Documents/Smart_nav/docs/CODE_GUIDE.md)

This explains how to discuss the code and separates configured demonstration inputs from calculated behavior. It combines newer architecture references with an earlier walkthrough. It helps with presentations and code reading, but dated sections must be read in their historical context.

### [COMPLETE_FILE_GUIDE.md](/Users/edmundafunyah/Documents/Smart_nav/docs/COMPLETE_FILE_GUIDE.md)

This is the complete file-by-file guide you are reading. It explains each project file’s contents, use and reason for existing, grouped by its actual folder. It provides a readable inventory for learning the code and distinguishing app logic, evidence, resources, tests and historical documents.

### [FILE_GUIDE.md](/Users/edmundafunyah/Documents/Smart_nav/docs/FILE_GUIDE.md)

This is the shorter folder guide and suggested reading order for understanding the navigation pipeline. It points readers toward the main models, services and screens before deeper exploration. It remains a quick orientation aid, while the new complete guide gives every file its own paragraph.

### [PRODUCT_PLAN.md](/Users/edmundafunyah/Documents/Smart_nav/docs/PRODUCT_PLAN.md)

This is the historical product and delivery plan covering the intended navigation experience, phases, risks and future work. It records why work was proposed and provides planning context. It is not a current completion checklist, and later implementation/status records supersede its predictions.

### [REQUIREMENTS_TRACEABILITY.md](/Users/edmundafunyah/Documents/Smart_nav/docs/REQUIREMENTS_TRACEABILITY.md)

This maps the report’s detailed requirements to implementation, evidence, limitations and semester scope. It helps identify what code supports each academic requirement and what remains unfinished. Its dated status entries should be read alongside newer field and live-guidance updates.

### [TAB_DESIGN.md](/Users/edmundafunyah/Documents/Smart_nav/docs/TAB_DESIGN.md)

This records the agreed tab layout, visual palette, fonts and accessibility-oriented display decisions. It is used as a design reference when changing UI code. Its purpose is to preserve the user’s chosen direction instead of inventing a different interface during maintenance.

### [UI_IMPLEMENTATION.md](/Users/edmundafunyah/Documents/Smart_nav/docs/UI_IMPLEMENTATION.md)

This records UI implementation milestones and earlier cleanup/verification notes. It explains what changed at those stages and links to broader architecture documents. Some gate descriptions predate the walked-route live update, so it is historical evidence rather than the sole authority for current behavior.

## docs/semester-one

### [ARCHITECTURE.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/ARCHITECTURE.md)

This explains the shared navigation architecture and includes a data-flow diagram and a recommended code-reading order. It connects map preparation, graph search, input adapters, engine decisions and outputs. It helps readers understand how separate files cooperate rather than treating the app as one large screen.

### [BASELINE.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/BASELINE.md)

This records the state before the semester-one architecture work, including features and gaps observed at that time. It exists to explain the starting point and scope of the implementation. Statements such as missing graph routing describe that earlier baseline, not the current application.

### [BOYD_LIBRARY_FIELD_CHECKLIST.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/BOYD_LIBRARY_FIELD_CHECKLIST.md)

This lists concrete locations and attributes to inspect along Boyd-to-library, including stairs, junctions, entrances and supporting measurements. It turns graph uncertainties into field tasks. Later user observations establish stairs and a working door actuator, while the checklist retains the broader survey work still needed.

### [BOYD_LIBRARY_SURVEY.png](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/BOYD_LIBRARY_SURVEY.png)

This is a rendered raster copy of the SVG survey map for convenient viewing and sharing. It shows the same dated comparison rather than new geographic evidence. The vector file remains the more flexible source for resizing and inspection.

### [BOYD_LIBRARY_SURVEY.svg](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/BOYD_LIBRARY_SURVEY.svg)

This is the standalone vector survey map overlaying the candidate paths, original demonstration line and older recording, with annotated manual marks. It supports route/entrance inspection and can be enlarged without raster blur. It is a dated working map, not a current live-position display or surveyed route certificate.

### [CAMPUS_GRAPH_REVIEW.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/CAMPUS_GRAPH_REVIEW.md)

This reports candidate component sizes, nearby Boyd/library nodes, the existing candidate path and unresolved entrance evidence. It is generated by the graph inspection script. Its role is to focus field work without adding assumed connectors or promoting candidate data to verified status.

### [DEMONSTRATION.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/DEMONSTRATION.md)

This is the earlier seven-to-nine-minute professor demonstration script, organizing mapping, routing, guidance and evidence into a presentation sequence. It helps explain the prototype honestly. Some route-availability statements predate the newer walked-route live update, so rehearse it against current code before presenting.

### [EVALUATION.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/EVALUATION.md)

This is generated evidence from production-model runs, including synthetic scenario counts and the older measured recording’s failed expectations. It is used to report what the engine actually produced. Passing synthetic cases does not convert the measured negative result into a successful field trial.

### [FIELD_VERIFICATION.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/FIELD_VERIFICATION.md)

This provides the general campus survey and supervised-trial checklist, including route approval, data collection, independent checking and accessibility review. It is a procedure for obtaining evidence rather than a completed certification. It helps keep physical validation separate from successful software builds.

### [HOME_LIVE_GUIDANCE.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/HOME_LIVE_GUIDANCE.md)

This documents the November 17 Home update: the reviewed route, actual Core Location input, stair cue, endpoint estimate, scoped live permission and unchanged uncertainty rules. It explains why live guidance can now start without relabeling candidate geometry as independently surveyed. It also records that video capture and the next physical walking check remain separate tasks.

### [IMPLEMENTATION_STATUS.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/IMPLEMENTATION_STATUS.md)

This tracks implementation phases, verification evidence, limitations and later field observations. It serves as a status ledger rather than raw test output. Newer changes should also be checked against HOME_LIVE_GUIDANCE.md, since a dated status table can lag the latest code.

### [IPHONE_TEST_PROCEDURE.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/IPHONE_TEST_PROCEDURE.md)

This gives step-by-step physical-phone checks for permissions, accuracy, speech, haptics, progress, turns, deviations, rerouting, arrival and recording/replay. It specifies expected observations and evidence to save. It supports supervised testing without treating a simulator result as proof of hardware behavior.

### [MAP_FORMAT.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/MAP_FORMAT.md)

This describes the internal JSON and GeoJSON graph schema, including node, edge, source and verification fields. It helps people prepare compatible maps and understand imported records. The later walked-route review extension is also explained in the live-guidance update and source model.

### [MAP_VALIDATION.txt](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/MAP_VALIDATION.txt)

This preserves structural graph-validator output, including errors, warnings, disconnected components and verification reminders. It is evidence that map files were checked against the production schema. Structural validity does not establish that their physical paths or accessibility attributes are correct.

### [RECORDED_FIX_TRACE.csv](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/RECORDED_FIX_TRACE.csv)

This is the detailed per-fix production-engine trace for the older bundled recording, including rejection/matching decisions and geometric measurements. The diagnostic report uses it to justify exact causes. It separates a fix accepted for assessment from one trusted enough to update navigation progress.

### [REMAINING_TASKS.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/REMAINING_TASKS.md)

This prioritizes unfinished semester-one work, from field/device evidence to reproducible live trials and report updates. It provides an actionable backlog with completion evidence. Its older prerequisites should be reconciled with the subsequent user-reviewed live-route change rather than read as automatic descriptions of today’s gate.

### [VERIFICATION_CHECKS.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/VERIFICATION_CHECKS.md)

This records the commands and outcomes of the focused verification pass, including model/import checks, map validation, formatting and builds. It provides reproducible evidence for that revision and marks physical testing separately. It should not be interpreted as certifying every later change or real-world usability.

### [VERIFICATION_REPORT.md](/Users/edmundafunyah/Documents/Smart_nav/docs/semester-one/VERIFICATION_REPORT.md)

This explains the original recorded-walk failures using per-event timing, GPS uncertainty, geometry and progress calculations. It also documents supported fixes and cross-mode differences. It exists to distinguish implementation defects from data/calibration limitations without loosening thresholds merely to obtain a pass.

## presentation

### [Argus-Architecture-Deck.html](/Users/edmundafunyah/Documents/Smart_nav/presentation/Argus-Architecture-Deck.html)

This is the generated standalone architecture deck with embedded resources. It can be opened directly or served locally for presentation. It exists as a portable deliverable; the architecture-deck folder contains the editable source, and the slides may describe an earlier implementation revision.

### [data.js](/Users/edmundafunyah/Documents/Smart_nav/presentation/data.js)

This exposes the reference route and sampled recorded coordinates as browser-readable presentation data. Interactive deck visuals use it to illustrate the route and recorded walk. It is a fixed presentation dataset rather than a live GPS feed or the app’s current Home graph.

## presentation/architecture-deck

### [app.js](/Users/edmundafunyah/Documents/Smart_nav/presentation/architecture-deck/app.js)

This implements the deck’s navigation, diagram rendering, subsystem content, staged slide builds and interactive controls. It is browser presentation code, not the iPhone navigation engine. It exists to explain architecture interactively, and its illustrative behavior must not be confused with live app evidence.

### [build.py](/Users/edmundafunyah/Documents/Smart_nav/presentation/architecture-deck/build.py)

This bundles HTML, CSS, JavaScript, fonts and screenshots into one portable HTML presentation, resizing screenshots when supported and checking for remaining external references. It makes the deck convenient to move and present offline. Edit the source files first, then rebuild rather than maintaining divergent copies.

### [index.html](/Users/edmundafunyah/Documents/Smart_nav/presentation/architecture-deck/index.html)

This is the editable HTML source for the architecture presentation’s static slides and document structure. The browser loads its styling, data and interaction code from companion files. It is the place to edit slide markup before rebuilding the portable deck.

### [README.md](/Users/edmundafunyah/Documents/Smart_nav/presentation/architecture-deck/README.md)

This explains how to open, navigate, edit and rebuild the architecture deck, including keyboard shortcuts and source files. It is the presenter/developer operating guide. It keeps deck-specific instructions out of the app’s source documentation.

### [styles.css](/Users/edmundafunyah/Documents/Smart_nav/presentation/architecture-deck/styles.css)

This defines the presentation’s typography, cream/pink styling, layout and visual states. The browser uses it to render the editable deck and the build script embeds it into the portable version. It keeps presentation appearance separate from slide content and interaction logic.

## presentation/assets

### [app-home.png](/Users/edmundafunyah/Documents/Smart_nav/presentation/assets/app-home.png)

This is a captured image of the app’s Home screen used in the architecture presentation. It helps the audience connect the design to an actual interface. It is a static screenshot from its capture revision, not a live view and not guaranteed to show the latest changes.

### [app-record.png](/Users/edmundafunyah/Documents/Smart_nav/presentation/assets/app-record.png)

This is a captured image of the app’s Record screen used in the architecture presentation. It helps the audience connect the design to an actual interface. It is a static screenshot from its capture revision, not a live view and not guaranteed to show the latest changes.

### [app-simulate.png](/Users/edmundafunyah/Documents/Smart_nav/presentation/assets/app-simulate.png)

This is a captured image of the app’s Simulate screen used in the architecture presentation. It helps the audience connect the design to an actual interface. It is a static screenshot from its capture revision, not a live view and not guaranteed to show the latest changes.

### [OFL.txt](/Users/edmundafunyah/Documents/Smart_nav/presentation/assets/OFL.txt)

This contains the font’s Open Font License text. It accompanies the bundled Poppins files to preserve their licensing terms and attribution requirements. It is retained with the font resources rather than used by the routing engine.

### [Poppins-Bold.ttf](/Users/edmundafunyah/Documents/Smart_nav/presentation/assets/Poppins-Bold.ttf)

This is the Poppins Bold font binary used by the browser presentation. It supplies the actual letter shapes for that weight, allowing consistent typography without downloading fonts at runtime. It is a visual resource rather than executable navigation code.

### [Poppins-Regular.ttf](/Users/edmundafunyah/Documents/Smart_nav/presentation/assets/Poppins-Regular.ttf)

This is the Poppins Regular font binary used by the browser presentation. It supplies the actual letter shapes for that weight, allowing consistent typography without downloading fonts at runtime. It is a visual resource rather than executable navigation code.

### [Poppins-SemiBold.ttf](/Users/edmundafunyah/Documents/Smart_nav/presentation/assets/Poppins-SemiBold.ttf)

This is the Poppins SemiBold font binary used by the browser presentation. It supplies the actual letter shapes for that weight, allowing consistent typography without downloading fonts at runtime. It is a visual resource rather than executable navigation code.

## scripts

### [check_models.py](/Users/edmundafunyah/Documents/Smart_nav/scripts/check_models.py)

This compiles the selected production Swift models and test files into a temporary executable, runs it against bundled resources and optionally writes evaluation evidence. It is the convenient repeatable model-test command and keeps compiler caches and binaries out of the source tree.

### [inspect_boyd_library.py](/Users/edmundafunyah/Documents/Smart_nav/scripts/inspect_boyd_library.py)

This audits candidate-graph components and nearby Boyd/library nodes, traces an existing permitted candidate path and produces a local survey map and report. It is read-only with respect to graph data. Its purpose is to guide field inspection and identify missing evidence without automatically adding connections.

### [prepare_campus_map.py](/Users/edmundafunyah/Documents/Smart_nav/scripts/prepare_campus_map.py)

This prepares campus graph data from the preserved trace or OpenStreetMap input, supports acquisition/export and retains source information. It builds connections from actual source topology rather than arbitrary proximity. It exists to turn mapping inputs into reviewable JSON/GeoJSON datasets without inventing field verification.

### [validate_campus_map.py](/Users/edmundafunyah/Documents/Smart_nav/scripts/validate_campus_map.py)

This compiles and invokes the production Swift graph loader and validator on supplied map files. It avoids maintaining a second Python version of validation rules, so command-line checks agree with what the iPhone accepts.
