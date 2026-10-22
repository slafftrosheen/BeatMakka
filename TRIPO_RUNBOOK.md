# Tripo production runbook

## 1. Verify the existing connection; do not assume its shape

A Tripo integration may be a Codex plugin invoking a CLI, a direct MCP tool, a Blender-addon bridge, or an authenticated API adapter. The official Codex plugin page and CLI guide describe a Codex-specific route [T05,T06]; the older official MCP repository describes an alpha Blender integration [T13]. They are not interchangeable.

In Codex, inspect available installed skills/tools first. For MCP, `codex mcp list` and `/mcp` expose configured/active servers [O01]. An absent MCP entry does not prove a skill/CLI plugin is disconnected. Read installed tool signatures; for the CLI inspect `tripo --version`, `tripo --help` and `tripo make --help`. The documented `tripo doctor` performs connection/account checks [T05]. Read the installed agent documentation with `tripo docs --llm`, then `tripo docs --topic commands/make` and `tripo docs --topic examples/game-asset`; these are documented inspection commands, not generation commands [T05]. Compare bundled guidance with current online docs when versions differ. Never dump local token files. Use browser sign-in when the installed integration supports it; no key in chat. A direct API key must stay in an approved local secret/environment store.

Create templates/connection_receipt.json as a new evidence file, not by marking an untested connection verified. Record route, API family, plugin/SDK version, available model snapshots, exact supported fields, region and account check. If the tool cannot enforce the required face limit, do not use its generic default. Prefer an already-authorized SDK/CLI route with those controls; changing providers or requesting new permissions is a separate user decision.

## 2. Read docs before every batch

Use docs/SOURCES_AND_DOCS_DRIFT.md and data/source_registry.json. Fetch the operation page AND the chosen model card, plus the installed schema. Record a docs receipt with checked_at, model, endpoint, fields and evidence hash. Re-read after 24 hours, a tool update or a validation error. If current docs conflict, stop only the affected paid operation and resolve it; continue deterministic work. A model advertised in a search snippet is not a complete request schema.

Pin a verified model snapshot for the batch. Current-docs-first does not mean blindly switching all assets to the newest Preview model. Keep a compatibility review and an explicit change record when upgrading.

## 3. Generation strategy

**Default candidate:** P1-20260311, image-to-model, explicit face_limit, texture=false, pbr=false, export_uv=true, only after verifying present support [T01,T02]. Both texture and pbr must be false for geometry-only output; otherwise PBR can force texturing [T02]. P1 already targets low-poly geometry. Do not add smart_low_poly, generate_parts, quad or geometry_quality to P1.

**Alternative:** H3.1 with compatible smart_low_poly=true and explicit face_limit, only after updated docs, cost and capability checks [T03]. Do not combine this with segmented-parts mode. For exact moving pieces, split/rebuild in Blender or generate individual approved parts instead of relying on provider segmentation.

**Preview:** P2-20260801 is listed as Preview in current official indexed material [T04]. It is disabled in this pack. Enabling it requires a newly reviewed full schema, approval and a comparison against the P1 baseline. Higher supported face limits are not our asset budgets.

**CLI:** the documented `--for game-mobile` preset is relevant [T05], but its name is not sufficient evidence. Inspect the installed implementation/help or a documented non-billable plan facility, then record model, topology, face cap, texture options and postprocessing. Do not invent a `--dry-run` option. If no preview of resolved settings is available, use explicit verified API fields rather than trusting hidden defaults. Avoid film/ultra/8K paths.

## 4. Reference preparation

Generate from one isolated part, not the district board. Prepare clean neutral-light front/three-quarter references. Resolve backs and undersides in an approved drawing or coherent multiview set. The included crops are style-only; none is pre-approved as generation input. H01 references must show a blank housing without controls.

Text prompts in data/job_recipes.json are for reference creation or a verified text-to-model route. Do NOT attach prompt/negative_prompt to the image endpoint unless its current schema explicitly supports them. For image-to-model the shape guidance lives in the image. For multiview, use consistent views and documented view-key inputs; no mixed modes or contact sheets [T11]. Upload using the integration’s documented file handling. A sandbox path or local filename is not a public image URL and is not a provider file token.

## 5. Non-billable plan and authorization

Resolve the recipe into one request and a full cost estimate, including optional texturing, retopology and conversion. Read the account balance/usage through the existing authorized route [T08]. Obtain an explicit total batch cap and allowed asset list. Default authorized credits are zero. Use one concurrent billable task initially; increase only after verification and budget approval. Two generation attempts per asset is a project ceiling, not permission to spend twice.

Run the offline gate with the actual request, asset registry and current receipts before dispatch. Integrate that guard into any future adapter rather than running it once manually and then allowing unrestricted tools. Human review and truthful evidence remain essential; a local JSON receipt is not a cryptographic attestation of vendor state.

## 6. Submit once; resume safely

Persist a job key built from asset ID, input hash, operation, model and parameter hash. Write submission intent before POST, then persist the real returned task_id immediately. The v3 base candidate is https://openapi.tripo3d.ai/v3; operation routes, field names and output paths must match the verified family [T07,T14]. Do not combine v2 model_version/type payloads with v3 model/input routes.

Poll the existing task using the documented query route and bounded polling, obeying current rate limits. Capture returned errors and status. If submission times out before returning a task ID, mark UNKNOWN_SUBMISSION_OUTCOME and reconcile account/task history; do not automatically POST again. SDK automatic retries must be reviewed for this reason [T14]. Unknown statuses must stop or time out safely, never spin forever.

Download output/preview promptly and keep hashes plus real local paths. Signed URLs are not durable asset records [T14]. Retain sanitized responses, model/texture seeds when supported, and consumed credits. Never attach the Tripo bearer token when downloading a signed CDN URL. Store original raw output read-only before DCC edits.

## 7. Clean, texture and export

Low-poly generation can still produce bad topology, merged components, missing undersides, weak silhouettes or unsuitable UVs. Inspect all sides. Split rig and control parts; rebuild thin elements; author exact dimensions and pivots; triangulate and count after modifiers. Face_limit is requested, measured triangles are accepted.

Prefer deterministic palette materials and shared trim/atlas reuse. Tripo does not promise our shared atlas. Re-UV/rebake deliberately. For a texture-only problem, reuse accepted geometry via the documented texture workflow or DCC tools rather than generating a new shape [T12]. Any retopology/convert job needs its own verified options and cost; documentation drift is recorded for retopology [T09].

Keep GLB as raw source if supplied. Deliver validated FBX or glTF for Studio, preserving hierarchy and separate maps as needed [R01,T10]. Check actual texture dimensions after export; standard texture quality is not a 512/1024-pixel guarantee. Never rename .glb to .fbx. Final coordinate/pivot changes happen once in DCC/export; avoid conflicting provider rotations.

## 8. Acceptance

Only after art, technical and Studio checks can an asset enter the approved catalog. Import is not public publishing. Verify ownership/access before binding IDs. All runtime assets are pre-generated; Roblox clients never contain provider credentials or call Tripo. Use docs/QA_AND_ACCEPTANCE.md and templates/asset_evidence.json.

Sources: IDs refer to docs/SOURCES_AND_DOCS_DRIFT.md. Policy thresholds and stage names are project decisions.
