# Needle Quay — MPC workflow replacement, revision 3

**User-directed implementation contract, 30 October 2026.** This supersedes the revision-1 instruction to retain four fixed pattern slots. It is a work order for the local Codex agent, which has the user's current uncommitted project. The supplied experience source and patch are comparison inputs; they do not already implement this replacement.

## 1. Required outcome

Implement one coherent music-making system across the entire game:

**64 sounds on four pad banks → tracks → reusable named sequences → Song Mode arrangement → explicitly finished, saved song.**

A/B/C/D are exclusively **sound-bank labels** in ordinary instrument operation. The old fixed A/B/C/D pattern controls and four-pattern save container must be replaced. Renaming those controls to Pattern 1–4 does not satisfy this request. A fifth sequence must be a normal supported operation, and a saved loop must never masquerade as a finished song.

Use a classic MPC-inspired sequence/Song Mode workflow with consistent track routing. Akai's classic MPC1000 uses four banks of 16 pads; current MPC generations can expose more banks. Four banks here are the user's deliberate 64-sound design. Do not claim exact MPC3 parity, an Akai-compatible project format, or that modern MPCs are limited to four banks. Official references are at the end.

The independently commissioned Flow Music demo remains a production reference for the first sound pack. It is not the player's authored song and cannot complete their musical quests.

Revision 3 retains the sequence/Song Mode architecture and incorporates the vocal first-pack direction. A–C keep their proposed roles; Bank D contains twelve harbour sounds and four reserved vocal one-shots at D13–D16. The first-pack contract governs these pending sounds. A vocal sample uses the same pad, event, save and approval model as any other one-shot; it does not introduce microphone capture or require the player to sing or use vocals. The approved full demo and any stems remain outside the 64-pad runtime instrument.

## 2. Vocabulary and object boundaries

| Object | Definition | What saving it means |
|---|---|---|
| **Sample** | One actual approved one-shot and its metadata. | Preserves the source sound; it contains no player's note arrangement. |
| **Kit / Program** | Exactly 64 pad definitions, each with a stable sample reference and playback settings. | Preserves mapping, trim, pitch, gain, envelope and choke intentions. |
| **Track** | A stable instrument/part routing identity used by sequence events. | Preserves the part's kit routing and mixer settings. A pad is not a track. |
| **Sequence** | A named, reusable musical section with length, timing and events on tracks. It may loop while being edited. | Saves an editable musical idea. It does not create a song. |
| **Song draft** | An ordered list of references to sequences with repeat counts. It may be incomplete. | Saves the arrangement in progress. |
| **Finished song** | An explicit, successfully saved, reproducible revision of a finite arrangement and all the musical data it depends on. | Creates a song-library item that can be performed from beginning to end. |
| **Project** | The editing workspace containing kits, tracks, named sequences and song drafts. | Preserves work in progress without claiming any of it is finished. |

Use **Sequence** as the main instrument term, with the beginner hint “a section you can repeat.” A loop describes repetition or a reusable idea, not a different hidden four-slot data type. Use “Song draft” and “Finished song” as distinct library states. “Beat” can remain informal dialogue; it must not remain an ambiguous storage container.

The wardrobe's three outfit presets and the logic side activity's internal `pattern_bench` ID are unrelated. Do not remove or migrate them as musical patterns.

## 3. Four sound banks, everywhere

Keep 16 physical pads. Resolve their input to an absolute program-pad address:

```luau
absolutePad = (bankIndex - 1) * 16 + physicalPad
-- bankIndex: 1..4; physicalPad: 1..16; absolutePad: 1..64.
```

The address pairs are A01–A16, B01–B16, C01–C16 and D01–D16. The same absolute address must mean the same program pad in the editor, recording, automation/settings, playback, jam, listening, saved music and concerts. Names and page positions must not become identity keys.

Changing the sound bank changes the visible/input page only. It must not select a sequence, alter the song step, replace a kit, reset the playhead, clear notes, remove a required audio voice or silence hidden-bank notes. A track may play any of the 64 pads; bank A is not track 1 and bank B is not track 2.

Capture absolute pad identity at the moment of input. A delayed tap made on B03 must not be remapped through bank C because the player changed banks before the server handled the tap. Capture the relevant project, sequence, track and transport epoch too. Validate those identities server-side.

Preserve the established physical grid orientation for existing controls. Do not reorder pad numbers to imitate a different hardware drawing. Show the full address, such as **C07**, in pad editing and event inspection. Physical world feedback projects the appropriate visible-bank pad, while audio and saved events retain absolute identity.

## 4. Kit and track model

Separate the sound definition from the notes that trigger it. Do not keep a different hidden 16-sound assignment table inside every new sequence.

- A Program owns 64 pad definitions. A definition contains an approved stable sample ID or an explicit empty/unavailable reference, plus supported `PadSound`-equivalent settings.
- A Track has a stable ID, a human-readable name, a program reference and mixer state. Track identity/routing stays consistent across sequences in the project.
- A Sequence stores timed events for those tracks and any explicit per-sequence mute state. Selecting a sequence does not silently reroute track 1 to a different kit.
- Several tracks may use one Program. Editing a shared Program affects the editable sequences using it; the UI must make that sharing apparent and offer Duplicate Kit when independent edits are wanted.
- Alternatively, a coherent existing local implementation may use MPC3-like track containers owning their program data. Preserve the same separation between sound definitions and sequence events, and the same stable routing. Do not introduce both models as overlapping authorities.

Start the beginner workspace with one clearly named drum/sample track. Additional tracks are normal musical parts, not required chores. Suggested names such as Drums, Bass, Melody and Harbour are editable conveniences; they do not restrict which banks a track may use.

A track's mute/solo and a pad's settings are separate controls. Store sequence-specific track mute overrides separately from the project track mix. Preserve pad mutes explicitly as `trackPadMutes[trackId][absolutePad]` (string pad keys in JSON/wire maps, absent entry means false); do not delete a muted pad's events or replace mute with gain zero. This state is separate from `track.mix.muted` and Program sound settings and must be copied into Finished Songs. Route effects by the actual track/program/pad identity, not by the visible physical pad index. A01 and B01 must not share settings accidentally. The finalized snapshot preserves the chosen routing and mix.

## 5. Sequence mode: make and develop loops

Provide the following working operations, wired to the real engine:

| Operation | Required behavior |
|---|---|
| New / Rename / Duplicate Sequence | Stable new IDs; duplication preserves content and creates an independent editable variation. Names do not identify the underlying object. |
| Sequence selector | A named collection, not four slots; create and reopen a fifth and later sequence normally. |
| Length | Set musical length in bars. Default 4 bars for new ideas; shorter and longer sections are supported. A 16-step view is a page of the sequence, not its entire storage limit. |
| Tracks | Select a part, add a track, name it, choose its kit, mute/solo and adjust supported mix controls. |
| Record / Overdub | First recording and additive recording are visibly distinct. Neither operation silently erases existing music; destructive replacement/clear is explicit and undoable. |
| Play / Play Start / Stop | Play resumes the supported cursor position; Play Start begins at the section start; Stop ends transport predictably. |
| Count-in / Metronome | Clear on/off/record-only behavior; click is not recorded into the player's composition. |
| Timing Correct | Quantization choices, including straight and triplet divisions where implemented; retain a clear Off choice for live timing. |
| Swing / Note Repeat | Musical timing controls, not visual switches. Record generated repeated hits using the same event path. Avoid double-quantizing or applying swing twice. |
| Velocity / Full Level | Preserve editable event velocity. Mouse/touch input uses an honest default or explicit level control; do not claim pressure sensing that the device does not supply. |
| Grid / Event edit | Page through bars, edit events and velocities on any pad bank; keep recorded off-grid events unless the user requests quantization. |
| Double / Copy / Clear | Duplicate an idea to extend it, copy musical material, and clear only the selected scope. Preserve undo. |
| Undo / Redo | Covers musical edits, sequence edits and song-step edits with bounded history. Undo is not a DataStore rollback. |
| Save Sequence / Save Project | Saves editable material and shows truthful saving/saved/error state; does not create a Finished Song. |

Use integer musical ticks. Proposed contract: 960 PPQ, 4/4 default, 3,840 ticks per bar, with sixteenth-grid positions 240 ticks apart. Event ticks are zero-based integers in `[0, bars * 3840)` for that meter. Velocity is an integer from 1 to 127; Full Level is 127, and zero is not an audible note-on. This is storage resolution, not a claim about measured playback precision. Keep the first demo at 4/4 if needed, record that scope explicitly, and reject unsupported meters without reinterpreting the data. Preserve per-sequence BPM and a tempo map where conversion requires it.

Avoid a giant dense matrix of empty booleans for every track, pad and bar. A sparse event list can store `{eventId, tick, pad, velocity, durationTicks?}` per track. One-shot playback does not automatically become a gated sustained instrument because a duration field exists. Event order and same-tick tie-breaking must be deterministic. Shortening a sequence must make any removed musical material explicit and recoverable through undo/import backup; a sanitizer must not silently discard events beyond a newly chosen end.

## 6. Next Sequence: live improvisation

Sequence mode also needs a clearly identified live-launch view:

- Show **Playing** and **Queued next** separately.
- Queue a named sequence for the end of the current sequence by default.
- Allow cancelling the queued choice and holding the current sequence.
- A Next Bar transition is useful when explicitly selected; it must not be an accidental immediate jump.
- Selecting a sequence for editing and queuing a sequence for performance are different actions.
- If the 16 pads are temporarily used as sequence launchers, show a prominent **Sequence launch** mode and numbered pages. Do not reuse A/B/C/D as sequence-bank labels. Returning to normal pad play restores sound-bank controls.

This is live improvisation. It does not quietly append song steps or create a Finished Song. A separate, explicit capture-arrangement operation may be added if it records the actual sequence choices and repetitions into a draft honestly.

## 7. Song Mode: arrange a complete piece

Song Mode is an editable ordered list of steps. Each step references a sequence by stable ID and stores a repeat count:

```json
{
  "stepId": "step_003",
  "sequenceId": "seq_main_groove",
  "repeats": 2
}
```

**Repeats = 1 means one complete play.** It does not mean one play plus an extra repeat. Removing a step removes a reference; it must not delete the underlying sequence. Renaming or reordering a sequence must not redirect any song step. Deleting a referenced sequence needs a deliberate resolution, such as removing/replacing the affected references; do not silently choose the next sequence in a list.

Required controls:

- New/rename/duplicate song draft.
- Insert, duplicate, move and remove steps.
- Select the sequence and repeat count for a step.
- Show step number, sequence name, repeats, sequence bars, effective tempo, start bar and contributed duration.
- Show total bars and total duration, derived from actual data.
- Play from beginning or audition from a chosen step; show current step, repetition, sequence and bar/beat position.
- Stop at the explicit end. Whole-song looping is an intentional preview setting, off by default.
- Save Draft, Finish & Save Song, and Convert to Sequence are separate operations.

Suggested example:

| Step | Sequence | Sequence bars | Repeats | Contribution |
|---:|---|---:|---:|---:|
| 1 | Harbour intro | 4 | 1 | 4 bars |
| 2 | Main groove | 8 | 2 | 16 bars |
| 3 | Quiet break | 4 | 1 | 4 bars |
| 4 | Main variation | 8 | 2 | 16 bars |
| 5 | Lantern outro | 4 | 1 | 4 bars |

This arrangement contains **44 bars**. The example is an editable teaching shape, not a mandatory genre, duration or aesthetic score.

Editing a sequence changes every reference to it in the **draft** arrangement. Offer Duplicate Sequence / Make Variation to isolate one section. Editing the draft must not alter an already playing snapshot or a previously finished song.

### Tempo

Offer two explicit modes: **Sequence tempo** and **Song tempo**. Sequence tempo follows each referenced sequence's own tempo/map; Song tempo applies a chosen master tempo for that arrangement without overwriting sequence source values. New material may default to the project's chosen tempo. Imported sequences retain their original BPM. Show effective tempo clearly before the user plays or finishes an arrangement.

Derive duration by integrating the actual tempo schedule, not by multiplying every bar by the first sequence's BPM. Tempo changes must not cause a boundary gap or duplicate the first/last event of a section.

## 8. Draft, finished song, conversion and audio export

These must be four distinct concepts in both code and UI:

| Action | Result |
|---|---|
| **Save Draft** | Mutable editing project/arrangement retained for later work. It may be incomplete or have unavailable sounds. |
| **Finish & Save Song** | A new immutable, reproducible song revision with finite playback, committed successfully to the selected storage backend. |
| **Convert to Sequence** | A new editable long sequence with steps/repetitions expanded into a timeline. The song and its source sequences stay intact. |
| **Export Audio** | A real rendered audio file delivered through a functioning supported path. A saved JSON/Luau arrangement is not a WAV. |

For Finish & Save Song, the server must verify the expected draft revision **and the project/dependency revision covering its referenced sequences, shared Programs, track mix, tempo and cover**, as well as owned data, finite bounded arrangement, real admitted audio for audible events and at least one audible event. Editing a referenced sequence or shared Program can change the song without changing its step list; a draft-only revision check is insufficient. Resolve and deep-copy the validated dependency graph without yielding into an inconsistent view. Freeze the arrangement order, repetitions, referenced sequence revisions/events, track routing, kits/pad edits, mix, tempo schedule and cover metadata. Do not store only mutable references and call the result finished.

Save the snapshot first; show **Finished song saved** only when the actual backend has accepted it. Bind an idempotent finish request to the exact resolved revision so retries cannot create duplicate songs. If the player edits while saving is in flight, the accepted older snapshot may be finished while the newer draft remains dirty; do not mark the newer draft finished. During an error, retain the complete draft and allow retry. An explicitly session-only Studio backend may say **Finished song — saved for this session**; never describe that as durable cloud persistence.

Reopening a finished song for editing creates an editable copy or a new draft revision. Subsequent finishing creates a new immutable revision. Existing concert/listening references keep their pinned revision. Saving a sequence, saving a project, attaching a sleeve, importing an old shelf bundle or retaining an old Q12 completion flag must never create a Finished Song implicitly.

Convert to Sequence must preserve expanded event timing, routing, mute intent and tempo changes. If the current implementation cannot represent a needed tempo map or the expanded length exceeds a budget, refuse the conversion clearly and preserve the song; do not silently flatten it at one tempo or truncate the ending. Implement correct conversion as part of the requested workflow, including a real supported path for the ordinary single-tempo case. Record any remaining multi-tempo conversion limit explicitly.

Audio export is a separate engineering capability. Do not expose a functioning-looking export button, pretend a file was rendered, or use “export” to describe arrangement persistence. The required first outcome here is a complete song that is saved and playable in the game. If a real local renderer already exists, integrate it under its actual capabilities without uploading or publishing anything.

## 9. One transport and event model for the whole game

Use a common resolver/scheduler for Sequence, Song and Finished Song playback. Mode-specific code chooses its source and end/loop policy; it must not implement different pad-number meanings or unrelated timing math.

At playback start, resolve and pin the intended revision. Compute an absolute musical schedule from sequence lengths, repeat counts and tempo changes. Derive cursor state from a server-owned epoch/time anchor and current pause/seek state rather than accumulating frame delta error. Stop or seek invalidates already scheduled events with a new epoch. Define end boundaries as half-open intervals so a tick at the start of the next section is triggered exactly once.

Do not mutate the playing schedule halfway through a step because an editor changed a source sequence. Draft edits take effect on the next explicit start or an explicitly implemented boundary-commit operation. Live Sequence recording/overdub is its own controlled event-update path, not permission to replace an immutable concert snapshot.

Record requests must capture the original sequence, track, absolute pad and transport epoch. Validate ownership, event ranges, permitted sample bindings and timing windows. Rate-limit and bound payloads; keep an idempotent request identity where retries could duplicate notes or song steps.

Don't broadcast the entire sequence library or all finished songs on every tap. Send lightweight editor/transport deltas and library summaries. Fetch a selected object by stable ID/revision and use bounded, versioned snapshots where listeners need musical content. Reject unsupported protocol/schema versions instead of silently interpreting them as 16-pad data.

The existing `Finish` remote action changes a Roamer cosmetic finish. **Use `SongFinish` for finishing a song; do not overload `Finish`.** Likewise keep storage revision, editor revision, saved-object revision, transport epoch and jam generation as separate concepts.

## 10. Audio readiness and resource use

All 64 program addresses must be supported throughout selection, trim, FX, voice routing, scheduling and shared playback. The first pack still contains only 64 unique one-shot assets, even when several tracks use them.

Prepare voices lazily for the complete set of sounds needed by the playing arrangement, plus bounded live audition. The current four-voices-per-selected-sample scheme must not grow blindly into 256 personal voices. Use explicit configurable polyphony and effect budgets, with documented choke/voice-stealing rules. Loading only the visible bank is invalid.

Missing/retired/planned audio is silent and clearly unavailable. It cannot qualify a new musical achievement or Finished Song. A saved draft and legacy archive can preserve unavailable musical intent. A finished song whose approved content later becomes unavailable keeps its immutable data and shows a playback problem; it is not silently rewritten with replacement sounds.

Maintain separate projections for content validity and actual client load readiness. A valid server manifest does not prove that a particular device played audible audio. Report observed runtime/listening evidence honestly.

## 11. Music library

Replace the ambiguous six bundled Beat Shelf positions with a library that clearly distinguishes:

- **Projects / Drafts** — editable workspaces and arrangements in progress.
- **Sequences / Loops** — reusable named sections, associated with their project/kit definitions.
- **Finished songs** — titled, versioned complete arrangements eligible for full-song playback.
- **Imported legacy work** — preserved older material until the user edits/remaps it.

A sequence card shows name, bars and tempo. A song draft shows arrangement progress and readiness. A finished song shows title, duration, revision, cover and truthful save/playback status. Only the Finished Songs collection feeds the Lantern Room's finished-song picker. Early dockside loop sharing uses a separate Sequence picker.

Keep save, duplicate, edit-copy, rename and delete scopes understandable. Replacing a draft, deleting a source used by a draft, or removing a visible song entry must not erase unrelated sequences or a currently pinned performance snapshot. Preserve undo/recovery appropriate to the operation.

Sleeve Studio provides a reusable cover design. Copy that design onto a selected draft explicitly. Changing a finished song's cover creates a **new finished-song revision** with the selected cover; it never mutates the existing immutable revision. Changing today's cover design must not change every old finished song. A cover does not determine musical completion.

## 12. Story and quests must teach the workflow

Keep canonical Q IDs, discoveries I01/I02/I03, award IDs, XP amounts, earned wardrobe and existing completed milestones. Change the musical evidence for new completions.

| Quest | Revised learning step and evidence |
|---|---|
| Q00 | Arrive with the Roamer and open the instrument; no song required. |
| Q01 | Existing dock preparation. |
| Q02 | Make a first playable sequence using I01 on at least four distinct rhythmic positions. Resolve the discovery role across all banks. |
| Q03 | Optional saved-loop sharing or private continuation. Keep it optional and reward-neutral; a Finished Song is not required. |
| Q04 | Existing safe repair order and I02 discovery. |
| Q05 | Save an original named sequence and a musically distinct variation. Compare audible musical intent, not names/IDs or an unused edit. No A/B slots or fixed indices. |
| Q06 | Existing listening/role matching using the final pack's semantic kick/hat/pluck bindings. |
| Q07 | Save a Song Mode draft containing at least one owned saved sequence. Naya teaches the move from a loop to an arrangement; finishing is not required yet. |
| Q08 | Existing preparation with Sana. |
| Q09 | Make Mica's reply in the explicitly selected one-bar phrase: old positions 1/5/9/13 correspond to ticks 0/960/1920/2880 relative to that bar. Use the canonical I03 role. Additional bars and unrelated instruments must not confuse this check. |
| Q10 | Existing invitation/signal interaction. |
| Q11 | Meet existing neighbourhood readiness and select a successfully saved Finished Song. For the demo lesson, it has an intentional ordered arrangement, at least two musically distinct sequence sections and a collected sound layered with another part. Offer an intro/main/variation/ending template; do not grade genre or taste. |
| Q12 | Perform that pinned Finished Song revision from beginning to its real end; then complete the chapter once. |

Teach the transition in ordinary language:

- Tori: “That's our loading rail in your loop. Give the sequence a name so you can find it again.”
- Ivo: “Keep that first sequence. Make a variation and save it with another name. Both ideas can belong in the same song.”
- Naya: “A loop can keep an idea going. A song lets you decide what happens next. Put one of your sequences into Song Mode and save a draft. You can finish it later.”
- Ronan: “Choose the song you finished for this evening. We'll hear it from the beginning to the last sound.”

Update canonical quest/world data and regenerate runtime projections; do not change only dialog labels. The existing earned Q05/Q07/Q12 states remain history. They neither revoke rewards nor manufacture new Finished Song objects.

## 13. Replace the finale's old six-loop state machine

The current `ChapterConcert` is a guided loop-remix exercise that reads four saved slots, requires six actions and waits one loop after each. That behavior is not the revised finale.

Start the new finale with a **finishedSongId and immutable revision**, not a shelf number. Resolve that song, validate current readiness, and play its arrangement in order. Show title, current named section, repetition and total progress. The server controls the performance epoch and completion eligibility.

The six existing dramatic ideas—rhythm, support, space, return, variation and signature—may become presentation cues or optional performance accents. They must not require exactly six sequences, six new manual remixes or four fixed slots. Optional actions must not silently change the finished composition or its saved revision.

Finishing requires a complete eligible traversal from the start to the arrangement end **without skipped musical intervals**, with the authored audio-tail policy applied. Pauses freeze progress; stop/seek/leave follows an explicit cancellation/resume policy and cannot jump the quest to completion. Sitting in the room, selecting a song or waiting the old loop duration is insufficient. An actual end-of-song event, not a UI assertion, drives Q12 and the dedication ending. Preserve NPC support and solo play; no public audience is required.

## 14. Jam, listening, stage queue and world behavior

- **Jam:** use the same program-pad/event identities. Remove old first-16 and four-audible-pad data assumptions where they would prevent the full bank set from participating. Bound polyphony/events separately. The shared session tempo is explicit; adapting playback to it must not overwrite a player's saved source sequence BPM. Version the protocol and reject incompatible snapshots safely.
- **Listening:** select a typed Sequence or Finished Song. The UI must say which it is. Finished songs follow their complete schedule; loops remain explicitly looped previews.
- **Stage queue:** queue a typed performance reference. Finished-song queue items carry ID/revision and finite duration; early loop-sharing remains a separate supported mode.
- **Concert:** uses the saved complete-song contract above, never the current editor's mutable selection.
- **World previews:** use semantic approved sound roles and proper absolute addresses. Unavailable content does not fall back to old test samples.
- **Roamer/stations:** changing station or parking preserves the project and its music identities. The viewed bank and UI cursor may be session state; they must not replace musical data.

## 15. Data contract and storage budgets

Recommended modules are `MusicProject`, `MusicSequence`, `SongArrangement`, `FinishedSong`, `MusicTransport` and a migration layer, with server services and UI projections around them. Names may match the local project's architecture, but keep one authority for each concept. `BeatBook` may temporarily remain as a migration adapter; its four-slot model must not remain the new runtime authority.

The included `MPC_WORKFLOW_CONTRACT.json` gives the agreed semantic invariants. `MPC_PROJECT_EXAMPLE.json` demonstrates a draft with named sequences and repeat steps; its audio is deliberately pending and it contains **no Finished Song**.

Start with configurable authored limits, not hard-coded four-item UI assumptions. Suggested first-demo budgets: 32 named sequences per editable project; 8 tracks; 8 song drafts; 128 song steps; repeat counts 1–32; normal sequence lengths 1–64 bars; a separate bounded long-sequence range for conversion. These are game planning choices, not Akai or Roblox limits. Apply total event, expanded-duration and serialized-byte budgets as well, and expose limits before an edit would exceed them.

Do not store every possible empty grid cell or expand all repetitions into the persisted Song draft. Store references and repeat counts; copy referenced content once per immutable song revision, or use immutable versioned blobs with equivalent retention guarantees. Reject an operation that exceeds a budget atomically, preserving the last good state and the user's work; never trim the final bars or discard old library entries.

The current profile store's schema 2 and one-pattern projection must be migrated. If local work already uses another schema, negotiate a new explicit version instead of reusing its number. Keep profile revision, music edit revision, immutable song revision, transport epoch and save status separate. Unknown future versions must not be rewritten by older readers.

Roblox currently documents a 4,194,304-character value limit per DataStore key and recommends checking serialized size. Use a materially lower measured budget for each actual record. If music must be split into separate records, write immutable dependency records first, then atomically update the revision-checked root/index; an interrupted save must never advertise a Finished Song with missing dependencies. Do not assume multiple DataStore keys form one transaction. Keep uncommitted drafts available when saving fails.

## 16. Preserve all legacy musical intent

Before removal, inspect the actual local schema and take reversible backups. The baseline has four independent one-bar patterns, each with its own BPM, 16 assignments, mute state and pad edits. Six shelf entries each contain another complete four-pattern snapshot.

Migrate all of them:

1. Old working slots become named imported sequences, such as Imported 01–04. Preserve exact notes, tempo, mutes and edits. Map old step `n` to tick `(n - 1) * 240`, with velocity 127 for the former full-level boolean hits; preserve the original PadSound gain separately. A legacy slot name may appear in import metadata, never as an active A/B/C/D pattern control.
2. Each legacy 16-pad mapping occupies bank A of an isolated legacy Program, with B/C/D empty. Different old assignments/edits require different Program definitions or an equivalently isolated track container. Do not merge all old sequences into one pad map and change their sound intent.
3. Give imported sequences stable track routing. If they use different legacy Programs, separate track identities preserve those definitions when sequences are arranged together. Do not make track 1 switch its meaning secretly between sections.
4. Preserve each of the six shelf bundles as its own imported draft project/archive with all of its sequences and version metadata. Do not keep only the four working patterns and discard up to 24 shelf sequences.
5. Retired sample IDs remain unavailable references; exact rows/events remain recoverable. Never substitute the first final-pack kick or another default ID.
6. Import creates no Finished Songs and no guessed order/repetition. The player may later choose an order, replace unavailable sounds and finish a song explicitly.
7. Preserve original recoverable data until successful migration is recorded. Make migration idempotent, so retry does not duplicate projects or sequences. An oversized or unsupported legacy object becomes preserved read-only material, not truncated data.
8. Keep existing discoveries, missions, chapter history, wardrobe, outfit presets, RPG awards and covers. Old concert phase/checkpoint data may be retained as legacy history but must not resume into or certify a new Finished Song performance.

Do not rely on changing a schema number to protect against already-running old writers. Document the coordinated reader/writer rollout requirement; all work remains local under the existing deployment policy.

## 17. Whole-game dependency map

Paths refer to the supplied baseline. Re-audit local equivalents and new files before editing.

| Area | Required files/authorities |
|---|---|
| Pad addressing, sample catalog, kit settings | `src/shared/SamplerPadLayout.luau`, `SampleCatalog.luau`, `StylePacks.luau`, `PadSound.luau`; add/centralize program definitions and semantic roles. |
| Musical data | `src/shared/Pattern.luau`, `BeatBook.luau`; replace fixed-size/four-slot assumptions with project, sequence and song models. |
| Persistence | `src/server/ProfileStore.luau`; migrate working data, all shelves, future guards and saved-object revisions. |
| Server commands/state | `src/server/MusicService.luau`; typed music actions, projections, budgets and epochs. Preserve cosmetic Finish. |
| Physical/input UI | `src/client/PadInput.luau`, `init.client.luau`, `WorkshopView.luau`, `SampleEditor.luau`; 64 addresses, multi-bar grids, real transport and sound-bank labels. |
| Input affordances and help | `src/client/CommandPolicy.luau`; `src/client/RecorderGuide.luau`; update supported actions, recording help and old kit/shelf instructions without weakening server validation. |
| Music library/Song Mode UI | `src/client/BeatBookView.luau` and new sequence/song/library views; remove the four-pattern footer and bundled Beat Shelf workflow. |
| Audio/FX | `src/client/AudioEngine.luau`, `PadVoiceProcessor.luau`; program/track/pad routing and bounded voices independent of visible bank. |
| Shared playback | `src/shared/JamProtocol.luau`; `src/client/JamPlayback.luau`; `src/server/JamService.luau`, `ListeningSession.luau`, `StageQueue.luau`. |
| Social playback UI | `src/client/JamView.luau`; `src/client/ListeningView.luau`; `src/client/StageView.luau`; show typed sequence/song identity, active section, duration and shared-tempo semantics. |
| Physical world feedback | `src/client/WorldFeedback.luau`; project logical played events onto visible physical pads without conflating their 1–16 IDs with absolute 1–64 program addresses. |
| Finale | `src/shared/ChapterConcert.luau`; `src/server/ConcertService.luau`; `src/client/ConcertView.luau`; update presentation consumers such as `ConcertScene` where their input contract changes. |
| Quest evidence | `src/shared/QuayProgress.luau`, `NeighborhoodMissions.luau`, `FirstPerformanceQuest.luau`, `DiscoveryCatalog.luau`; typed sequence/song evidence across all banks. |
| Story/UI | `src/shared/QuayStory.luau`; `src/server/QuayDemoService.luau`, `WorldBuilder.luau`; `src/client/QuayDemoView.luau`; complete wording and objective migration. |
| Covers/RPG | `QuayActivities`, `QuayExperienceService`, `QuayExperiencePanel`, `QuayIdentity`; keep existing IDs/awards and distinguish covers from musical completion. |
| Canonical world/quest data | `data/needle-quay-environment.v1.json`, `data/world-districts.v1.json`; regenerate `src/shared/NeedleQuayCatalog.luau` through `tools/compile_needle_quay_register.py` or its verified local successor. |
| Content pipeline | All manifests, bindings and packaging paths listed in `REMOVE_TEST_PACKS.md`; no regeneration of old test audio. |
| Active documentation | Readme, play guide, instrument help, current quest descriptions and implementation report. Historical reports stay historical with clear supersession. |

Use symbol-aware review after a broad search for `SlotCount`, `SlotLabels`, `activeSlot`, `profile.slots`, `entry.slots`, `shelf`, `savedPattern`, `samePattern`, `Pattern.Pads`, `Pattern.Steps`, `for pad = 1, 16`, A/B patterns and old save labels. Some 16s are correct physical pad counts and some slot references are wardrobe data; do not perform blind replacement.

## 18. UI expectations

Keep the warm Needle Quay instrument identity. Make the workflow legible on desktop, touch and controller:

- Persistent music context: current Sequence name, Track, sound Bank, BPM and bar/beat; no mysterious letter-only pattern tabs.
- Main work views: **Sequence**, **Song**, **Library**. Mixer/sample editing are clearly labelled tools within the instrument.
- A–D controls sit with the 16 sound pads, not in the song arrangement toolbar.
- Song Mode shows an ordered arrangement with repeats and a visible end marker. Provide move-up/down controls in addition to drag interaction.
- Make Save Sequence, Save Draft and Finish & Save Song visibly different actions. Show honest pending/saved/error status.
- Before a song exists, show a useful empty state: “Add a sequence to start your song.” Do not insert a generic demo song into the user's library automatically.
- Reuse a clear explanation when needed: “A sequence is a section you can repeat. A song is your sections arranged from beginning to end.”
- Public titles/descriptions must go through the project's appropriate text-filtering path. Internal stable IDs never depend on display text.

## 19. Completion evidence and implementation order

Do the actual code and integration; a documentation-only change, relabelled four buttons or isolated Song Mode mockup is not completion for the local agent.

Work in coherent batches: data model/migration first; commands and shared transport; pad/sequence/song/library UI; world/quest/finale integration; content reset; final consistency pass. Use the real local code and preserve uncommitted edits. Follow the project's test restrictions: no new or executed test suites unless the user separately requests verification. Record static checks actually performed and distinguish them from pending Studio/device/listening acceptance.

The final implementation report must address these concrete criteria:

1. A–D selects 64 program pads. A fifth sequence is ordinary. No four-slot musical ceiling remains.
2. A01, B01, C01 and D01 can all sound in one sequence/song, with distinct edits and no bank-switch interruption.
3. Bank changes during delayed input do not remap a recorded event.
4. Multi-bar sequence record/overdub, velocity, quantization, duplication and undo work through one data path.
5. Song steps preserve order, stable references and exact repeat counts; 1 means once. Reordering/renaming source sequences is safe.
6. Sequence tempo and Song tempo are explicit; mixed-tempo imports are not silently changed.
7. Song playback has a real end, correct repeats and stable cursor after pause/stop/restart; stale scheduled events are cancelled.
8. A saved loop/project is absent from the Finished Songs picker. Finishing creates a saved immutable revision; failed save creates no false success.
9. Editing a source sequence or kit leaves an older Finished Song and an active pinned performance unchanged.
10. Convert to Sequence is non-destructive and honest about tempo/length support; arrangement save is never called audio export.
11. All working legacy patterns and six shelf bundles preserve their musical intent, independent tempo/settings and unavailable old IDs. Unmuting a migrated pad restores its retained original notes. Retry does not duplicate imports.
12. Jam/listening/stage/FX/3D pad feedback understand all 64 addresses and the new typed music objects.
13. Q02/Q05 work before a finished song exists; Q07 accepts a draft; Q11 requires a valid finished song; Q12 follows its actual full performance.
14. Existing earned progress and cosmetics survive without generating phantom songs.
15. No old test pack is playable or silently repackaged; planned audio remains unavailable until approval.
16. Save/payload/voice budgets are measured and bounded; no per-tap broadcast of the entire library and no silent data truncation.

Finish the authorized local code work before reporting. State any real remaining limitation explicitly. This handoff authorizes no commit, push, upload, paid generation, shop activation or Roblox publication.

## Official references and their scope

- [Akai MPC1000 operator manual](https://cdn.inmusicbrands.com/akai/mpc1000/mpc1000v2_operators_manual_00.pdf_055b8b24eeb101e27a2f4042c6819727.pdf): classic pad/program terminology, 64-pad programs, sequence/song structure and Next Sequence. We borrow workflow concepts, not proprietary assets or file formats.
- [Akai MPC3 FAQ](https://support.akaipro.com/en/support/solutions/articles/69000857771-mpc3-faq): architectural explanation of track/program unification. Other availability statements on that older FAQ are not used as current product guidance.
- [Akai sequence-editing guide](https://www.akaipro.com/guides/mpc-sample/editing_sequences.htm): sequence operations and distinction between sequence conversion and audio output.
- [Akai song export guide](https://support.akaipro.com/en/support/solutions/articles/69000856471-mpc-series-how-do-i-export-my-song-): arranging sequences before Audio Mixdown. This does not establish a Roblox audio-export capability.
- [Roblox DataStore error codes and limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits): current per-key data limits and serialized-size guidance. Recheck platform limits during implementation.

The game-specific object model, limits, immutable Finished Song semantics and quest mapping above are authored implementation decisions. They are not claims that every MPC generation implements identical behavior.
