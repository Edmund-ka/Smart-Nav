# Argus · architecture-focused capstone deck

**Present:** open `presentation/Argus-Architecture-Deck.html` in Chrome, Safari or Edge. It is one self-contained file that works offline.

| Key | Action |
|---|---|
| → / Space / click | next build step, then next slide |
| ← | previous step |
| ⇧→ / ↓ | skip the builds and go to the next slide |
| G | slide index, click to jump |
| N | speaker notes (shown on the same screen) |
| F | full screen |

The architecture slide (7) builds in 6 steps. Each subsystem slide (9–16) builds itself, then → spotlights components 1…n, then shows a **key idea** visual. Clicking a block on the architecture or a tile on slide 8 jumps to that subsystem. Clicking a component card spotlights it.

**Edit:** `index.html` (static slides), `app.js` (subsystem data in `SUBS`, architecture layout in `AN`/`AE`, step captions in `ARCH_STEPS`), `styles.css`. Rebuild the portable file:

```sh
python3 presentation/architecture-deck/build.py
```

Sources: Chapter 3 design (architecture and subsystem figures), the Chapter 2 requirement groups, prototype code (`TurnInstruction.swift`, `OffRouteDetector.swift`), and `presentation/data.js` (the recorded Boyd Hall → library walk).
