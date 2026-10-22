# B00 connection, docs, and capability receipt

Checked: 2026-10-22. This is non-billable setup evidence. No model generation, paid processing, account login, Studio import, or runtime acceptance occurred.

## Connection summary

| Route | Evidence | Result |
| --- | --- | --- |
| Codex Tripo skill | Local `tripo-3d` and `tripo-game-asset` skill files are present under the installed Tripo plugin cache. | Available as guidance; this does not prove a connected provider account or exposed generation tool. |
| Tripo MCP/tools | `codex mcp list` contains no Tripo server, and no Tripo tool schema is exposed to this task. | Not available here. |
| Tripo CLI | `tripo-cli` 0.7.2 installed; local `docs --llm`, `commands/make`, `commands/generate`, `commands/account`, and `examples/game-asset` inspected. | Available for local dry runs. |
| Tripo account | `tripo doctor` reports Node OK, API key missing, API reachability skipped, and the default region it would use is `ov`. No balance or usage query could authenticate. | Not connected; account, selected region, balance, and live usage remain unverified. |
| Roblox Studio | Local Studio executable and `mcp.bat` are present. Codex lists `Roblox_Studio` as enabled. Rojo plugin 7.7.0 is installed. | Installed/configured, but Studio tools were not exposed in this task session and no live sync/import was performed. |
| Blender | Blender 5.2.2 is installed under Program Files. | Available by full path; not on `PATH`. |

## Resolved CLI capabilities

| Capability | Available? | Evidence and limit |
| --- | --- | --- |
| Explicit per-request `face_limit` | Yes | CLI dry runs resolve P1 face limits 2,200 and 900 into request payloads. The current official P1 search result reports 48–20,000, while the CLI skill reference says 50–20,000; both ranges include these project caps. Reconfirm before a paid batch. |
| Explicit model selection | Yes | CLI help accepts `--model`; dry runs resolve `tripo-p1` to wire model `P1-20260311`. |
| Low-poly P1 route | Yes | P1 is the selected low-poly model. Current docs say it does not support `smart_low_poly`, `generate_parts`, `quad`, or `geometry_quality`; those fields are excluded. |
| Geometry-only output | Yes | Dry runs accept `texture=false`, `pbr=false`, and `export_uv=true`; they return a no-texture cost note. |
| Game-mobile preset | Available, unsuitable by default | Dry run resolves P1 with face limit 15,000, `texture=true`, `pbr=true`, standard texture, and FBX conversion with 2,048 texture size. This project uses tighter per-asset limits and geometry-first output, so use explicit parameters instead. |
| Result download | Yes | CLI `make` downloads results by default; `task get --download` can fetch a successful task into an output directory. No result exists yet. |
| Usage tracking | CLI support yes; account evidence unavailable | CLI exposes `balance`, `usage`, task queries, task IDs, and credits consumed. `doctor` found no API key, so no live account usage was read. |

The B01 H01 dry run now resolves an explicit P1 text-to-model request, using the documented text route permitted by `TRIPO_RUNBOOK.md`. It is non-billable and validates only the CLI payload. H05 remains an image-to-model proposal and still needs an approved isolated reference.

## Initial non-billable batch plan

| Item | Route and constraints | Cost estimate | State |
| --- | --- | ---: | --- |
| H01 sampler housing | P1 text-to-model, `face_limit=2200`, `texture=false`, `pbr=false`, `export_uv=true`. Housing only; 6 x 1.25 x 4 studs; bottom-center pivot; front -Z. Build the 4 x 4 pads, screen, labels, and targets deterministically. Full assembled cap: 4,500 triangles. | 30 credits for one bare P1 text-to-model request, based on the installed Tripo CLI pricing table. | Blocked: account region and paid cap are not confirmed. |
| H05 curved street lamp | P1 image-to-model, `face_limit=900`, `texture=false`, `pbr=false`, `export_uv=true`. 2.5 x 12 x 3 studs; floor-center pivot; separate emissive insert and light attachment. Full asset cap: 1,100 triangles. | 40 credits for a bare P1 image-to-model request, based on the current P1 card. | Blocked: isolated approved reference missing; no paid cap. |
| M03 + M05 + M10 storefront corner | DCC/code exact: 1 x 12 x 1 corner post, 8 x 12 x 1 display-window bay, and 8 x 2 x 4 awning bay on the 4-stud planning grid. No Tripo request. | 0 provider credits. | Exact outer bounds are recorded. The window opening dimensions are unspecified, so do not freeze its cutout until the missing reference/graybox decision is available. |

The proposed B01 H01 estimate is 30 provider credits before any optional work. It is not an approved cap or authorization. Batch B00 and all paid batches remain at 0 authorized credits.

## Remaining B00 blockers

- `references/APPROVED_STYLE_BOARD.png` is named in the handoff but was not present in the provided folder. The PDFs supply art direction and crops, not approved isolated generation inputs.
- `docs/SOURCES_AND_DOCS_DRIFT.md`, `docs/EXECUTION_BATCHES.md`, the referenced `data/assets.json`, `data/job_recipes.json`, and `tools/preflight_gate.py` were missing initially; repository copies now bootstrap the register and this setup. Source files should be reconciled with the complete originals if they are provided later.
- The official Tripo P1 search result and installed CLI agree on P1-20260311 and its geometry-only fields, but the fresh direct P1 page open redirected to the P2 page. The per-asset limits used here remain within both documented P1 face-limit ranges.
- The current Roblox texture page reports 4K support near the top and also a 1K maximum in its UV section. The project uses 512/1024 authoring budgets as project limits, not as claims about the platform maximum.
- No Tripo login, account/region confirmation, paid request, DCC cleanup, Studio import, ownership check, or runtime evidence has occurred.

See `templates/connection_receipt.json` and `docs/evidence/b00/docs_receipt.json` for machine-readable receipts; the other files under `docs/evidence/b00/` preserve the local command outputs.
