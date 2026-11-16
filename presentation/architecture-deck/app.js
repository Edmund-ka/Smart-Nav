/* Argus · Architecture deck engine */
(() => {
"use strict";

/* ================= Icons ================= */
const ICONS = {
  map: '<path d="M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2z"/><path d="M9 4v14M15 6v14"/>',
  train: '<rect x="5" y="5" width="14" height="14" rx="2"/><path d="M9.5 9.5h5v5h-5zM9 2v3M15 2v3M9 19v3M15 19v3M2 9h3M2 15h3M19 9h3M19 15h3"/>',
  pos: '<circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2.5"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/>',
  route: '<circle cx="6" cy="19" r="2.5"/><circle cx="18" cy="5" r="2.5"/><path d="M8.5 19H15a3.5 3.5 0 0 0 0-7H9a3.5 3.5 0 0 1 0-7h6.5"/>',
  guide: '<path d="M4 9v6h4l5 4V5L8 9H4z"/><path d="M16.5 8.5a5 5 0 0 1 0 7M19 6a8.5 8.5 0 0 1 0 12"/>',
  recog: '<path d="M3 8V5a2 2 0 0 1 2-2h3M16 3h3a2 2 0 0 1 2 2v3M21 16v3a2 2 0 0 1-2 2h-3M8 21H5a2 2 0 0 1-2-2v-3"/><path d="M6 12s2.5-4 6-4 6 4 6 4-2.5 4-6 4-6-4-6-4z"/><circle cx="12" cy="12" r="1.5"/>',
  glass: '<circle cx="6.5" cy="14" r="3.5"/><circle cx="17.5" cy="14" r="3.5"/><path d="M10 14h4M3 14l1.2-6H7M21 14l-1.2-6H17"/>',
  test: '<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/><path d="M10 9l5 3-5 3z"/>',
  phone: '<rect x="6" y="2" width="12" height="20" rx="3"/><path d="M11 18h2"/>',
  access: '<circle cx="12" cy="4.5" r="2"/><path d="M5 8l7 1.5L19 8M12 9.5V15M9 21l3-6 3 6"/>',
  clock: '<circle cx="12" cy="13" r="8"/><path d="M12 9v4l3 2M9 2h6"/>',
  shield: '<path d="M12 3 5 6v6c0 4.5 3 7.5 7 9 4-1.5 7-4.5 7-9V6l-7-3z"/><path d="M9 12l2 2 4-4"/>',
  db: '<ellipse cx="12" cy="5" rx="8" ry="3"/><path d="M4 5v14c0 1.7 3.6 3 8 3s8-1.3 8-3V5M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3"/>'
};
const icon = (k) => `<svg viewBox="0 0 24 24" fill="none" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">${ICONS[k]}</svg>`;
document.querySelectorAll("[data-icon]").forEach(el => { el.innerHTML = icon(el.dataset.icon); });

/* ================= Subsystems ================= */
const C = { map:"#0284c7", train:"#9333ea", pos:"#0d9488", route:"#4f46e5", guide:"#e8457a", recog:"#ea580c", glass:"#16a34a", test:"#ca8a04", store:"#64748b", ext:"#8aa0b4" };
const INK = "#072d50", MUTED = "#35566f";

const SUBS = [
 { id:"map", name:"Campus Mapping", req:"R1", where:"Team laptop · before deployment", archSub:"routes, entrances, landmarks, walked and checked on foot",
   summary:"Turns campus maps and on-foot walks into a verified pedestrian graph and a set of landmark photos.",
   inputs:[["Map sources","OSM, campus maps"],["Campus walks","checked on foot"]],
   outputs:[["Campus accessibility","data (store)"]],
   comps:[
    ["Map data collection","OpenStreetMap, TSU maps","Start from OpenStreetMap and the available TSU campus maps for each selected route."],
    ["Route graph recording","nodes, edges, entrances","Nodes mark decision points and key places. Edges are walkable paths. Each one records location and accessibility: crossings, ramps, stairs, entrances."],
    ["Landmark photos","selected classes, no faces","Photograph selected landmarks such as building signs, entrances and crosswalks, and organize them for training. No faces."],
    ["Export and check","GeoJSON, second walker","Store every route as GeoJSON, then have a second person walk it to confirm the graph matches reality."]],
   key:"map", keyTitle:"A campus becomes a graph" },
 { id:"train", name:"Landmark Model Training", short:"Model Training", req:"R8", where:"Team laptop · before deployment", archSub:"small vision model → Core ML",
   summary:"Fine-tunes a small vision model on our landmark photos and ships it to the phone. Nothing is trained at run time.",
   inputs:[["Landmark photos","from Campus Mapping"]],
   outputs:[["App bundle","landmark model"]],
   comps:[
    ["Labeling and split","boxes; train, val, test","Draw bounding boxes on each landmark photo, then split the set into training, validation and test images."],
    ["Model fine-tuning","small YOLO model","Fine-tune a small YOLO detector on the selected campus landmark classes."],
    ["Model testing","accuracy and speed","Measure accuracy on held-out test images and how fast the model runs."],
    ["Core ML conversion","runs on the iPhone","Convert to Apple's Core ML format and include it in the app bundle."]],
   key:"train", keyTitle:"Train once, run on the phone" },
 { id:"pos", name:"Positioning", req:"R4", where:"iPhone · every update", archSub:"GPS, compass, motion, snapped to the route",
   summary:"Estimates where the user is and which way they face, then snaps that estimate onto the mapped walkways.",
   inputs:[["iPhone sensors","GPS, compass, motion"],["Replayed readings","from Testing"]],
   outputs:[["Route Planning","position"],["Guidance","position, heading"]],
   comps:[
    ["Sensor reading","Core Location, Core Motion","GPS and compass from Core Location; accelerometer and gyroscope from Core Motion. Replayed readings enter here too."],
    ["Sensor smoothing","position and heading","Combine readings into a steadier estimate of position and heading."],
    ["Map matching","nearest walkway","GPS drifts near buildings, so the estimate is placed on the closest mapped walkway."],
    ["Uncertainty monitor","reliable or not","Flags when the location is unreliable, so the app warns the user instead of giving wrong directions."]],
   key:"pos", keyTitle:"Map matching: snap to the nearest walkway" },
 { id:"route", name:"Route Planning", req:"R2, R5", where:"iPhone · on request and on deviation", archSub:"accessible paths, rerouting",
   summary:"Loads and validates the campus graph, then finds an accessible path and the turns along it.",
   inputs:[["App bundle","route graph"],["Destination","from Guidance"],["Position","from Positioning"]],
   outputs:[["Guidance","route and turns"]],
   comps:[
    ["Graph loading","GeoJSON to graph","Read the bundled GeoJSON into nodes and edges in memory."],
    ["Graph validation","error report","Check that the graph is connected and well formed, and report errors before any route is planned."],
    ["Accessible path search","A* with costs","A* search over edge costs that combine distance with accessibility, so stairs can be avoided."],
    ["Route steps","turns, decision points","Extract the turns and intersections along the path and hand them to Guidance."],
    ["Deviation and rerouting","off-route check","If the user leaves the route, plan a new accessible path, or tell them when no reliable path exists."]],
   key:"route", keyTitle:"Cost decides the route" },
 { id:"guide", name:"Accessible Interface and Guidance", short:"Interface & Guidance", req:"R3, R6, R9", where:"iPhone (+ glasses, optional watch)", archSub:"VoiceOver and voice controls, spoken instructions, vibration patterns",
   summary:"Everything the user hears, feels and says. It decides when to speak so each instruction arrives before the turn.",
   inputs:[["Route and turns","from Route Planning"],["Position","from Positioning"],["Landmark","from Recognition"]],
   outputs:[["Glasses or phone","speech"],["Phone","vibration"],["Apple Watch","optional"]],
   comps:[
    ["Destination and controls","VoiceOver, voice","Choose a destination, start or stop, repeat an instruction, or ask “where am I?”, by VoiceOver or voice."],
    ["Guidance timing","zones around nodes","Watches the user approach each decision point and triggers the instruction early enough to act on."],
    ["Spoken instructions","text-to-speech","Speaks turns, warnings and arrival through the glasses or the phone speaker."],
    ["Vibration patterns","one per event","A distinct vibration for turns, deviations, warnings and arrival."],
    ["Watch relay","optional","If implemented, forwards vibrations and quick controls to an Apple Watch. Never required.", true]],
   key:"guide", keyTitle:"Speak before the turn" },
 { id:"recog", name:"Landmark Recognition", short:"Recognition", req:"R8", where:"iPhone · on camera frames", archSub:"runs the model on camera frames",
   summary:"Runs the bundled model on camera frames and only announces a landmark when the model and the map agree.",
   inputs:[["Camera frames","Glasses Connection"],["App bundle","landmark model"]],
   outputs:[["Guidance","landmark"]],
   comps:[
    ["Frame sampling","glasses or phone camera","Take frames at a steady rate from the glasses camera, or from the phone camera as a fallback."],
    ["On-device model","Core ML","Run the trained landmark model on the iPhone. No network is needed."],
    ["Confidence check","score and location","Accept a detection only if its score is high enough and that landmark is actually near the user."],
    ["Landmark event","announce, confirm","Send a confirmed landmark to Guidance to be announced, without repeated alerts."]],
   key:"recog", keyTitle:"Trust, then verify" },
 { id:"glass", name:"Glasses Connection", req:"R7", where:"iPhone ↔ Meta smart glasses", archSub:"camera, mic, speaker, phone fallback",
   summary:"Manages the link to the Meta glasses and routes camera, microphone and speaker, with the phone always ready to take over.",
   inputs:[["Meta smart glasses","camera, mic, speakers"]],
   outputs:[["Recognition","frames"],["Guidance","voice commands"]],
   comps:[
    ["Connection manager","connect, monitor","Connects through the supported Meta developer tools and watches the connection state."],
    ["Camera frames","to Recognition","Forwards camera images to Landmark Recognition where the toolkit allows it."],
    ["Microphone input","voice commands","Passes the user's voice commands to Guidance."],
    ["Speaker output","spoken instructions","Plays spoken instructions in the glasses' open-ear speakers."],
    ["Phone fallback","when glasses drop","If the glasses disconnect, the iPhone's camera, microphone and speaker take over, so navigation continues."]],
   links:[[0,1],[0,2],[0,3],[0,4]],
   key:"glass", keyTitle:"Glasses optional, navigation never" },
 { id:"test", name:"Testing and Replay", req:"R10, R11, R12", where:"iPhone + logs", archSub:"record, replay, trials",
   summary:"Records real walks and replays them through the app, so behavior can be checked again and again without walking.",
   inputs:[["Sensor readings","and camera video"]],
   outputs:[["Logs and results","(store)"],["Positioning","replayed readings"]],
   comps:[
    ["Session recording","sensors and video","Save GPS, accuracy, motion and compass readings during a test walk, with time-stamped event marks."],
    ["Replay","recording as if live","Feed a recording back into Positioning exactly as if it were live."],
    ["Event comparison","expected vs actual","Compare the replayed events, such as turn cues and deviations, with the expected ones."],
    ["Walking trials","supervised, daylight","Supervised walks on verified routes, measuring completion, wrong turns and assistance needed."],
    ["Accessibility review","and limitations","Review the VoiceOver and voice-control journey and document the system's limits."]],
   key:"test", keyTitle:"A real walk, replayed" }
];
const SUB = Object.fromEntries(SUBS.map(s => [s.id, s]));
SUBS.forEach(s => s.color = C[s.id]);

/* ================= Helpers ================= */
const NS = "http://www.w3.org/2000/svg";
const esc = (s) => String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
const pad = (n) => String(n).padStart(2, "0");
function wrap(text, maxChars) {
  const words = text.split(" "); const lines = []; let cur = "";
  words.forEach(w => { if ((cur + " " + w).trim().length > maxChars && cur) { lines.push(cur); cur = w; } else cur = (cur + " " + w).trim(); });
  if (cur) lines.push(cur); return lines;
}
const ptsToD = (pts) => "M" + pts.map(p => p.join(" ")).join(" L");

/* ================= Architecture ================= */
const AN = [
 { id:"osm", kind:"ext", x:30, y:0, w:300, h:64, t:"OpenStreetMap", s:"and TSU campus maps", step:0 },
 { id:"laptop", kind:"dev", x:15, y:100, w:340, h:600, t:"Team laptop", s:"preparation", step:0 },
 { id:"phone", kind:"dev", x:395, y:40, w:1050, h:760, t:"iPhone", s:"runs the navigation app", step:0 },
 { id:"mapping", sub:"map", x:45, y:180, w:280, h:110, step:1 },
 { id:"store", kind:"db", x:45, y:345, w:280, h:100, t:"Campus accessibility data", s:"route graph (GeoJSON), photos", step:1 },
 { id:"training", sub:"train", x:45, y:505, w:280, h:110, step:1 },
 { id:"bundle", kind:"db", x:430, y:112, w:250, h:100, t:"App bundle", s:"route graph, landmark model", step:1 },
 { id:"sensors", kind:"hw", x:1120, y:300, w:290, h:120, t:"iPhone sensors", s:"GPS, compass, accelerometer, gyroscope", step:2 },
 { id:"positioning", sub:"pos", x:760, y:300, w:290, h:120, step:2 },
 { id:"routing", sub:"route", x:430, y:300, w:250, h:120, step:2 },
 { id:"guidance", sub:"guide", x:430, y:480, w:620, h:120, step:3 },
 { id:"recognition", sub:"recog", x:1120, y:480, w:290, h:120, step:4 },
 { id:"glassconn", sub:"glass", x:1120, y:655, w:290, h:115, step:4 },
 { id:"glasses", kind:"hw", x:1490, y:655, w:290, h:115, t:"Meta smart glasses", s:"camera, microphone, speakers", step:4 },
 { id:"person", kind:"ext", x:1490, y:470, w:290, h:96, t:"Pedestrian", s:"and campus surroundings", step:4 },
 { id:"watch", kind:"opt", x:30, y:728, w:310, h:80, t:"Apple Watch", s:"optional · vibration, quick commands", step:4 },
 { id:"testing", sub:"test", x:760, y:112, w:290, h:110, step:5 },
 { id:"logs", kind:"db", x:1120, y:112, w:290, h:100, t:"Logs and results", s:"sensor logs, video, trial results", step:5 }
];
const AE = [
 { p:[[180,64],[180,180]], c:"map", l:"map data", lx:192, ly:132, a:"start", step:1 },
 { p:[[185,290],[185,345]], c:"map", l:"GeoJSON, photos", lx:197, ly:323, a:"start", step:1 },
 { p:[[185,445],[185,505]], c:"map", l:"landmark photos", lx:197, ly:481, a:"start", step:1 },
 { p:[[325,395],[370,395],[370,150],[430,150]], c:"map", step:1 },
 { p:[[325,560],[384,560],[384,178],[430,178]], c:"train", l:"routes · model", lx:358, ly:475, a:"middle", rot:true, step:1 },
 { p:[[1120,360],[1050,360]], c:"pos", l:"readings", lx:1085, ly:350, a:"middle", step:2 },
 { p:[[760,360],[680,360]], c:"pos", l:"position", lx:720, ly:350, a:"middle", step:2 },
 { p:[[555,212],[555,300]], c:"route", l:"route graph", lx:565, ly:262, a:"start", step:2 },
 { p:[[515,420],[515,480]], c:"route", l:"route, turns", lx:505, ly:456, a:"end", step:3 },
 { p:[[605,480],[605,420]], c:"guide", l:"destination", lx:615, ly:456, a:"start", step:3 },
 { p:[[905,420],[905,480]], c:"pos", l:"position, heading", lx:915, ly:456, a:"start", step:3 },
 { p:[[1120,540],[1050,540]], c:"recog", l:"landmark", lx:1085, ly:530, a:"middle", step:4 },
 { p:[[1265,655],[1265,600]], c:"glass", l:"frames", lx:1275, ly:633, a:"start", step:4 },
 { p:[[985,600],[985,690],[1120,690]], c:"guide", l:"speech", lx:1052, ly:682, a:"middle", step:4 },
 { p:[[1120,740],[935,740],[935,600]], c:"glass", l:"voice commands", lx:1028, ly:762, a:"middle", step:4 },
 { p:[[1490,695],[1410,695]], c:"glass", l:"frames, voice", lx:1450, ly:686, a:"middle", step:4 },
 { p:[[1410,738],[1490,738]], c:"glass", l:"speech", lx:1450, ly:760, a:"middle", step:4 },
 { p:[[668,112],[668,80],[1432,80],[1432,540],[1410,540]], c:"train", l:"landmark model", lx:1050, ly:72, a:"middle", step:4 },
 { p:[[1600,566],[1600,655]], c:"ext", l:"voice, scene", lx:1590, ly:614, a:"end", step:4 },
 { p:[[1690,655],[1690,566]], c:"ext", l:"speech", lx:1700, ly:614, a:"start", step:4 },
 { p:[[430,580],[372,580],[372,768],[340,768]], c:"guide", dash:true, both:true, l:"vibration · commands", lx:360, ly:676, a:"middle", rot:true, step:4 },
 { p:[[945,300],[945,222]], c:"test", l:"recorded readings", lx:955, ly:263, a:"start", step:5 },
 { p:[[865,222],[865,300]], c:"test", dash:true, l:"replayed readings", lx:855, ly:263, a:"end", step:5 },
 { p:[[1050,165],[1120,165]], c:"test", l:"logs", lx:1085, ly:155, a:"middle", step:5 }
];
const ARCH_STEPS = [
 ["Two places, one system", "Preparation happens once, on the team laptop. Navigation runs on the iPhone. Connected devices are added around it."],
 ["Prepare the campus", "Campus Mapping turns maps and on-foot walks into a GeoJSON route graph and landmark photos. Model Training turns the photos into a Core ML model. Both ship in the app bundle."],
 ["Know where the user is", "iPhone sensors feed Positioning, which snaps readings onto mapped walkways. Route Planning searches the bundled graph for an accessible path."],
 ["Guide by voice and touch", "Interface & Guidance takes the destination, turns and position, and speaks each instruction before the decision point, with vibration for events."],
 ["Add wearable context", "Glasses Connection carries frames and voice. Recognition runs the bundled model on frames. If the glasses drop, the phone takes over. Apple Watch is optional."],
 ["Make it testable", "Testing & Replay records sensor readings on real walks and feeds them back into Positioning as if live. Logs and trial results are stored."],
 ["The whole system", "Most processing stays on the iPhone. Every arrow is a defined interface, so each subsystem can be built and tested on its own. Click any block to go deeper."]
];

function archSVG() {
  let defs = `<defs>`;
  Object.entries(C).forEach(([k, col]) => {
    defs += `<marker id="am-${k}" viewBox="0 0 10 10" refX="8.5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 z" fill="${col}"/></marker>`;
  });
  defs += `<filter id="soft"><feGaussianBlur stdDeviation="2"/></filter></defs>`;
  let nodes = "", edges = "", frames = "";
  AN.forEach(n => {
    const s = n.sub ? SUB[n.sub] : null;
    const col = s ? s.color : (n.kind === "db" ? C.store : n.kind === "ext" ? C.ext : "#072d50");
    let g = `<g class="an hide ${s ? "sub" : ""}" data-step="${n.step}" ${s ? `data-goto="${s.id}"` : ""} style="--nc:${col}">`;
    if (n.kind === "dev") {
      g += `<rect class="nb" x="${n.x}" y="${n.y}" width="${n.w}" height="${n.h}" rx="30" fill="rgba(255,255,255,.6)" stroke="rgba(7,45,80,.5)" stroke-width="3"/>`;
      g += `<text class="dtitle" x="${n.x + 22}" y="${n.y + 34}">${n.t}</text><text class="dsub" x="${n.x + 22}" y="${n.y + 56}">${n.s}</text>`;
    } else if (n.kind === "db") {
      const ry = 13, x = n.x, y = n.y, w = n.w, h = n.h;
      g += `<path class="nb" d="M${x} ${y + ry} a${w / 2} ${ry} 0 0 1 ${w} 0 v${h - 2 * ry} a${w / 2} ${ry} 0 0 1 ${-w} 0 z" fill="rgba(148,163,184,.12)" stroke="${col}" stroke-width="2"/>`;
      g += `<path d="M${x} ${y + ry} a${w / 2} ${ry} 0 0 0 ${w} 0" fill="none" stroke="${col}" stroke-width="2"/>`;
      g += `<text class="ntitle" text-anchor="middle" x="${x + w / 2}" y="${y + 52}" style="font-size:17px">${n.t}</text>`;
      wrap(n.s, 30).forEach((ln, i) => g += `<text class="nsub" text-anchor="middle" x="${x + w / 2}" y="${y + 74 + i * 18}">${ln}</text>`);
    } else {
      const dash = n.kind === "ext" ? `stroke-dasharray="7 7"` : n.kind === "opt" ? `stroke-dasharray="10 7"` : "";
      const fill = s ? `${col}22` : n.kind === "hw" ? "#ffffff" : "rgba(255,255,255,.6)";
      const sw = n.kind === "hw" || n.kind === "opt" ? 3.5 : 2.2;
      g += `<rect class="nb" x="${n.x}" y="${n.y}" width="${n.w}" height="${n.h}" rx="18" fill="${fill}" stroke="${col}" stroke-width="${sw}" ${dash}/>`;
      const title = s ? (s.short || s.name) : n.t;
      const sub = s ? s.archSub : n.s;
      const cx = n.x + n.w / 2;
      const lines = wrap(sub, Math.floor(n.w / 8.4));
      const blockH = 24 + (s ? 20 : 0) + lines.length * 18;
      let y = n.y + (n.h - blockH) / 2 + 18;
      g += `<text class="ntitle" text-anchor="middle" x="${cx}" y="${y}">${esc(title)}</text>`;
      if (s) { y += 21; g += `<text class="nreq" text-anchor="middle" x="${cx}" y="${y}" fill="${col}">${s.req}</text>`; }
      lines.forEach((ln) => { y += 19; g += `<text class="nsub" text-anchor="middle" x="${cx}" y="${y}">${esc(ln)}</text>`; });
    }
    if (n.kind === "dev") frames += g + `</g>`; else nodes += g + `</g>`;
  });
  AE.forEach(e => {
    const col = C[e.c]; const d = ptsToD(e.p);
    const m = `marker-end="url(#am-${e.c})" ${e.both ? `marker-start="url(#am-${e.c})"` : ""}`;
    let g = `<g class="ae hide" data-step="${e.step}" ${e.dash ? "data-dash" : ""}>`;
    g += `<path class="ln" pathLength="1" d="${d}" fill="none" stroke="${col}" stroke-width="2.8" ${m} opacity=".7"/>`;
    g += `<path class="fl" d="${d}" fill="none" stroke="${col}" stroke-width="7"/>`;
    if (e.l) {
      const tr = e.rot ? `transform="rotate(-90 ${e.lx} ${e.ly})"` : "";
      g += `<text class="elab" x="${e.lx}" y="${e.ly}" text-anchor="${e.a}" ${tr}>${e.l}</text>`;
    }
    edges += g + `</g>`;
  });
  return `<svg viewBox="0 0 1800 820">${defs}<g class="frames">${frames}</g><g class="edges">${edges}</g><g class="nodes">${nodes}</g></svg>`;
}

function initArch(slide) {
  slide.querySelector(".arch-wrap").innerHTML = archSVG();
  const cap = slide.querySelector(".arch-cap");
  cap.innerHTML = `<div class="cap-body"></div><div class="pips">${ARCH_STEPS.map(() => "<i></i>").join("")}</div>`;
  const body = cap.querySelector(".cap-body");
  slide.querySelectorAll(".an.sub").forEach(g => g.addEventListener("click", (ev) => { ev.stopPropagation(); goToSub(g.dataset.goto); }));
  let lastStep = -1;
  slide._render = (step) => {
    const final = step === ARCH_STEPS.length - 1;
    slide.querySelectorAll(".an, .ae").forEach(el => {
      const s = +el.dataset.step;
      el.classList.toggle("hide", s > step);
      el.classList.toggle("hot", final || s === step);
      el.classList.toggle("seen", !final && s < step);
      if (el.classList.contains("ae")) {
        if (s <= step) requestAnimationFrame(() => el.classList.add("drawn")); else el.classList.remove("drawn");
      }
    });
    slide.querySelectorAll(".ae[data-dash]").forEach(el => {
      const ln = el.querySelector(".ln");
      if (+el.dataset.step <= step) setTimeout(() => { if (el.classList.contains("drawn")) ln.style.strokeDasharray = ".012 .01"; }, 1050);
      else ln.style.strokeDasharray = "";
    });
    const [t, p] = ARCH_STEPS[step];
    const write = () => {
      body.innerHTML = `<div class="st">${final ? "COMPLETE" : step === 0 ? "OVERVIEW" : `STEP ${step} OF ${ARCH_STEPS.length - 2}`}</div><h3>${t}</h3><p>${p}</p>`;
      body.classList.remove("swap");
    };
    if (lastStep === -1) write(); else { body.classList.add("swap"); setTimeout(write, 250); }
    lastStep = step;
    cap.querySelectorAll(".pips i").forEach((pi, i) => pi.classList.toggle("on", i <= step));
  };
}

/* ================= Locator (mini architecture) ================= */
function locatorSVG(activeId) {
  let g = `<rect x="15" y="100" width="340" height="600" rx="40" fill="none" stroke="rgba(7,45,80,.28)" stroke-width="8"/>`;
  g += `<rect x="395" y="40" width="1050" height="760" rx="40" fill="none" stroke="rgba(7,45,80,.28)" stroke-width="8"/>`;
  AN.filter(n => n.sub).forEach(n => {
    const s = SUB[n.sub]; const on = s.id === activeId;
    g += `<rect x="${n.x}" y="${n.y}" width="${n.w}" height="${n.h}" rx="22" fill="${on ? s.color : s.color + "30"}" ${on ? `style="filter:drop-shadow(0 0 30px ${s.color})"` : ""}/>`;
  });
  AN.filter(n => n.kind === "hw" || n.kind === "db").forEach(n => g += `<rect x="${n.x}" y="${n.y}" width="${n.w}" height="${n.h}" rx="22" fill="rgba(7,45,80,.1)"/>`);
  return `<svg viewBox="0 0 1800 820">${g}</svg>`;
}

/* ================= Subsystem slides ================= */
function subDiagram(s) {
  const BX = 280, BW = 620, CX = 340, CW = 520, CH = 88, GAP = 30, TOP = 100, HEAD = 64;
  const n = s.comps.length;
  const H = TOP + n * CH + (n - 1) * GAP + 34;
  const W = 1180, col = s.color;
  const cardY = (k) => TOP + k * (CH + GAP);
  let out = `<svg viewBox="-4 -4 ${W + 8} ${H + 8}"><defs>
    <marker id="sm-${s.id}" viewBox="0 0 10 10" refX="8.5" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0 0 L10 5 L0 10z" fill="${col}"/></marker>
    <marker id="sg-${s.id}" viewBox="0 0 10 10" refX="8.5" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0 0 L10 5 L0 10z" fill="#8aa0b4"/></marker></defs>`;
  // container
  out += `<g class="sd-box"><rect x="${BX}" y="0" width="${BW}" height="${H}" rx="28" fill="${col}14" stroke="${col}" stroke-width="2.5"/>
    <path d="M${BX} ${HEAD} V28 a28 28 0 0 1 28 -28 H${BX + BW - 28} a28 28 0 0 1 28 28 V${HEAD} Z" fill="${col}"/>
    <text class="sd-boxtitle" x="${BX + 30}" y="${HEAD / 2 + 9}">${esc(s.name)}</text>
    <text class="sd-boxreq" x="${BX + BW - 28}" y="${HEAD / 2 + 7}" text-anchor="end">${s.req}</text></g>`;
  const ioBlock = (items, x, side, baseDelay) => {
    let o = ""; const m = items.length; const bodyTop = HEAD + 10, bodyH = H - bodyTop;
    items.forEach(([t, sub], k) => {
      const cy = bodyTop + bodyH * (k + 1) / (m + 1); const ph = 86, pw = 220;
      const d = (baseDelay + k * .12).toFixed(2);
      o += `<g class="${side === "in" ? "sd-in" : "sd-out"}" style="--d:${d}s">
        <rect x="${x}" y="${cy - ph / 2}" width="${pw}" height="${ph}" rx="18" fill="rgba(7,45,80,.04)" stroke="#9fb3c4" stroke-width="2" stroke-dasharray="7 6"/>
        <text class="sd-iotitle" x="${x + pw / 2}" y="${cy - 5}" text-anchor="middle">${esc(t)}</text>
        <text class="sd-iosub" x="${x + pw / 2}" y="${cy + 20}" text-anchor="middle">${esc(sub)}</text></g>`;
      const x1 = side === "in" ? x + pw + 2 : BX + BW + 2, x2 = side === "in" ? BX - 4 : x - 4;
      o += `<g class="sd-ar" style="--d:${(+d + .2).toFixed(2)}s"><path class="ln" pathLength="1" d="M${x1} ${cy} H${x2}" stroke="#8aa0b4" stroke-width="2.5" fill="none" marker-end="url(#sg-${s.id})"/>
        <path class="fl" d="M${x1} ${cy} H${x2 - 8}" stroke="${col}" stroke-width="7" fill="none"/></g>`;
    });
    return o;
  };
  out += ioBlock(s.inputs, 0, "in", .35);
  // links
  const links = s.links || s.comps.slice(1).map((_, k) => [k, k + 1]);
  links.forEach(([a, b]) => {
    const d0 = (.7 + b * .35).toFixed(2);
    let d;
    if (b === a + 1) { const x = CX + CW / 2; d = `M${x} ${cardY(a) + CH + 2} V${cardY(b) - 4}`; }
    else { const xr = CX - 26; d = `M${CX} ${cardY(a) + CH / 2} H${xr} V${cardY(b) + CH / 2} H${CX - 4}`; }
    out += `<g class="sd-ar" style="--d:${d0}s"><path class="ln" pathLength="1" d="${d}" stroke="${col}" stroke-width="2.8" fill="none" marker-end="url(#sm-${s.id})" opacity=".55"/>
      <path class="fl" d="${d}" stroke="${col}" stroke-width="8" fill="none"/></g>`;
  });
  // cards
  s.comps.forEach(([t, sub, , dashed], k) => {
    const y = cardY(k); const d = (.7 + k * .35).toFixed(2);
    out += `<g class="sd-card" data-k="${k + 1}" style="--d:${d}s;--c:${col}"><g class="cg">
      <rect class="cb" x="${CX}" y="${y}" width="${CW}" height="${CH}" rx="20" fill="#ffffff" stroke="${col}" stroke-width="2" ${dashed ? `stroke-dasharray="9 7"` : ""}/>
      <circle cx="${CX + 46}" cy="${y + CH / 2}" r="23" fill="${col}"/>
      <text class="sd-num" x="${CX + 46}" y="${y + CH / 2 + 7}" text-anchor="middle">${k + 1}</text>
      <text class="sd-ctitle" x="${CX + 88}" y="${y + 39}">${esc(t)}</text>
      <text class="sd-csub" x="${CX + 88}" y="${y + 66}">${esc(sub)}</text></g></g>`;
  });
  out += ioBlock(s.outputs, W - 220, "out", .7 + n * .35);
  return out + `</svg>`;
}

function initSub(slide) {
  const s = SUB[slide.dataset.sub]; const idx = SUBS.indexOf(s);
  slide.style.setProperty("--c", s.color);
  slide.dataset.accent = s.color;
  slide.dataset.accent2 = SUBS[(idx + 3) % SUBS.length].color;
  slide.dataset.section = "Design · Detailed";
  slide.dataset.steps = s.comps.length + 1;
  slide.dataset.notes = `${s.name} (${s.req}). ${s.summary} Walk through each numbered component with the arrow key; the last step shows the key idea.`;
  const reqs = s.req.split(", ").map(r => `<span class="chip r">${r}</span>`).join("");
  const n = s.comps.length;
  const dots = (k) => `<div class="dots">${s.comps.map((_, i) => `<i class="${i < k ? "on" : ""}"></i>`).join("")}</div>`;
  let panes = `<div class="pane card on" data-p="0"><div class="lab">Overview</div><div class="big">${esc(s.summary)}</div>
    <div class="io"><div><b>Runs on</b><span>${esc(s.where)}</span></div><div><b>Inputs</b><span>${s.inputs.map(i => esc(i[0])).join(" · ")}</span></div><div><b>Outputs</b><span>${s.outputs.map(i => esc(i[0])).join(" · ")}</span></div></div>
    <div class="hint"><kbd>→</kbd> walk through the ${n} components</div></div>`;
  s.comps.forEach(([t, sub, desc], k) => {
    panes += `<div class="pane card" data-p="${k + 1}"><div class="lab">Component ${k + 1} of ${n}</div><div class="cn">${pad(k + 1)}</div><h3>${esc(t)}</h3><div class="tagline">${esc(sub)}</div><p>${esc(desc)}</p>${dots(k + 1)}</div>`;
  });
  panes += `<div class="pane card key" data-p="${n + 1}"><div class="lab">Key idea</div><h3>${esc(s.keyTitle)}</h3>${KEY[s.key].html(s)}</div>`;
  slide.innerHTML = `
    <div class="sub-head">
      <div>
        <div class="kicker rv" style="--i:0">05 · Detailed design · ${idx + 1} of 8</div>
        <h1 class="rv" style="--i:1">${esc(s.name).replace(/(\S+)$/, '<span class="grad">$1</span>')}</h1>
        <div class="chips rv" style="--i:2">${reqs}<span class="chip"><span class="dot" style="color:${s.color}"></span>${esc(s.where)}</span></div>
      </div>
      <div class="locator rv fade" style="--i:3" title="Location in the architecture">${locatorSVG(s.id)}</div>
    </div>
    <div class="sub-body">
      <div class="sub-diag">${subDiagram(s)}</div>
      <div class="sub-panel rv" style="--i:4">${panes}</div>
    </div>`;
  const diag = slide.querySelector(".sub-diag");
  slide.querySelectorAll(".sd-card").forEach(c => c.addEventListener("click", (ev) => { ev.stopPropagation(); setStep(+c.dataset.k); }));
  const key = KEY[s.key]; let keyCtl = null;
  slide._render = (step) => {
    slide.querySelectorAll(".pane").forEach(p => p.classList.toggle("on", +p.dataset.p === step));
    const spotting = step >= 1 && step <= n;
    diag.classList.toggle("spotting", spotting);
    slide.querySelectorAll(".sd-card").forEach(c => c.classList.toggle("spot", +c.dataset.k === step));
    if (step === n + 1) { if (!keyCtl) keyCtl = key.start(slide.querySelector(".pane.key"), s); }
    else if (keyCtl) { keyCtl(); keyCtl = null; }
  };
  slide._leave = () => { if (keyCtl) { keyCtl(); keyCtl = null; } };
}

/* ================= Key-idea visuals ================= */
const loop = (fn) => { let id, t0 = performance.now(); const f = (t) => { fn(Math.max(0, (t - t0) / 1000)); id = requestAnimationFrame(f); }; id = requestAnimationFrame(f); return () => cancelAnimationFrame(id); };
const KEY = {
  map: {
    html: () => `<div class="kv"><svg viewBox="0 0 520 300" id="kv-map">
      <g class="kedges" fill="none" stroke-width="5" stroke-linecap="round"></g><g class="knodes"></g></svg></div>
      <div class="eq" style="font-family:var(--mono);font-size:14.5px;text-align:left;line-height:1.55;color:#1e3a5f">{ "type": "Feature",<br>&nbsp;&nbsp;"geometry": { "type": "LineString", … },<br>&nbsp;&nbsp;"properties": { "<span style="color:var(--map)">stairs</span>": false, "<span style="color:var(--map)">crossing</span>": true } }</div>
      <div class="note">GeoJSON shown is illustrative; field names will follow our final schema.</div>`,
    start: (pane, s) => {
      const svg = pane.querySelector("#kv-map");
      const N = [[40,250,"e"],[170,250,"d"],[170,140,"x"],[330,140,"d"],[330,40,"e"],[470,140,"d"],[470,250,"e"],[330,250,"s"]];
      const E = [[0,1],[1,2],[2,3],[3,4],[3,5],[5,6],[1,7],[7,6]];
      const eg = svg.querySelector(".kedges"), ng = svg.querySelector(".knodes");
      eg.innerHTML = E.map(([a,b],i) => `<line x1="${N[a][0]}" y1="${N[a][1]}" x2="${N[b][0]}" y2="${N[b][1]}" stroke="${N[b][2]==="s"||N[a][2]==="s" ? "#dc2626" : s.color}" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1" style="transition:stroke-dashoffset .7s ${0.3 + i * .18}s"/>`).join("");
      const lab = { e:"entrance", x:"crossing", s:"stairs" };
      ng.innerHTML = N.map(([x,y,t],i) => {
        const shape = t === "e" ? `<rect x="${x-13}" y="${y-13}" width="26" height="26" rx="6" fill="${s.color}"/>`
          : t === "s" ? `<rect x="${x-13}" y="${y-13}" width="26" height="26" rx="6" fill="#dc2626"/>`
          : t === "x" ? `<circle cx="${x}" cy="${y}" r="14" fill="#ffffff" stroke="#072d50" stroke-width="3"/><path d="M${x-7} ${y-5}h14M${x-7} ${y}h14M${x-7} ${y+5}h14" stroke="#072d50" stroke-width="2"/>`
          : `<circle cx="${x}" cy="${y}" r="11" fill="#072d50"/>`;
        const lbl = lab[t] ? `<text x="${x}" y="${y + (y > 200 ? 36 : -22)}" text-anchor="middle" font-size="14" fill="#5b7389">${lab[t]}</text>` : "";
        return `<g style="opacity:0;transition:opacity .4s ${0.15 + i * .15}s">${shape}${lbl}</g>`;
      }).join("");
      setTimeout(() => {
        eg.querySelectorAll("line").forEach(l => l.style.strokeDashoffset = "0");
        ng.querySelectorAll("g").forEach(g => g.style.opacity = "1");
      }, 40);
      return () => {};
    }
  },
  train: {
    html: (s) => `<div class="kv" style="display:flex;flex-direction:column;gap:18px;justify-content:center">
      <div class="ktiles" style="display:grid;grid-template-columns:repeat(6,1fr);gap:10px">${Array.from({length:6}).map((_,i)=>`<div style="aspect-ratio:1;border-radius:12px;background:linear-gradient(140deg,#e3f1f9,#ffffff);position:relative;overflow:hidden"><div class="bx" style="position:absolute;left:${18+i*3}%;top:${22+(i%3)*8}%;width:${48-(i%2)*10}%;height:${40+(i%3)*6}%;border:2.5px solid ${s.color};border-radius:4px;opacity:0;transform:scale(1.4);transition:all .5s ${0.3+i*.15}s"></div></div>`).join("")}</div>
      <div style="font-size:15px;color:var(--muted)">labeled photos → split</div>
      <div class="ksplit" style="display:flex;height:40px;border-radius:12px;overflow:hidden;font-size:15px;font-weight:600;color:#fff">
        <div style="flex:0;background:${s.color};display:grid;place-items:center;transition:flex 1s 1.4s">train</div>
        <div style="flex:0;background:#e9d5ff;color:#072d50;display:grid;place-items:center;transition:flex 1s 1.6s">val</div>
        <div style="flex:0;background:#e2e8f0;color:#072d50;display:grid;place-items:center;transition:flex 1s 1.8s">test</div></div>
      <div class="kchain" style="display:flex;align-items:center;gap:12px;font-size:17px;font-weight:600">
        ${["small YOLO","Core ML model","App bundle"].map((t,i)=>`<span style="padding:12px 16px;border-radius:14px;border:1.5px solid ${s.color};background:${s.color}1f;opacity:0;transform:translateY(10px);transition:all .5s ${2.3+i*.35}s">${t}</span>${i<2?`<span style="color:${s.color};opacity:0;transition:opacity .4s ${2.45+i*.35}s">→</span>`:""}`).join("")}</div>
      </div><div class="note">Train, validate and test on the laptop. The phone only runs the finished model.</div>`,
    start: (pane) => {
      setTimeout(() => {
        pane.querySelectorAll(".bx").forEach(b => { b.style.opacity = 1; b.style.transform = "none"; });
        const fl = [3, 1, 1]; pane.querySelectorAll(".ksplit div").forEach((d, i) => d.style.flex = fl[i]);
        pane.querySelectorAll(".kchain span").forEach(x => { x.style.opacity = 1; x.style.transform = "none"; });
      }, 40);
      return () => {};
    }
  },
  pos: {
    html: (s) => `<div class="kv"><svg viewBox="0 0 520 250" id="kv-pos">
      <line class="e1" x1="30" y1="200" x2="490" y2="170" stroke-width="10" stroke-linecap="round"/>
      <line class="e2" x1="40" y1="50" x2="480" y2="80" stroke-width="10" stroke-linecap="round"/>
      <text x="30" y="232" font-size="15" fill="#5b7389">walkway A</text>
      <text x="40" y="34" font-size="15" fill="#5b7389">walkway B</text>
      <line class="pr1" stroke-width="2" stroke-dasharray="5 5"/><line class="pr2" stroke-width="2" stroke-dasharray="5 5"/>
      <circle class="q" r="10" fill="${s.color}"/><circle class="qh" r="20" fill="none" stroke="${s.color}" stroke-width="2" opacity=".5"/>
      <circle class="p" r="8" fill="#072d50"/><text class="pl" font-size="16" font-weight="700" fill="#072d50">p</text>
      <text class="dl1" font-size="14" fill="#35566f"></text><text class="dl2" font-size="14" fill="#35566f"></text>
    </svg></div>
    <div class="eq"><i>t</i> = clip<span style="font-size:30px">(</span><span class="frac"><span>(<b>p</b>−<b>a</b>)·(<b>b</b>−<b>a</b>)</span><span>‖<b>b</b>−<b>a</b>‖²</span></span>, 0, 1<span style="font-size:30px">)</span> &nbsp;&nbsp; <i>d</i> = ‖<b>p</b> − (<b>a</b> + <i>t</i>(<b>b</b>−<b>a</b>))‖</div>
    <div class="note">White dot = raw GPS estimate <b>p</b>. It is placed on the walkway with the smallest <i>d</i>. Proposed method; final choice pending.</div>`,
    start: (pane, s) => {
      const svg = pane.querySelector("#kv-pos"); const $ = (c) => svg.querySelector(c);
      const A = [[30,200],[490,170]], B = [[40,50],[480,80]];
      const proj = (p, [a, b]) => { const abx = b[0]-a[0], aby = b[1]-a[1]; let t = ((p[0]-a[0])*abx + (p[1]-a[1])*aby) / (abx*abx + aby*aby); t = Math.max(0, Math.min(1, t)); const q = [a[0]+t*abx, a[1]+t*aby]; return { q, d: Math.hypot(p[0]-q[0], p[1]-q[1]) }; };
      const set = (el, o) => Object.entries(o).forEach(([k, v]) => el.setAttribute(k, v));
      return loop((t) => {
        const p = [270 + 150 * Math.sin(t * .45), 125 + 62 * Math.sin(t * .9 + 1) + 8 * Math.sin(t * 5.3)];
        const r1 = proj(p, A), r2 = proj(p, B); const win = r1.d <= r2.d ? r1 : r2;
        set($(".e1"), { stroke: r1.d <= r2.d ? s.color : "#cbd8e4" }); set($(".e2"), { stroke: r1.d > r2.d ? s.color : "#cbd8e4" });
        set($(".pr1"), { x1: p[0], y1: p[1], x2: r1.q[0], y2: r1.q[1], stroke: r1.d <= r2.d ? "#072d50" : "#9fb3c4" });
        set($(".pr2"), { x1: p[0], y1: p[1], x2: r2.q[0], y2: r2.q[1], stroke: r1.d > r2.d ? "#072d50" : "#9fb3c4" });
        set($(".q"), { cx: win.q[0], cy: win.q[1] }); set($(".qh"), { cx: win.q[0], cy: win.q[1] });
        set($(".p"), { cx: p[0], cy: p[1] }); set($(".pl"), { x: p[0] + 12, y: p[1] - 10 });
        const m = (d) => (d / 6).toFixed(1);
        const dl1 = $(".dl1"), dl2 = $(".dl2");
        set(dl1, { x: (p[0] + r1.q[0]) / 2 + 8, y: (p[1] + r1.q[1]) / 2 + 4 }); dl1.textContent = `d = ${m(r1.d)}`;
        set(dl2, { x: (p[0] + r2.q[0]) / 2 + 8, y: (p[1] + r2.q[1]) / 2 + 4 }); dl2.textContent = `d = ${m(r2.d)}`;
      });
    }
  },
  route: {
    html: (s) => `<div class="kv"><svg viewBox="0 0 520 260" id="kv-route"></svg></div>
      <div style="display:flex;justify-content:center;gap:12px;margin:2px 0 12px"><span class="chip kav" style="transition:all .4s">Avoid stairs: ON</span><span class="chip kcost" style="font-family:var(--mono)"></span></div>
      <div class="eq"><i>c</i>(<i>e</i>) = <span class="case"><span>∞ &nbsp;&nbsp;if <i>e</i> has stairs and the user avoids stairs</span><span><i>L</i>(<i>e</i>)·<i>m</i>(<i>e</i>) &nbsp;&nbsp;otherwise</span></span></div>
      <div class="note"><i>L</i> = length in meters · <i>m</i> ≥ 1 penalty for rough surface, steep slope or street crossing. Searched with A*.</div>`,
    start: (pane, s) => {
      const svg = pane.querySelector("#kv-route");
      const N = { S:[40,130], A:[170,40], B:[170,220], C:[340,40], D:[340,220], G:[480,130] };
      const E = [["S","A",40],["A","C",35,true],["C","G",40],["S","B",45],["B","D",35],["D","G",45],["A","B",30]];
      let h = "";
      E.forEach(([a,b,c,st],i) => {
        const [x1,y1] = N[a], [x2,y2] = N[b];
        h += `<line data-e="${a}${b}" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${st ? "#dc2626" : "#cbd8e4"}" stroke-width="7" stroke-linecap="round" ${st ? `stroke-dasharray="3 9"` : ""} style="transition:stroke .4s"/>`;
        const mx = (x1+x2)/2, my = (y1+y2)/2;
        h += `<text x="${mx + (a==="A"&&b==="B" ? 14 : 0)}" y="${my - 12}" text-anchor="${a==="A"&&b==="B" ? "start" : "middle"}" font-size="15" font-family="var(--mono)" fill="${st ? "#dc2626" : "#5b7389"}" ${st ? 'class="stc"' : ""}>${st ? "stairs · ∞" : c}</text>`;
      });
      h += `<path class="best" fill="none" stroke="${s.color}" stroke-width="9" stroke-linecap="round" stroke-linejoin="round" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1" style="filter:drop-shadow(0 0 10px ${s.color})"/>`;
      Object.entries(N).forEach(([k,[x,y]]) => {
        const end = k === "S" || k === "G";
        h += `<circle cx="${x}" cy="${y}" r="${end ? 20 : 13}" fill="${end ? s.color : "#072d50"}"/>` + (end ? `<text x="${x}" y="${y + 6}" text-anchor="middle" font-weight="700" font-size="17" fill="#fff">${k}</text>` : "");
      });
      svg.innerHTML = h;
      const best = svg.querySelector(".best"), av = pane.querySelector(".kav"), cost = pane.querySelector(".kcost"), stc = svg.querySelector(".stc");
      const paths = { on: { d:"M40 130 L170 220 L340 220 L480 130", c:"S→B→D→G = 125" }, off: { d:"M40 130 L170 40 L340 40 L480 130", c:"S→A→C→G = 115" } };
      let avoid = true;
      const show = () => {
        const p = avoid ? paths.on : paths.off;
        best.style.transition = "none"; best.style.strokeDashoffset = 1; best.setAttribute("d", p.d);
        best.getBoundingClientRect();
        best.style.transition = "stroke-dashoffset 1.4s cubic-bezier(.2,.8,.2,1) .2s"; best.style.strokeDashoffset = 0;
        av.textContent = `Avoid stairs: ${avoid ? "ON" : "OFF"}`;
        av.style.color = avoid ? s.color : "#dc2626"; av.style.borderColor = avoid ? s.color : "#dc2626";
        stc.textContent = avoid ? "stairs · ∞" : "stairs · 35"; cost.textContent = p.c;
      };
      show(); const iv = setInterval(() => { avoid = !avoid; show(); }, 4200);
      return () => clearInterval(iv);
    }
  },
  guide: {
    html: (s) => `<div class="kv"><svg viewBox="0 0 520 250" id="kv-guide">
      <path d="M30 60 H330 V240" fill="none" stroke="#cbd8e4" stroke-width="14" stroke-linecap="round" stroke-linejoin="round"/>
      <path class="done" d="M30 60 H330 V240" fill="none" stroke="${s.color}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1"/>
      <circle cx="330" cy="60" r="62" fill="${s.color}10" stroke="${s.color}" stroke-dasharray="4 6" stroke-width="2"/>
      <line x1="225" y1="40" x2="225" y2="80" stroke="#072d50" stroke-width="2" stroke-dasharray="3 4"/>
      <text x="225" y="102" text-anchor="middle" font-size="13" fill="#5b7389">cue point</text>
      <path d="M225 24 H330" stroke="#5b7389" stroke-width="1.5" marker-end="url(#gm)" marker-start="url(#gm)"/>
      <text x="277" y="18" text-anchor="middle" font-size="14" font-family="var(--mono)" fill="#35566f">35 m</text>
      <defs><marker id="gm" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z" fill="#5b7389"/></marker></defs>
      <circle class="rip" r="16" fill="none" stroke="${s.color}" stroke-width="3" opacity="0"/>
      <circle class="w" r="11" fill="#072d50"/>
      <g class="bub" opacity="0"><rect x="350" y="120" width="160" height="70" rx="14" fill="#072d50"/><text x="364" y="148" font-size="15" font-weight="700" fill="#fff">“In about 35 m,</text><text x="364" y="172" font-size="15" font-weight="700" fill="#fff">turn right.”</text></g>
    </svg></div>
    <div class="rules">
      <div><b>TURN CUE</b><span>Bend ≥ 45° · spoken 35 m before the turn</span></div>
      <div><b>OFF ROUTE</b><span>≥ 12 m away for 3 readings in a row</span></div>
      <div><b>BACK ON</b><span>≤ 5 m for 3 readings, so one stray fix never alarms</span></div>
    </div>
    <div class="note">Current prototype settings (ReplayTurnCue, RouteDeviationDetector), not yet field-calibrated. A vibration pattern per event is still to be defined.</div>`,
    start: (pane) => {
      const svg = pane.querySelector("#kv-guide"); const $ = (c) => svg.querySelector(c);
      const path = [[30,60],[330,60],[330,240]]; const L1 = 300, L2 = 180, L = L1 + L2;
      const at = (d) => d <= L1 ? [30 + d, 60] : [330, 60 + (d - L1)];
      return loop((t) => {
        const cyc = 7, u = (t % cyc) / cyc; const d = Math.min(1, u / .85) * L;
        const [x, y] = at(d); $(".w").setAttribute("cx", x); $(".w").setAttribute("cy", y);
        $(".done").style.strokeDashoffset = 1 - d / L;
        const cueOn = d >= 195 && d < 380; $(".bub").setAttribute("opacity", cueOn ? 1 : 0);
        const rp = d >= 195 && d < 260 ? (d - 195) / 65 : -1;
        const r = $(".rip"); if (rp >= 0) { r.setAttribute("cx", x); r.setAttribute("cy", y); r.setAttribute("r", 12 + rp * 34); r.setAttribute("opacity", 1 - rp); } else r.setAttribute("opacity", 0);
      });
    }
  },
  recog: {
    html: (s) => `<div class="kv" style="display:grid;grid-template-columns:250px 1fr;gap:26px;align-items:center">
      <svg viewBox="0 0 250 200" id="kv-recog"><rect x="2" y="2" width="246" height="196" rx="18" fill="#ffffff" stroke="#cbd8e4" stroke-width="2"/>
        <rect x="30" y="70" width="190" height="128" fill="#d6e6f1"/><path d="M20 70 L125 22 L230 70Z" fill="#b9cfe0"/>
        <rect x="100" y="140" width="50" height="58" fill="#35566f"/><rect x="72" y="84" width="106" height="30" rx="4" fill="#35566f"/>
        <rect class="bbox" x="64" y="76" width="122" height="46" rx="6" fill="none" stroke="${s.color}" stroke-width="3.5" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1" style="transition:stroke-dashoffset .9s .3s"/>
        <text class="blab" x="64" y="66" font-size="14" font-weight="700" fill="${s.color}" opacity="0" style="transition:opacity .4s 1.1s">building sign</text>
        <circle cx="22" cy="22" r="6" fill="#dc2626"><animate attributeName="opacity" values="1;.2;1" dur="1.4s" repeatCount="indefinite"/></circle></svg>
      <div style="display:grid;gap:14px;font-size:19px">
        ${[["Score high enough?","model confidence"],["Is it near the user?","matches the map"]].map(([a,b],i)=>`<div class="gate" style="display:flex;gap:14px;align-items:center;padding:14px 16px;border-radius:14px;background:rgba(7,45,80,.04);opacity:.35;transition:opacity .4s ${1.5+i*.7}s"><span style="width:34px;height:34px;border-radius:50%;display:grid;place-items:center;background:${s.color};color:#fff;font-weight:700">✓</span><div><b style="font-weight:600">${a}</b><div style="font-size:14px;color:var(--muted)">${b}</div></div></div>`).join("")}
        <div class="gate" style="padding:14px 16px;border-radius:14px;border:1.5px solid ${s.color};background:${s.color}1c;font-weight:600;opacity:.0;transition:opacity .5s 3s">→ Announce the landmark</div>
      </div></div>
      <div class="note">Both checks must pass. A detection that doesn't match the user's location is dropped, because the model can be wrong.</div>`,
    start: (pane) => {
      setTimeout(() => {
        pane.querySelector(".bbox").style.strokeDashoffset = 0; pane.querySelector(".blab").setAttribute("opacity", 1);
        pane.querySelectorAll(".gate").forEach(g => g.style.opacity = 1);
      }, 40);
      return () => {};
    }
  },
  glass: {
    html: (s) => `<div class="kv"><svg viewBox="0 0 520 260" id="kv-glass">
      <g class="gl"><rect x="20" y="40" width="150" height="80" rx="20" fill="#ffffff" stroke="${s.color}" stroke-width="2.5"/>
        <g transform="translate(95 80)" stroke="${s.color}" stroke-width="3" fill="none"><circle cx="-26" cy="0" r="17"/><circle cx="26" cy="0" r="17"/><path d="M-9 0h18"/></g>
        <text x="95" y="146" text-anchor="middle" font-size="15" fill="#35566f">Meta glasses</text>
        <g class="x" opacity="0" stroke="#dc2626" stroke-width="5" stroke-linecap="round"><path d="M70 55 L120 105 M120 55 L70 105"/></g></g>
      <g class="ph"><rect x="55" y="170" width="80" height="80" rx="16" fill="#ffffff" stroke="#35566f" stroke-width="2.5"/><rect x="83" y="182" width="24" height="44" rx="5" fill="none" stroke="#35566f" stroke-width="2.5"/><text x="150" y="216" font-size="15" fill="#35566f">iPhone</text></g>
      <rect x="330" y="80" width="170" height="110" rx="20" fill="${s.color}14" stroke="${s.color}" stroke-width="2"/>
      <text x="415" y="128" text-anchor="middle" font-size="17" font-weight="600" fill="#072d50">Navigation</text><text x="415" y="152" text-anchor="middle" font-size="14" fill="#5b7389">keeps running</text>
      ${["camera","mic","speaker"].map((t,i)=>`<path class="lg" d="M170 ${60+i*25} C 250 ${60+i*25}, 260 ${105+i*25}, 328 ${105+i*25}" fill="none" stroke="${s.color}" stroke-width="3" stroke-dasharray="5 9" style="animation:flow .8s linear infinite;transition:opacity .5s"/><path class="lp" d="M135 ${195+i*15} C 240 ${195+i*15}, 250 ${115+i*25}, 328 ${115+i*25}" fill="none" stroke="#35566f" stroke-width="3" stroke-dasharray="5 9" opacity="0" style="animation:flow .8s linear infinite;transition:opacity .5s"/><text x="250" y="${70+i*30}" font-size="13" fill="#5b7389" class="lt">${t}</text>`).join("")}
    </svg></div>
    <div class="chip kst" style="align-self:center;margin:4px 0 6px;font-size:17px"></div>
    <div class="note todo">To confirm: which Meta toolkit we use and which features it exposes (camera frames, microphone, speaker). If frames are not available, Landmark Recognition uses the phone camera.</div>`,
    start: (pane, s) => {
      const svg = pane.querySelector("#kv-glass"), st = pane.querySelector(".kst");
      let on = true;
      const show = () => {
        svg.querySelectorAll(".lg").forEach(l => l.style.opacity = on ? 1 : 0);
        svg.querySelectorAll(".lp").forEach(l => l.style.opacity = on ? 0 : 1);
        svg.querySelector(".x").setAttribute("opacity", on ? 0 : 1);
        svg.querySelector(".gl").style.opacity = on ? 1 : .45;
        st.textContent = on ? "● Glasses connected" : "● Glasses dropped → phone fallback";
        st.style.color = on ? s.color : "#dc2626";
      };
      show(); const iv = setInterval(() => { on = !on; show(); }, 3500);
      return () => clearInterval(iv);
    }
  },
  test: {
    html: (s) => `<div class="kv"><svg viewBox="0 0 520 270" id="kv-test"></svg></div>
      <div class="stats"><div><b>245</b><span>GPS fixes</span></div><div><b>5</b><span>event marks</span></div><div><b>2</b><span>turn cues</span></div><div><b>3</b><span>scenarios</span></div></div>
      <div class="note"><span style="color:${C.route}">━</span> planned route &nbsp; <span style="color:${s.color}">━</span> recorded walk, Boyd Hall → library. The route is an approximate trace, not surveyed ground truth.</div>`,
    start: (pane, s) => {
      const svg = pane.querySelector("#kv-test"); const D = window.ARGUS_DATA;
      if (!D) { svg.innerHTML = `<text x="260" y="135" text-anchor="middle" fill="#5b7389">route data not loaded</text>`; return () => {}; }
      const all = D.route.concat(D.recorded); const lat0 = all.reduce((a, p) => a + p[1], 0) / all.length; const k = Math.cos(lat0 * Math.PI / 180);
      const xs = all.map(p => p[0] * k), ys = all.map(p => p[1]);
      const minX = Math.min(...xs), maxX = Math.max(...xs), minY = Math.min(...ys), maxY = Math.max(...ys);
      const sc = Math.min(480 / (maxX - minX), 240 / (maxY - minY));
      const ox = (520 - (maxX - minX) * sc) / 2, oy = (270 - (maxY - minY) * sc) / 2;
      const P = (p) => [(p[0] * k - minX) * sc + ox, (maxY - p[1]) * sc + oy];
      const d = (arr) => "M" + arr.map(p => P(p).map(v => v.toFixed(1)).join(" ")).join(" L");
      const st = P(D.route[0]), en = P(D.route[D.route.length - 1]);
      svg.innerHTML = `<path d="${d(D.route)}" fill="none" stroke="${C.route}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round" opacity=".55"/>
        <path class="rec" d="${d(D.recorded)}" fill="none" stroke="${s.color}" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round" pathLength="1" stroke-dasharray="1" stroke-dashoffset="1"/>
        <circle cx="${st[0]}" cy="${st[1]}" r="9" fill="#072d50"/><text x="${st[0] + 14}" y="${st[1] + 24}" font-size="14" fill="#35566f">Boyd Hall</text>
        <circle cx="${en[0]}" cy="${en[1]}" r="9" fill="${C.guide}"/><text x="${en[0] - 12}" y="${en[1] - 14}" font-size="14" fill="#35566f" text-anchor="end">Library</text>
        <circle class="hd" r="7" fill="${s.color}" style="filter:drop-shadow(0 0 8px ${s.color})"/>`;
      const rec = svg.querySelector(".rec"), hd = svg.querySelector(".hd"); const pts = D.recorded.map(P);
      return loop((t) => {
        const u = Math.min(1, (t % 9) / 7); rec.style.strokeDashoffset = 1 - u;
        const p = pts[Math.min(pts.length - 1, Math.floor(u * (pts.length - 1)))]; hd.setAttribute("cx", p[0]); hd.setAttribute("cy", p[1]);
      });
    }
  }
};

/* ================= Subsystem index tiles ================= */
const idx = document.querySelector(".subidx");
idx.innerHTML = SUBS.map((s, i) => `<div class="st-tile rv pop" style="--i:${i + 2};--c:${s.color}" data-goto="${s.id}">
  <div class="num">${pad(i + 1)}</div>${icon(s.id)}<h3>${esc(s.name)}</h3>
  <div class="meta"><span>${/laptop/i.test(s.where) ? "Team laptop · offline" : "iPhone · live"}</span><b>${s.req}</b></div></div>`).join("");
idx.querySelectorAll(".st-tile").forEach(t => t.addEventListener("click", (ev) => { ev.stopPropagation(); goToSub(t.dataset.goto); }));

/* ================= Deck engine ================= */
const slides = [...document.querySelectorAll(".slide")];
initArch(document.getElementById("arch"));
document.querySelectorAll(".s-sub").forEach(initSub);
// generic data-show fragments
slides.forEach(sl => {
  const shows = sl.querySelectorAll("[data-show]");
  if (shows.length && !sl._render) {
    sl.dataset.steps = Math.max(...[...shows].map(e => +e.dataset.show));
    sl._render = (step) => shows.forEach(e => e.classList.toggle("off", +e.dataset.show > step));
  }
});
const maxStep = (sl) => +(sl.dataset.steps || 0);

let cur = -1, step = 0;
const stage = document.getElementById("stage"), root = document.documentElement;
const progress = document.getElementById("progress"), counter = document.getElementById("counter"), section = document.getElementById("section"), notes = document.getElementById("notes");

function fit() { const s = Math.min(innerWidth / 1920, innerHeight / 1080); stage.style.transform = `translate(-50%, -50%) scale(${s})`; }
addEventListener("resize", fit); if (window.ResizeObserver) new ResizeObserver(fit).observe(document.documentElement); fit();

function goTo(i, st = 0) {
  i = Math.max(0, Math.min(slides.length - 1, i));
  const prev = slides[cur];
  if (i !== cur) {
    if (prev) {
      prev.classList.remove("active"); prev.classList.add("leaving");
      prev._leave && prev._leave();
      setTimeout(() => prev.classList.remove("leaving"), 800);
    }
    slides.forEach((s, k) => s.classList.toggle("past", k < i));
    const next = slides[i];
    next.classList.remove("leaving");
    void next.offsetWidth;
    next.classList.add("active");
    cur = i;
    root.style.setProperty("--accent", next.dataset.accent || "#0284c7");
    root.style.setProperty("--accent2", next.dataset.accent2 || "#fe5c8d");
    section.innerHTML = `<span class="mark">Argus<i>.</i></span><span>${esc(next.dataset.section || "")}</span>`;
    counter.textContent = `${pad(i + 1)} / ${slides.length}`;
    progress.style.width = `${(i + 1) / slides.length * 100}%`;
    notes.innerHTML = `<b>NOTES · ${pad(i + 1)}</b>${esc(next.dataset.notes || "-")}`;
    history.replaceState(null, "", `#${i + 1}`);
    renderOverview();
  }
  setStep(Math.min(st, maxStep(slides[i])));
}
function setStep(st) { step = st; const sl = slides[cur]; sl._render && sl._render(step); }
function next() { if (step < maxStep(slides[cur])) setStep(step + 1); else if (cur < slides.length - 1) goTo(cur + 1, 0); }
function prev() { if (step > 0) setStep(step - 1); else if (cur > 0) goTo(cur - 1, maxStep(slides[cur - 1])); }
function goToSub(id) { const i = slides.findIndex(s => s.dataset.sub === id); if (i >= 0) goTo(i, 0); }

/* overview */
const ov = document.getElementById("overview"), ovg = ov.querySelector(".g");
function slideTitle(s) { const h = s.querySelector("h1, .brand, .big"); return h ? h.textContent.trim().replace(/\s+/g, " ") : "Slide"; }
function renderOverview() {
  ovg.innerHTML = slides.map((s, i) => `<button data-i="${i}" class="${i === cur ? "cur" : ""}" style="--c:${s.dataset.accent || "#0284c7"}"><small>${pad(i + 1)} · ${esc(s.dataset.section || "")}</small>${esc(slideTitle(s))}</button>`).join("");
}
ovg.addEventListener("click", (e) => { const b = e.target.closest("button"); if (b) { ov.classList.remove("on"); goTo(+b.dataset.i, 0); } });

/* input */
addEventListener("keydown", (e) => {
  if (e.metaKey || e.ctrlKey || e.altKey) return;
  const k = e.key;
  if (ov.classList.contains("on") && (k === "Escape" || k === "g" || k === "G")) { ov.classList.remove("on"); return; }
  if (["ArrowRight", " ", "PageDown", "Enter"].includes(k)) { e.preventDefault(); if (e.shiftKey && k === "ArrowRight") goTo(cur + 1, 0); else next(); }
  else if (["ArrowLeft", "PageUp", "Backspace"].includes(k)) { e.preventDefault(); if (e.shiftKey && k === "ArrowLeft") goTo(cur - 1, 0); else prev(); }
  else if (k === "ArrowDown") { e.preventDefault(); goTo(cur + 1, 0); }
  else if (k === "ArrowUp") { e.preventDefault(); goTo(cur - 1, 0); }
  else if (k === "Home") goTo(0, 0);
  else if (k === "End") goTo(slides.length - 1, 0);
  else if (k === "n" || k === "N") notes.classList.toggle("on");
  else if (k === "g" || k === "G" || k === "o" || k === "O") ov.classList.toggle("on");
  else if (k === "f" || k === "F") { if (!document.fullscreenElement) document.documentElement.requestFullscreen?.(); else document.exitFullscreen?.(); }
});
stage.addEventListener("click", (e) => {
  if (e.target.closest("a, button, [data-goto], .sd-card")) return;
  const r = stage.getBoundingClientRect(); (e.clientX - r.left) < r.width * .25 ? prev() : next();
});
let tx = null;
addEventListener("touchstart", (e) => { tx = e.touches[0].clientX; }, { passive: true });
addEventListener("touchend", (e) => { if (tx == null) return; const dx = e.changedTouches[0].clientX - tx; if (Math.abs(dx) > 50) dx < 0 ? next() : prev(); tx = null; });
let idleT; const wake = () => { document.body.classList.remove("idle"); clearTimeout(idleT); idleT = setTimeout(() => document.body.classList.add("idle"), 3500); };
addEventListener("mousemove", wake); wake();

addEventListener("hashchange", () => { const h = parseInt(location.hash.slice(1), 10); if (Number.isFinite(h) && h - 1 !== cur) goTo(h - 1, 0); });
window.deck = { goTo: (i, st) => goTo(i - 1, st || 0), next, prev, get state() { return { slide: cur + 1, step, max: maxStep(slides[cur]) }; } };
if (/[?&]static\b/.test(location.search)) document.body.classList.add("static");
const start = parseInt(location.hash.slice(1), 10);
const startStep = parseInt((location.hash.split(".")[1] || "0"), 10) || 0;
goTo(Number.isFinite(start) ? start - 1 : 0, startStep);
})();
