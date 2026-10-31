# Groovebox v4 implementation — 30 October 2026

This is a source implementation record. Build, Studio MCP execution, rendered layout, performance measurements and package hashes belong to the separate QA report and machine-readable receipts in this evidence directory. This document does not declare runtime PASS for a build or replace those receipts.

The canonical local build is `output/needle-quay-demo/NeedleQuay-Groovebox-v4.rbxlx`, packaged as `NeedleQuay-Groovebox-v4.zip`. The player-facing package guide is [FINAL_DEMO_README.md](../../../needle-quay/FINAL_DEMO_README.md). Original v3 reports remain historical evidence for their named builds.

## Fixed interface and preserved controls

`DeviceGrooveboxView` replaces the instrument's rebuilt, scrolling editor with persistent physical pads and fixed LCD pages. Sixteen pad controls address the four A–D sound banks independently of the named sequence collection. The performance and editor areas sit beside each other on landscape screens and stack in portrait. Layout code bounds the controls within each surface; final rendered/device acceptance is established by QA.

- `DeviceSequencerScreen` retains bar navigation, selected-pad steps, four-lane overview, and programmed/playhead states. Section tools retain length, duplication, doubling, timing correction, swing, velocity, event timing/removal, track and program routing, queue/cancel, teaching-bar selection and undo/redo.
- `DeviceSoundScreen` and `DevicePadControls` expose real sample trim, envelope and DSP parameters, audition, presets and the selected pad's live knobs. Native captions remain outside generated artwork.
- `DeviceSongScreen` uses a fixed card pool with bounded pages, repeat blocks, section selection, drag ordering, explicit source replacement and section audition. Draft creation, rename/duplicate/delete, tempo modes, conversion, sleeve copying, save and idempotent Finish requests remain available.
- `DeviceLibraryScreen` reuses six sleeve cards, or four in compact layouts. Sections, drafts and Finished Songs have separate segments and bounded paging. OPTIONS retains editable copies, legacy imports and recovery. PLAY targets the selected typed object; PUBLIC selects a typed reference for the next voluntary listening set.
- `ConcertView` and `JamView` use fixed hardware keys, graphical progress/channel strips, digital time/tempo and bounded INFO pages. Their Chapter and Jam callbacks, saved-revision eligibility, next-bar publication, conductor controls, mute, leave and focus handoff remain connected to the existing services.

These surfaces construct their widgets once and bind state to existing controls. Graphics use the local `ui-device-v3` namespace with v4 artwork names; native fallbacks preserve usable controls while an image loads. The original approved visual board and supplied world/character sources remain preserved.

## Erasure and live playback

The stuck-pad fault had two independent paths. `MusicWorkspace` updated the editor project while a personal transport retained its old looping schedule. Separately, a buffered recording delta could be sent after a clear with the project's newer revision and restore an erased note on the client.

The personal sequence transport now publishes a replacement schedule for live sequence edits. Clear, note removal, destructive mute/length changes and active-sequence deletion invalidate the cancellation epoch; deletion also removes the paused resume snapshot and cancels a deleted queued section. Pad clear, selected-track clear and explicit `scope="sequence"` clear retain distinct scopes. Undo/redo reconcile the personal loop with restored notes.

Adding notes and changing source, FX, kit, routing or mixer settings advance `scheduleRevision` while retaining the playback anchor and sounding tails. `SchedulePlayback` advances its consumption floor to the edit instant, so it neither restarts the loop nor retroactively triggers earlier notes. Upcoming triggers use the current parameters. During recording, instrument dependencies stay pinned, while note edits update the recording project so a later Tap cannot restore cleared notes. After recording stops, sound and mixer edits affect subsequent personal-loop triggers.

Full editor mutations clear older queued Tap deltas. Recording details carry their transport epoch and the client rejects mismatched epochs. Input cancellation also releases held-pad/repeat state and clears obsolete pad flashes. Song previews, accepted Finished Songs and shared performance snapshots retain their captured dependency graph.

Pause/resume preserves the explicit playback cursor. The consumer waits for the resumed start anchor before advancing, keeps its consumption floor monotonic, and never applies initial lookbehind to notes preceding a resume/seek cursor. Full-song QA caught and removed a two-note replay during the resume lead window.

`MusicTransport.eventsBetween` now seeks the first event with a binary lower bound before consuming the half-open frame window. `PadVoiceProcessor` separates voice parameters from DSP channel settings, avoiding an effect-channel allocation for dry playback and allowing already-playing effect tails to finish with their original parameters.

## All 64 local sounds and onset derivatives

The user's pack-native map is A01–A16 drums, B01–B16 bass, C01–C16 MC vocals and D01–D16 harbour FX/melodics. Canonical IDs are unchanged. Current selected source kinds in `pack-native-manifest.json` are:

| Source kind | Count |
|---|---:|
| Unchanged supplied WAV | 43 |
| Deterministic repair for an all-zero instrumental WAV | 7 |
| Level-only A15 derivative | 1 |
| Leading-silence derivative | 13 |
| Total | 64 |

The thirteen onset derivatives are A02, A03, A06, A07, A08, A11, A13, A14, B05, B09, C08, C09 and C10. They are contiguous PCM slices retaining 2 ms before the detected attack. They do not change pitch, amplitude, sample rate or the retained tail. Original source files stay byte-preserved. Recipes, original/selected hashes and selected-source measurements are in `assets/production/needle-quay/harbour-pulse-v3/local-dsp-repairs/manifest.json` and `onset-audit.json`; the generator is `tools/prepare_pack_native_audio.py`. File onset measurements are separate from input-to-speaker latency.

`Catalog.isPlaybackReady` admits the approved catalog or an explicitly configured, technically ready Studio-local preview URI. The Studio path is shared by audition, recording, draft playback, Finish, Finished playback, listening/stage, jam and musical gameplay evidence. Outside Studio, the preview path cannot pass readiness. Local-only snapshots/progress retain their local provenance.

Human listening review stays `pending`; `audio_approved` and `runtime_admitted` remain false for these local sources. These metadata fields do not disable the authorized Studio functionality. `data/studio-local-music-roles.v1.json` explicitly supplies local discovery substitutes A15 / harbour metal, D10 / vent hiss and D04 / helper bell, while preserving I01/I02/I03 and declaring `recording_equivalence=false`. The D01 lesson uses the actual Lantern Bell D5. This does not recategorize a vocal or bell as an approved original field recording.

## Verification and delivery boundaries

Scoped source changes were formatted and linted using the repository's Rokit-pinned StyLua and Selene. Private regression probes are available at `tools/qa/sequence_transport_server.luau` and `sequence_transport_client.luau`; they exercise erasure, delayed input/deltas, live parameters, recording pins and immutable performances without changing an active player profile. Their execution results must be read from the current QA receipts.

Studio saves remain session-only. Durable cloud rejoin, independent multiplayer clients, physical touch/audio latency and human listening/art approval require their own evidence. No Roblox asset upload, Experience publication, provider spending, commerce activation, commit or push is part of this implementation record.

Rebuild with an explicit current evidence directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/build_current_demo.ps1 -EvidenceDir docs/evidence/handoff-v4/groovebox-2026-10-30
```

The existing builder retains a locked live Studio place and stages its replacement. Package/launcher generation remains in the existing build tools; generated output is not an authored documentation source.
