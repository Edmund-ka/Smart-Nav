#!/usr/bin/env python3
"""Compile and test the actual model files without starting the iOS app or sensors."""
from pathlib import Path
import subprocess
import tempfile
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCES = [
    "Argus/Screens/WalkRecording/WalkData.swift",
    "Argus/Screens/Home/HomeGreeting.swift",
    "Argus/Screens/Home/VoiceDestinationParser.swift",
    "Argus/Shared/Navigation/CampusPlace.swift",
    "Argus/Shared/Navigation/SimulationRoute.swift",
    "Argus/Shared/Navigation/TurnInstruction.swift",
    "Argus/Shared/Navigation/OffRouteDetector.swift",
    "Argus/Shared/Preferences/SavedPlaces.swift",
    "Tests/WalkModelChecks.swift",
    "Tests/NavigationChecks.swift",
    "Tests/NavigationEvaluationChecks.swift",
    "Tests/NavigationVerificationChecks.swift",
    "Tests/ModelChecks.swift",
]


SOURCES += [str(p.relative_to(ROOT)) for folder in ("CampusMap", "Guidance")
            for p in sorted((ROOT / "Argus/Shared" / folder).glob("*.swift"))
            if p.name not in {"LiveLocationProvider.swift", "GuidanceOutput.swift", "NavigationController.swift", "CampusMapStore.swift"}]

def main():
    # Keep compiler caches and test binaries out of the source tree.
    with tempfile.TemporaryDirectory(prefix="argus-model-checks-") as directory:
        temporary = Path(directory)
        executable = temporary / "checks"
        subprocess.run([
            "swiftc", "-module-cache-path", str(temporary / "cache"),
            *(str(ROOT / source) for source in SOURCES), "-o", str(executable),
        ], check=True)
        subprocess.run([str(executable), str(ROOT / "Argus/Resources"), *([str(ROOT / "docs/semester-one/EVALUATION.md")] if "--report" in sys.argv else [])], check=True)


if __name__ == "__main__":
    main()
