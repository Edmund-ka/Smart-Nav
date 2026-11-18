# Current tab design

The user's `IMG_8809.HEIC` sketch and subsequent greeting request define the current design.

## Shared design

Poppins Regular, SemiBold, and Bold. Palette: pale blue `#DBF2FC`, navy `#072D50`, and pink `#FE5C8D`. Rounded glass cards use an opaque fallback for Reduce Transparency or Increase Contrast. Small text uses a darker secondary ink for legibility. Fonts scale with Dynamic Type.

Tabs remain **Home · Simulate · Record · Profile**, with the map icon for Simulate. Labels and selected-state accessibility traits supplement the icons. At accessibility text sizes, tab labels yield to larger icons while spoken labels remain available.

## Home

- At standard text size, MapKit occupies approximately 70% of the screen and the bottom card, tabs, and bottom safe area occupy 30%.
- Circular menu at upper left, centered Location dropdown, and circular notification button at upper right. The system draws the Dynamic Island.
- The card begins with a small, legible “Good morning/afternoon/evening, Edmund” above “Where to?”, with the profile avatar on the right.
- The rounded Search control activates voice input without a keyboard. It changes to Listening, supports tap-to-finish, and exposes Cancel.
- Centered pink Start button with a navigation arrow. Start requests a destination if none exists; otherwise it opens native Argus guidance for a valid graph route. Apple Maps is an explicit menu fallback.
- Tabs sit inside the bottom of the card. Start and tabs remain visible while longer status content scrolls.
- The menu offers a destination-list fallback. The location selector chooses a planning origin. Notifications report current session status with an honest empty state.
- Larger accessibility text expands the card to keep controls usable. Map attribution remains visible.

## Simulate

One page containing the MapKit map or bundled campus image, scenario selector, speed, progress, instruction, and playback controls. No simulation library or nested presentation pages. Data and route geometry are explicitly simulated/approximate.

## Record

One page for capture controls, draft review, and saved walks. Start, Stop, Save, and Discard have distinct meanings. Saved-walk details provide metrics, map, replay, rename, export, and confirmed deletion.

## Profile

Local photo and name, speech rate, haptics, saved places, sensor diagnostics, and inline explanatory sections. The same photo appears on Home. No account is required.
