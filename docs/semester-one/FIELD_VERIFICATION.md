# Campus verification and supervised trial checklist

No route has been certified by this implementation. This checklist is work to perform, not a completed survey.

## Prepare and approve

- [ ] Advisor approves the study boundary and 3–5 entrance-to-entrance routes, each 200–600 m, including the required crossing, ramp/stairs, bus stop and sharp turn.
- [ ] Choose an engineering walker, sighted companion, map editor and second checker. Obtain applicable campus/research approval before recruiting participants.
- [ ] Assign graph version and route IDs. Retain raw OSM IDs and source attribution. Print the candidate map and validation report.

## Check each node and edge on foot

- [ ] Confirm the walkway actually exists; record correct, wrong or missing without deleting source provenance.
- [ ] Confirm every connection and crossing physically. Never join paths merely because GPS coordinates are close.
- [ ] Record coordinates/reference quality, node type, spoken description, path direction, width, surface, slope, stairs, restrictions and access limitations. Leave unobserved attributes unknown.
- [ ] Check each entrance: actual approach, door type, accessible-entrance status, operating hours and whether any opener works. A sign alone is insufficient evidence.
- [ ] Identify alternate connected paths before claiming rerouting. Test one-way restrictions and disconnected/no-path cases.
- [ ] Record checker, date, notes, photographs allowed for sharing, and second-checker confirmation. Set `verified` only after these observations; setting a flag is not evidence of field work.
- [ ] Update both node and edge records, increment dataset version, rerun validation, and import the checked graph in Profile.

## Supervised phone trial

- [ ] Use daylight, an approved route and a sighted companion. Keep usual mobility aids. Establish a stop word/action and stop the trial whenever conditions become unsafe.
- [ ] Start from the selected verified node with a reliable location reading. Keep Argus foregrounded; background and lock-screen guidance are not supported by this baseline.
- [ ] Record phone/OS, graph version, route ID, start/end references, conditions, walk ID and manual marks.
- [ ] Test normal journey, missed turn/rejoin, connected alternative, no valid alternative, stationary jitter, poor/stale GPS, backtracking, nearby parallel path, wrong starting place and near-wrong-entrance arrival.
- [ ] Measure cue distance/time against independently identified decision points; separate device-reported accuracy from measured position error.
- [ ] Record completion, wrong turns, missed/duplicate instructions, human assistance, departure/rejoin timing, recovery success, and stop reasons. Keep failure trials.
- [ ] Test location/microphone denial, interruptions, background return and repeated start/stop. Document expected foreground-stop behavior.
- [ ] Verify VoiceOver order and labels on every screen; test large text and opaque backgrounds. Test repeat/where-am-I/stop voice commands and each haptic pattern with intended users.
- [ ] Report participant count separately from walk count. Export only consented data and remove identifying imagery before sharing.

## Required physical work still open

Route surveys and independent checks; entrance and accessibility attributes; alternate-path verification; sensor accuracy and guidance timing; spoken input/audio routing; haptic distinguishability; complete record/save/export/delete device trial; accessibility usability; endurance/battery observations; independent installation.
