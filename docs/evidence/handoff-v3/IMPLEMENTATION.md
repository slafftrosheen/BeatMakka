> Historical handoff checkpoint. Current source implementation is documented in [Groovebox v4](../handoff-v4/groovebox-2026-10-30/IMPLEMENTATION.md), with the current package workflow in the [demo guide](../../needle-quay/FINAL_DEMO_README.md). The v3 record below retains the decisions and evidence from its original checkpoint. Its earlier written-map and blocked-Finish statements do not describe v4: all 64 pack-native sounds support local Studio playback, Finished Songs and local performances while human listening approval and Roblox admission metadata remain pending.

# Needle Quay v3 local implementation — 30 October 2026

> Subsequent user-authorized [Studio QA](studio-qa-2026-10-30/README.md) completed: 9 regression and 3 UI checks passed; journal, Song resume and Song UI issues were fixed. The original implementation record below describes the earlier static-only delivery. Audio admission and the documented acceptance boundaries remain pending.

The supplied handoff was read and selectively integrated into the existing local game. The current source build is `output/needle-quay-demo/NeedleQuay-MPC-v3.rbxlx`. Source consistency is established by the static checks below; Studio/runtime, listening, multiplayer, device and cloud-rejoin acceptance have not been performed.

## Preservation and intake

- Original HEAD/branch: `8e8b91f6a5472eb6200599e60932e45a8c9ea56b`, `main`. Existing staged/unstaged/untracked work was inspected and preserved without reset, stash, clean, commit or push.
- Pre-task source/metadata backup and tracked/staged patches: `C:/Users/slavd/.codex/backups/BeatMaka/handoff-v3-20261030-141720`.
- All 146 supplied files were copied to `assets/supplied/needle-quay-handoff-v3`. `INTAKE_PROVENANCE.json` records source paths, sizes and SHA-256 hashes.
- The user-materials directory `C:/Users/slavd/OneDrive/Pictures/Assets` was inventoried before work. Existing world art, materials, models and companion work were retained; no new visual generation was requested or performed.
- The additional song and WAV ZIP are production sources under `assets/production/needle-quay/harbour-pulse-v3`, with measured metadata and source hashes in `intake-manifest.json`.

## Implemented source behavior

| Handoff criterion | Implementation and boundary |
|---|---|
| 1. Four banks; more than four sequences | Absolute program pads 1–64, 16 physical controls, independent A–D view, named sequence collection with authored capacity 32. |
| 2. Independent A01/B01/C01/D01 | Shared program pad definitions and per-track absolute pad events/settings; playback preloads its complete pinned dependency set. Pending audio remains silent. |
| 3. Delayed input identity | Input captures project, sequence, track, absolute pad, epoch and request identity; the server rejects stale identities. Held/repeated input retains its captured context. |
| 4. Multi-bar editing/recording | Sparse 960-PPQ events, 4/4, default four bars, record/overdub, velocity, Full Level, timing Off/straight/triplet, swing, note repeat, count-in, metronome, bar/event editing, duplication/doubling/clear and bounded undo/redo. |
| 5. Stable song steps | Ordered sequence IDs, exact 1–32 repeat counts, insert/duplicate/move/remove/replace controls; repeat edits preserve the existing sequence reference. |
| 6. Tempo | Explicit Sequence tempo and Song tempo, preserved imported BPM and integrated tempo schedules. |
| 7. Transport | Common resolved schedules, half-open event ranges, pinned playback, pause/start/stop epochs, finite ends and explicit live sequence queue/cancel. Stop/new playback clears stale queued launches. |
| 8. Distinct save states | Sequences/projects/drafts remain editable. `SongFinish` validates dependency/draft revisions and actual admitted audio; immutable songs are advertised only after accepted storage. Studio saves say session-only. |
| 9. Immutable dependencies | Finish captures sequence events, shared programs, routing, mute/mix/tempo/cover. Ordinary edits cannot mutate active playback. Controlled recording updates only its captured graph with the same server-created event ID. |
| 10. Conversion/export | Non-destructive single-tempo conversion, bounded to 1,024 bars. Multi-tempo conversion refuses explicitly. No audio-file export is claimed or exposed. |
| 11. Legacy migration | Four working patterns and each of six shelf bundles retain independent maps, BPM, notes, mutes, pad settings and raw preimages. Import is idempotent; unavailable historical IDs remain exact. No guessed arrangement or Finished Song. Archive switching reuses each workspace's archive while retaining original preimages. |
| 12. Whole-game consumers | Protocol-3 jam, typed listening/stage, street speakers, commissions, audio/FX, NPC/world clock and physical pad feedback use common schedule/absolute identities. |
| 13. Musical quest evidence | Q02/Q05 use named sequences; Q07 uses a saved draft; Q09 checks an explicitly selected teaching bar; Q11 selects a ready saved Finished Song; Q12 certifies its full pinned traversal plus the authored two-second tail. |
| 14. Progress and experience | Supplied story/journal, four activities, finite 575-XP identity ledger, wardrobe, three outfit presets, mirror and disabled cosmetic shop integrated alongside newer local companions/world. Existing earned history is retained without phantom songs. |
| 15. Content retirement | 179 historical musical IDs removed from active local/cloud bindings, waveforms and packaging/generation authorities. Five separately inventoried UI/ambience bindings and unrelated non-musical world/voice/visual assets retained. |
| 16. Bounded storage/resources | Measured project/music/root/schedule budgets, bounded requests/events/history/voices/FX, lightweight recording deltas, revision-checked writes, future-schema protection and atomic refusal without truncation. |

Normal sequence lengths are 1–64 bars; meter support is explicitly 4/4. The root save budget is 3,000,000 serialized bytes, below the current documented platform limit. Schedules are bounded to 750,000 serialized bytes. These are authored game budgets. Current platform reference: [Roblox DataStore limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits), inspected on 30 October 2026.

Successful project saves mark the exact captured sequence/draft revisions as saved; newer edits made while storage yields retain dirty status. Finish request receipts bind the saved immutable object and its resolved revisions. Unknown/future storage versions cannot be rewritten. Old server writers must be drained and coordinated before any future deployment.

The original experience patch was merged selectively; the full source snapshot was retained as historical input. Old prerecorded guidance that contradicts the new workflow is suppressed with revised text guidance, while original audio/metadata remain preserved. There was no paid voice regeneration.

## Audio remains pending

The user explicitly answered: **“Keep the written map; leave mismatched slots pending.”** The active plan therefore remains A drums, B bass, C melody/harmony, D twelve harbour sounds and four vocals. I01/I02/I03 remain D01/D02/D03; vocals remain D13–D16.

The appended ZIP instead has C containing sixteen vocal files and D containing harbour FX/melodics, with other slot-role/pitch mismatches. All 64 planned slots remain pending approval/admission; the supplied files are preserved as candidates rather than silently rebound. Pending/retired audio cannot satisfy readiness, new musical quests or Finish & Save Song. Editable sequences and drafts can still be saved.

The ZIP contains 64 WAV filenames but 63 unique byte contents: its two closed-hat files are identical. WAV measurements are stereo, 44.1 kHz, PCM16; the proposed production target is mono. The supplied M4A is a 158.4-second stereo AAC production reference. Metadata does not establish listening, pitch, isolation or artistic approval.

`content-retirement.json` records repository removal and a read-only audit of the installed Studio namespace. Existing installed retired files were not changed during this task. The updated launcher/installer removes only exact retired filenames with matching hashes on the next user-initiated installation. No recursive directory removal is used.

## Actual checks and remaining acceptance

- Project-pinned Rokit shims: StyLua 2.6.0 and Selene 0.32.0 over all **75 source files changed by this task relative to the pre-task backup**: formatting check passed; **0 errors, 0 warnings, 0 parse errors**.
- Rojo 7.7.0 built `NeedleQuay-MPC-v3.rbxlx` successfully from the repository root. This compiles the local place structure; it does not execute the game.
- SHA-256/content allowlist checks run by the existing local packaging pipeline. Receipts: `source-checks.json`, `content-retirement.json`, `local-package.json` and the production intake manifest.
- Fresh read-only source review found and prompted fixes for repeat edits replacing sections, stale queued playback, archive capacity on repeated switching, saved-revision markers, live-record dependency/event identities, mixed-tempo presentation, optional-loop revision eligibility and shared audio resource starvation.
- No test suite was created or run. No Studio play session, acoustic measurement, two-client session, device interaction or cloud persistence/rejoin check was performed.
- Approved slot mapping/audio admission, listening acceptance, runtime UI/transport/social/finale acceptance and actual persistence behavior remain to be established separately.
- No commit, push, Roblox upload/publication, paid generation, pass creation, purchase testing or shop activation occurred.
