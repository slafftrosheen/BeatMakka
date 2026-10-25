# Needle Quay — five hero sheets

All five concepts are **approved by the user as of 2026-10-25**; see [approval receipt](ART_APPROVAL_2026-10-25.json). Original PNG footers and generation provenance record their pre-approval state. The supplied style board remains the visual authority. Generated orthographic-looking views and dimension arrows are illustrations; use JSON contracts and authored geometry for construction. This concept approval does not approve a Tripo input or production mesh acceptance.

Sheets 01–02 below were authored on 2026-10-24. [Sheets 03–05: Morrow Repairs, Harbor Market Hall and Signal House](HERO_SHEETS_03_05.md) were added on 2026-10-25 in the same style, with their own prompts, provenance and contract links.

## NQ-BLD-01 — The Lantern Room

`assets/concepts/needle-quay/NQ-BLD-01-lantern-room-v1.png`

- Proposed envelope: **44 × 30 × 26 studs**, W × D × H. Floor-center blockout pivot; front points -Z.
- Access: 8-stud-wide front opening, 10-stud headroom, side service opening 6 × 10. Main circulation stays clear; no collision on trim, signs or translucent review roof.
- Zoning: conceptual lobby 40 × 6, hall 40 × 14, rear stage 28 × 6. Stage step and camera clearance still require avatar review. No fully modeled finished interior in this batch.
- Reuse: M01/M02 wall rhythm, M03 posts, M04 portal, M05 display/window proportions, M07 floors, M08 roof, M10 sign and H05 lamp design vocabulary. These are reuse directions; the blockout uses plain Parts, not validated final module assemblies. Do not rescale pinned modules to force a fit.
- Materials: MAT-05 brick/stone proxy, MAT-01 teal, MAT-02 trim, MAT-03 wood, MAT-09 brass, MAT-10 amber light. Brick and brass surface treatment remains pending.
- Facade graphics: NQ-SGN-01; POST-01; GRA-02 approach; GRA-10 side wall. Sheet illustrations do not count as exported sign/poster/graffiti assets.
- Narrative: Ronan location at the front approach; Q11 preparation and Q12 six-phase finale. Service path connects to the promenade. No new quest logic is implemented.
- Before/after: same building; restore light targets, marquee readability, poster and NPC activity through later personal presentation. Dormant light targets are authored in the blockout; no global progression switch is installed.
- Optimization: simple wall collisions, shared materials, removable/non-collidable review roof; future LOD should remove dressing first. New triangle budgets are not invented here.

## NQ-BLD-02 — Needle Records / H06

`assets/concepts/needle-quay/NQ-BLD-02-needle-records-v1.png`

- New concept envelope: **24 × 18 × 19**. Existing H06 contract: **32 × 16 × 24**, pivot front-left floor grid corner. Existing workbook also asks for a 24 × 20 usable interior, inconsistent with its 16-stud depth. **Envelope fit is OPEN.**
- The scene uses canonical **32 × 16 × 24** for the H06 proxy. A named canonical-pivot marker preserves the front-left reference. The blockout container's floor-center pivot is only for layout, not a revision of the asset contract.
- Preserve public record shop identity: teal shell, cream trim, striped coral awning, vinyl sign, walnut crates, warm windows. Upper silhouette is decorative; no accessible second-floor/home functionality.
- Access: clear central 8 × 10 front opening; compact sales area, two counters and listening nook. Keep main entrance route clear. No new home, ownership rules or ProfileStore fields.
- Reuse: existing H06 identity and M01/M03/M04/M05/M06/M07/M08/M10/M11/M12/M17 kit vocabulary; H03 vinyl-crate detail in later production. Do not instantiate a second competing H06 in the playable scene.
- Materials: MAT-01/02/03/07/09/10/11. NQ-SGN-02, POST-02, GRA-07 nearby; decals remain separate production items.
- Narrative: Naya location, Q06 material sorting and Q07 Beat Shelf saving. Market adjacency supports Q08; no new progression is inferred from the old mission predicates.
- Before/after: window/sign illumination and stocked crates; reuse geometry. Production door, shutter and state animations remain pending.
- Optimization: public shop shell with simple wall proxies, no decorative collisions, shared atlas. Future production asset keeps its canonical budget and module contracts until explicitly revised.

## Deliverable gates

Colored isometric and illustrative front/side/top/before-after views: authored for all five hero concepts. Dimensions, zoning, reuse, material/graphic IDs and NPC/interaction positions: documented and represented as blockout proposals. Source geometry and a native Studio scene: delivered separately under `assets/blockouts/needle-quay` and `output/needle-quay`; the 2026-10-25 sheet continuation does not modify that geometry or advance its acceptance. Precision orthographic drawings, final neutral production renders, DCC-clean assets, art approval, native production mesh import, runtime quest acceptance and LOD profiling: **pending**.

Do not inherit the pasted UI's “4 of 9 ready” count: it had no accompanying acceptance evidence.
