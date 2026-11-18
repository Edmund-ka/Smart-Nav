# Post-implementation verification

## Result

The bundled measured walk still produces **0 matched, 3 missing, 0 unexpected, 0 outside-window events**. This is an explained negative result, not a passing field trial. No navigation thresholds, reference geometry, marks, or candidate verification flags were changed. UI layout is preserved.

The engine emitted only `started` at 0 s and `uncertain` at 0.284 s. Of 245 fixes, 79 fail the 10 m accuracy limit; the other 166 pass the input filter but **all fail route matching**. “Accepted” therefore means usable for assessment, not confidently on the path. Engine progress remains 0 m throughout.

## Recording and reference

Source: `Argus/Resources/Recordings/BoydWalkSample.json`, UUID `CA7E539D-C2BA-405D-9E32-AAC6BBEA5869`. Start: **2026-11-12 15:30:00.715659 UTC**. Swift JSON dates count seconds since 2001-01-01; no Unix-epoch conversion is applied by the engine. There are 245 strictly increasing readings from +0.284 to +244.284 s, approximately one second apart (0.999988–1.001050 s). No duplicate, reordered, stale, future, or implausible-jump rejection occurs in this replay.

This legacy recording has no graph snapshot or route IDs; replay explicitly falls back to the approximate eight-node Boyd/library demonstration graph. The reference is 201.113 m long. Boyd anchor: 36.1654389, -86.8275056; library anchor: 36.1658583, -86.8283694. These are not surveyed doors.

The first usable fix is at +51.283 s: (36.1652335, -86.8279582), accuracy 9.877 m, projected progress 47.491 m. All earlier fixes fail the accuracy filter. The origin requirement (confident projection within the first 15 m) is consequently never established. This is an additional barrier after route-match uncertainty, not the branch that first rejects those accepted fixes.

## Each failed expectation

Distances below come from the production `MapGeometry.project` and `NavigationSession`; exact per-fix results are in `RECORDED_FIX_TRACE.csv`. Windows are mark time ±10 s, inclusive.

| Expected event / window (seconds from start) | Nearest recorded fix | Actual engine output | Exact mismatch and cause |
| --- | --- | --- | --- |
| Left route → `offRoute`, 103.579 / [93.579, 113.579] | +103.284 s; (36.1651203, -86.8285029); accuracy 5.848 m; cross-track 6.852 m | No departure; state uncertain, progress 0 | Departure uses `max(0, distance − accuracy) ≥ 12 m`. At the mark this is 1.004 m; maximum in the window is 9.391 m. Across the **entire recording** the maximum is 11.675 m. No fix qualifies, so three qualifying confirmations cannot accumulate. The human mark does not establish 12 m of GPS-supported departure from this approximate line. |
| Rejoined route → `rejoined`, 135.584 / [125.584, 145.584] | +135.284 s; (36.1651868, -86.8285415); accuracy 6.835 m; cross-track 3.903 m | No rejoin; state uncertain, progress 0 | No prior confirmed departure exists. Independently, rejoin requires `distance + accuracy ≤ 5 m`; this is 10.737 m at the mark and at least 10.365 m in its window. Thus widening the matching window cannot repair the event. |
| Arrived → `arrived`, 239.886 / [229.886, 249.886] | +240.284 s; (36.1659079, -86.8283725); accuracy 7.936 m; endpoint distance 5.527 m | No arrival; state uncertain, progress 0 | Endpoint distance + accuracy is 13.463 m at the mark, minimum 12.546 m in the available window, above the 5 m radius. Accuracy alone is 7.706–8.278 m in this window. Origin/progress were never established, and no qualifying arrival streak exists. Data ends at +244.284 s, before the window ends; available fixes still decisively fail the conditions. |

Two additional marks say only “Turn” (+129.793 and +198.538 s). They are intentionally excluded from left/right event expectations because direction and decision-point identity are absent. At the second turn the nearest fix has 11.291 m accuracy and is rejected. Future annotations must record direction, location, observed crossing time and marking delay.

## Why progress is uncertain

Let `d` be perpendicular distance to the finite route polyline and `a` the reported horizontal accuracy. The matching rule requires `d + a ≤ 8 m`. The best value in this recording is **8.825 m**, so not one fix reaches the following/progress/turn/arrival branch. Accepted-fix projected progress runs from 47.491 to 201.113 m, but these are geometric projections, not trusted journey progress.

The minimum reported accuracy anywhere is 5.594 m. Under the current `endpointDistance + accuracy ≤ 5 m` arrival rule, **no fix in this recording could confirm arrival even exactly at the endpoint**. This is an operational limitation of the present conservative configuration, not evidence that the user failed to reach the building. Reported accuracy is treated as an uncertainty allowance; it is not a guaranteed physical error bound.

Arrival additionally needs remaining distance ≤5 m, three fixes over ≥2 seconds, a confirmed origin, and no intervening uncertainty. Departure/rejoin confirmations are spaced at least one second apart; approximately one-second readings can require an extra callback because of timestamp jitter. That timing detail is not causal here: no departure or rejoin candidate qualifies at all.

The reference-line/door accuracy, actual pedestrian path and annotation delay remain unverified. The trace alone cannot separate GPS bias from map error. Survey both entrances and junctions independently, record a fresh stationary origin acquisition and endpoint dwell, and compare repeated walks against that surveyed geometry before deciding whether thresholds should change. Do not move the route onto this one GPS trace to improve its score.

## Supported fixes

1. **Event matcher:** Previously, a missed early expectation could consume a later valid event as “outside window.” Matching now reserves valid one-to-one matches first, ordered by deadline, then classifies remaining events. Regressions cover later matches, overlapping windows and inclusive boundaries. This defect did **not** cause the three bundled misses: none of their event kinds was emitted.
2. **Batch ordering:** The recorder previously iterated Core Location batches in supplied order and rejected a lower timestamp after a higher one. Live conversion and recording now share stable timestamp ordering, preventing valid samples in an unsorted batch from being silently discarded. Equal-time samples preserve their original order. This does **not** change the already ordered bundled recording.
3. **Observability:** Added a read-only last-fix decision label and a production-engine CSV trace. No filtering or matching thresholds were loosened.

## Navigation mode consistency

| Path | Production data flow | Clock / intentional differences |
| --- | --- | --- |
| Simulation tab | `SimulationRoute.sample` → `NavigationInputs.simulated` → `NavigationSession.receive` | Synthetic time advances by 0.5 s; playback delay and checkpoint pauses do not change sensor time. Authored `demonstration` events are simulation-only. |
| Native route demonstration | Route interpolation → `NavigationInputs.simulated` → `NavigationController.receive` → same session | Synthetic clock; uses selected route/preferences. |
| Recorded replay | `WalkData` → `ReplayInputs.positions` → `NavigationInputs.recording` → same session | Sorted original sensor times; `now = sample.time`; playback batches do not skip fixes. No live silence timer. |
| Live | Core Location → `NavigationInputs.live` → controller → same session | `now = callback wall time`; foreground freshness timer; verified-route gate; permission failures explicitly mark uncertainty. |

Automated checks exercise actual adapter conversion (coordinates, accuracy, timestamps, stable duplicate ordering) and compare decision kinds, times, progress, next-decision distances and counts across all three sources on the same synthetic verified fixture. Outlier and poor-accuracy samples are included; a separate detour fixture confirms departure and verified-junction rerouting parity. Started/arrival wording intentionally identifies the mode. Live fixes delivered 11 s late are rejected; silence past 10 s causes uncertainty. Replay cannot reconstruct these differences because old recordings contain sensor times, not callback-delivery times, permission changes or live timer ticks.

Equivalence requires the **same route, preferences, settings and evaluation clock**, not just equal coordinates. New walk snapshots preserve the graph/endpoints but not selected edge sequence, route preferences or callback timing. Recordings currently target Boyd/library. Exact reproduction of arbitrary live journeys remains an instrumentation task before claiming live/replay equivalence in field trials. Tests do not exercise real sensor delivery, audio hardware, or UI lifecycle.

## Campus graph and device readiness

The graph review finds 36 weak components, including 11 isolated nodes. The largest contains 2,949 nodes/3,142 edges. Nearest candidates to the approximate Boyd/library anchors are in this component, with a 37-edge, 209.5 m permitted candidate path. The endpoint gaps are 2.56 m and approximately 5.00 m; no connectors were created. See `CAMPUS_GRAPH_REVIEW.md`, `BOYD_LIBRARY_SURVEY.svg` and `BOYD_LIBRARY_FIELD_CHECKLIST.md`.

**Ready for supervised data collection and stationary output checks after a signed device install; not yet cleared for live campus guidance.** No surveyed live route or tested physical device is established. See `IPHONE_TEST_PROCEDURE.md` for prerequisites, expected outcomes, stop criteria and evidence capture. A generic unsigned iPhone build is compilation evidence only.

## Reproduction

Run from the repository root:

```sh
python3 scripts/check_models.py --report
python3 -m unittest discover -s Tests -p 'test_*.py'
python3 scripts/validate_campus_map.py data/campus/tsu_candidate_graph.json data/campus/tsu_candidate_graph.geojson
python3 scripts/inspect_boyd_library.py
xcrun swift-format lint --strict --recursive Argus Tests
```

Build/test outcomes are recorded in `VERIFICATION_CHECKS.md`; Chapter 3 diagram/component corrections are in `../CHAPTER3_ALIGNMENT.md`. Original report sources and graph data remain unchanged.
