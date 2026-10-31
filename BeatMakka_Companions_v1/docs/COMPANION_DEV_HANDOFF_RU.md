# Frequency Zero / BeatMakka — Companions v1.0: Codex dev handoff

**Repository:** `https://github.com/slafftrosheen/BeatMakka`  
**Inspected ref:** `main@a4a309bdb5b8db90ddad4ddb6f07a7f61d74a29c`, 2026-10-25  
**Status:** local source-compatible candidate patch, **not merged/pushed, not executed in Studio, not runtime accepted**.  
**Goal:** Alissia and Nikolas live inside the existing sampler-first game loop as *optional* companions. Preserve MK-I, real audio truth, Mica and all player-owned progress.

## 1. Non-negotiable source authority

Read `AGENTS.md`, `CODEX_START_HERE.md`, `README.md`, `01_Visual_Artbook.pdf`, `02_Production_Atlas.pdf`, `BeatMakka_World_v2/BeatMakka_World_Artbook_v2_RU.pdf`, `docs/WORLD_ATLAS_2026-10-24.md`, `docs/NEEDLE_QUAY_DEMO_BUILD_PLAN_2026-10-24.md`, and production NPC prompts/manifests before promotion. The approved visual board at `assets/references/needle-quay-approved-style-board.png` wins over generic concept imagery. Inspect local user asset folder listed in `AGENTS.md` when available; it was **not accessible to this authoring environment**.

Rules from repo: **no asset upload/publishing to Roblox from testing account, no paid Tripo, no CI creation, no unrelated feature changes, no commit/push without explicit new authorization**. This package intentionally contains no childhood source photo and no Roblox upload IDs. These images remain candidate concept art, not imported models.

## 2. Actual inspected architecture / where to connect

| Existing module | Verified responsibility | Companion integration |
|---|---|---|
| `src/server/MusicService.luau` | server-owned `MusicNetwork.Command` / `.State`; `Hello`, sample discovery, station, save/restore, Stage, Chapter | `CompanionSelect` whitelisted **before** sampler ownership gate; `State.companion` server-derived |
| `src/server/ProfileStore.luau` | schema 2 snapshot, conflict-aware async `UpdateAsync`, local Studio session mode | optional `companion: "none" \| "alissia" \| "nikolas"` field, sanitized on load/capture |
| `src/shared/FirstPerformanceQuest.luau` | Mica first courtyard set | remains sole authoritative first concert progression |
| `src/shared/NeighborhoodMissions.luau` | `metal_pulse`, `vent_duet`, `helper_reply` from saved shelf evidence | read-only hints using `Missions.summary`, **never** award flags |
| `src/shared/BeatBook.luau` | 4 A-D patterns, six shelf positions, saved pattern check | no changes; hints refer to real saved evidence |
| `src/shared/DiscoveryCatalog.luau` | fixed I01–I03 virtual sounds | no fake sample IDs or mic capture |
| `src/client/CommandPolicy.luau` | client affordance guard, authority stays server | permit only valid ready-state `CompanionSelect` away from a station |
| `src/client/init.client.luau` | State listener, heartbeat, teardown | update companion dock and client-only blockout follow |
| `src/client/WorkshopView.luau` | MK-I performance, Sounds, Beats, settings | no tab additions or duplicate playback controls |
| `src/server/WorldBuilder.luau` | authored workshop/first-zone blockout | deliberately untouched in v1; don't pretend production venues are present |

`assets/production/needle-quay/npcs/npc-manifest.json` already has six new adult design candidates plus canonical Mica/H04; character status remains `LOCAL_DESIGN_AND_RIG_CANDIDATE`, with no new imported rigs. The companion IDs use `NQ-CMP-` prefix, separate from `NQ-NPC-`.

## 3. Source patch deliverables

```
src/shared/CompanionCatalog.luau      Stable IDs, names, palette keys, safe selection sanitizer
src/shared/CompanionProgress.luau     Server-derived hint & story beat from existing quest states
src/client/CompanionView.luau        Select Alissia / Nikolas / Alone in roaming only
src/client/CompanionFollower.luau    Client-only collision-free model fallback, smoothing, teardown
tools/apply_companions.py             Fail-closed anchored edits to four existing files
```

**Integration script touches exactly:** `MusicService`, `ProfileStore`, `CommandPolicy`, and `init.client`; no new RemoteEvents, libraries, paid services, or ProfileStore schema bump. Creates four modules. No writes happen unless `--dry-run` is omitted. Before applying, make a clean local Git worktree/branch and diff source. Do not launch builds in a loop after every line edit.

```powershell
cd C:\work\BeatMakka
# Confirm origin/main HEAD, git status, source files, and local assets.
git status --short
python path\to\bundle\tools\apply_companions.py --repo . --dry-run
python path\to\bundle\tools\apply_companions.py --repo .
# Copy documents into docs/ only after reviewing the actual updated repo.
rokit install
stylua src
selene src
rojo build default.project.json --output work\BeatMakka-companions-candidate.rbxlx
```

The supplied Python patch script rejects drift when exact source anchors are gone or files exist; it is deliberately **not** a blind `git apply` against an unknown newer branch. A Codex run should review/edit these anchors if current main diverged.

## 4. Network protocol / trust model

Existing `RemoteEvent` names are unchanged. Client sends only:

```
Command:FireServer("CompanionSelect", "alissia")
Command:FireServer("CompanionSelect", "nikolas")
Command:FireServer("CompanionSelect", "none")
```

- Server validates player profile and readiness, existing token budget, type and exact known ID.
- Sender can select **only their own** profile preference. The client cannot select an NPC for someone else and never sends a reward, sound ID, world position, progression, or music pattern in this operation.
- Changing a valid selection increments `editVersion`; sets `progressNeedsSave`; existing `drainQuestSave` persists through `ProfileStore` snapshot conflict detection. Old profile saves load as `"none"`; schema remains 2.
- State payload `companion` is projection, not trusted input. Format: `{ selected, available, name?, title?, role?, hint?, progress? }`.
- Hints are derived from `unlocked.I01`/I02/I03, server accepted `quest`, `Missions.summary` and chapter completion. They are **not** a new quest authority. Suppressing/closing the UI does not suppress or break gameplay.
- `CompanionFollower` adds client-local parts with `CanCollide=false`, `CanTouch=false`, `CanQuery=false`; no world collisions or server physics, no exposed interaction reward.
- Choices do not grant cosmetics, currency, badges, badges/achievements, extra samples, unlocks, or boosts in this batch.

## 5. Gameplay dependency trace

```
player starts -> current ProfileStore schema-2 state / option none
      |
      +-> current Mica quest + MK-I remain playable exactly as before
      |
      +-> optional select Alissia / Nikolas in roaming UI
                  |
                  +-> MusicNetwork.Command / server allowlist
                  +-> ProfileStore snapshot / server State.companion
                  +-> client follower appearance, with pause/hide in performance UI
                  +-> player action in actual game (collect I01/I02/I03; add steps; store/save)
                                    |
                                    +-> existing server Quest/Missions validators
                                    +-> next State update displays next hint
                                    +-> no companion-produced reward
```

### Companion journey per real mission

- **Intro:** both recommend meeting Mica, without auto-accepting `first_courtyard_set`.
- **I01 Dockside Exchange:** Alissia leads player's attention to the sound; Nikolas explains two *different unmuted steps* and using the shelf.
- **I02 Repair Alley:** Alissia points out timbre; Nikolas explains metal + vent as one audible saved pattern.
- **I03/Breakwater:** Alissia helps locate chirp; Nikolas explains two distinct chirp rhythms on saved patterns.
- **Lantern Room / concert:** both respect existing `ChapterConcert` six phases, player-owned save, listening consent and mute/leave affordances; no additional completion requirement.
- **P3 Vinyl Market:** narrative hook with Naya/Sana and later visual dialogue only; new 3D scene action deferred until P3 is actually live.

## 6. Critical preservation contracts

- H01 MK-I exact 16 physical pads, 16 steps, four A–D patterns, BPM 60–180, six shelf slots and 4500-triangle assembled instrument cap are unchanged.
- Do not rename H04/Mica, I01/I02/I03 or original samples `metal_hit`, `vent_thump`, `robot_chirp`. A style kit must never be gated by a locked district.
- No modifications to listening/StageQueue/concert clock; client follower is visual only; VFX OFF must not hide the meaningful companion hint text.
- No automatic handling of free mic sample recording; AudioRecorder and permissions are not part of this implementation.
- No school-like grades, public rankings, pressure to invite a friend, or forced NPC progression. The default "Alone" mode is fully supported.
- Do not put true child portraits, names plus personal identifying data, family photos or raw source imagery in a public repository.

## 7. QA matrix: required before marking implemented

`[ ]` Repo-clean application on latest HEAD. Compare `git diff` and audit no unintended changes.

`[ ]` `stylua` + `selene` on changed Luau; pinned Rojo build. Author/execute focused unit checks only with user approval per AGENTS.md. The included files were **not** run in Studio from this chat.

`[ ]` New profile: selected companion `none`; Mica and all original quests operable; no follower.

`[ ]` Choose Alissia -> hint tracks actual I01/02/03. Choose Nikolas -> hint tracks **stored/save-validated** `metal_pulse`, `vent_duet`, `helper_reply`. Forged client state never grants flags.

`[ ]` Invalid inputs (`number`, `{}`, unknown string, other user's ID, spam) rejected; selection never bypasses ready or rate limiting.

`[ ]` Selecting companion during another async save cannot overwrite newer shelf data; failed save leaves clear `saveMode` and retry behavior; legacy schema 1/2 without companion field remains readable. Cloud rejoin requires an authorized private experience.

`[ ]` Selecting while remote session is open doesn't steal pad keyboard focus, hide Stop/Leave, or interrupt audio clock; on reopen the UI remains available.

`[ ]` Respawn, moving away, streaming transitions, listening, chapter performance and script Destroying leave no orphan parts/connections.

`[ ]` 2–3 clients: per-player choice and hints remain independent; local follower never changes another user's world; no client-unlocked region sharing.

`[ ]` Physical phone portrait/landscape, tablet and gamepad: companion dock not under Roblox top bar / on-screen joystick / important prompts; selection controls >= 44 px, readable without color.

`[ ]` Verify all current H04, Mica, FirstPerformanceQuest, NeighborhoodMissions, ChapterConcert, stage controls, audio, room, and discovery contract checks after patch. No publisher audio or mesh IDs invented.

`[ ]` Compare new character art with **visually opened** approved PDFs + real NPC render sheets. Artist signs off two consistent turnarounds before modeling; current candidate PNGs are concept only.

## 8. Follow-up production batches (do not mix into integration)

- **C1** Studio source validation, phone QA, optional selection UX, server save migration audit. Decide whether UI works well enough in current blockout before expanding.
- **C2** Author separate Alissia/Nikolas front/side/back neutral refs; Blender low-poly meshes, matched skeletons and original material maps; no generated multi-character sheets to Tripo. Log measured triangles, texture sizes, rigs, license/provenance.
- **C3** Local Roblox Studio import and animation, no asset uploads. Replace `CompanionFollower` primitive stand-in with accepted model/animation factory; LOD/perf on phone; never assign in-memory generated visuals as published asset IDs.
- **C4** Add context-aware physical NPC encounter points only once Needle Quay P1–P4 blockout/quests actually exist; authority remains existing mission/profile service. Introduce bounded, optional narrative interactions with proper localization.
- **C5** Polishing, live 2–3 player, cloud rejoin and real phone verification, only when requested/authorized. No silent Tripo/Roblox account spend.

## 9. Files / links to keep together

`docs/COMPANION_ARTBOOK_RU.md`, `docs/COMPANION_DEV_HANDOFF_RU.md`, `data/companion-production.v1.json`, `art/Character_Turnarounds_CANDIDATE.png`, `art/Character_World_Scenes_CANDIDATE.png`, the four added Luau modules, and `tools/apply_companions.py` are one candidate package. `COMPANION_ARTBOOK_RU.md` contains all narrative + art constraints; this file is the technical change contract.

**What is actually true now:** the repository was read and the integration patch is authored locally; **nothing has been applied to the user's checkout, committed, deployed, uploaded to Roblox or run in Studio**. The sole correct next move for Codex is a clean merge into an updated worktree plus source validation.
