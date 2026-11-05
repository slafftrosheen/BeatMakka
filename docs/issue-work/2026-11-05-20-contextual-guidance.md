# Issue 20 — contextual companion guidance, 5 November 2026

Source implementation extends the existing optional companion path. Alissia and Nikolas keep their canonical identities; Alone remains the default. This batch changes six companion modules, the client affordance whitelist and the existing text-only voice-hint projection, with no assets, new dependencies, save schema, reward rules or musical engine.

## Implemented

- Companion advice now reads the server's actual named sequence/track/program, First Groove marker, selected Draft and successfully saved Finished Song. Current Music distinguishes a pinned playing/paused transport snapshot from later editor selections. It reports recording, queued transitions and current save/session/unavailable state.
- Six explicit advice topics (Current Music, Next Sound Hunt, Selected Sequence, Selected Draft, Selected Finished Song, Quay Route) are offered in the existing People journal. Topic navigation is session-only, uses the existing independent companion limiter and changes no profile edit version or musical selection. Unknown topics and extra payloads are rejected.
- Next Sound Hunt comes from the existing authoritative NeighborhoodMissions summary. It reads canonical I01/I02/I03 collection, actual catalogue playback readiness, selected-track pad address and source origin. There is no invented second quest state and no claim to mirror RecorderGuide's client-only source tab.
- Sequence advice explains A–D sample banks, independent named sequences, copied variations/shared track kits and Song Mode. First Groove advice recognizes the actual starter object. Draft and Finished advice distinguish developing arrangements, deliberate Finish, full playback and short Spotlight/take drafts.
- Removed the companion's separate fixed four-metal/fixed-I03-rhythm script. Route detail and existing text-only metal/chirp voice cues now consume the authoritative QuayObjectives definition, while musical discovery advice consumes NeighborhoodMissions. Optional echo is described as retryable/skippable practice and never an award or creative gate.
- The projection cache now follows workspace replacement/generation, project revision, selected objects, active transport, bank, playback/recording, pending transition, collection, mission and save state. Changing context returns to the gentle first hint; more detail still requires a request. Hints remain dismissible.
- Alissia's notebook reports actual source provenance, current selected-track address and truthful collected/unavailable/local-preview/approved state, including explicit Studio substitutes. Nikolas retains saved-only observations. Notebook caching follows project/track changes without changing its saved-progress authority.
- Restored follower focus guards for the instrument, listening/stage/concert/jam surfaces and the journal. A hidden follower resumes as the same one selected local companion after leaving the surface. No collision, audio, progression or rig/art status changes were introduced.

## Source review and boundaries

Inspected the existing CompanionCatalog/Progress/Journal/Service/View/Follower, FirstGroove, SoundHunt/DiscoverySession/RecorderGuide, music workspace projection/selection, save state, route objectives and the existing journal lifecycle. Reviewed the changed source and ran scoped `git diff --check` successfully. No tests, Luau compilation/lint, Studio builds, runtime/input/listening checks or hosted persistence were run. No commit/push, uploads/publication, generation or paid work was performed.

The existing journal is hidden while an instrument/performance surface is open; selected-object guidance is available by reopening People afterwards. Current Music labels a retained transport snapshot separately from selected-object topics. The source-only implementation does not certify hint comprehension or physical layout.

## Acceptance still requiring the user's later run

1. With Alone and each companion, create/edit/copy/save/reopen the same music; switching hints/topics/assistance must leave notes, selected music, rewards and progress unchanged.
2. Check each topic with a starter, another sequence, a selected Draft, a saved Finished Song, and a different pinned playback snapshot; names, readiness, save status and next Hunt must remain current.
3. Try I01/I02/I03 before collection, after collection, after reassignment to another pad and with unavailable audio. Confirm source names, bank/pad addresses and optional echo messaging match the actual interaction.
4. Verify requested escalation/reset, Hints OFF, invalid/burst commands and cleanup, including Roamer travel, respawn and each performance mode.
5. Review phone/tablet/gamepad text/layout, character rig/animation/LOD delivery and visual approval separately. Character candidates remain candidates; this code does not promote art or establish actual destination loading or cloud rejoin.
