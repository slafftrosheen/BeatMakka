# Issue #6 — First Groove implementation and local acceptance

Base: `b414ae0ee4e634fbac0fc36fde94ad00c85ccc45`.
Scope: the current First Groove brief in #6, using #21's existing 64-pad musical contract and #10's workspace/persistence code. This is a code-only batch; no new asset production, uploads, publishing, dependencies, CI or storage service.

## Goal and implementation order

Give an Alone-mode player an optional example or blank loop, a few intelligible sound choices, the normal note editor, and a truthful path through naming, saving, leaving and reopening. Full editing remains available without completing guidance.

- [x] Add authored starter data and canonical sound-role choices.
- [x] Add a version-checked server transaction that preserves existing work before opening a starter.
- [x] Integrate optional guidance into the live Sequence screen, not the retired BeatBook UI.
- [x] Wire normal sound editing, note editing, playback, mute, undo, naming, variation, save, restore and recovery commands.
- [x] Keep small-screen note targets usable through reflow and native scrolling rather than shrinking controls indefinitely.
- [x] Review command routing, state ownership, failure paths, confirmation lifetime and module dependencies at source level.
- [ ] Roblox Studio, actual audio, physical input, hosted persistence and novice observation: user-local acceptance, not remotely observed.

## Files and responsibilities

`src/shared/FirstGroove.luau` contains the four role definitions and a two-bar Harbour Pulse example. It populates an ordinary `MusicProject`/`MusicSequence` candidate with stable absolute-pad events at the shared 960 PPQ. The example has 21 events on A01, A05, A09, B01, C01 and D10; blank mode has no events. It is explicitly named as an example loop, not a Finished Song. Both retain the complete normal 64-slot program.

The offered choices are drums A01/A02, bass B01/B03, hook C01/C02 and harbour texture D10/D09. Labels and sample identities come from the current catalogue. These are authored choices for local listening review, not a claim that their musical balance or phone-speaker result has been approved.

`src/server/FirstGrooveSession.luau` owns starter admission. `MusicWorkspace.handles/command` routes `GrooveStart` through the existing station ownership, bounded payload and rate-protected server path. The request includes schema, mode, project ID/revision, edit version, workspace generation and station. Every value must still match before replacement. Duplicate or delayed requests cannot open additional starters against an old workspace.

Before activation, the server checks the requested template's declared audio readiness, preserves the current project, validates the complete music document and checks the normal serialized budget. The untouched factory project need not occupy an archive slot; renamed/edited/other work is preserved as an exact version. Existing finished songs, archives, recovery data and earned progress remain in the document. All failure gates precede activation. Pending saves block replacement. No auto-save or success claim is fabricated.

`src/client/FirstGrooveCoach.luau` provides the optional native UI. It owns no audio engine, transport, note buffer or save backend. Role selection selects the real bank and physical pad; the player taps that pad through the existing immediate local input path to audition it. Sound-choice buttons explicitly edit the selected role slot through `ProgramPad`, with the normal revision check. They do not pretend that selecting a button proves audible playback.

`src/client/DeviceSequencerScreen.luau` integrates the coach and retains the existing step/lane instances. Full Editor and Edit Notes are view-only switches: no project transfer, event conversion, transport restart or destructive reset occurs. The 16 note-step controls reflow to 8/4/2 columns with 44-pixel row targets. The editor scrolls inside its own screen; the physical performance-pad deck is not moved into that scroll container. The lane overview follows the optimistic absolute-pad bank while acknowledgement is pending.

## Player path

1. A fresh unsaved empty workspace opens optional First Groove guidance. Existing saved work is not forced through it. FIRST GROOVE reopens help; FULL EDITOR dismisses it. The dismissal preference is session-local, not a new persistent profile field.
2. EXAMPLE LOOP or START BLANK uses a five-second, two-press confirmation. The button itself changes to CONFIRM. Starting preserves prior work in CRATES / Archives; a stale confirmation/request does not overwrite it.
3. Select a role and tap its physical pad. The eight offered source choices remain ordinary canonical samples. Unavailable choices are explicitly labelled and disabled. Missing example audio blocks only the example; blank and full editing remain accessible.
4. EDIT NOTES exposes the normal grid. Add/remove notes, switch A-D banks, use live recording or the full sound editor. PLAY LOOP starts the currently selected sequence from its beginning rather than resuming an unrelated pinned transport.
5. The guide exposes mute/unmute, Undo, Rename and Copy Variation. Naming still uses the existing server text-filter path. Copy Variation uses normal sequence duplication: note data is independent; the track's kit is shared, as indicated by the guide's sound-edit explanation. This does not invent per-sequence program routing.
6. SAVE invokes normal whole-project persistence. The header distinguishes NEW, UNSAVED CHANGES, SAVING SNAPSHOT, SESSION SAVED, SAVED TO STORAGE and TEMPORARY / SAVE UNAVAILABLE. Edits during saving remain governed by ProfileStore's captured-version checks.
7. BACK TO QUAY releases editing without discarding the workspace. Re-entering the instrument resumes that workspace. REOPEN SAVE deliberately restores the last saved whole-project snapshot, using #10's recovery preservation. OPEN RECOVERY exposes the existing recovery path when a retained copy prevents another restore.
8. The existing SHOW BOARD is linked when a Finished Song is available. A repeating loop is never labelled a completed Song or made automatically eligible for a public set. SONG and FINISH remain the existing arrangement workflow; #22's new short-set gameplay is not claimed implemented here.

## Safety and lifecycle

Confirmation identity includes station, workspace generation, project/edit revision, sequence, track and bank. Changes invalidate it. Page/ancestor-panel hiding, station exit, ScreenGui disabling, window focus loss, viewport-size changes and teardown cancel the local confirmation; it cannot survive a quick leave/re-enter of the same station. Closing guidance releases its name field and restores a usable controller focus when necessary. Connections are disconnected with the Sequence screen.

The example and offered swaps use the existing catalogue readiness policy. Local preview readiness is explicitly not approval, moderation or hosted permission evidence. The template never substitutes another sample when a required source is missing. Starting a blank loop does not require the final audio pack to be ready.

The existing profile schema (3), music schema (1), DataStore name, sample IDs and save/migration contracts are unchanged. `sequence.firstGroove` is optional authored provenance retained with normal sequence data; it is not a completion/reward gate. Help never requires a companion, cleanup task or social audience.

## Verification boundary

Performed: source-level integration review and GitHub commit/diff/ref inspection. The pinned Rokit/StyLua/Selene toolchain is not installed in the execution container and its direct network access failed. No substitute compiler or formatter was installed. No test suite, Luau lint, Studio build, actual audio/device run, novice study or live DataStore operation was run. Source review is not runtime acceptance.

The existing native `GuiButton.Activated` event is used for action controls; controls remain selectable and display a focus ring. Their actual touch/controller behaviour still requires the device pass below. The current Roblox reference was consulted, but no platform-specific latency or accessibility certification is inferred from it.

## User-local acceptance — no additional programming handoff

- Start from a fresh profile in Alone mode. Open the example, select/swap a sound, tap the physical pad, change a step and replay. Confirm that all four banks remain available and that no quest/dialogue blocks access.
- Repeat with blank mode. Confirm no prefilled notes appear. Name the loop, copy a variation, change its notes and Undo; observe the documented shared-kit behaviour separately from independent note data.
- Toggle guidance/full editing while playing, recording and switching banks. Compare project/sequence IDs, exact events, source sample IDs and the transport cursor before/after the view-only toggle.
- Save, leave the instrument, re-enter, edit, confirm Reopen Save, then Open Recovery. Compare the saved and recovered musical versions. Confirm session-only wording and that a failed/conflicted/pending save never appears clean.
- Try stale/duplicate starter requests, a full archive library, exhausted byte budget, pending save, unavailable example audio, focus loss, rotation and station exit during confirmation. Rejected operations must leave the previous musical workspace intact.
- Inspect narrow portrait and short landscape layouts plus mouse, multi-touch and controller navigation. Check that scrolling the note editor does not intercept the separate performance pads and that long source labels/status messages remain usable.
- Observe the issue's proposed 60-second first-choice and 7-of-10/three-minute novice targets, recording actual outcomes and voluntary follow-up edits. These targets have not been measured by this batch.
- Hosted exit/rejoin remains #10's separately authorized release gate. Do not publish or upload assets from the current testing account.

Issue #6 remains open for those actual usability/input/audio observations. No remaining code task in this batch is delegated to the local agent; implementation defects found by acceptance still belong to code development.
