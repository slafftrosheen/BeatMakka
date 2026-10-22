# Frequency Zero

Frequency Zero is a Roblox music-making game built around a playable sampler and a cozy creative neighborhood. The proposed first zone is Needle Quay. The instrument and creation loop lead; the world supports them.

The project starts as a file-system-first Luau project. Roblox Studio is the place/runtime editor, Rojo syncs local source into Studio, and Rokit pins project tools. Blender is the DCC for authored geometry and cleanup. Tripo is an optional offline asset-production route; it is not a game runtime dependency.

## Requirements

- Roblox Studio (installed locally on the current workstation).
- Rokit 1.2.0 or newer.
- Node.js 20+ and `tripo-cli` 0.7.2 for non-billable Tripo planning and account commands. Authentication is optional and has not been configured by this repository setup.
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

Read `AGENTS.md`, `CODEX_START_HERE.md`, `TRIPO_RUNBOOK.md`, the two supplied art/production PDFs, and the source ledger before asset work. The approved style board, full source-drift ledger, execution-batch checklist, and some referenced templates were not included in the provided folder; B00 records these as setup blockers rather than inventing evidence.

Paid provider work is disabled until a named asset batch, current quote, and total credit cap are explicitly authorized and the offline preflight passes. See `docs/EXECUTION_BATCHES.md` and `tools/preflight_gate.py`.
