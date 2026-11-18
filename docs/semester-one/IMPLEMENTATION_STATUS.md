# Semester-one implementation status

Implemented on branch `codex/semester-one-navigation`, preserving the existing working tree. This is a software milestone, not completion of the field-verified semester-one acceptance gate.

| Phase | Changed files / outcome | Evidence and limits |
| --- | --- | --- |
| 1: Audit and architecture | `BASELINE.md`, `ARCHITECTURE.md`; parsed both supplied TeX reports and nine diagrams | Existing behavior inspected; original reports unchanged. Dedicated branch created. |
| 2: Mapping | `Shared/CampusMap`, `prepare_campus_map.py`, `validate_campus_map.py`, `data/campus`, `CampusDataView` | Candidate OSM download; JSON/GeoJSON validation: zero structural errors, warnings retained. Importer unit checks. No survey claim. |
| 3: Routing | `RoutePlanner.swift`, `NavigationChecks.swift` | Dijkstra, hard exclusions, unknown-data policy, configurable penalties, reverse edges, no-route and synthetic recovery fixtures. Field alternatives absent. |
| 4: Shared engine | `Shared/Guidance`, `SimulationView`, `WalkReplayView` | Normal/missed-turn/noisy scenarios, two turns, departure/rejoin, arrival, 1×/4× equality, stale/bad/out-of-order inputs. Native simulator playback reached arrival; its event/evaluation sheet was visually inspected. |
| 5: Live phone path | `LiveLocationProvider`, `NavigationController`, `NavigationView`, `HomeView`, `GuidanceOutput`, `NavigationCommand` | Core Location adapter, native screen, voice commands, haptics and verification gate compiled. Native route preview visually inspected. No physical-phone or field validation. |
| 6: Evaluation | `NavigationEvaluation`, `NavigationEvaluationChecks`, `WalkData`, `WalkRecorder`, `ReplayInputs`, `NavigationEventsView` | Actual output in `EVALUATION.md`; 245-fix measured replay remains uncertain and misses three manually marked expected events. Graph snapshots preserve new-recording context; legacy data still decodes. |
| 7: Documentation | Chapter 3 alignment, all 88 detailed requirement rows, format/source notes, field checklist, demo script, file guide | No requirements deleted. Proposed report changes separated from implementation and original documents. |

## Post-implementation verification status

| Area | Revised status | Evidence / remaining boundary |
| --- | --- | --- |
| Measured-walk diagnosis | Complete software investigation; field failure remains | `VERIFICATION_REPORT.md` and `RECORDED_FIX_TRACE.csv`: 79 poor-accuracy fixes, 166 uncertain route matches; no trusted progress; each missing event explained numerically. Thresholds unchanged. |
| Evaluation correctness | Matcher defect fixed and regression-tested | Valid later matches are reserved before outside-window classification; overlapping/inclusive one-to-one checks pass. This did not cause the measured-walk failures. |
| Input consistency | Shared production conversion and model decision parity tested | `NavigationInputs`, `NavigationVerificationChecks`: stable ordering, raw coordinate/accuracy/time preservation, three-source decisions, outliers, poor accuracy, departure/rerouting, live delay/silence. Real callback/audio/UI integration remains device work. |
| Recording batches | Unsorted-batch sample loss fixed | Recorder and live adapter share stable timestamp ordering. The already ordered reference recording is unchanged. |
| Candidate graph | Topology audited; no verification promoted | 36 weak components, 11 isolated nodes; nearest Boyd/library candidates linked by existing 37-edge / 209.5 m path, confirmed by production planner. Entrance gaps are unverified. Map/checklist provided. |
| Physical readiness | Procedure prepared; no physical run claimed | Signed install and stationary checks needed; live campus guidance blocked by missing surveyed route. Exact live replay additionally needs selected route/preferences and callback/timer history. |
| Chapter 3 | All eight subsystems and overall diagram reviewed | Component/file/data-flow/algorithm/test/limitation table added in `../CHAPTER3_ALIGNMENT.md`; original professor documents preserved. |
| Final checks | Model/import checks, validators, lint and both builds passed | See `VERIFICATION_CHECKS.md`. JSON/GeoJSON each retain 13 warnings. No physical speech/haptic, permission or field pass is inferred. |

## Verification boundaries

The model tests pass while the bundled field recording remains a documented negative result: 0 matched / 3 missing. “Accepted fix” does not mean trusted progress; every accepted fix fails the 8 m route-match uncertainty allowance. Independent geometry and device measurements must precede threshold calibration. Scripted obstacle cues remain authored examples.

The iPhone simulator was previously opened in Device Hub; this pass compiles the existing UI without changing its layout. Neither simulator observation nor an unsigned generic iPhone build establishes physical-device or VoiceOver usability. See `IPHONE_TEST_PROCEDURE.md` for explicit PASS/FAIL/NOT RUN steps.

## Remaining semester-one work requiring campus/device access

- Advisor-approved 3–5 routes and independently checked entrances/attributes; at least one complete verified route before live demonstration.
- Surveyed connected alternatives for actual rerouting; no invented connectors.
- Independent field evaluation and evidence-based calibration of uncertainty, departure/rejoin, turn lead and arrival thresholds; retain held-out recordings.
- Physical iPhone speech, haptics, permissions, interruptions, recording lifecycle, battery and accessibility testing.
- Supervised intended-user trials, independent position reference, and independent build/install handoff.

## Remaining software limitations

- Rerouting starts only from a uniquely matched verified node. Partial-edge routing and stronger travel-heading estimation are not implemented.
- Voice destination aliases remain Boyd Hall/library; searchable touch destinations expand with imported graph place IDs. Voice-start and a complete voice-only journey remain open.
- Exact live replay does not yet preserve selected route preferences/edge sequence, callback timing, timer ticks or interruptions.
- New recording context defaults to the Boyd/library reference when those entrance IDs exist; arbitrary route selection for recording remains open.
- Map warnings currently cover verified stairs and crossings. Full entrance descriptions, width-specific constraints and other survey attributes need richer guidance rules.
- Native navigation ends when leaving its screen or when the app becomes inactive. Recording remains foreground-only. Basemap and recognition may require network.
- No video recording/replay, motion fusion, landmark recognition, glasses SDK or Watch app is claimed.

## Semester two

Confirm Meta hardware/toolkit camera, audio and microphone capabilities; add supported adapters and phone fallback; collect and label landmark data; train/test a model on held-out sessions; integrate Core ML with confidence/location gating; synchronize frames and sensor clocks; evaluate latency, false detections and endurance; optionally implement Watch controls/haptics; complete release evidence and report.

## Subsequent field evidence — November 16 evening

A new 263-fix iPhone recording and five entrance photos are preserved under `ReferenceData/FieldVisits/2026-11-16-boyd-library/`. The walker confirms descending Boyd stairs, two right turns and successful use of the library door actuator. Production replay establishes origin/progress and emits both right turns; after applying the user's direction clarification, 2 events match and arrival remains missing. Raw automatic evaluation still treats unqualified “Turn” marks as unscored. This improves the evidence but does not validate live guidance, survey coordinates or establish a step-free route. See that folder's `README.md` for timing and uncertainty details.
