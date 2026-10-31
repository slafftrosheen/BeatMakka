# Needle Quay v3 MPC implementation plan

> **For agentic workers:** Use superpowers:executing-plans for integration and superpowers:dispatching-parallel-agents for independent model, content and experience tasks. User instructions override skill test, commit and approval defaults.

**Goal:** Implement the supplied v3 experience and four-bank sequence/Song Mode workflow in the current local game.

**Architecture:** Sparse tick events belong to named sequences, with stable project tracks and 64-pad programs. A shared schedule resolver feeds editing, listening, jam and finite immutable performances. Legacy patterns and every shelf bundle are preserved as imported music, with their own routing and unavailable sample identities.

**Tech Stack:** Existing Luau, Roblox, project-pinned Rojo/StyLua/Selene and Python asset tools; no new dependencies.

**Spec:** `assets/supplied/needle-quay-handoff-v3/MPC_WORKFLOW.md`, `EXPERIENCE_SCOPE.md`, `LOCAL_AGENT_TASK.md` and the JSON contracts.

## Global constraints

- Keep the current working copy and all unrelated changes; backup: `C:/Users/slavd/.codex/backups/BeatMaka/handoff-v3-20261030-141720`.
- No commit, push, Roblox upload/publication, paid generation, commerce activation or test suites.
- Preserve canonical IDs, earned history, companion/world work, cosmetics and three wardrobe presets.
- A–D are sound banks only; 960 PPQ, 3840 ticks per 4/4 bar, absolute pad addresses 1–64.
- No audio substitutions. Keep the written final-pack bank map. The supplied ZIP has incompatible roles; mismatched slots remain pending per the user's answer.
- Static compilation/lint/source inspection may establish source consistency only; runtime and listening acceptance remain distinct.

## Review focus

- An old save with four independent maps and six shelves must retain all music without creating finished songs.
- Delayed input must keep original project/sequence/track/pad/epoch identity across a bank change.
- Editing dependencies during save/playback must preserve the captured finished/performance revision.
- Failed or oversized operations must leave editable work and saved objects intact.
- Pending/retired audio must fail readiness visibly, including world quests and finite performances.

## Tasks

- [x] Copy handoff with SHA-256 provenance and make reversible local backup.
- [x] Implement shared project, sequence, arrangement, snapshot, transport and migration modules. Enforce authored capacities and future-schema guards; retain all legacy preimages.
- [x] Retire active test musical packs and their regeneration paths. Inventory/extract supplied audio with metadata and hashes; keep incompatible assignments pending and preserve non-musical audio/visuals.
- [x] Selectively merge supplied experience modules, journal, wardrobe and disabled commerce. Preserve newer local world/companion behavior. Adapt Q02/Q05/Q07/Q09/Q11/Q12 evidence and finale to typed music.
- [x] Integrate schema-safe persistence, bounded commands, undo/redo, explicit save states, revision-checked idempotent finishing and bank-independent transport.
- [x] Wire Sequence/Song/Library instrument UI, 64-pad input/editing, multibar grids, timing/velocity controls, live queue, finite arrangement and immutable library.
- [x] Update jam/listening/stage/world/FX consumers to the common typed schedule and absolute addresses.
- [x] Update canonical data, generated catalogs and active help. Compile and statically inspect affected code with pinned tools; no test suites or runtime execution.
- [x] Review integration and write an honest completion report with remaining audio/runtime acceptance.

## Ledger

## Authorized full-demo verification and consolidation

- [x] Reread the complete v3 scope, refresh user asset inventory and inspect the approved board.
- [x] Back up affected source/data/tooling and preserve unrelated dirty work.
- [x] Test the remaining activities, identity, wardrobe, mirror, covers, companion choices and disabled commerce through Roblox MCP.
- [x] Reproduce and fix invisible story text, stale finale copy, obsolete quest regeneration and ambiguous bank display.
- [x] Standardize a final v3 launcher/place/package and implement demo-only reversible archival cleanup.
- [x] Fresh-build Studio regression, presentation and world acceptance checks.
- [x] Verify the final archive and archive safe older generated builds with checksums.
- [x] Present the final local demo with explicit audio/deployment acceptance boundaries.
- [x] Archive the last old MPC-v3 place after the user closes that Studio window; its lock was removed normally and the final window remains open.

The user explicitly requested this execution and verification through Roblox MCP. Existing pending-audio/map decisions, disabled commerce and local-only deployment policy continue to apply. No further design-selection approval is needed for these fixes.

- Ruling: Execute the supplied detailed design/work order directly; it already specifies the intended implementation. Preserve native Luau architecture and current local art. No additional design approval is needed for the authorized implementation.
- Ruling: The actual audio ZIP is additional supplied source, not evidence that the written map changed. The user chose to retain the written map and leave mismatches pending.
- Ruling: The handoff explicitly prohibits commits and test suites. Those constraints replace skill defaults.

- Final source evidence: 75 changed Luau files, pinned StyLua/Selene clean; Rojo local build passed. No test suites or runtime sessions. Audio admission/runtime acceptance remain explicitly pending.
