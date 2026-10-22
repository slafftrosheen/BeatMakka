# Execution batches

## Global rules

- Default authorized spend is zero. A balance is not authorization.
- Each billable batch needs a user-approved credit cap and named canonical asset IDs. Refresh official docs and the installed tool schema for each batch.
- Resolve the exact request and quote using the CLI's non-billable `--dry-run --json` mode. Run `tools/preflight_gate.py` against the real batch manifest before any future submission.
- Start with one concurrent billable task. Never auto-retry an unknown submission outcome or generate again to repair dimensions, pivots, labels, controls, UV layout, or interfaces.
- Preserve stage state and evidence: candidate -> DCC-clean -> art-approved -> Studio-imported -> runtime-verified.
- The gate checks readiness only. It never submits work or handles credentials.

## B00 — connection and project setup

- Authorized provider spend: 0 credits; no generation authorized.
- Completed locally: repository initialization, Roblox/Rojo toolchain manifest, Tripo CLI 0.7.2 installation for inspection, current CLI help/dry-run inspection, and local receipts.
- Current gate state: BLOCKED. Tripo account is not connected, its region is unselected, and no paid cap has been approved.
- H01/H05 model proposals are recorded in `data/job_recipes.json`; the corner is DCC/code exact and does not need a Tripo request.
- Do not mark B00 as art, DCC, Studio, or runtime acceptance.

## B01 — H01 sampler shell

- Candidate list: H01 sampler housing only. H05 and the DCC/code storefront corner remain separate work.
- Route: P1 `text-to-model`, wire model `P1-20260311`, `face_limit=2200`, `texture=false`, `pbr=false`, `export_uv=true`. The prompt describes only the blank housing shell; controls and interfaces stay deterministic in code. No artbook crop is sent as a provider reference.
- Provider cost: one bare P1 text-to-model request, 30 credits; no conversion or texture tasks.
- User approval: H01 only, capped at 30 credits; `ov` region selected.
- Tripo task `803380d4-9f8a-41fd-9ece-d935e4565fb6` succeeded. Post-task balance: 970 credits, 0 frozen.
- Result: candidate GLB saved under `assets/candidates/tripo-out/b01-h01-sampler-housing-803380d4/`. Blender measured 2,106 triangles (within the 2,200 candidate cap), 2 mesh objects, and 2 x 2 x 2 bounds against the 6 x 1.25 x 4 stud target.
- Review: preview shows unwanted built-in controls despite the shell-only prompt, and the candidate proportions do not match the target. Keep it as an unapproved candidate. See `docs/evidence/b01/H01-geometry-inspection.json`.
- Build the exact 16-pad layout and 4-stud/8-stud architectural module interfaces deterministically. Do not use Tripo to invent those details.
- No DCC-clean model, art approval, Studio import, or runtime verification exists yet.

## B02 — H01 isolated-reference image candidate

- Reference: `references/production/B01-H01-sampler-shell.png`, derived from the artbook sampler styling and generated as a clean, blank shell at the canonical 6:4:1.25 proportion. Its SHA-256 is recorded in the task evidence.
- Request: one P1 image-to-model call, wire model `P1-20260311`, `face_limit=2200`, `texture=false`, `pbr=false`, `export_uv=true`; no text prompt or extra processing steps.
- Estimated cost: 40 credits; the CLI dry run is valid. Proposed total spent to date after this call: 70 credits; remaining balance expected: about 930.
- User-authorized overall cap: 1,000 credits across assets. B02 names H01 only; continue one candidate at a time and review each before moving to another asset.
- Tripo task `76920209-9592-4049-9a34-7a282188d0ce` succeeded and consumed 40 credits. The post-task API balance is 930 credits.
- Result: raw GLB preserved under `assets/candidates/tripo-out/b02-h01-sampler-shell-image-76920209/`. DCC-clean candidate is `assets/cleaned/H01/H01_sampler_shell.glb`, with the editable source at `assets/cleaned/H01/H01_sampler_shell.blend`.
- Blender inspection after clearing the startup scene measured 2,049 triangles, 6 x 1.25 x 4 Roblox-axis bounds, bottom-center pivot, one UVMap, and three deterministic palette materials. No controls were generated.
- Status: DCC-clean candidate; grouped art approval, Studio import, and runtime verification remain open. Do not treat the preview as final acceptance.
- Preflight manifest: `templates/B02-H01-image.json`.

## B03 — H05 curved street lamp (plan prepared)

- Reference: `references/production/B03-H05-curved-street-lamp.png`, generated from the atlas's large primary lamp. It omits glass and the bulb insert so those can be separate pieces as specified. SHA-256: `0D3BEC962C2F2A83AFEF042448ADB5ABF8CECD537BBA97A3A89137BFCC0E55F0`.
- Request: one P1 image-to-model call, wire model `P1-20260311`, `face_limit=900`, `texture=false`, `pbr=false`, `export_uv=true`; no processing steps.
- Estimated cost: 40 credits. Project total after B01/B02 is 70; projected total after B03 is 110, leaving 890 of the 1,000-credit overall budget, subject to the live account balance.
- Preflight manifest: `templates/B03-H05-image.json`; the gate passed before submission.
- Tripo task `d9329072-9ea5-4c1e-b958-90321ede34c9` succeeded and consumed 40 credits. Live post-task balance: 890 credits, 0 frozen.
- Provider preview reads as a curved street lamp with a broad base, curved arm and open lantern cage. Raw output is preserved under `assets/candidates/tripo-out/b03-h05-curved-street-lamp-d9329072/`.
- Status: generated candidate pending DCC measurements and art review. No DCC cleanup, art approval, Studio import, or runtime verification is claimed. See `docs/evidence/b03/H05-task-result.json`.


## B04 — H02 compact speaker stack

- Reference: `references/production/B04-H02-compact-speaker-stack.png`, generated from Production Atlas page 05. One two-cabinet stack, teal cabinets, warm trim, one large woofer and one square horn.
- Request: one P1 image-to-model call, wire model `P1-20260311`, `face_limit=1800`, `texture=false`, `pbr=false`, `export_uv=true`; no processing steps.
- Preflight manifest: `templates/B04-H02-image.json`; gate passed before submission.
- Tripo task `090d3674-c965-40bb-8e9d-d6ff720a3022` succeeded and consumed 40 credits. Live post-task balance: 850 credits, 0 frozen.
- Raw GLB and preview are under `assets/candidates/tripo-out/b04-h02-compact-speaker-stack-090d3674/`. Preview shows one stacked two-cabinet speaker with a square horn and large woofer.
- Read-only Blender inspection measured 1,584 triangles, one mesh object, one material and one UVMap. Raw bounds are normalized `[0.5293, 0.6270, 0.9980]` Blender units, not the 4 x 8 x 3 stud target. DCC scale/pivot/part split and color/material work remain open.
- Status: generated candidate pending DCC and art review; no cleanup, Studio import, or runtime verification is claimed. Evidence: `docs/evidence/b04/H02-task-result.json` and `docs/evidence/b04/H02-geometry-inspection.json`.


## B05 — H03 vinyl crate shell

- Reference: `references/production/B05-H03-vinyl-crate-shell.png`, generated from Production Atlas page 06. The image shows only the empty crate shell; the record insert stays separate and deterministic.
- Proposed request: one P1 image-to-model call, wire model `P1-20260311`, `face_limit=650`, `texture=false`, `pbr=false`, `export_uv=true`; no processing steps.
- CLI dry run was valid. The batch preflight passed before submission.
- Tripo task `0959611a-7ad8-4a88-a9ad-b9dfba678416` succeeded and consumed 40 credits. Live post-task balance: 810 credits, 0 frozen.
- Raw GLB and preview are under `assets/candidates/tripo-out/b05-h03-vinyl-crate-shell-0959611a/`. Preview shows the empty crate shell with a front handhold opening; the separate record insert was not generated.
- Read-only Blender inspection measured 632 triangles, one mesh, one material and one UVMap. Bounds are normalized `[0.9980, 0.9941, 0.6816]`; height needs DCC scaling to match the 3 x 2.5 x 3 stud target.
- Status: generated candidate pending DCC and art review. No cleanup, art approval, Studio import, or runtime verification is claimed. Evidence: `docs/evidence/b05/H03-task-result.json` and `docs/evidence/b05/H03-geometry-inspection.json`.


## B06 — H04 maintenance helper robot

- Reference: `references/production/B06-H04-maintenance-helper-robot.png`, generated from Production Atlas page 07. It depicts one neutral-pose robot with the face, body and arms kept readable; later DCC rigging and part separation remain required.
- Proposed request: one P1 image-to-model call, wire model `P1-20260311`, `face_limit=3500`, `texture=false`, `pbr=false`, `export_uv=true`; no processing steps.
- CLI dry run was valid; the preflight gate passed before submission.
- Tripo task `d452487b-36f3-40b8-a339-c21980b760c0` succeeded and consumed 40 credits. Live post-task balance: 770 credits, 0 frozen.
- Raw GLB and preview are under `assets/candidates/tripo-out/b06-h04-maintenance-helper-robot-d452487b/`. Preview reads as a compact robot with head, torso, arms and wheels, but its face is blank and its material is monochrome gray.
- Read-only Blender inspection measured 3,400 triangles, one mesh, one material and one UVMap. Raw bounds are normalized `[0.4316, 0.8418, 0.9980]`; proportions need adjustment to the 3.5 x 4 x 3 stud target. DCC part separation, pivots, face graphics/materials and rigging remain open.
- Status: generated candidate pending DCC and art review. No cleanup, art approval, Studio import, or runtime verification is claimed. Evidence: `docs/evidence/b06/H04-task-result.json` and `docs/evidence/b06/H04-geometry-inspection.json`.


## H05 deterministic base repair

- Preserved the B03 raw provider output unchanged. Added a broad stepped 12-sided foundation flange and four anchor heads in Blender to address the user's incomplete-base review.
- Cleaned working files: `assets/cleaned/H05/H05_curved_street_lamp.glb`, `.blend`, and `preview.png`.
- Inspection: 1,034 triangles, one mesh object, one material, one UVMap, floor contact at Blender z=0; within the 1,100 full-asset triangle budget.
- Exact stud scaling, separate bulb/glass and light attachment, Studio import, and runtime validation remain open. See `docs/evidence/b03/H05-base-repair.json`.


## B07 — P01 studio workbench

- Reference: `references/production/B07-P01-studio-workbench.png`, generated from the artbook palette and canonical P01 construction contract: walnut top, teal structural frame, broad cream drawer, no clutter.
- Proposed request: one P1 image-to-model call, wire model `P1-20260311`, `face_limit=700`, `texture=false`, `pbr=false`, `export_uv=true`; no processing steps.
- CLI dry run was valid; the preflight gate passed before submission.
- Tripo task `8fc6650b-2c61-4172-afa4-e9e4368cda8e` succeeded and consumed 40 credits. Live post-task balance: 730 credits, 0 frozen.
- Raw GLB and preview are under `assets/candidates/tripo-out/b07-p01-studio-workbench-8fc6650b/`. Preview reads as an uncluttered standing bench with a broad work surface, side supports and front drawer.
- Read-only Blender inspection measured 616 triangles, one mesh, one material and one UVMap. Bounds are normalized `[0.4473, 0.9980, 0.4160]`; target scale and floor-center pivot remain pending.
- Status: generated candidate pending DCC and art review; no cleanup, Studio import, or runtime verification is claimed. Evidence: `docs/evidence/b07/P01-task-result.json` and `docs/evidence/b07/P01-geometry-inspection.json`.


## B08 — P02 round workshop stool

- Reference: `references/production/B08-P02-round-workshop-stool.png`, generated from the artbook palette and workbench prop family: broad walnut seat, sturdy teal supports and foot ring.
- Proposed request: one P1 image-to-model call, wire model `P1-20260311`, `face_limit=350`, `texture=false`, `pbr=false`, `export_uv=true`; no processing steps.
- CLI dry run was valid; the preflight gate passed before submission.
- Tripo task `3c9288ec-22fe-4efb-8ac6-9e176a95c861` succeeded and consumed 40 credits. Live post-task balance: 690 credits, 0 frozen.
- Raw GLB and preview are under `assets/candidates/tripo-out/b08-p02-round-workshop-stool-3c9288ec/`. Preview reads as a round seat, four legs and a supporting ring.
- Read-only Blender inspection measured 338 triangles, one mesh, one material and one UVMap. Bounds are normalized `[0.9980, 0.9863, 0.9199]`; target scaling and floor-center pivot remain pending.
- Status: generated candidate pending DCC and art review; no cleanup, Studio import, or runtime verification is claimed. Evidence: `docs/evidence/b08/P02-task-result.json` and `docs/evidence/b08/P02-geometry-inspection.json`.


## B09 — P03 listening bench

- Reference: `references/production/B09-P03-listening-bench.png`, generated in the walnut and faded-teal prop family with a low back to preserve the stage sightline.
- Proposed request: one P1 image-to-model call, wire model `P1-20260311`, `face_limit=500`, `texture=false`, `pbr=false`, `export_uv=true`; no processing steps.
- CLI dry run was valid and the preflight gate passed before submission.
- Tripo task `a484dfae-34da-4a6d-917c-1d2da891f8c3` succeeded and consumed 40 credits. Live post-task balance: 650 credits, 0 frozen.
- Raw GLB and preview are under `assets/candidates/tripo-out/b09-p03-listening-bench-a484dfae/`. Preview shows a low-back bench with broad seat, supports and cross brace.
- Read-only Blender inspection measured 470 triangles, one mesh, one material and one UVMap. Raw bounds are normalized `[0.3770, 0.9980, 0.4199]`; target scale and floor-center pivot remain pending.
- Status: generated candidate pending DCC and art review; no cleanup, art approval, Studio import, or runtime verification is claimed. Evidence: `docs/evidence/b09/P03-task-result.json` and `docs/evidence/b09/P03-geometry-inspection.json`.


## B10 — P04 record browsing bin

- Reference: `references/production/B10-P04-record-browsing-bin.png`, matching the walnut and faded-teal prop family. It shows the required empty front browse socket; sleeve artwork remains a separate deterministic detail.
- Proposed request: one P1 image-to-model call, wire model `P1-20260311`, `face_limit=650`, `texture=false`, `pbr=false`, `export_uv=true`; no processing steps.
- CLI dry run was valid and the preflight gate passed before submission.
- Tripo task `c79fb1fa-814e-45b9-9da7-cea4d15fc8ca` succeeded and consumed 40 credits. Live post-task balance: 610 credits, 0 frozen.
- Raw GLB and preview are under `assets/candidates/tripo-out/b10-p04-record-browsing-bin-c79fb1fa/`. Preview shows the divided bin and front browse socket in monochrome gray.
- Read-only Blender inspection measured 634 triangles, one mesh, one material and one UVMap. Raw bounds are normalized `[0.6582, 0.9980, 0.5332]`; target scale and floor-center pivot remain pending.
- Status: generated candidate pending DCC and art review; palette, sleeve artwork and close-range artwork legibility remain open. No Studio import or runtime verification is claimed. Evidence: `docs/evidence/b10/P04-task-result.json` and `docs/evidence/b10/P04-geometry-inspection.json`.


## DCC normalization — H02-H05 and P01-P04

- Preserved all Tripo source candidates unchanged. H05's earlier repaired-base working source is also preserved at `assets/candidates/dcc-source/H05_base_repaired_unscaled.glb` with its editable Blender source; its exact-scale result uses a separate filename.
- Added deterministic Blender normalization in `tools/normalize_dcc_candidates.py`: bake imported glTF transforms, orient front-facing props to the project forward direction where specified, scale to canonical dimensions, and set a floor-center origin.
- Re-imported each exported GLB in Blender 5.2.2. All eight measured bounds match their contracts, floor minimum is Z=0, mesh origin is `(0, 0, 0)`, and each remains within its full-asset triangle cap. Measurements and hashes are in `docs/evidence/dcc-normalization/`.
- Outputs: H02 1,584 tris; H03 632; H04 3,400; H05 1,034; P01 616; P02 338; P03 470; P04 634.
- DCC geometry stage only. Authored palette/material separation, H02/H04 moving-part separation, H03 record insert, H05 glass/bulb attachment, P04 sleeve artwork, art review and Roblox Studio/runtime checks remain open.


## P05 — wall shelf (DCC-exact candidate)

- Built a reusable wall shelf deterministically to the 6 x 0.7 x 1.5 stud contract instead of spending Tripo credits on simple boards and brackets. The shelf uses the walnut, muted-teal and cream artbook palette.
- Export: `assets/cleaned/P05/P05_wall_shelf.glb`; editable source and preview sit alongside it. Blender measured 148 triangles, one mesh, three materials, one UVMap, exact bounds, and a rear-center wall pivot.
- No provider credits were used. Candidate still needs art review and Roblox Studio/runtime validation. Evidence: `docs/evidence/p05/P05-dcc-result.json`.

## B11 — P06 storage crate (plan prepared)

- Reference: `references/production/B11-P06-storage-crate.png`, isolated stackable crate in the walnut, faded-teal and cream prop family, with an integrated front handhold.
- Proposed request: one P1 image-to-model call, wire model `P1-20260311`, `face_limit=280`, `texture=false`, `pbr=false`, `export_uv=true`; no processing steps.
- Non-billable CLI dry run is valid at 40 credits. Current balance is 610; a submitted B11 would bring project spend to 430 of the 1,000-credit limit and leave an expected balance of 570.
- B11 is not authorized or submitted. Exact manifest: `templates/B11-P06-image.json`; dry-run evidence: `docs/evidence/b11/P06-image-to-model-dry-run.json`.


## B11 — P06 Storage crate

- Reference: `references/production/B11-P06-storage-crate.png` (SHA-256 `e54d8b20ef38477d69a5949fd8341b88134e7bf1bfd64e7e3080c51047be3e73`); isolated generated reference prompt and provenance are recorded in `references/production/reference-provenance.json`.
- Request: P1-20260311 image-to-model, face_limit=280, texture=false, pbr=false, export_uv=true; one generation call, no processing chain.
- CLI dry run valid; offline preflight passed. Task `add32aad-1457-469d-8afe-1c47b5a1aa3c` succeeded; actual spend 40 credits; live balance after task 570 (0 frozen).
- Raw candidate and preview: `assets\candidates\tripo-out\b11-p06-storage-crate-add32aad`. DCC normalization, art approval and Studio/runtime checks remain open. Evidence: `docs/evidence/b11/P06-task-result.json` and `docs/evidence/b11/P06-summary.json`.


## B12 — P07 Headphones

- Reference: `references/production/B12-P07-headphones.png` (SHA-256 `24a6bf0bec44aa2ad63fd22fd9ec820c3a3878aff7b35f888c6128cbb0e38d5c`); isolated generated reference prompt and provenance are recorded in `references/production/reference-provenance.json`.
- Request: P1-20260311 image-to-model, face_limit=800, texture=false, pbr=false, export_uv=true; one generation call, no processing chain.
- CLI dry run valid; offline preflight passed. Task `6e5357d9-c58e-47e7-adea-134676fa4459` succeeded; actual spend 40 credits; live balance after task 530 (0 frozen).
- Raw candidate and preview: `assets\candidates\tripo-out\b12-p07-headphones-6e5357d9`. DCC normalization, art approval and Studio/runtime checks remain open. Evidence: `docs/evidence/b12/P07-task-result.json` and `docs/evidence/b12/P07-summary.json`.


## B13 — P11 Planter pot

- Reference: `references/production/B13-P11-planter-pot.png` (SHA-256 `087f4578ccc22c7325b099ce956c52814091990210cefa6338e8e37b9f0fe52c`); isolated generated reference prompt and provenance are recorded in `references/production/reference-provenance.json`.
- Request: P1-20260311 image-to-model, face_limit=300, texture=false, pbr=false, export_uv=true; one generation call, no processing chain.
- CLI dry run valid; offline preflight passed. Task `daea9589-f31d-4294-ac08-5c03f2a87c33` succeeded; actual spend 40 credits; live balance after task 490 (0 frozen).
- Raw candidate and preview: `assets\candidates\tripo-out\b13-p11-planter-pot-daea9589`. DCC normalization, art approval and Studio/runtime checks remain open. Evidence: `docs/evidence/b13/P11-task-result.json` and `docs/evidence/b13/P11-summary.json`.


## B14 — P12 Broad-leaf plant cluster

- Reference: `references/production/B14-P12-broad-leaf-plant.png` (SHA-256 `80322b2011b5d346b6858b1134fdc13377630e2a01d72ccf8572ead4c078008e`); isolated generated reference prompt and provenance are recorded in `references/production/reference-provenance.json`.
- Request: P1-20260311 image-to-model, face_limit=450, texture=false, pbr=false, export_uv=true; one generation call, no processing chain.
- CLI dry run valid; offline preflight passed. Task `eebbc149-1581-4d0a-855b-1f6d31bb0380` succeeded; actual spend 40 credits; live balance after task 450 (0 frozen).
- Raw candidate and preview: `assets\candidates\tripo-out\b14-p12-broad-leaf-plant-eebbc149`. DCC normalization, art approval and Studio/runtime checks remain open. Evidence: `docs/evidence/b14/P12-task-result.json` and `docs/evidence/b14/P12-summary.json`.


## B15 — P13 Wall / pendant lamp family

- Reference: `references/production/B15-P13-lamp-core.png` (SHA-256 `ec1f9c1654a501fdb7922a0c95402c6530a444c24ea4f085914ad19da25f85ca`); isolated generated reference prompt and provenance are recorded in `references/production/reference-provenance.json`.
- Request: P1-20260311 image-to-model, face_limit=400, texture=false, pbr=false, export_uv=true; one generation call, no processing chain.
- CLI dry run valid; offline preflight passed. Task `09cb43ae-7107-467c-a41d-cf67461a2f0d` succeeded; actual spend 40 credits; live balance after task 410 (0 frozen).
- Raw candidate and preview: `assets\candidates\tripo-out\b15-p13-lamp-core-09cb43ae`. DCC normalization, art approval and Studio/runtime checks remain open. Evidence: `docs/evidence/b15/P13-task-result.json` and `docs/evidence/b15/P13-summary.json`.


## B16 — P14 Utility junction box

- Reference: `references/production/B16-P14-utility-junction-box.png` (SHA-256 `7cc3ef1b8db425bd76810ab440a0a736b7406998789a4af70cd2c451bd074635`); isolated generated reference prompt and provenance are recorded in `references/production/reference-provenance.json`.
- Request: P1-20260311 image-to-model, face_limit=300, texture=false, pbr=false, export_uv=true; one generation call, no processing chain.
- CLI dry run valid; offline preflight passed. Task `d57e4c07-7762-4c7b-9356-2de36b60e47d` succeeded; actual spend 40 credits; live balance after task 370 (0 frozen).
- Raw candidate and preview: `assets\candidates\tripo-out\b16-p14-utility-junction-box-d57e4c07`. DCC normalization, art approval and Studio/runtime checks remain open. Evidence: `docs/evidence/b16/P14-task-result.json` and `docs/evidence/b16/P14-summary.json`.


## B17 — P16 Rooftop vent / duct

- Reference: `references/production/B17-P16-rooftop-vent.png` (SHA-256 `cc797978ef2153b1b2d518d867e697c3c0ba1ef515866cf6784fe47d6715c59c`); isolated generated reference prompt and provenance are recorded in `references/production/reference-provenance.json`.
- Request: P1-20260311 image-to-model, face_limit=400, texture=false, pbr=false, export_uv=true; one generation call, no processing chain.
- CLI dry run valid; offline preflight passed. Task `c6945d18-e29e-4f9c-999f-5cde0817fdd7` succeeded; actual spend 40 credits; live balance after task 330 (0 frozen).
- Raw candidate and preview: `assets\candidates\tripo-out\b17-p16-rooftop-vent-c6945d18`. DCC normalization, art approval and Studio/runtime checks remain open. Evidence: `docs/evidence/b17/P16-task-result.json` and `docs/evidence/b17/P16-summary.json`.


## B18 — I01 Metal strike-sign discovery node

- Reference: `references/production/B18-I01-metal-strike-sign.png` (SHA-256 `2b076c6f4b45f0ec964ad6422daf3219daee00ad5f456212188aaf11308e2592`); isolated generated reference prompt and provenance are recorded in `references/production/reference-provenance.json`.
- Request: P1-20260311 image-to-model, face_limit=250, texture=false, pbr=false, export_uv=true; one generation call, no processing chain.
- CLI dry run valid; offline preflight passed. Task `b931a097-b2e2-484d-8de1-ed94bf300e74` succeeded; actual spend 40 credits; live balance after task 290 (0 frozen).
- Raw candidate and preview: `assets\candidates\tripo-out\b18-i01-metal-strike-sign-b931a097`. DCC normalization, art approval and Studio/runtime checks remain open. Evidence: `docs/evidence/b18/I01-task-result.json` and `docs/evidence/b18/I01-summary.json`.


## B19 — I04 Workshop resonator junction

- Reference: `references/production/B19-I04-resonator-junction.png` (SHA-256 `3e3c8104e7a07c1151ed75fde80f93846a73e3a05e59367fdaca1e8b4d5bc3b9`); isolated generated reference prompt and provenance are recorded in `references/production/reference-provenance.json`.
- Request: P1-20260311 image-to-model, face_limit=500, texture=false, pbr=false, export_uv=true; one generation call, no processing chain.
- CLI dry run valid; offline preflight passed. Task `0b2aa08d-601d-46af-9cbe-a203364583e6` succeeded; actual spend 40 credits; live balance after task 250 (0 frozen).
- Raw candidate and preview: `assets\candidates\tripo-out\b19-i04-resonator-junction-0b2aa08d`. DCC normalization, art approval and Studio/runtime checks remain open. Evidence: `docs/evidence/b19/I04-task-result.json` and `docs/evidence/b19/I04-summary.json`.


## B20 — I05 Listening-stage control podium

- Reference: `references/production/B20-I05-listening-podium.png` (SHA-256 `f98b64c9c515807b8db3f9bc821bd22bebfa0da42c2cddbcfc0f99f85dacc6e5`); isolated generated reference prompt and provenance are recorded in `references/production/reference-provenance.json`.
- Request: P1-20260311 image-to-model, face_limit=650, texture=false, pbr=false, export_uv=true; one generation call, no processing chain.
- CLI dry run valid; offline preflight passed. Task `d89353d8-83b7-42f5-8130-dd1e849aefab` succeeded; actual spend 40 credits; live balance after task 210 (0 frozen).
- Raw candidate and preview: `assets\candidates\tripo-out\b20-i05-listening-podium-d89353d8`. DCC normalization, art approval and Studio/runtime checks remain open. Evidence: `docs/evidence/b20/I05-task-result.json` and `docs/evidence/b20/I05-summary.json`.


## B11-B20 DCC geometry normalization

- Added `tools/normalize_remaining_candidates.py`; raw Tripo GLBs remain preserved. All ten B11-B20 exports were re-imported with Blender 5.2.2. Bounds and pivots match each contract; all stay within triangle budgets and retain UVs.
- Outputs are tagged DCC-normalized geometry candidates, not art-approved or Studio-ready. Review notes and per-asset paths: `docs/evidence/dcc-normalization/remaining-batch-review.md`.
- Spent 400 credits for B11-B20. Total project Tripo spend is 790 / 1,000; live remaining balance is 210 credits with 0 frozen.


## B11-B20 DCC art-detail repair candidates

- Added `tools/fix_candidate_details.py` for P12, P13, P14, I01, I04 and I05. It preserves every raw provider source and every earlier normalized GLB, and exports separate editable `.blend`, `.glb` and preview files under `assets/cleaned/<ID>/`.
- Re-imported each GLB with Blender 5.2.2 and verified contracted dimensions, zeroed pivot anchor, UVs and triangle caps. Results: P12 380/550, P13 312/500, P14 396/400, I01 260/300, I04 648/650 and I05 756/800.
- The project owner approved the art direction for these six, requesting contact fixes for the I05 podium. Those details are reseated and the updated preview inspected. The candidates are art-reviewed and remain in `assets/cleaned/` pending Roblox Studio import, interface/collision review and runtime validation. Evidence: `docs/evidence/dcc-normalization/art-review-approval.md`, `docs/evidence/dcc-normalization/art-repair-candidates.json`, `docs/evidence/dcc-normalization/art-repair-export-inspection.json`, and `docs/evidence/dcc-normalization/remaining-batch-review.md`.
- Prepared `docs/evidence/studio-import-queue.md` with the six GLBs, Studio dimensions/pivots and per-asset import checks. Studio is installed, but no Studio import evidence or runtime acceptance has been captured.
- No Tripo credits were used for the repair pass; total project spend remains 790 / 1,000 with 210 remaining.


## B11-B20 solid-geometry hole repairs

- Following the owner's Studio feedback, replaced P12's zero-thickness leaf sheets and the irregular P14/I05 body meshes with separate closed-geometry candidates. Earlier candidate files and Tripo sources remain untouched.
- Blender 5.2.2 GLB re-import audit: P12 460/550 triangles, 15 MeshParts; P14 304/400, 8 MeshParts; I05 484/800, 11 MeshParts. All match contracted dimensions; after welding split export vertices in-memory, each has 0 open edges and 0 degenerate faces.
- These three replacement candidates are pending visual/art and Studio review; they do not inherit the prior visual approval. Evidence: `docs/evidence/dcc-normalization/solid-repair-candidates.json`. No Tripo credits were used.


## Cleaned asset surface audit and repair

- Audited all 51 existing GLBs, including preserved Tripo sources and earlier candidates, then produced 13 surface-repaired GLBs for active production assets. Raw/provider GLBs remain unchanged.
- Recalculated face winding across the affected assets; closed expected surfaces on H02, H05, P01, P02 and P03; patched H01 where loops allowed. P12, P14 and I05 use their separately rebuilt solid-geometry candidates.
- Re-import checks retained bounds, mesh count and UV presence. Repaired outputs have zero winding conflicts; all except H01 and the intentional P16 vent mouth have zero boundary/non-manifold edges. H01 remains explicitly flagged for Studio visual review.
- Full inventory: `docs/evidence/glb-surface-audit.json`; active 20-asset paths and outcomes: `docs/evidence/cleaned-asset-surface-review.md`; detailed repair receipts: `docs/evidence/glb-normal-repair.json` and `docs/evidence/open-surface-repair.json`.
- Roblox Studio re-import and visual acceptance remain pending.
