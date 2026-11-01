# Issue #22 phase B — editable performance takes

Base: `b90ea0f0e9f1b53543953694c90b679b84b4be82`. Spec: issue #22 phase B.

## Design and implementation plan

Extend the existing Spotlight preparation/stop path and stage board. Capture is opt-in before Prepare, not automatic and not microphone recording. Retain one temporary take per player containing only completed bars of the accepted sequence/mute timeline. Keep as Draft appends ordinary copied sequences, isolated track/kit copies and a new SongArrangement draft in one validated transaction. Original music is never overwritten; the import is one ordinary undo operation. Failed conversion leaves both the workspace and temporary take intact.

- [x] Implement bounded capture and conversion with an event-level round-trip guard.
- [x] Wire preparation, stop/interruption, temporary ownership, discard and keep transactions.
- [x] Expose opt-in capture, recording state, retained-take status and explicit confirmations in the stage UI.
- [x] Review data/permission/lifecycle/limit paths and the source diff.
- Delivery verification: compare uploaded hashes and commit scope, then guarded main update/read-back; the issue receipt records these results.

Rulings: reuse profile/music schema and limits; no dependencies, new audio engine, RemoteEvent, tests or CI. Follow AGENTS.md's no-test-suite instruction and user-local build/asset boundary. Source/static inspection does not establish runtime, listening or hosted durability. New UI uses existing native widgets; no asset production or import.

## Connected flow

At the existing stage board, select Spotlight and explicitly enable CAPTURE before Prepare. Practice and Full Song remain unchanged and reject a capture request instead of silently altering their meaning. The prepared queue state and active performer surface identify capture; listeners cannot enable, consume or discard the performer's take.

The source project is pinned at preparation, alongside the existing resolved musical sources. For a Finished Song this is its actual saved immutable project/draft, never the current mutable editor. Compatible sequence alternatives share that same pinned source project. Source settings changed later in the editor cannot leak into a retained take.

On natural finish, Stop, range exit or focus-loss leave, the server retains only completed bars. A partially played final bar and all later queued changes are excluded; a cancelled transition is absent from the accepted timeline. Stopping before one whole bar produces an explicit no-take result. One temporary take is retained per profile; another recording is refused until it is kept/discarded. Performing with capture off remains possible and does not replace it.

The temporary recording is **session-local and not saved**. Its card states that leaving the server loses it. It survives leaving/reopening the stage during the same session. The existing profile save whitelist does not serialize the temporary performance object. No hidden autosave, raw-audio file, external recorder or new persistent music format is introduced.

KEEP AS DRAFT and DISCARD TAKE use five-second two-press confirmation. Confirmation is bound to take ID, project ID/revision, edit version and workspace generation. Workspace changes, timeout, window focus/text focus, panel/ScreenGui hiding and viewport resize cancel it. The server rechecks identity and refuses management while the player is performing/listening or holds a prepared queue entry. Existing nearby/living-player, ownership and request-rate gates apply. Keep also waits for any in-progress save. Duplicated Keep packets cannot create duplicate drafts.

## Conversion and preservation

`PerformanceTake.capture` retains a bounded completed-prefix schedule, immutable source project, source references and accepted bar/mute timeline. `materialize` is a pure transaction over clones. It walks sequence boundaries/repeats, groups consecutive source bars with the same layer mask, and creates ordinary copied sequence sections. Repeated identical variants reuse a sequence reference; adjacent repeats collapse into the normal Song step repeat count.

Copied sections retain original absolute pads, raw note data, source mutes and sample settings. Performance layer mutes become ordinary copied-sequence pad mutes rather than deleting notes. Kits and tracks used by the take are cloned under new IDs, so later sound edits in the take do not overwrite the source kit. The full 64-pad program and its pack/version metadata are copied, not rebuilt from a substitute palette. Provenance is optional `takeSource` metadata on ordinary sequence/draft objects; root profile/music schemas stay unchanged.

Track and event ID ordering is deterministic so simultaneous hits retain their order after ID remapping. Current global solo state is not toggled on existing tracks. New tracks inherit the current solo predicate, while captured source solo/mute intent is explicit in each copied section. Original sequences have no notes on these new tracks; their immediate playback is unchanged. Global track solo remains global under the existing workstation contract: subsequent deliberate mix changes can affect which tracks are heard.

Before installation, the normal MusicTransport resolves the proposed Draft. An internal safety guard compares duration/bar count and every ordered event's tick, time, sample ID, pad, velocity, duration, settings, pan and remapped track/program identity against the retained performance. Any mismatch refuses the entire import. This is implemented runtime validation, not a report that a replay test ran here, and it does not prove acoustic output.

`PerformanceTakeSession` then validates the complete proposed profile with the existing capture/byte gate. Only after all checks does it activate the new selection and append one bounded Undo snapshot. Existing source sequences, programs, tracks, drafts, Finished Songs, archives, recovery and earned progress are preserved. The import creates no Finished Song and performs no storage call. It is one Undo operation; Redo restores it through existing history logic. The retained-take slot is consumed only after successful installation.

After Keep, leave to the normal instrument and open SONG: the imported draft is selected. Review/edit/play its beginning, development and ending; name it and Save through the existing controls. Finishing remains an explicit separate action. Receipt wording distinguishes an unsaved imported draft, a session-only saved draft, and a storage-acknowledged draft. An import removed by Undo is identified as absent rather than falsely offered as saved.

## Bounds and failure behaviour

Reuse the existing Spotlight maximum of 24 bars, four pinned sources, steady-tempo requirement, project/track/kit/sequence/draft/event/step/repeat/byte limits and root profile budget. There is no arbitrary FX automation, microphone recording or tempo-change recorder. Source pad effects already present at preparation are preserved in the copied kits.

Conversion needs space for isolated copied tracks/kits and sections. A full workspace, unavailable required source, pending save, stale request, exceeded byte/event budget or resolver mismatch leaves the current workspace and retained take unchanged. No partial import, silent shortening, asset replacement or automatic deletion makes room. Copies whose optional note-duration field exceeds the existing sequence model's cropped-section duration bound are explicitly refused, with the complete take retained; the converter does not silently truncate that intent. Ordinary one-shot pad events do not acquire artificial duration fields.

Runtime state uses the current profile lifetime, so it is released with the profile on disconnect. No cross-player take map or take contents are broadcast. The stage summary sends only the requesting player's bounded metadata and confirmation context. A capture failure produces explicit status rather than claiming a saved take.

## Files

- `src/shared/PerformanceTake.luau`: completed-prefix capture, segment/copy/repeat conversion and event-equivalence guard.
- `src/server/PerformanceTakeSession.luau`: arming, retention, status projection, identity-checked Keep/Discard and atomic undoable admission.
- `src/server/ListeningSession.luau`: opt-in preparation, pinned source attachment and retention at normal stop/interruption.
- `src/server/StageQueue.luau`: existing stage authorization/queue guards and private take status/commands.
- `src/client/StageView.luau`: capture option, in-set indicator, temporary/imported status and guarded Keep/Discard controls, using existing native widgets/scroll layout.

## Verification boundary

Reviewed source control flow, ownership, copy isolation, segment/repeat mapping, simultaneous event ordering, save/history integration, optional duration limits and confirmation lifecycle. The three edited baseline files were reconstructed locally and all matched the exact live Git blob hashes before modification: ListeningSession `fbc956d2b9be25fc1f8cf138e7d6d979f4e64be2`, StageQueue `c0d9431213f515645476d24bb2df826b9178bfe1`, StageView `b43078dcca6177bb41fbe8cc02bac1f0b166e9a7`. Local `git diff --cached --check` is the whitespace gate; uploaded hashes, commit scope and main read-back are checked at delivery. No independent subagent review is available in this session.

Not run: test suites, Luau compilation/lint, Studio builds, actual playback/listening, physical-device/multiplayer tests, live DataStore calls, hosted rejoin or novice observation. Repository instructions reserve tests unless requested; the pinned Rokit/Luau/StyLua tools are absent and direct container DNS to GitHub failed. No substitute compiler, dependency, CI, asset upload, Experience publication or production-profile write is introduced. These changes implement the code path, not acceptance evidence.

## Local acceptance — no programming handoff

1. Enable capture on a personal Spotlight; mute/reinstate layers, switch pinned sequences, cancel a queued change, finish and Keep. Inspect the new Draft's copied sections/repeats and exact source events/settings before and after. Compare replay through normal Song Mode.
2. Stop in the middle of a bar, at a boundary and before the first complete bar. Only completed accepted bars should remain, with partial/excerpt and temporary wording. Later queued changes must not appear.
3. Edit source kits after preparation, and record an excerpt from a saved Finished Song while the live editor differs. The Draft must follow the pinned source, not subsequent editor values. Include same-tick repeated/choked sounds, multi-track gain/pan and source/target solo/mute combinations.
4. Keep, Undo, Redo, rename, edit a copied kit, Save, leave and reopen. Source sequences/kits must remain independent; the take remains a Draft until deliberately finished. Verify the actual session/cloud boundary separately.
5. Fill track/kit/sequence/draft/event/byte budgets, use unavailable audio, long optional note durations, stale or duplicate requests and edit/save contention. Failure must preserve both workspace and retained take. Discard must remove only the temporary recording.
6. Reopen the board with a retained take; perform again with capture OFF and verify it remains. Verify a new capture cannot silently replace it. Test other players' spoofed IDs, range/death/disconnect, focus loss, rotation, hidden screens and expired confirmation.
7. On target phone/controller inspect the new status/confirmation controls, scrolling and uninterrupted Sound/Leave access. Observe replay/re-edit behaviour separately from source validation.

Phase B's code is implemented by this batch; #22 remains open for actual phase A/B playback, usability and local/hosted acceptance evidence. Source code and an accepted Git commit are not a 100% runtime-completion claim.
