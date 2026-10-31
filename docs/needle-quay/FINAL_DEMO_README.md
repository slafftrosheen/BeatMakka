# Needle Quay — Groovebox v4 local demo

Current build name: **NeedleQuay-Groovebox-v4.rbxlx**, with its companion content in **NeedleQuay-Groovebox-v4.zip**. Extract the complete ZIP, then run **Launch-NeedleQuay.cmd**. The launcher checks and installs the listed local content before opening Studio. Press Play. All content stays local; nothing is uploaded or published to Roblox.

The Roamer opens a fixed physical groovebox. Four bank keys, sixteen pads, selected-pad knobs and transport stay available beside the LCD pages. Portrait layouts stack the two halves. Sequence, Song, Sounds, Crates and Setup use fixed controls and bounded pages. The library, Lantern Room and two-player jam retain their actions without scrolling lists. Native labels, focus marks, held-pad states, trigger flashes and step lights show distinct input and playback states.

## Play and shape the 64-pad kit

The user's selected pack-native order is:

- A01–A16: drums, source 01–16.
- B01–B16: bass, source 17–32.
- C01–C16: MC vocals, source 33–48.
- D01–D16: harbour effects and melodics, source 49–64.

A–D switch sounds, independently of sequences. Tap a pad to select and hear it. LEVEL, PITCH, TONE, DRIVE, ECHO and SPACE change the selected pad; Sounds also exposes trim, envelope, recipes and audition. All 64 sounds can be reassigned. Loading the native kit creates a fresh program and retains the earlier edited kit.

The local payload contains 64 playable WAV sources: 43 unchanged supplied files, seven deterministic repairs for silent instrumental originals, one level-only A15 derivative and thirteen onset-trim derivatives. The onset derivatives retain 2 ms before each measured attack, preserving the remaining PCM, pitch, amplitude and tail. Original files, recipes and hashes remain in `assets/production/needle-quay/harbour-pulse-v3/`. `pack-native-manifest.json`, `local-dsp-repairs/manifest.json` and `onset-audit.json` identify every selected source. Source onset timing is separate from physical input/audio latency.

## Build sections and songs

In Sequence, place notes in the selected pad's bar grid or use Record/Overdub. Name and save sections, make variations and queue the next section. Tools retain length, timing correction, swing, velocity, count-in, metronome, exact hit editing, track/program controls and undo/redo.

ERASE separates the selected lane, selected track and whole sequence. Clearing/removing notes updates the personal loop immediately; deleting the active sequence also removes its old paused-resume snapshot. Additions and sound/mixer edits update upcoming personal-loop triggers without restarting the cursor or cutting an existing tail. Recording retains its captured instruments; subsequent note edits cannot resurrect cleared notes.

In Song, create a draft and ADD sections. Cards show order and repeats; drag to reorder, change SOURCE or adjust REPEAT. Choose section tempos or an explicit master tempo, audition, then SAVE. FINISH captures an immutable saved revision after the current dependency revisions and session save are accepted. Finished playback follows the full arrangement to its finite end. Opening an editable copy preserves the saved original.

Crates separates Sections, Drafts and Finished Songs. OPTIONS opens editable copies, retained imports and recovery. PLAY auditions the selected item. PUBLIC takes the selected Sequence or saved Finished Song to the courtyard board; choose PREPARE, then START when your turn is offered. Leaving returns you to your Roamer. The Lantern Room performs a selected ready Finished Song from beginning to end. In a jam, edit your own section in the sampler and PUBLISH its pinned copy at the next bar; the conductor controls shared tempo. Mute and leave remain available.

## Local gameplay and save status

All 64 technically ready local sounds support Studio audition, recording, song finishing, saved-song playback and local listening/stage/jam. Human listening approval and Roblox runtime admission remain pending metadata; they do not block these Studio functions. Outside Studio, only approved/admitted sources pass the production readiness path.

I01/I02/I03 keep their discovery identities. The local demo explicitly uses A15 Metallic Clank Hit for harbour metal, D10 Hydraulic Steam Release for vent hiss and D04 Lantern Bell High D6 for helper bell. These named substitutes enable local lessons and progression without claiming equivalence to the original field recordings. The tune lesson uses D01 Lantern Bell D5. The 179 retired musical IDs remain archived without active audio bindings.

Studio saves are session-only. Read the visible save state; a temporary or failed save does not become a durable save. Cloud rejoin, independent multiplayer clients, real-device acceptance and human listening/art approval are separate evidence. The cosmetic shop stays disabled.

## Evidence and rebuilding

Current implementation and QA receipts belong in `docs/evidence/handoff-v4/groovebox-2026-10-30/`. Read the current QA report/results for the actual checks completed on the delivered build. [IMPLEMENTATION.md](../evidence/handoff-v4/groovebox-2026-10-30/IMPLEMENTATION.md) documents source behavior; older v3 receipts describe their named historical builds.

Rebuild from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/build_current_demo.ps1 -EvidenceDir docs/evidence/handoff-v4/groovebox-2026-10-30
```

Pinned Rojo resolves through Rokit. Repack the already built place and current reports with:

```powershell
python tools/package_needle_quay_demo.py --place NeedleQuay-Groovebox-v4.rbxlx --evidence-dir docs/evidence/handoff-v4/groovebox-2026-10-30
```

An existing Studio lock preserves its live place during rebuilding. The cleanup tool previews recognized older generated demos and archives them with hashes only when requested. Unique source files and historical receipts remain retained.
