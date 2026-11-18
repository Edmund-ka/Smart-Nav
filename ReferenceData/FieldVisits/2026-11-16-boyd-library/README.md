# Boyd Hall–library field evidence — November 16, 2026

User-supplied walk and five photographs. Originals are preserved byte-for-byte; `manifest.json` records SHA-256 hashes and source paths. JPEG previews are derived viewing copies. No graph coordinates, verification flags, app thresholds or original manual marks were changed.

## Confirmed by the walker

The user stated: “Started above the stairs, descended the stairs and started my walk, did two right turns and i tried the automatic door button and it worked”.

Record this as a dated first-person field observation: the journey includes descending Boyd entrance stairs, both marked turns were right turns, and the library automatic-door switch successfully operated the door during this visit. This does not establish a step-free journey, independently surveyed coordinates, measured accessibility dimensions, or continuing door operability.

## Photo index

| Original / preview | Subject | Visible evidence / limits |
| --- | --- | --- |
| `IMG_8816.HEIC` / `IMG_8816-preview.jpg` | Boyd entrance overview | Door banks, raised landing, exterior stairs and handrails, paved approach. Building identity comes from the user. No verified step-free alternative shown. |
| `IMG_8817.HEIC` / `IMG_8817-preview.jpg` | Boyd stairs and doors close-up | Stair treads and central/side handrails; landing and entrance. Stair dimensions, clear widths and condition need measurement. |
| `IMG_8818.HEIC` / `IMG_8818-preview.jpg` | Looking outward from Boyd stair landing | Descent toward the paved walk and nearby junction. Does not establish the geometry of the full walk or a step-free connector. |
| `IMG_8819.HEIC` / `IMG_8819-preview.jpg` | Library entrance overview | Glass entrance/vestibule, automatic-door notice and freestanding switch on the right when approaching from outside. Threshold dimensions and approach slope remain unmeasured. |
| `IMG_8820.HEIC` / `IMG_8820-preview.jpg` | Library door switch close-up | Wheelchair-marked automatic-door actuator; its operation is supported by the user's explicit test, not by the photo alone. |

Night photographs limit surface/level inspection. No QR codes or posted text were treated as instructions.

## Walk replay using production navigation code

Recording: `9C6FFB3C-2D88-4F64-8704-F2A1EEF0D17D.json`, original name “New walk”. Started November 16 at **21:04:17 America/Chicago** (November 17 03:04:17 UTC). Duration **292.966 s** (4 min 53 s); 263 GPS, 2,926 motion and 2,494 compass samples. Saved graph snapshot: `boyd-library-demo`, version `2026-11-16`, `trace-0` → `trace-7`.

The graph snapshot preserves the approximate demonstration geometry; it does not become surveyed merely because it accompanied a real walk. Replay uses GPS only; motion/compass counts do not imply sensor fusion.

| Result | New walk | Earlier bundled walk |
| --- | ---: | ---: |
| GPS samples | 263 | 245 |
| Accepted for assessment | 207 | 166 |
| Rejected for poor reported accuracy | 56 | 79 |
| Fixes reaching following/progress branch | 38 | 0 |
| Right-turn events | 2 | 0 |
| Final trusted progress | 173.964 m | 0 m |
| Final state | uncertain | uncertain |

The other 169 accepted fixes fail route-match confidence. Origin was established at +2.812 s in this new walk, unlike the previous one. The reference route is approximately 201.113 m. GPS sample gaps reach 10.509 s; the original recording does not capture the reason or callback delivery times.

## Event comparison after user clarification

The raw marks say only “Turn”. The app's existing automatic evaluation therefore still scores only the arrival mark: **0 matched / 1 missing**. Separately applying the user's confirmed right-turn directions gives **2 matched / 1 missing** with the existing ±10 s tolerance. The raw JSON is unchanged.

| Expected observation | Mark time from start | Actual engine event | Difference / conclusion |
| --- | ---: | ---: | --- |
| First right turn | 133.466 s | `turnRight` 124.812 s | 8.654 s before mark; inside ±10 s. This is a replay event, not proof of when the phone spoke during the walk. |
| Second right turn | 191.100 s | `turnRight` 199.812 s | 8.712 s after mark; inside ±10 s but late relative to the user's annotation. Precise guidance was uncertain at the mark and recovered at 199.812 s. Matching does not establish acceptable real-world cue timing. |
| Arrival at library | 259.790 s | No arrival event | Minimum endpoint distance + accuracy within ±10 s is 20.543 m, above the 5 m rule. The closest-in-time recorded fix is +264.321 s, 4.531 s after the mark: 15.393 m from the approximate endpoint, with 5.150 m reported accuracy. |

The final fix is 14.529 m from the current endpoint (20.973 m including reported accuracy), and final trusted progress remains 27.149 m short. The recording continues approximately 33.177 s after the arrival mark; lack of an arrival event cannot simply be attributed to immediately stopping recording. GPS bias and an incorrect/approximate destination coordinate remain competing explanations. Do not move the endpoint to a single observed fix or loosen the arrival rule to manufacture success.

Full evidence: `replay-fixes.csv` (per-fix production-engine decisions) and `replay-results.txt` (events and evaluation). Comparison uses the saved graph snapshot, original timestamps, unchanged settings and production `NavigationSession`, `MapGeometry`, `RoutePlanner`, `ReplayInputs` and `NavigationEvaluation`.

## What is established and what comes next

- Boyd entrance stairs are photo-supported and the user confirms descending them. The observed journey must not be presented as step-free. Determine and survey a separate step-free origin/connector if needed.
- The library has a visible door actuator on the right; the user reports it worked during this visit. Record dated functionality rather than assuming permanent operation.
- Both turn directions are now known. Inspect actual junction positions and define independent cue reference points before evaluating advance-warning timing.
- Survey the library door/approach coordinate independently and compare multiple stationary readings and fixed landmarks. This is the next priority for the arrival mismatch.
- Measure widths, slopes, thresholds and any alternative path; obtain independent review before marking graph features verified or enabling live campus guidance.
