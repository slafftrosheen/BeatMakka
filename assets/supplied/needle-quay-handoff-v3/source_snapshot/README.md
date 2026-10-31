# Frequency Zero

Frequency Zero is a Roblox music-making game built around a playable sampler and a cozy creative neighborhood. The proposed first zone is Needle Quay. The instrument and creation loop lead; the world supports them.

The [Needle Quay playable-experience chapter](docs/needle-quay/PLAYABLE_EXPERIENCE_BIBLE_2026-10-30.md), **A Place for Every Sound**, adds a story around the existing route, four optional activities, Listener/Beatmaker/Neighbour progression, an accessory wardrobe and a cosmetic shop with sales disabled. The [implementation handoff](docs/needle-quay/EXPERIENCE_IMPLEMENTATION_2026-10-30.md) separates implemented source from pending Studio/device/save/art acceptance; [commerce setup](docs/needle-quay/COMMERCE_SETUP.md) describes the later production configuration. Rebuild/sync current source to use these changes; the older packaged place is not updated automatically.

The [historical Needle Quay local demo](docs/needle-quay/LOCAL_DEMO_2026-10-25.md) integrates the district map, four parking venues, personal Roamers, thirteen activities and the six-phase finale. Run `output/needle-quay-demo/Launch-NeedleQuay.ps1` to install the checksum-checked local content and open its packaged Studio build. Exact local meshes, PBR finishes and 184 WAV bindings are recorded there; [the subsequent artbook revision](docs/needle-quay/ARTBOOK_REVISION_2026-10-25.md) supersedes its art-acceptance claim. Multiplayer, real-device and cloud rejoin acceptance remain separate.

The project starts as a file-system-first Luau project. Roblox Studio is the place/runtime editor, Rojo syncs local source into Studio, and Rokit pins project tools. Blender is the DCC for authored geometry and cleanup. Tripo is an optional offline asset-production route; it is not a game runtime dependency.

## Requirements

- Roblox Studio (installed locally on the current workstation).
- Rokit 1.2.0 or newer.
- Node.js 20+ and `tripo-cli` 0.7.2 for non-billable Tripo planning and account commands. Account configuration is external; inspect current connection state rather than treating the historical B00 setup status as current.
- Blender 5.2 (installed under `%ProgramFiles%\Blender Foundation\Blender 5.2` on the setup workstation).

Project CLIs are pinned in `rokit.toml`: Rojo, Selene, and StyLua. No Wally packages or other external Luau dependencies are used yet.

## First setup

From the repository root in PowerShell:

```powershell
rokit install
rojo build default.project.json --output work\FrequencyZero.rbxlx
rojo serve default.project.json
```

Open Roblox Studio, open the Rojo plugin, and connect it to the local server. `rojo serve` stays running while Studio is connected. The generated place file is a local build artifact and is ignored by Git.

For Blender, launch:

```powershell
& "$env:ProgramFiles\Blender Foundation\Blender 5.2\blender.exe"
```

## Project layout

- `src/shared/` - shared Luau modules replicated to clients and server.
- `src/server/` - server scripts.
- `src/client/` - player scripts.
- `assets/references/` - approved visual references and provenance.
- `assets/candidates/`, `assets/dcc-clean/`, `assets/approved/` - separate asset pipeline stages.
- `assets/studio-evidence/` - actual Roblox Studio import and runtime evidence.
- `data/assets.json` - canonical asset contracts and budgets.
- `data/job_recipes.json` - candidate route and per-asset Tripo plan fields.
- `docs/B00_CONNECTION_AND_CAPABILITIES.md` - current non-billable integration evidence and blockers.

## Asset work

The current local implementation is covered by the [workshop play and import guide](docs/WORKSHOP_PLAY_GUIDE.md), [material customization guide](docs/MATERIAL_CUSTOMIZATION.md), and [milestone design](docs/WORKSHOP_MILESTONE.md). It includes a sampler, discovery route, saved finish presets, optimized models, texture sets and UI sources. Persistent mesh uploads and successful image/audio loading remain separate acceptance steps.

The [courtyard listening milestone](docs/LISTENING_MILESTONE.md) adds podium snapshot sharing, opt-in listening, accessible stage entry, and leave/mute controls. The subsequent two-client MCP run passed its session/ownership/cleanup checks; audible playback and final asset acceptance remain separate.

The [first-zone coverage table](docs/IMPLEMENTATION_COVERAGE.md) maps all 74 packages to sources. [Runtime verification](docs/RUNTIME_VERIFICATION.md) records the subsequent Studio MCP checks and fixes, including the remaining asset/audio/device acceptance. Build the current complete source place with `rojo build default.project.json --output work/FrequencyZero-Complete.rbxlx`.

Read `AGENTS.md`, `CODEX_START_HERE.md`, `TRIPO_RUNBOOK.md`, the two supplied art/production PDFs, and the source ledger before asset work. The original approved [style board](assets/references/needle-quay-approved-style-board.png) is restored with [provenance](assets/references/needle-quay-approved-style-board.json). B00 records historical setup gaps, not present-day connection or acceptance state. The dated execution log and evidence remain authoritative for completed batches.

The [audio/content readiness continuation](docs/AUDIO_CONTENT_CONTINUATION.md) records safe incremental binding, bounded audio readiness handling, and the remaining authorized acceptance work. It is source implementation, not a replacement for Studio/runtime evidence.

The [next playable milestone](docs/NEXT_PLAYABLE_MILESTONE.md) implements four independent pattern slots, six personal beat shelf positions and Mica's first courtyard quest. Its [Studio verification](docs/MILESTONE_VERIFICATION.md) records 16 contract groups, 26 two-client checks, the confirmation-expiry fix and phone layouts. Live published cloud persistence and audible content acceptance remain open.

The [audio acceptance stage](docs/AUDIO_ACCEPTANCE_STAGE.md) records the 24-file source inspection, audition reel and proposed private test experience. Uploads, destination ownership and experience permissions remain pending.

The [Alpha 01 work package](docs/ALPHA_01.md) links the 18 GitHub development tasks, audio research and the [36-page MK-I device artbook](output/artbook-alpha01/BeatMakka_MK-I_Artbook_Alpha01_RU.pdf). Its [interactive design prototype](output/artbook-alpha01/MK-I_Prototype.html) demonstrates the proposed fixed performance surface with original local audio; it is separate from Roblox runtime acceptance. Editable sources, design tokens and research references are included in the [artbook package](output/artbook-alpha01/README.md).

Paid provider work is disabled until a named asset batch, current quote, and total credit cap are explicitly authorized and the offline preflight passes. See `docs/EXECUTION_BATCHES.md` and `tools/preflight_gate.py`.

Large supplied source models that exceed GitHub file limits are retained as verified gzip archives. Restore the city model with python tools/restore_supplied_asset.py low_poly_city_pack; SHA-256 and source size are checked before writing the original filename.
