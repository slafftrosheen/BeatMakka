# Needle Quay — complete local Codex handoff v3

**Revision 3, 30 October 2026. Use this full ZIP in place of the earlier handoffs.**

This consolidates the playable Needle Quay experience, whole-game MPC workflow, test-pack retirement and first final 64-sample pack. The latest music direction is an original vocal harbour song, with four reserved vocal pads inside Bank D.

The user has sent a music prompt to the music agent. A shorter vocal correction has also been provided to the user; forwarding that correction and song approval have not been confirmed. Continue the game work locally, preserving their uncommitted changes. Do not start another music-generation task.

## The required experience

Keep **A Place for Every Sound**: the Roamer, residents with motives and relationships, optional side activities, Listener/Beatmaker/Neighbour progression, wardrobe and saved looks, and the cosmetic Robux shop implementation with sales disabled pending production setup. `EXPERIENCE_SCOPE.md` consolidates that work and distinguishes supplied code from remaining targets.

## The music model

**A/B/C/D means four SOUND banks of 16 pads, for 64 samples. Remove the fixed A/B/C/D musical-pattern system. Replace it with named reusable sequences, real MPC-style Song Mode and separately saved finished songs.**

This is a whole-game requirement: data, recording, playback, saves, UI, jam/listening/stage, quests and finale. Renaming the controls to Pattern 1–4 does not satisfy it.

## Read first

1. The actual local working copy's current `AGENTS.md` and `CODEX_START_HERE.md`.
2. `CODEX_UPDATE_V3.md` — the consolidated changes, including how to continue if an earlier ZIP is already merged.
3. `LOCAL_AGENT_TASK.md` — local merge and execution work order.
4. `EXPERIENCE_SCOPE.md` — lore, story, activities, RPG, wardrobe and shop scope/status.
5. **`MPC_WORKFLOW.md` — authoritative workflow, object model, whole-game migration and completion criteria.**
6. `MPC_WORKFLOW_CONTRACT.json` and `MPC_PROJECT_EXAMPLE.json` — semantics and a pending-audio example draft.
7. `REMOVE_TEST_PACKS.md`, then `FIRST_PACK_SPEC.md` and `FIRST_PACK_64_SLOTS.json`.
8. The original experience bible/implementation/commerce documents under `source_snapshot/docs/needle-quay/`, read as the experience baseline subject to this revision's musical replacement.

## Contents and precedence

| Location | Purpose |
|---|---|
| `LOCAL_AGENT_PROMPT.txt` | A short instruction to paste into the local Codex session. |
| `EXPERIENCE_SCOPE.md` | Current experience scope, story, side activities, creative progression, wardrobe and cosmetic shop. |
| `MPC_WORKFLOW.md` | Sequences, Song Mode, Finished Songs, migration, protocol, UI, world consumers and revised quest evidence. |
| `CODEX_UPDATE_V3.md` | All current changes and the specific v2-to-v3 vocal amendment. |
| `source_snapshot/` | Complete original incoming experience source: 93 Luau files, configuration and the 19-file lore/RPG/wardrobe/shop change. It still contains the legacy music model that Codex must replace. It is not an implemented Song Mode. |
| `merge/base/`, `merge/BASELINE.json` | Exact original versions of five modified existing files, baseline commit and original 19-file change list, for three-way merging around local edits. |
| `merge/NeedleQuay-Experience.patch` | The unchanged original experience diff. It is an input for that earlier implementation, not an implemented MPC music replacement. |
| `reference/` | Original audio manifests and packaging tools, retained as evidence of content paths that must be retired. |
| `FIRST_PACK_64_SLOTS.json` | Schema 2, planning revision 3: exactly 64 proposed sounds. D13–D16 now reserve four vocal cuts in place of the previous effects. Actual audio fields remain null. |
| `MANIFEST.json` | Complete inventory, checksums and implementation status. |

The user's current instructions take precedence. Within this archive, the top-level v3 task, experience scope, MPC contract and first-pack contract define the target. The source snapshot and merge inputs are exact historical integration material. Conflicting four-pattern, A/B-variation, bundled Beat Shelf and six-loop-finale statements there are **superseded requirements**. Update source, canonical/generated data, active docs and player-facing help together. Preserve old musical content and earned progress through migration.

## First pack and music production

Bank A contains drums; B bass; C melody/harmony; D twelve harbour sounds and four vocals. D01/D02/D03 keep I01/I02/I03. D13 is the Needle Quay call, D14 a response, D15 a short phrase and D16 a rhythmic vocal hit. Suggested wording remains provisional until the song is heard and approved. There are **64 samples total**, including discoveries and vocals.

The order is **vocal demo song → user approval → 64 clean one-shots → sample approval/admission → runtime integration**. The separate short Flow Music prompt stays outside this ZIP, as requested. Stems and the full song are production sources, not extra instrument pads or player-authored Finished Songs.

## Actual status

- Original experience code is supplied for local integration.
- The four-bank/sequence/Song Mode/Finished Song replacement is specified for the local agent; it is **not already implemented or runtime-verified** in the source snapshot.
- Test-pack removal remains part of the local task.
- No generated song or final one-shot files are contained here. Song approval has not been reported in this conversation.
- No commit, push, Roblox upload/publication, pass creation or shop activation is authorized. Existing local/repository restrictions continue to apply.

This is a complete handoff for the existing local project; it does not duplicate the large world assets or supply a standalone Roblox place. If an earlier handoff is already integrated, continue from current local work and apply the current requirements without force-reapplying the original patch.
