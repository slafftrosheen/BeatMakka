# Sources and documentation drift

Live source check: 2026-10-22. Recheck this ledger before each paid batch, after any CLI/plugin update, and after any schema validation error. The asset register snapshot is not a permanent API contract.

## Tripo

| Source | Current observation |
| --- | --- |
| [P1 model card](https://developers.tripo3d.ai/en/models/p1) and [P Series image-to-model](https://developers.tripo3d.ai/en/docs/generation-image-to-model/p) | P1 snapshot is `P1-20260311`, the low-poly option. The P1 search result reports 48-20,000 faces, while the installed Codex CLI skill reference reports 50-20,000. The CLI accepts this project's 900 and 2,200 caps and resolves them in dry runs. P1 excludes `smart_low_poly`, `generate_parts`, `quad`, and `geometry_quality`. Bare image-to-model is listed at 40 credits; standard texturing is 50. The image endpoint defaults to `texture=true` and `pbr=true`, so both must be explicitly disabled for the project's geometry-first request. |
| [Image-to-model API schema](https://developers.tripo3d.ai/en/docs/generation-image-to-model/p) | Current request family is v3. An image request carries an input reference, model snapshot, face limit, texture/PBR flags, and optional supported parameters. Use the CLI for upload, task persistence, downloads, and accounting; do not build a second submitter for this setup. |
| [Tripo CLI](https://developers.tripo3d.ai/en/docs/cli) | Documents `game-mobile` and non-billable plan/dry-run behavior. The local 0.7.2 dry run resolves the preset to P1 with `face_limit=15000`, texture and PBR enabled, plus a 2,048-size FBX conversion. The project must pass explicit per-asset caps and geometry-only settings instead. |
| [Task query](https://developers.tripo3d.ai/en/docs/task-query) and [billing](https://developers.tripo3d.ai/en/docs/billing) | Task queries expose status/output/accounting; the CLI exposes task IDs, downloads, `balance`, `usage`, and consumed credits. No account data was read because the local CLI has no API key. |
| [Codex plugin](https://developers.tripo3d.ai/en/docs/codex-plugin) | Official guide exists. The local skill files are installed, but there is no Tripo MCP entry or provider tool signature in this task session. A skill file alone is not a connected account. |

### Tripo receipt evidence

- Installed CLI: `tripo-cli` 0.7.2; Node.js 22.23.2.
- `tripo doctor`: Node check passed; API key missing; reachability skipped. Its fallback would use region `ov`, but no account region was verified.
- Explicit P1 dry runs succeeded for face caps 2,200 and 900 with `texture=false`, `pbr=false`, `export_uv=true`. They were text-only schema placeholders and made no network calls.
- Result downloads are available with the default `make` behavior or `task get --download`; `task get` and `usage` help were inspected.
- No generation, upload, billable conversion, or account login occurred.

## Roblox and Rojo

| Source | Current observation |
| --- | --- |
| [Roblox Studio Importer](https://create.roblox.com/docs/studio/importer) | Studio imports mesh files as `.fbx`, `.obj`, or `.gltf` (including `.glb`); `.fbx` and `.gltf` support multiple objects and hierarchies, PBR textures, rigs, and animation. GLB imports can create nested Models per glTF mesh primitive, so inspect hierarchy during the real Studio import. Review settings to preserve this project's GLB parts: Import Only As Model on, Merge Meshes off, Scale Unit Studs, and preserve imported pivots. `Upload to Roblox` defaults on; turn it off for local review and keep Add to Workspace on. |
| [Roblox texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications) | The current page recommends 256/512/1024 sizes by object scale and says 4K is supported, but its later UV section also says a 1024 maximum for texture maps. Keep 512/1024 as the project's own authoring cap until Roblox's exact current map limits are confirmed for the chosen import route. Roblox also documents one material per mesh and one UV set per component. |
| [Roblox third-party tools](https://create.roblox.com/docs/projects/external-tools) and [Rojo project setup](https://rojo.space/docs/v7/getting-started/new-game/) | Local files sync to Studio through Rojo. Project tool versions are pinned with Rokit. The installed workstation already has Rokit and Roblox Studio; the repo now pins Rojo, Selene, and StyLua. |

## Missing source files and unresolved choices

- The user-selected `references/APPROVED_STYLE_BOARD.png` was not in the provided folder. The PDFs contain crops and authored proposals, not approved isolated model inputs.
- The supplied folder did not contain the original `docs/SOURCES_AND_DOCS_DRIFT.md`, `docs/EXECUTION_BATCHES.md`, or referenced JSON/templates/scripts. This repo creates bootstrap versions from the supplied handoff and register. Reconcile with originals if later supplied.
- Exact storefront window cutout dimensions are not specified in the supplied materials. The outer M03/M05/M10 dimensions and their 4/8-stud mounting grid are captured; do not lock the opening yet.
- The official P1 model page search result presents the P1 data, while a fresh direct page open redirected to the P2 page. The installed CLI schema and the P Series image endpoint were separately inspected; the discrepancy remains in the receipt for recheck before billing.
