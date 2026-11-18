# Supervised iPhone test procedure

## Readiness and prerequisites

The software is ready to attempt a signed physical-device install and supervised **data collection/stationary checks**, subject to the build results in `VERIFICATION_CHECKS.md`. A physical iPhone was not operated in this pass. Simulator compilation does not verify GPS, audio or haptics.

Before outdoor live-guidance testing:

1. Install the current build with a valid signing team on the intended iPhone; record build identifier, iOS/device, graph version, settings, tester and observer. Verify launch and saving/export indoors.
2. Complete the Boyd/library survey and import an independently reviewed graph with verified nodes, edges and destination. The bundled demo and OSM candidate data correctly keep live start disabled. Do not flip verification flags to bypass this gate.
3. Run stationary speech/haptic/permission checks below. Resolve crashes, unusable output, unavailable permissions, inability to save data or stale guidance before walking.
4. Agree the course and safe stop points with the supervisor. Use daylight, a sighted observer, normal mobility aids and a route already inspected for hazards. Never rely on Argus to determine crossing safety or obstacle clearance. Stop for uncertain/contradictory guidance, unsafe conditions or participant discomfort.
5. For an exact live/replay comparison, first add or externally capture callback times, selected route/preferences/settings, interruptions and timer events. Current walk JSON does not preserve all of that context. Until then label the result sensor-time replay, not full live reproduction.

The 8 m match and 5 m arrival uncertainty allowances failed the old real recording. Assess their practicality on independent surveyed data before an intended-user navigation trial. Do not relax them to pass this sample.

## Steps and expected observations

| Test | Procedure | Expected / evidence to retain |
| --- | --- | --- |
| GPS permission | Fresh install: start recording, deny access, then allow While Using in Settings and restart. Repeat revocation while stationary. | Clear unavailable/stopped state without crash; no claim of usable location after denial. Note prompt text and timestamps. |
| Accuracy | Test Precise Location on/off, then acquire fixes stationary outdoors before moving. | Poor-accuracy fixes must not advance navigation. Reduced accuracy may leave guidance uncertain; no precise-location-specific prompt is currently implemented. Log reported accuracy and raw points. |
| Speech | Run a stationary route demonstration; test rate, Repeat, “Where am I?”, stop, voice-command microphone permission and an interruption. | Intelligible speech, no unwanted overlap with listening, stop silences speech. Live hardware latency and speech interruption behavior must be observed, not inferred from event timestamps. |
| Haptics | With vibration enabled, exercise left/right turns and warning/arrival events in a controlled demonstration; repeat disabled. | Left: one medium pulse; right: two separated by 220 ms; warning/error/success patterns as documented. Disabled means no pulse. If multiple events share a fix, only the last event chooses haptics. Record what the tester actually distinguishes. |
| Progress/origin | On a surveyed live route, wait at its origin for reliable matching, then walk slowly between independently marked points. Also test starting mid-route while stationary. | Progress updates only with a confident match and established origin. Mid-route start requests origin confirmation rather than claiming completion. Record raw/projection/engine progress and observer position. |
| Turns | Approach each mapped decision point from the correct direction; mark physical turn time and spoken-cue onset independently. | One cue per instruction when remaining distance is 0–35 m, unless uncertainty prevents guidance. Record missed/late/premature cues, direction, observer distance and assistance. |
| Deviation | At an inspected safe area, observer guides a planned detour. Do not step into a road or obstacle to trigger an alert. | Three spaced fixes meeting `d−accuracy ≥12 m` confirm departure. Distance + accuracy ≤5 m confirms rejoin after three spaced fixes. No qualifying evidence means uncertain/no event; document that result. |
| Rerouting | At an independently verified alternate junction, try the approved alternative; separately test a location without a reliable graph connection. | Replan only from a unique verified node within 5 m including uncertainty, using verified connected paths. Otherwise explicit no reliable route. Never expect a straight-line connector. Capture replacement edge IDs and event times. |
| Arrival | Approach the surveyed destination, stop early for a negative check, then dwell at the actual mapped endpoint. | Remaining≤5 m and endpoint distance+accuracy≤5 m over ≥3 fixes and ≥2 s, after origin established. No early arrival; report failure to confirm rather than repeatedly walking to fit GPS drift. |
| Recording | Start Record before the walk, add explicitly documented event labels, stop/save/name/export, relaunch and reopen. | Raw timestamps and marks survive; graph/endpoints present if Boyd/library IDs exist. Current recorder does not record the selected arbitrary journey. Keep screen/app active. |
| Replay | Replay saved walk at 1× and 4× and compare event logs; compare with observer annotations separately. | Same sensor-time decisions at both speeds. Manual “Turn” lacks direction and is not scored as left/right. Save event export and original JSON, not just screenshots. |
| Interruptions | Stationary: lock phone, background app, switch away from guidance, reopen; interrupt audio and permissions. | Native navigation ends on inactive/leaving guidance; recording is foreground-only. Do not assume automatic resume or background recording. Verify stopped/draft behavior and save before restarting. |
| Accessibility | Use VoiceOver for destination, start/stop, repeat, evaluation and saving; test larger text and navigation with observer present. | Controls identifiable and reachable; no essential information available only visually. Record blockers; labels/build success alone do not establish usability. |

The Record tab and guidance screen have separate lifecycles. Starting a recording before entering guidance may collect sensor data while foregrounded; switching out of guidance to add marks stops native guidance. Use an independent observer log during live guidance, then export events **after stopping**. Do not switch tabs to mark turns and assume the original live session continues.

## Trial record and acceptance

For each run save original walk JSON, event export, exact graph file/version, route preferences, build identifier, observer log and issue list. Include completion, time, wrong turns, assistance, uncertainty intervals, departure/recovery latency, arrival outcome, cue timing and any stop reason. Keep sensor timestamp, callback/observer time and audio onset separate.

Outcome per row: PASS / FAIL / NOT RUN, with evidence filename. No physical row is pre-marked passed. Resolve critical failures before progressing from engineering collection to supervised intended-user trials; define acceptance targets with the advisor using independent field data.
