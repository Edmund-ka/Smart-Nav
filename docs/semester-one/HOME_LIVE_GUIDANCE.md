# Home live guidance — November 17 update

Home now defaults to `boyd_library_walked.json`. The old supplied demo selection is upgraded in memory; other imported maps remain selected. The Simulation tab and legacy replay keep the original demonstration graph and labels.

Choose Boyd Hall → TSU Library → Start → Start live guidance. This starts `LiveLocationProvider` and feeds actual Core Location fixes into `NavigationSession`; no route interpolation or recorded GPS feeds this action. The walked route has no demonstration button on its guidance screen. Other unreviewed maps retain their demonstration behavior.

The walker explicitly confirms repeated traversal, origin above Boyd stairs, descent, two right turns and the photographed library entrance. `walkReview` permits live use only for the reviewed origin/destination and exact ordered edge IDs on the matching graph/version. Candidate coordinate verification flags are preserved: this is a user-reviewed walk, not an independently surveyed map. Reverse routes and unrelated campus paths are not authorized by that review. Verified-only rerouting remains unchanged.

The first segment is marked as containing stairs, without fabricating a stair-bottom coordinate. The approach screen and live start speech warn of stairs and descent. Avoid-stairs planning rejects this route. Other stair statuses remain unknown.

Library endpoint: latitude 36.16598269804493, longitude -86.82840429001145, the coordinate-wise median of nine fixes after the user's arrival mark, covering +4.531 to +32.124 seconds. Median reported accuracy is 5.098 m. The final segment terminates at this estimate and its length is recalculated. Original recording, graph snapshot, photos and old demo geometry remain intact.

Limitations: the endpoint is an observed GPS estimate; intermediate geometry is still approximate. Accuracy/matching/arrival thresholds are unchanged. The strict 5 m arrival allowance can still prevent confirmation when reported uncertainty exceeds it. Enabling real GPS does not establish successful end-to-end field navigation. No video was recorded or labeled as live. The user deferred capture until a future outdoor walk; the phone was unavailable during this update.

Model regressions check live acceptance for this reviewed route, rejection without review and in reverse, pre-start stair speech, and avoid-stairs no-route. Existing model checks and formatting pass. Simulator and generic unsigned iPhone builds are checked separately; a later signed install and physical walking test are still required.

# Home live guidance — November 17 evening update

Guidance now runs on Home instead of a separate screen. Say a destination ("take me to the library"); the route draws on the Home map with distance, time, turn count and route facts. Tap **Start guidance** (or tap the mic and say "start") for live GPS guidance in place. The ▶ button, or Menu → Preview guidance, runs a simulated walk that is labelled **SIMULATED** on screen. Without a spoken or chosen origin, Home starts from the walk-reviewed origin (Boyd Hall) and says how far away you are.

Tracking changes (`NavigationSession`), measured against the November 16 recording (9C6FFB3C):

| | Before | After |
| --- | ---: | ---: |
| Fixes used for guidance | 38 of 263 | 220 of 263 |
| "Uncertain / guidance paused" announcements | 4 | 0 |
| Right turns announced (walker confirmed 2) | 1 | 2 |
| Arrival detected | no | yes |

- The route-match gate was `cross-track + reported accuracy ≤ 8 m`; the walk's median cross-track was 4.5 m and median accuracy 6.3 m, so most fixes were rejected. Fixes within a 20 m corridor are now used, weighted by reported accuracy.
- Windowed map matching searches only the stretch of route reachable since the last estimate, replacing the ambiguity rejection.
- An alpha–beta filter smooths distance along the route and estimates walking speed; backward steps are capped at 3 m per fix.
- Single bad fixes no longer announce uncertainty; guidance pauses after 6 s without a usable fix. Accuracy limit is 30 m (was 10 m). Arrival radius is 8 m (was 5 m). Turns are announced 25 m ahead, and late by up to 8 m rather than skipped.
- Turn threshold is 40° (was 45°): moving the library endpoint made the second turn 42°.
- Live location uses `kCLLocationAccuracyBestForNavigation` and never auto-pauses; the screen stays awake during guidance, and opening Control Center (for screen recording) no longer ends guidance.

`NavigationChecks.checkRecordedWalk` asserts both turns, arrival, no false off-route alerts and ≤3 m backward steps on that recording. These are replay results, not a supervised field trial; the route geometry is still the approximate trace.
