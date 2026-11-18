# Verification check results

Executed during the November 16, 2026 post-implementation pass, against the preserved working tree on `codex/semester-one-navigation`.

| Check | Result | Evidence / scope |
| --- | --- | --- |
| `python3 scripts/check_models.py --report` | PASS | All existing model checks plus actual adapter conversions, source decision parity, departure/rerouting parity, live delay/silence, event-matcher regressions and production candidate path. Generated `EVALUATION.md` and `RECORDED_FIX_TRACE.csv`. |
| `python3 -m unittest discover -s Tests -p 'test_*.py'` | PASS, 2 tests | Existing map importer checks. |
| Production validator on candidate JSON and GeoJSON | PASS structural validation | Each: 3,158 nodes, 3,323 edges, 0 errors, 13 warnings: 11 isolated nodes, 36 components and all edges needing field verification. Warnings intentionally retained. |
| `python3 scripts/inspect_boyd_library.py` | Completed | Read-only topology analysis and local SVG; production Swift planner independently confirms candidate path of 37 edges / 209.5 m. |
| `xcrun swift-format lint --strict --recursive Argus Tests` | PASS | No formatting diagnostics. |
| `git diff --check` | PASS | No tracked-diff whitespace errors; many source files were already untracked before this pass. |
| Xcode generic iOS Simulator build | PASS, exit 0 | `xcodebuild -quiet build -project Smart_nav.xcodeproj -scheme Smart_nav -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/Argus-verification-simulator CODE_SIGNING_ALLOWED=NO`; no warning/error output. |
| Xcode generic iPhone build | PASS, exit 0 | Same project/scheme with `-destination 'generic/platform=iOS' -derivedDataPath /tmp/Argus-verification-device CODE_SIGNING_ALLOWED=NO`; no warning/error output. This is unsigned compilation, not installation. |
| Physical iPhone tests / campus survey | NOT RUN | Requires device/signing and field evidence. Procedure/checklist supplied; no field verification flags changed. |

Temporary logs: `/tmp/argus-verification-models.log`, `/tmp/argus-verification-graph.log`, `/tmp/argus-verification-simulator.log`, `/tmp/argus-verification-device.log`. Durable results and reproduction commands are in this directory.

The measured replay's 0/3 event result is deliberately retained. A passing automated suite means the documented behavior and regressions are checked; it does not turn the measured recording into a successful navigation trial.
