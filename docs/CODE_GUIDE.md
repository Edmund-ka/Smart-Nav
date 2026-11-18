# Current navigation code

The semester-one additions are explained in [ARCHITECTURE.md](semester-one/ARCHITECTURE.md), including the projection equation, Dijkstra loop, quality checks and shared event pipeline. Simulation and recorded replay now both feed `NavigationSession`; their screens only control presentation and input timing. The earlier configured-versus-calculated notes below still describe the synthetic input generator, not a separate live navigation engine.

# Code walkthrough

## How to explain the architecture

“Argus has four tabs. Each feature owns its screen and behavior. Shared helpers handle things needed by multiple screens, such as speaking an instruction. Views describe what to display, models describe the data, and services talk to Apple frameworks or local storage.”

`App/ArgusApp.swift` registers the bundled fonts and creates `MainTabView`. `MainTabView` owns one `ProfilePhotoStore` and one `WalkRecorder`. SwiftUI passes these objects down to screens through the environment. This keeps the same recording session alive when tabs change. The root stops recording when the app goes into the background.

## Home: words to a route

1. `HomeView` lays out the map and bottom card. A small `TimelineView` updates `HomeGreeting` once a minute. Morning is 05:00–11:59, afternoon is 12:00–16:59, and evening covers the remaining hours, using the phone's current time zone.
2. `VoiceDestinationInput` handles permission, audio capture, partial transcription, cancellation, and its 12-second timeout. A session ID prevents an old callback from completing a cancelled request.
3. `VoiceDestinationParser` parses the transcript without touching hardware. It recognizes the supported place names, rejects ambiguity, and distinguishes an omitted origin from an explicit “current location.”
4. `CurrentLocationService` requests a fresh location only when asked. A user-selected origin is a planning point, not a claim about their actual location.
5. `HomeView.calculateRoute` invokes the local Dijkstra planner over `CampusMapStore.graph`. Origin/destination/preferences changes recalculate the route. `CampusMapView` draws its geometry.
6. Start opens `NavigationView`. It runs the common session with synthetic input or foreground live input when the route is verified. Apple Maps is an explicit menu fallback.

`Shared/Speech/SpeechOutput` centralizes speech rate and VoiceOver announcements for Home and both replay screens. The microphone service owns input; the speech helper owns output.

## Simulation: calculated geometry with scripted inputs

`SimulationView` drives a single-page demonstration. `SimulationRoute` loads `Resources/Routes/boyd_to_library.geojson` and calculates distances between its points. The route coordinates were estimated from screenshots, not surveyed.

| Behavior | How it is determined |
| --- | --- |
| Total distance | Calculated by adding segment lengths |
| Walker position | Interpolated between neighboring points at a distance along the route |
| Turn direction | Calculated from the signed angle of consecutive segments |
| Which bends count as turns | Configured minimum angle of 45° |
| Early turn warning | Configured 35 m lead distance |
| Normal movement | Scripted 0.7 m per playback step |
| Missed turn | Scripted 30 m past the first turn and 30 m back |
| Noisy GPS case | One scripted sample displaced approximately 50 m |
| Off-route/rejoin decision | Three consecutive samples at least 12 m away / at most 5 m away |
| Presentation photo | Selected by authored route-progress milestones |

`OffRouteDetector` uses different departure and return thresholds to avoid flickering between states. These thresholds are demo settings, not calibrated safety guarantees. Both synthetic and recorded replay reuse the same calculation. Recorded replay processes every raw fix even at faster playback speeds.

The image view compares its name and description before rendering, avoiding repeated file loads for an unchanged presentation scene.

## Recording: capture first, save explicitly

`WalkData.swift` defines the JSON data format independently of the recorder. Optional motion, heading, name, and event fields preserve compatibility with older recordings.

`WalkRecorder` receives GPS and compass callbacks and samples device motion at a configured 10 Hz. Motion timestamps start at phone boot, so the recorder converts them to wall-clock dates to align them with GPS and user marks. Raw coordinates and reported accuracy are retained.

Stopping releases the hardware and backs up the stopped draft. Save writes a complete JSON file atomically before clearing the draft. Discard and Delete require confirmation in the UI. An unexpected termination before stopping can still lose an active recording.

The distance shown for saved walks is an estimate. It sums adjacent GPS segments only when reported accuracy is valid and at most 25 m, timestamps move forward, and implied speed is at most 4 m/s. These are configured filtering rules. They do not change the stored raw readings.

## Profile and sensors

`ProfilePhotoStore` crops a chosen photo to 512 × 512 pixels and stores one local JPEG. `ProfilePhotoView` reuses it on Home and Profile. Preferences use the existing UserDefaults keys; `SavedPlaces` handles exact IDs in the existing comma-separated format.

`SensorService` is a diagnostics service separate from recording. Opening Sensors starts nothing. Each Start action checks hardware availability and avoids duplicate subscriptions. The proximity observer is retained and removed when stopped. Exiting the page or backgrounding stops diagnostics. `SensorDashboardView` has one reusable card layout rather than seven copies.

## Conventions

- Put new feature-specific code beside its feature. Share code only when multiple features actually use it.
- Use descriptive names and short responsibility comments. Explain units, configured constants, cancellation, and persistence decisions near the code.
- Keep colors and fonts in `Appearance`, not repeated in screens.
- Preserve saved JSON field names, preference keys, and resource filenames unless a migration is deliberately implemented.
- Run model checks after changing parsing, route math, or saved-data structures. Build and visually inspect layout changes.
