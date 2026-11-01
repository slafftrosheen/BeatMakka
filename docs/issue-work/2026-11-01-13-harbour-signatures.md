# Issue #13 — musical harbour signatures and chapter integration

Base: `51cd5fc18ea6bd373d7a746534f377bf96060584`.
Spec: #13, using the existing #22 accepted schedule and chapter playback.

## Design and execution plan

Extend WorldFeedback and ConcertScene with one shared, read-only schedule evaluator and a bounded native presentation component. Do not add a music clock, reward service, audio player, generated asset or saved schema. The alternative of timed cutscenes was rejected because it cannot follow mutes/cancelled transitions. Rebuilding the concert was rejected because its full-song traversal and server reward guards already exist.

- [x] Derive percussion, helper-answer and returning-layer signatures from accepted events and explicit tempo segments.
- [x] Render those cues on existing venue/helper targets; keep captions readable and motion optional.
- [x] Connect public opt-in listening and the existing chapter scene; clear on pause/stop/leave/teardown.
- [x] Replace time-only chapter presentation cues with musical evidence without changing earned progression or full-song eligibility.
- [x] Review source integration and inspect the local diff/whitespace.
- Delivery: the guarded main update and read-back are recorded in the issue receipt after publication; this document is not runtime evidence.

Ruling: preserve the user's code-only/no-test-suite workflow. No tests, Studio builds or replacement toolchains are run. Runtime/device/audio acceptance remains explicitly unobserved. All code in this scope is implemented here, not delegated locally.

Ruling: this batch reuses existing tagged scene objects and native adornments only. The user's Windows asset folder is not accessible from this environment; no visual source asset is generated, imported, changed or promoted.

## Implemented contracts

`src/shared/HarbourSignatures.luau` compiles a read-only scene index from the resolved MusicTransport/StreetSet schedule. Bar boundaries come from explicit tempo segments, so full Songs with tempo changes are not treated as constant-tempo music. Role classification reuses StreetSet and the actual sample catalogue, not the currently visible bank. Muted or unavailable notes are already excluded by the accepted playback resolver; nonpositive velocity/gain is excluded again. No event, sample assignment, source revision, volume or save marker is written.

Three optional signatures are implemented:

- Percussion produces restrained glow pulses on the nearest existing dock/venue target. Visual pulses are limited to one per 0.32 seconds; this does not quantize, throttle or remove audio notes.
- I03 (including its explicitly labelled local binding) answers an earlier non-helper note in the same or preceding bar. Simultaneous notes alone are not a call/answer. The helper glow lasts up to 0.6 seconds, with at most one new visual response every 0.75 seconds. Nothing plays a synthetic reply; the response follows the player's scheduled helper note.
- In the last third of a finite arrangement, a return to at least three musical roles after a lighter bar produces a restrained venue accent. Both a rhythm role and a hook/harbour role must occur. The cue waits until the qualifying roles' actual first notes have occurred, and qualifying accents are separated by at least four bars. Reaching a timestamp alone cannot trigger it. Practice loops can repeat the same musical response on later cycles; there is no completion counter or reward to farm.

Different rhythms work: percussion at 1/7 or 4/13 can drive the dock; an earlier drum/bass/hook followed by I03 at different positions can drive the reply; several combinations of three/four returning roles can drive the venue. These are structural presentation rules, not music-quality judgements. Future-only performance edits and cancellations are reflected by rebuilding the scene index for the accepted scheduleRevision, retaining the identical prefix. There is no callback queue that can replay an obsolete future cue.

`src/client/HarbourFeedback.luau` is a presentation component of the existing WorldFeedback and ConcertScene, not another reaction/audio service. It maintains at most three native Highlights and one explanatory BillboardGui per active component. Duplicate fallback targets share one enabled highlight. It never changes the target's Color, Material, existing lights, restoration flags or profile. Existing podium geometry is a fallback when a dedicated lamp/helper is absent; this is not a replacement character or audio source. Captions explicitly identify NPC feedback. Effects OFF disables glows and keeps a static textual explanation.

Public-listening placement uses the existing QuayPublicBeat coordinates only when its epoch and startedAt match the accepted listening packet. A late old attribute cannot attach new music to the previous venue. Chapter placement uses the authoritative podium position added to ConcertService's projection. Target discovery is streamed and distance-bounded; candidate scanning happens when the presentation is attached, then relevant additions/removals invalidate selection. Missing streamed targets suppress adornments until usable targets arrive. No generated geometry, texture, audio or imported asset is required by this component.

`WorldFeedback` handles only the local player's opted-in listening packet; it suppresses that presenter while the personal chapter panel owns the scene. All opted-in listeners compute the same musical cues from the accepted schedule/time, independently of their personal audio mute. This is schedule evidence, not proof a device actually loaded or emitted sound. The existing QuayPublicBeat/QuayNeighbors nearby-NPC path from #22 remains unchanged.

`ConcertScene` uses the same cues for its existing H04 stand-ins. Crew motion follows percussion pulses; Mica follows helper replies. Pause, silence, ending and reduced effects settle the actors to their base poses. The old independent os.clock dance and shared base-colour/material writes are removed. Temporary crowd/effects are removed whenever the panel closes, even if legacy checkpoint/completion history is retained. Stand-in captions are labelled NPC; this is not final character-art approval.

`ChapterConcert.summary` exposes compact scene evidence and replaces time-only cue/reaction descriptions with musical evidence. The six existing presentation phase labels remain in `phase`. Chapter.start/tick/act, eligibility, source-snapshot selection, full-song duration, pause/resume clock, earned ledger and ConcertService's idempotent completion write remain unchanged. Closing a completed chapter does not erase completion. No signature is a new completion prerequisite.

## Lifecycle and verification

The presenter owns its connections/adornments and removes them on Stop/Leave, chapter Pause, scene replacement and instrument-screen destruction. It samples synchronized time directly; late joining or a stalled frame shows the current cue without playing a backlog. It does not stop or duplicate one-shot tails. Full-song scene cues end at musical duration; the existing audio tail/completion deadline is unchanged.

Source review checked require dependencies, normal and variable-tempo boundaries, simultaneous helper/call ordering, scheduled future-only changes/cancellation, streamed/missing targets, reduced effects, pause/resume/close and retained completion. The four edited pre-existing files were reconstructed locally and their baseline Git hashes exactly matched the live remote blobs before modification. `git diff --cached --check` is the static whitespace gate. Uploaded blob hashes and the remote branch are verified at delivery. No independent subagent review was available.

Not run: test suites, Luau compilation/lint, Studio builds, actual audio, physical input, multiplayer runtime, novice observation, live DataStore calls or hosted rejoin. The pinned toolchain is not installed here; direct container DNS to GitHub failed. No substitute compiler/dependency/CI was installed. No runtime, perceptual, accessibility certification or final-art approval is claimed.

Official API references consulted for the reused presentation/time primitives:
- https://create.roblox.com/docs/reference/engine/classes/Highlight
- https://create.roblox.com/docs/reference/engine/classes/BillboardGui
- https://create.roblox.com/docs/reference/engine/classes/Workspace

## User-local acceptance — no remaining programming handoff

1. Start an Alone-mode Spotlight with a percussion/hook/bass/harbour source. Queue a drum mute and cancel it, then commit a drum mute. Glow/crew response must track the accepted notes at the scheduled boundary, not the button press. Confirm no source events/save revisions change.
2. Use at least two different call/reply rhythms with I03. Same-time-only hits must not imply a prior call; muting the helper removes its reply. Verify current local binding labels and listen separately from visual timing.
3. Arrange a lighter bar followed by three/four returning roles late in a Song. The venue cue must wait for the relevant first notes. A late timestamp alone, muted parts or a silent final bar must not qualify. Try two substantially different rhythms/role combinations.
4. Run the existing chapter beginning-to-end, pause/resume across a reply or climax, interrupt, retry, finish, close and reopen. Confirm exact Song duration, unchanged reward/save semantics, no wall-clock dance during silence/pause, and no leftover crowd after close.
5. Join the same public set with two opt-in clients, mute one listener's personal audio, cancel a queued transition and test late join/stalled frames. Both visible cues must follow the same accepted schedule; this is not a promise of measured acoustic synchronization.
6. Toggle effects off/on. Verify static explanatory text remains, highlights stop, base materials/restoration remain unchanged and no old pulses are replayed when effects return. Inspect caption occlusion/readability on the target phone.
7. Exercise streaming-out/in, missing dedicated lamp/helper targets, venue switches, focus-loss leave and instrument destruction. Confirm bounded adornments, detached signal cleanup and no previous venue receiving a new set's effects.
8. Reopen an already-completed legacy profile. Completion/history must survive; scene signatures must not require replaying the chapter or add a new gate. Hosted persistence remains #10's separately authorized acceptance.

Issue #13's three selected signatures and chapter presentation integration are implemented in code by this batch. Its actual visual/audio/multiplayer/comprehension acceptance remains open. #22 phase B take-to-Draft-Song capture remains subsequent code work, not delegated to the user's asset/build pass. No Roblox upload, publishing or production-profile mutation is performed.
