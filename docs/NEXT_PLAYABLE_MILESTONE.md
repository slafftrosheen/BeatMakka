# Four patterns, a beat shelf and Mica's first courtyard set

Implementation plan and design, 23 October 2026. User-approved continuation of the existing first-zone game. Base: `dc898d887e5f147d95e728040a20a035a1e24c08`, retaining the uncommitted audio/content patch.

## Goal and constraints

Give one visit a complete personal journey: meet the helper robot, discover the quay, compose variations, save a beat, and perform it at the existing courtyard. Follow the approved style board at `assets/references/needle-quay-approved-style-board.png`: teal/cream equipment, restrained amber feedback, coral details and substantial wood. Keep the exact sixteen physical pads, existing canonical asset IDs, independent collision and opt-in listening.

The initial implementation pass was source-only. The user subsequently explicitly authorized Studio MCP testing, fixes, commit and push of all pending changes; see [Studio verification](MILESTONE_VERIFICATION.md). No new dependencies, provider calls, upload IDs or production publishing are included. Audio/content readiness work and its fourteen image bindings remain intact.

## Architecture and behavior

- `BeatBook` owns four independent sixteen-pad/sixteen-step patterns, active-slot selection, bounded shelf snapshots and validation. Each slot retains its own BPM, assignment and mute state. Selecting a slot stops transport/recording; switching never erases another slot. Public state retains the current `pattern` projection for the existing instrument/audio interfaces.
- Six personal shelf positions hold an entire four-slot project, with fixed native UI labels Beat 01–06. No arbitrary player text or public naming/moderation system is introduced. Saving to the selected shelf position captures a deep snapshot and saves the profile. A failed cloud write keeps the local work dirty and says so. Replacing an occupied position and loading a beat require a second explicit click; shelf versions reject stale overwrite/load commands. Loading replaces working slots, stops transport and leaves other shelf positions untouched.
- `ProfileStore` reads existing schema-1 saves into slot A and three empty slots; schema 2 stores the slots, active slot, shelf and quest flags. Keep the existing DataStore namespace and revision checks. Unknown schemas, failed reads and malformed revisions cannot be overwritten. Restore restores working slots/finish while retaining acquired discoveries, shelf work and earned quest progress; dirty state reflects preserved changes.
- `FirstPerformanceQuest` derives objectives from server-owned profile/saved shelf data. Mica reuses H04; a separate F/Y talk prompt avoids the existing I03 discovery interaction. Accept → collect I01/I02/I03 → save a beat with an unmuted discovery-sample note → perform that saved pattern for one complete sixteen-step loop. Any populated slot can be the performance pattern. No spectator, popularity, effects, mute or audio-fetch result is a story gate.
- `ListeningSession` exposes optional server lifecycle hooks and a first-full-loop observation. Eligibility is captured at session start and rechecked at completion. Stopping, leaving range, respawning or disconnecting before the bar finishes cannot complete it. Quest completion is personal, queued for one save attempt, and remains visibly dirty if persistence fails.
- `BeatBookView` supplies native responsive slot/shelf controls in the existing cream workstation. Current objective appears in the HUD and workstation; the listening panel displays the eligible performance goal. Gameplay text stays out of textures. Existing sound/effects/leave controls remain usable.

## Tasks

- [x] Add bounded shared book and quest models, plus schema-1 migration and schema-2 persistence.
- [x] Integrate validated slot/shelf commands, Mica interaction and server-observed performance completion.
- [x] Add slot/shelf/quest UI and personal completion feedback; preserve the audio patch and exact 4 x 4 controls.
- [x] Review source changes and whitespace, document controls and migration. Subsequent authorized runtime verification is recorded separately.

## Controls and save compatibility

Choose A–D using the workstation's pattern buttons; instrument letter shortcuts remain pad controls. Select Beat 01–06, then Save to shelf. Occupied replacement and loading use a five-second second-click confirmation. Loading stops transport and replaces working slots only. Save profile stores all current personal state; Restore slots retains shelf work and acquired quest/discovery progress. Unsaved retained changes remain dirty.

Talk to Mica using F / gamepad Y, collect the three sounds, assign a discovery sound to an enabled unmuted step, then save to the shelf. Perform that exact saved pattern at the courtyard podium for a complete loop. Other slots may contain variations. Studio uses session-only storage; published cloud persistence is not verified by the source implementation.

Schema 1 is read into A with B–D empty. The next successful save writes schema 2 to the existing namespace, including a legacy current-pattern projection. Older servers reject schema 2 and cannot edit it; a rollback needs a deliberate migration strategy, rather than restoring older source and assuming full compatibility.

## Source review record

A separate read-only source review covered slot isolation, shelf snapshot/version handling, migration, restore preservation, save concurrency, quest ownership and UI commands. It found a completion timing edge between one-second updates. Completion now uses a session-bound deadline callback and reconciles elapsed completion before stopping, with server-time, distance/alive and eligibility checks. Selected shelf positions also have a textual marker.

Project-pinned StyLua formatting and whitespace inspection were performed in the initial source-only pass. Its later user-authorized tests and fixes are recorded in [Studio verification](MILESTONE_VERIFICATION.md); earlier runtime evidence alone does not validate this schema or these controls.

## Review focus / future authorized verification

Independent slot edits and BPMs; shelf snapshot isolation; stale/duplicate shelf requests; failed or overlapping saves; legacy/future/corrupt saves; restore with newly acquired progress; mixed loaded/denied audio; no audience and muted performance; interrupted/restarted performances; another player's quest isolation; portrait/landscape text wrapping, focus and overwrite confirmation; migration rollback and rejoin persistence.

## Delivery boundary

Studio-simulated behavior is covered by the subsequent verification record. Audio uploads/permissions, persistent mesh imports, final rig/atlas art approval, physical-device behavior and live cloud persistence remain separate acceptance steps. No canonical asset stage is promoted by this milestone.
