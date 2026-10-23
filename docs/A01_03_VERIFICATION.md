# A01-03 first beat, save and reopen

23 October 2026. Issue #6 remains open. Background Studio/source checks pass; novice usability and hosted audio acceptance are incomplete.

## Implemented behavior

The workshop header offers short actions on Play, Steps, Sounds, Beats and Settings. A first pad hit leads toward Steps or Record. Record explains sixteen-step quantization and Stop. Notes lead toward playback and saving A-D to the six-position shelf. Hints do not edit music or introduce another save schema. Notices take temporary priority; current slot, BPM, transport and save status remain in the separate footer.

The footer distinguishes NEW, UNSAVED, SAVING, SESSION SAVED, SAVED and TEMPORARY. Session storage does not promise cloud durability. Unavailable storage remains temporary. Existing save errors still use notices.

Restore slots uses the existing five-second/two-press convention. It identifies replacement of working A-D, binds to the reviewed edit version/station and cancels after edits, navigation, Save, saving, station loss or expiry. The server rejects missing/stale versions before restoring; valid restoration advances the version so queued duplicate commands cannot replay it. Four independent patterns, six shelf positions, migrations and shelf confirmations remain intact.

## Evidence

[Studio receipts](evidence/a01-03/) came from local instance `f060d05e-09bc-466c-8945-37cb780e5bb8`. Explicit test modules are excluded from the production project.

- FirstBeatFlow first failed because Restore had no confirmation method. Final run verifies two presses, stale edit cancellation, expiry, navigation cancellation, no-save suppression and new/session/temporary labels. All page hints fit at 360x720 and 740x260.
- RestoreRuntime uses the actual Client-to-Server path after claiming the sampler through its prompt. It saves a note, changes working notes, proves stale/missing confirmations preserve newer edits, then restores the note with the current version. State/notice predicates identify expected replies. Storage is local-session only.
- Six-size layout regression passes, including 740x260. PadInput and PadLifecycle pass. All 25 recording-timing checks pass across 60/96/180 BPM. Eight Contracts and eight Milestone groups pass, including independent slots, shelf versions, migration, failure retention and restoration.
- Pinned Selene reports zero errors/warnings/parse errors; StyLua and Rojo build pass. Independent read-only review found no blockers. Its reply-correlation concern was addressed with explicit predicates.

No foreground browser/native actions were used in this continuation. These checks establish no audio IDs, cloud permissions, physical latency or paid assets.

## Novice usability protocol - NOT RUN

After #5 audio acceptance, use a fresh profile and give a new player only: "Make a short beat, save it, change it, and open your saved version again." Provide no oral navigation instructions. Record device, build, starting profile, elapsed time, missteps, help requested and the player's interpretation of working versus saved state. A developer following scripted steps does not count as novice evidence.

Observe independent pad audition, sound selection, step entry, playback, Record/Stop and understanding that recording snaps to sixteen steps. Observe slot A-D selection, saving the A-D set to an empty shelf position, changing working notes, choosing the saved Beat and confirming load. Verify saved notes return and other slots retain intended contents. Check occupied shelf overwrite and Restore explanations, cancellation and save errors without risking real user work.

Record usability results here separately from automated receipts. Current result: NOT RUN; hosted audio and a novice participant are unavailable. Do not close #6 on source checks alone.
