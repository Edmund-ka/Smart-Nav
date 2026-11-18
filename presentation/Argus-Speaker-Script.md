# Argus: Speaker Script

**Deck:** Argus · Smart-Edge Accessible Campus Navigation
**Target length:** about 18 minutes plus Q&A
**Suggested split:** Edmund takes slides 1–8 (the story and the architecture). Sydney takes slides 9–17 (the subsystems). Edmund returns for 18–20. Swap the split to suit you.

Stage directions are in *[brackets]*. **[CLICK]** means press → to reveal the next build step.
Speak slowly. Pause wherever you see a line break.

---

## 1 · Title (about 45 s)

Good morning, everyone.

Picture this: you're walking across campus to a building you've never been to, and you can't see the path in front of you.

You know roughly where the building is. But where's the accessible entrance? Is there a staircase on the way? What do you do when something is blocking the sidewalk?

That's the problem we've been working on. This is **Argus**: hands-free, spoken navigation for blind and low-vision pedestrians, running on an iPhone and using campus map data.

I'm Edmund Afunyah, this is Sydney Apenteng, and our advisor is Dr. Ali Sekmen.

*[Gesture to the animated route]* What you see here is the core idea: a route drawn on the campus map, and a voice saying "In 35 meters, turn right" before you reach the turn.

Today we'll focus on **how the system is designed**: the overall architecture first, then each subsystem.

---

## 2 · Agenda (about 20 s)

Here's our route for today.

We'll start with the problem, then the solution and what we set out to build, then the requirements.

*[Point to section 5]* Most of our time goes here, to the design: the architecture first, then the eight subsystems one by one.

We'll finish with what runs today and what comes next.

---

## 3 · Problem statement (about 1 min 15 s)

Let's start with the people this is for.

Blind and low-vision people get to work, to shops, to appointments and to public services every day, like anyone else. But a lot of the information the rest of us pick up at a glance just isn't available to them.

*[Card 1]* First, **everyday mobility barriers.** A blocked sidewalk. A street crossing. Uneven pavement. An entrance you've never used before. Any one of these can make a route hard to follow.

*[Card 2]* Second, **the technology gap.** Canes, guide dogs and navigation apps all help, and help a lot. But knowing which way the route goes is not the same as knowing what's in front of you right now. A map app can say "turn right on Main Street." It can't say there are stairs ahead or that the door you need is around the side. What's missing is guidance that combines the route with timely information about your surroundings, delivered through audio or vibration.

*[Card 3]* Third, **broad need, campus first.** We want this to help in everyday travel generally. But we're starting with one place we can map carefully and test safely: the TSU campus. Going wider later will take more mapping and more testing.

One more thing: Argus doesn't replace a cane or a guide dog. It works alongside them.

---

## 4 · Solution: why campus navigation matters (about 1 min)

So why focus on campus navigation?

*[Card 1]* Because **independent travel** matters. Getting to class, to work, to the library or to student services is part of everyday life. If you can't get there on your own, that costs you independence.

*[Card 2]* And campuses are **complicated to walk.** Sidewalks, crossings, ramps, stairs, buildings with three or four entrances where only one is accessible. A route that just says "go to this building" leaves out all of those decisions.

*[Card 3]* And **conditions change.** Construction goes up, crowds gather, something blocks the path. The route on the map stays the same, but the walk itself doesn't.

So what we need is more than directions. We need usable routes plus information about what's ahead. That leads to our goal.

---

## 5 · Goal and objectives (about 1 min 15 s)

*[Read the goal slowly]* Our goal is to build an accessible navigation system that combines **campus route data**, **phone sensors** and **wearable context** to guide blind and low-vision pedestrians between locations on the TSU campus.

We split that into four groups of objectives.

*[Card 01]* **Campus mapping:** identify the sidewalks and accessible entrances, and build a map-based tool for marking them.

*[Card 02]* **The navigation app:** choose a destination, track position with GPS, compass and motion sensors, plan the route, recalculate when you go off course, and speak every instruction, with distinct vibrations for turns, warnings and arrival.

*[Card 03]* **Devices and vision:** connect to smart glasses over Bluetooth, and use camera models to recognize campus landmarks.

*[Card 04]* **Campus testing:** measure position accuracy, route completion, wrong turns, recognition accuracy and response time.

To be clear, these are objectives, not results yet. We'll show exactly where we are near the end.

---

## 6 · Functional requirements (about 1 min)

From those objectives we wrote **thirteen requirement groups**, R1 through R13.

The main thing to see on this slide is that **every requirement has an owner.** Each color is the subsystem responsible for that requirement.

*[Point across the grid]* Blue, R1, is Campus Mapping. Indigo, R2 and R5, is Route Planning: loading the graph, then routing and recalculating. Teal, R4, is Positioning. Pink, R3 and R6, is the accessible interface: speech and vibration. Green is the glasses. Orange is landmark recognition. Gold, R10 through R12, is testing: recording, supervised trials and an accessibility review.

R9, the Apple Watch, is optional. And R13, reproducible delivery, belongs to the whole project: someone outside the team should be able to build and run Argus.

Remember these colors. They carry through every slide that follows.

---

## 7 · Architecture: how the system fits together (about 2 min 30 s)

This is the most important slide in the deck, so I'll build it up one piece at a time.

**Step 0: Two places, one system.**
There are two places where work happens. *[Left box]* The team laptop is where we prepare data, once, before deployment. *[Big box]* The iPhone is where navigation runs. Connected devices sit around the phone.

**[CLICK] Step 1: Prepare the campus.**
On the laptop, **Campus Mapping** takes OpenStreetMap and TSU campus maps, checks them by walking the routes, and produces a route graph in GeoJSON plus landmark photos. **Model Training** will turn those photos into a Core ML model. Everything ships inside the app bundle on the phone. Model training is planned for next semester.

**[CLICK] Step 2: Know where the user is.**
The iPhone's sensors feed **Positioning**, which works out where you are on the mapped walkways. **Route Planning** searches the bundled graph for an accessible path.

**[CLICK] Step 3: Guide by voice and touch.**
**Interface and Guidance** takes three things: the destination you chose, the route and its turns, and your current position. From those it decides when to speak, so each instruction comes *before* the decision point, with a vibration for each event.

**[CLICK] Step 4: Add wearable context.**
This is the Semester 2 layer. **Glasses Connection** carries camera frames and voice commands from the Meta smart glasses. **Recognition** runs the landmark model on those frames. If the glasses disconnect, the phone takes over. The Apple Watch, bottom left, is optional.

**[CLICK] Step 5: Make it testable.**
**Testing and Replay** records real sensor readings on real walks, then feeds them back into Positioning *as if they were live.* The logs and trial results are stored.

**[CLICK] Step 6: The whole system.**
So here's the full picture. Most of the processing stays on the iPhone. And every arrow you see is a defined interface, which means each subsystem can be built and tested on its own.

*[Optional]* If anything raises a question during Q&A, I can click a block and jump straight to its detail slide.

---

## 8 · Architecture decisions (about 1 min 15 s)

Why is it organized this way? Four decisions.

*[01]* **The iPhone does the thinking.** Positioning, routing and guidance all run on the phone. The glasses and the watch are extra ways to interact with it. If they fail, navigation keeps working.

*[02]* **Prepare offline, run on the device.** The heavy work of preparing campus data happens before deployment, so the phone doesn't depend on a server while you're walking. Model training and glasses integration are planned for Semester 2.

*[03]* **Fail safely, not silently.** *[Slow down here]* This is the one I'd most like you to remember. If the location isn't reliable, or there's no accessible route, Argus tells you. It doesn't hand you directions that might be wrong. For someone who can't see where they are, a confident wrong instruction is worse than no instruction.

*[04]* **Replayable by design.** Live mode, simulation and replay all run through the same navigation engine, called NavigationSession. So we can test navigation logic again and again without walking the route every time.

That's the architecture. Sydney's going to take us one level deeper.

*[Hand off to Sydney]*

---

## 9 · Subsystem index (about 30 s)

*[Sydney]*

Thanks, Edmund.

Detailed design means going one level below the architecture. We have eight subsystems, and every one of them gets its own slide.

*[Point to the flow strip at the bottom]* Each slide reads the same way: **inputs** on the left, **numbered components** in the order data moves through them, then **outputs** on the right. The last build on each slide shows the key idea.

Three of them, Model Training, Recognition and Glasses Connection, are marked **planned**. That's Semester 2 work. The other five are implemented today, and I'll be clear about what's built and what's still being validated.

---

## 10 · Campus Mapping, R1 (about 1 min)

Campus Mapping turns the campus into data the app can navigate.

**[CLICK] 1 · Map data collection.** We import candidate paths from OpenStreetMap and campus sources, without treating them as field-verified.

**[CLICK] 2 · Graph and route review.** The candidate graph has **3,158 nodes and 3,323 edges.** But the Home screen doesn't use that raw data. It uses a separate, **walk-reviewed route** of eight nodes, from Boyd Hall to the library.

**[CLICK] 3 · Field photographs.** We keep the walker's photos and confirmations: the stairs, the right turns, and the fact that the library door button actually works.

**[CLICK] 4 · Validation and survey.** Our validator reports **36 disconnected components and 11 isolated nodes.** We survey those gaps on foot before connecting any paths.

**[CLICK] Key idea: a campus becomes a graph.** Nodes are decision points, edges are walkable paths. The important rule here: candidate data and verified data are kept apart. We don't route anyone along a path nobody has walked.

---

## 11 · Landmark Model Training, R8 · PLANNED (about 45 s)

This one is planned for Semester 2.

**[CLICK] 1 · Labeling and split.** Draw bounding boxes on the landmark photos and split them into training, validation and test sets.

**[CLICK] 2 · Fine-tuning.** Fine-tune a small YOLO detector on a handful of campus landmark classes, like building signs, entrances and crosswalks.

**[CLICK] 3 · Testing.** Measure accuracy on held-out images, and how fast the model runs.

**[CLICK] 4 · Core ML conversion.** Convert it to Apple's Core ML format and ship it inside the app.

**[CLICK] Key idea: train once, run on the phone.** Nothing is trained at run time, and no network is needed while you walk.

---

## 12 · Positioning, R4 (about 1 min 15 s)

Positioning answers the question "where am I, really?"

**[CLICK] 1 · Input adapters.** Live GPS, simulation and replay all provide positions to the same NavigationSession. The engine doesn't know or care which one it's getting.

**[CLICK] 2 · Fix filtering.** We reject readings that are too inaccurate, too old, or obvious outliers, and we flag stale live updates.

**[CLICK] 3 · Route projection.** GPS drifts near buildings. Instead of blindly snapping to the closest path, we project onto the route geometry and assess how confident we are in that match.

**[CLICK] 4 · Uncertainty monitor.** If a reading is uncertain, it doesn't count as progress along the route, and it can't trigger arrival.

**[CLICK] Key idea: route projection and confidence.** Being honest here: we haven't built custom GPS and motion fusion. What we have is careful filtering plus a confidence check. That's the "fail safely" decision from earlier, put into practice.

---

## 13 · Route Planning, R2 and R5 (about 1 min 15 s)

Route Planning takes the graph and finds a path you can actually walk.

**[CLICK] 1 · Graph loading.** Load the nodes, edges, geometry and verification metadata from JSON and GeoJSON.

**[CLICK] 2 · Graph validation.** Check references, geometry and connectivity *before* any route is planned. Disconnected pieces stay separate. We never guess a connection.

**[CLICK] 3 · Path search.** Dijkstra's algorithm over edge costs. The cost combines distance with accessibility, so a route can avoid stairs when an alternative exists. On the Boyd route, there are stairs and no step-free alternative has been verified yet, so the app warns about them.

**[CLICK] 4 · Route steps.** From the path we work out the distance, where the turns are, and when each instruction should be spoken.

**[CLICK] 5 · Deviation and rerouting.** We're deliberately conservative here. We only reroute from a verified, unambiguous junction. A field-verified alternate route is still needed.

**[CLICK] Key idea: cost decides the route.** Shortest isn't always best. Accessibility is built into the cost.

---

## 14 · Accessible Interface and Guidance, R3, R6, R9 (about 1 min 15 s)

This is everything the user hears, feels and says.

**[CLICK] 1 · Home controls.** Choose the destination, then start and stop. Home starts the reviewed route using live Core Location.

**[CLICK] 2 · Guidance timing.** Turn preparation starts **35 meters** ahead, which is the "In 35 m, turn right" you saw on the title slide. Route confidence decides whether guidance goes ahead.

**[CLICK] 3 · Spoken instructions.** The phone speaks turns and warnings, including the warning about the stairs at Boyd.

**[CLICK] 4 · Turn vibrations.** Left is **one** medium pulse. Right is **two**, 220 milliseconds apart. So you can tell the direction without listening. We still need to test how usable that is outdoors.

**[CLICK] 5 · Watch relay.** Planned and optional. Never required.

**[CLICK] Key idea: speak before the turn.** An instruction that arrives late is useless. Timing matters as much as wording.

---

## 15 · Landmark Recognition, R8 · PLANNED (about 45 s)

Also planned for Semester 2.

**[CLICK] 1 · Frame sampling.** Take frames at a steady rate from the glasses camera, or from the phone camera as a fallback.

**[CLICK] 2 · On-device model.** Run the Core ML model on the iPhone. No network.

**[CLICK] 3 · Confidence check.** A detection is accepted only if its score is high enough **and** that landmark is actually near you on the map.

**[CLICK] 4 · Landmark event.** Send confirmed landmarks to Guidance to announce, once, without repeating the alert.

**[CLICK] Key idea: trust, then verify.** The camera and the map have to agree before Argus says anything.

---

## 16 · Glasses Connection, R7 · PLANNED (about 45 s)

The glasses add context. They are never a requirement.

**[CLICK] 1 · Connection manager.** Connect through Meta's supported developer tools and monitor the connection.

**[CLICK] 2 · Camera frames** go to Recognition, where the toolkit allows it.

**[CLICK] 3 · Microphone input.** Voice commands go to Guidance.

**[CLICK] 4 · Speaker output.** Instructions play through the glasses' open-ear speakers, so you can still hear the world around you.

**[CLICK] 5 · Phone fallback.** If the glasses drop, the iPhone's camera, mic and speaker take over, and navigation continues.

**[CLICK] Key idea: glasses optional, navigation never.**

---

## 17 · Testing and Replay, R10, R11, R12 (about 1 min 15 s)

The last subsystem is how we know any of this works.

**[CLICK] 1 · Session recording.** During a test walk we store timestamped GPS, compass and motion readings, plus manual event marks like "I'm turning right now." No camera video is recorded.

**[CLICK] 2 · Shared-engine replay.** The replay goes through the same navigation logic as live mode. The one difference is that live mode also checks how old each callback is and handles stale updates.

**[CLICK] 3 · Event comparison.** We compare what the app did with what the walker marked. In our latest direction-checked evaluation, the app matched **both right turns.** Arrival was missing on the original recording, and we're reporting that rather than hiding it.

**[CLICK] 4 · Walking trials.** Still required: test the revised Home route outdoors with a sighted companion, and keep the new recording.

**[CLICK] 5 · Accessibility review.** Validate speech, haptics and VoiceOver, and document the limitations.

**[CLICK] Key idea: a real walk, replayed.** Walk once, test a hundred times.

*[Hand back to Edmund]*

---

## 18 · What runs today (about 1 min 15 s)

*[Edmund]*

So what actually runs today? These are screenshots from the iPhone simulator.

*[Phone 1]* **Home** is implemented. It runs live positioning and guidance on the walk-reviewed Boyd-to-library route. It warns about the Boyd stairs and uses the updated library endpoint.

*[Phone 2]* **Simulate** drives turn cues and route deviations from scripted, repeatable movement. There are three scenarios, all with spoken cues.

*[Phone 3]* **Record** is implemented. It captures GPS, accuracy, sensor readings and manual marks, and you can save, export and replay a walk.

*[Point to the footer]* To be completely clear: the latest build still needs a supervised outdoor test. Completing the route live outdoors has **not** been validated yet. That's the next step.

---

## 19 · Future work: from prototype to a tested journey (about 1 min 15 s)

Here's how we get from prototype to a tested journey. Every phase has a gate, a concrete check we have to pass before moving on.

*[Nov–Dec, "We are here"]* **Now through December:** map three to five routes, each 200 to 600 meters, covering crossings, ramps, stairs and accessible entrances. **Gate:** a second walker checks the GeoJSON dataset.

*[Jan–Feb]* **Validate live guidance:** calibrate the route geometry and cue timing, then test deviation, recovery and arrival. **Gate:** all four work live.

*[March]* **Glasses and recognition:** camera, mic and audio from the glasses, with landmark recognition on the phone. **Gate:** a Core ML model plus automatic iPhone fallback.

*[April]* **Trials and accessibility:** replay tests first, then supervised walks, plus testing VoiceOver, voice control and vibration. **Gate:** we report position error, completion, recovery and cue timing.

*[May]* **Final product:** the app, campus data, model, replay logs, trial results and guides. **Gate:** someone *outside* our team builds and runs Argus using only our documentation.

These dates are proposed, the watch is optional, and the glasses features depend on what Meta's SDK supports.

---

## 20 · Thank you / Questions (about 30 s)

*[Point to the three pillars as you say them]*

So, Argus in three lines:

**Campus data with evidence.** We don't route anyone along a path nobody has walked.
**Guidance you can hear.** Spoken and felt, before the turn.
**Evidence you can replay.** Every claim backed by a recording we can run again.

We'd like to thank **Dr. Ali Sekmen**, our advisor and professor, and **Dr. Rogers**, our Department Head, for their support.

Thank you. We're happy to take your questions.

*[During Q&A: press **G** for the slide grid and jump back to the architecture slide (slide 7). It's the best place to answer most design questions.]*

---

## Q&A prep: likely questions

| Question | Short answer |
|---|---|
| Why not just use Google or Apple Maps? | They route to a building, not to its accessible entrance, and they don't warn about campus stairs or give confidence-aware guidance. Ours runs on verified, walked campus data. |
| What happens when GPS is bad near buildings? | The uncertainty monitor stops counting progress and the app tells the user, rather than guessing (slide 12). |
| Does it work without the glasses? | Yes. The phone does all the processing. The glasses are optional context (slides 8 and 16). |
| How do you test without blind participants walking every route? | Record real walks, replay them through the same engine, and compare against manual marks. Supervised trials with a sighted companion come later (slide 17). |
| How accurate is it? | No field accuracy claims yet. Replay matched both right turns. Arrival detection and outdoor live completion are next to validate. |
| Privacy? | No faces in the training photos, no camera video recorded, and processing stays on the device. |
