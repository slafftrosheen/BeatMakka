# Needle Quay — MPC v3 local build

The current delivery is [NeedleQuay-Groovebox-v4](FINAL_DEMO_README.md); see its [current MCP checks](../evidence/handoff-v4/groovebox-2026-10-30/README.md). This document retains the v3 feature background. The current instrument uses a fixed physical pad/knob deck, named sequences, four playable sound banks, Song Mode and local Finished/public playback. Older build names, written-map restrictions and scrolling UI are superseded.

Open `output/needle-quay-demo/Launch-NeedleQuay.cmd` after rebuilding this package. The launcher installs only the active checksum-listed local content. It does not upload or publish anything. Focused local Studio QA passed for banks, sequences and Song Mode; see the Studio QA report for evidence and remaining audio/cloud/device boundaries.

## Make music

1. Open your Roamer instrument. **A–D select sounds**, with 16 physical pads and 64 absolute addresses.
2. In **Sequence**, name a section, choose its length and track, and add notes. The bar grid is a view into the complete sequence. Record and Overdub add notes; Clear is explicit and undoable. Velocity, Full Level, Timing Correct, swing, count-in and metronome have separate controls.
3. **Save Sequence** saves editable work. Make Variation creates an independent sequence. Next Sequence queues a live transition without changing the arrangement.
4. In **Song**, create a draft and add sequence references. Arrange their order and repeat counts; one repeat means one complete play. Sequence tempo preserves source tempos; Song tempo applies an explicit master tempo.
5. **Save Draft** retains the arrangement. **Finish & Save Song** validates the current dependency revision, captures its musical data and admits the immutable song only after storage accepts it.
6. **Library** separates sequences, drafts, Finished Songs and imported legacy work. Opening a Finished Song for editing creates a copy. Sleeve Studio copies a cover explicitly into a draft; a later finish creates a new saved song.

Song preview has a finite end. Convert to Sequence creates editable musical data, supports ordinary single-tempo arrangements up to 1,024 bars, and refuses unsupported multi-tempo conversion without altering the original. No audio-file export is advertised.

## Audio status

The supplied full song and all 64 WAVs are preserved under `assets/supplied/needle-quay-handoff-v3` and `assets/production/needle-quay/harbour-pulse-v3`. Their measured metadata and SHA-256 provenance are recorded in the intake receipt.

The supplied ZIP has a different bank/role layout from the written contract. The user explicitly chose to retain the written map and leave mismatches pending. All planned slots remain unavailable until actual mapping, audio approval and admission are recorded. They can hold editable notes, but cannot satisfy musical readiness, new musical quest completions or Finish & Save Song. I01/I02/I03 retain their canonical discovery IDs at planned D01/D02/D03. Vocals occupy planned D13–D16, within the total of 64.

The 179 retired test musical IDs have no active local/cloud bindings. Five separately inventoried UI/ambience bindings and the existing non-musical world/voice assets remain. Old saves keep their exact retired references; playback does not substitute another sample.

## Experience and storage

The journal, four optional activities, Listener/Beatmaker/Neighbour progression, earned cosmetics, three outfit presets, mirror and disabled cosmetic shop are integrated. The chapter progresses from a sequence to a saved draft, then a selected ready Finished Song and its complete pinned performance. Existing earned history remains intact.

Profile schema 3 preserves legacy working patterns and all six shelf bundles as isolated imported projects, with raw preimages, independent tempos, kits, notes, mutes and edits. Import never guesses an arrangement or manufactures a Finished Song. Unknown future versions are protected from rewriting. All old/new writers must be coordinated before any later deployment.

Studio saves are explicitly session-only. Cloud saves use revision-checked storage and a measured 3 MB record budget. Capacity failures retain the complete previous state. The cosmetic shop remains disabled; its proposed prices are planning data.

See `docs/evidence/handoff-v3/studio-qa-2026-10-30/README.md` for gameplay QA and `docs/evidence/handoff-v3/IMPLEMENTATION.md` for the original implementation record. The subsequent [Rojo warning fix and MCP retest](../evidence/handoff-v3/rojo-preload-warning-fix-2026-10-30/README.md) passed all 9 regression and 3 UI checks with empty Studio output. Its local developer-plugin compatibility fix does not change the game or admit pending audio. No commits, pushes, paid generation, Roblox uploads or publication were performed.
