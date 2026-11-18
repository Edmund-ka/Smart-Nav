# Professor demonstration — 7 to 9 minutes

## 0:00–1:00 — Scope and evidence

State that this is the semester-one iPhone prototype. Glasses are semester two. Show `CHAPTER3_ALIGNMENT.md` and distinguish candidate data, demonstration data and actual field verification. No verified campus route is included yet.

## 1:00–2:00 — Mapping

Open Profile → Campus map data. Show the bundled trace, source information and validation warnings. Show `data/campus/tsu_candidate_graph.geojson` and `MAP_VALIDATION.txt` on the laptop: 3,158 nodes and 3,323 edges, with disconnected components preserved. Explain that field checking is still required.

## 2:00–3:15 — Custom route planning

On Home use Location → Boyd Hall and Menu → Choose destination → TSU Library. The route summary says Argus and labels the unverified demonstration. Open Menu → Route preferences and enable Avoid stairs: unknown stair attributes prevent a false stair-free claim. Disable that restriction for the demonstration. Start opens native Argus guidance. Run the route demonstration; show progress, upcoming decisions, repeat and where-am-I. Live guidance stays disabled for this dataset. Apple Maps is an explicitly labeled menu fallback.

## 3:15–5:00 — Shared simulation

Open Simulate, choose 4× and Follow the route. Show a scripted checkpoint, its basis and its three-second pause. Explain that checkpoint placement is authored. Choose Miss the first turn, restart, and demonstrate departure and rejoin. The app cannot calculate a verified replacement on the candidate campus dataset; show the synthetic verified-graph rerouting test result separately. A single stray reading must not trigger departure.

## 5:00–6:30 — Recording and evaluation

Open Record → Reference recording. Replay at 4×, open Navigation evaluation, and inspect sensor-time events and manual-mark comparison. The sample contains 245 measured fixes; its route is approximate and marks are not precise ground truth. Show `EVALUATION.md` for reproducible software results, including any missed expected events. Do not call that a field accuracy score.

## 6:30–8:00 — Explain the code

Follow `ARCHITECTURE.md`: data → validator → Dijkstra → NavigationSession → events → speech/haptics and evaluation. Open the commented projection equation and route relaxation loop. All three position sources call the same session method. Motion is recorded but not fused. Show the recorded graph snapshot fields and the existing local JSON save/replay workflow.

## 8:00–9:00 — Remaining work

Show `FIELD_VERIFICATION.md`, the requirement matrix and semester-two backlog. Identify advisor-approved routes, entrance surveys, alternate paths, physical phone tests and accessibility trials as the next evidence. For live guidance, import a genuinely surveyed dataset, start at a known verified node, and perform a supervised daytime trial. Do not unlock it by editing flags for the presentation.

## Build and checks

```sh
python3 scripts/check_models.py --report
python3 -m unittest discover -s Tests -p 'test_*.py'
python3 scripts/validate_campus_map.py data/campus/tsu_candidate_graph.geojson
xcrun swift-format lint --strict --recursive Argus Tests
xcodebuild -quiet build -project Smart_nav.xcodeproj -scheme Smart_nav -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/Argus-build CODE_SIGNING_ALLOWED=NO
```

A physical iPhone requires signing. Allow location only when testing capture or live guidance, and microphone/speech when testing voice. Keep the app foregrounded. Saved walks and photos remain in Application Support; exporting shares only the selected data. Imported maps are local. No camera permission is required for this milestone.
