# Project instructions

## Scope and sources

- Before any visual work, inspect `C:/Users/slavd/OneDrive/Pictures/Assets` for user-supplied materials, textures, and models. The user adds files there over time; refresh the inventory when starting visual work. Copy every asset actually used into the repository with source provenance.
- This is the Roblox music-making project described in `CODEX_START_HERE.md`.
- Treat `01_Visual_Artbook.pdf`, `02_Production_Atlas.pdf`, `Asset_Production_Register.xlsx`, and `TRIPO_RUNBOOK.md` as project source material. The supplied visual board remains the visual authority. It is restored at `assets/references/needle-quay-approved-style-board.png`, with its original-attachment provenance and SHA-256 in the adjacent JSON. Use it for art direction, not as a multi-object Tripo input.
- Keep the machine-readable asset contracts in `data/` aligned with the supplied register. Preserve canonical IDs. Treat dimensions, budgets, and visual proposals as authored project constraints, not platform limits.
- Preserve stage separation: candidate -> DCC-clean -> art-approved -> Studio-imported -> runtime-verified. Never promote an asset based on a provider task or preview alone.

## Tripo and spending

- No Tripo spend is authorized by default. Do not generate, texture, convert, retopologize, or otherwise submit billable work without a current batch cap and named asset list explicitly approved by the user.
- Before any billable operation, refresh official docs and the connected schema, produce the exact resolved request/cost with a non-billable dry run, and require `tools/preflight_gate.py` to pass.
- Do not read, print, copy, or commit Tripo credentials. Keep credentials in the CLI's external user profile or an approved secret store.
- Prefer pinned P1 geometry-first output with per-asset caps when the current schema supports it. Never send P1-incompatible topology fields. Keep P2 Preview disabled unless the user explicitly approves it after a separate review.
- Network timeouts or unknown submission outcomes must never trigger automatic resubmission. Preserve real task IDs and reconcile usage first.

## Roblox and asset acceptance

- **User deployment policy, 2026-10-25:** keep all assets local and in Git. Do not upload any assets, images, models, textures, audio, or places to Roblox, and do not publish/update an Experience from the current testing account. Local Studio inspection/testing may use existing permitted bindings. Deployment will later use the user-designated adult account, under fresh explicit deployment authorization; do not infer account eligibility, monetization rights, or upload consent from this plan.

- Build exact controls, interfaces, modular joins, pivots, and collision deterministically in code/DCC. Use Tripo only for an isolated, reviewed candidate shape.
- Never create CI workflows, publish production assets, or introduce a runtime Tripo dependency without a direct user request.
- Keep asset IDs, permissions, importer warnings, measured geometry/maps, and Studio/runtime evidence truthful and traceable.
- Keep gameplay text and localization out of generated textures. Preserve authored/source models and provenance.

## Development workflow

- Use the project-pinned tools from the repository root with Rokit.
- Do not add dependencies unless the project needs them. Do not add test suites or run them unless the user asks for tests or verification.
- Do not commit or push unless the user explicitly requests it. The 2026-10-25 instruction to keep the current asset-production results local and on Git authorizes scoped Git preservation of this production work; preserve unrelated in-progress gameplay changes separately.
