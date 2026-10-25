# Needle Quay — full local design and visualization register

25 October 2026. This delivery consolidates the full environment register into a single review package. It does not promote local candidates to accepted game assets.

Open [the visual catalog](../../output/needle-quay/index.html) or [the consolidated artbook](../../output/needle-quay/BeatMakka_Needle_Quay_Environment_Quest_Artbook_Vol01.pdf). The catalog links every graphic, character, building source and export. The PDF uses print-compressed embeddings; original image masters are preserved separately.

| Register scope | Local deliverable |
| --- | --- |
| 13 buildings | Approved concept sheets; Blender and GLB candidates; neutral, front, side and top renders; placement/material/graphic/module/Before–After cards |
| 4 parking venues + LoopVan | Native Part blockout, authored routes/anchors and clearance boxes; static vehicle proxy |
| 7 NPC | Six new four-view design sheets and Blender/GLB candidates with 15 rigid bones; canonical Mica/H04 reused unchanged |
| 12 material families | Shared atlas mappings and procedural Blender material library with 12 rendered swatches; brick/brass finish sources |
| 61 graphics | 13 signs, 6 wayfinding signs, 8 posters, 10 transparent graffiti, 24 service decals; 8 additional faded poster variants |
| 13 quests | Completion conditions, geometry anchors, sound contracts, personal world-state rules, recovery and six finale phases |
| Integrity | SHA-256 payload manifest; 20 canonical game-dev packages with static inspection and package verification receipts |

## Concrete design decisions

- H06 retains canonical **32×16×24** and front-left floor-grid source pivot. The new interior proposal is a maximum **30×14** clear zone. The incompatible legacy **24×20** interior is not implemented. Final interior acceptance remains open; this does not amend canonical dimensions.
- Morrow has the canonical **3×3×2 P16 / I02** attachment, separate fan decoration, door leaf and rail. Final motion clearance still needs avatar review.
- Signal House console is on the front **-Z**, right side. The mast remains within its authored 26-stud total height.
- Market retains exactly four stalls, an open central aisle and a separate performance nook.
- Restoration reuses geometry. Rendered district Before/After demonstrates switched amber inserts; cards specify dressing changes. No global completion state is introduced.
- Graphic placement and NPC/sound/interaction coordinates are explicit proposals in `building-cards.json`. Gameplay text/localization remains outside generated textures.

## Sources and stage boundaries

The approved board and previous 13 building concepts remain visual authority. New models are simplified deterministic candidates; detail fidelity to concepts is still a production review gate. UVs exist, but smart-projected UVs and multiple color materials are not a finished shared-atlas bake. Brick/brass procedural sources need baking on final approved UVs. Six NPC rigs use rigid vertex weights; animation clips, face deformation and Roblox Humanoid acceptance are not supplied.

Measured GLB triangles, materials, bounds and hashes are in [static inspection receipts](../evidence/needle-quay-production). CLI default checks do not establish a new project budget or a Roblox platform limit. Decorative projections extend some core footprints; measured bounds and setback notes are recorded, not hidden by rescaling.

Candidate → DCC-clean → art-approved → Studio-imported → runtime-verified remain distinct gates. Prior human approval covers the historical artbooks and concept PNGs identified in [the approval receipt](ART_APPROVAL_2026-10-25.json). It does not automatically approve the new graphic/NPC/model/material files. Existing H04 evidence is retained without promoting it again.

Executable Q00–Q12 integration, persistent personal restoration, new animation clips, final UV/material consolidation, device LOD/draw-call profiling and production Studio import remain implementation/acceptance work. The full design register and local visualization package are supplied; this is not a claim that the district is ready to ship.

## Local tools and deployment policy

`game-dev` 1.5.1 was installed outside the repository from the official release, with SHA-256 verification. Blender 5.2.2 LTS authored sources and neutral previews. Build scripts are in `tools/build_needle_quay_*`; `tools/compile_needle_quay_register.py` builds manifests/catalog, and `tools/package_needle_quay.py` creates verified local CLI packages. Bundled Python provides ReportLab/Pillow; bundled Node/sharp exports SVG graphics. No new project dependency or CI workflow was introduced.

User Assets inventory was refreshed: 6,343 files; no new external source model/texture was used. Board provenance remains adjacent to the vendored reference. All generated design prompts are retained. License metadata is private project use; no public licensing of user references is inferred.

No test suites were added or run. Artifact bytes, dimensions, package integrity and representative document renders were inspected as production checks. Billable Tripo operations: **0**. Roblox uploads/publishing: **0**. Everything remains local and in Git. Current testing-account restrictions remain in force; future adult-account deployment requires fresh explicit authorization.

Unrelated in-progress jam/gameplay changes are excluded from this production commit and retained in the working tree.
