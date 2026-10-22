# B11-B20 candidate review

Blender 5.2.2 LTS normalization outputs were re-imported and measured. All ten exported GLBs match their authored dimensions and pivots, remain under the full-asset triangle caps, and contain UVs. This is DCC geometry normalization only; materials, interactive part separation, art approval, Studio import and runtime acceptance remain open.

| ID | Tris | Full cap | Dimensions W x H x D | Pivot | Neutral DCC candidate |
|---|---:|---:|---|---|---|
| P06 | 276 | 350 | 3 x 3 x 3 | floor-center | `assets/cleaned/P06/P06_normalized_geometry_candidate.glb` |
| P07 | 846 | 1000 | 2 x 1.5 x 0.8 | floor-center | `assets/cleaned/P07/P07_normalized_geometry_candidate.glb` |
| P11 | 280 | 400 | 2 x 2.5 x 2 | floor-center | `assets/cleaned/P11/P11_normalized_geometry_candidate.glb` |
| P12 | 488 | 550 | 3 x 4 x 3 | floor-center | `assets/cleaned/P12/P12_normalized_geometry_candidate.glb` |
| P13 | 412 | 500 | 1.5 x 2 x 1.5 | rear-center | `assets/cleaned/P13/P13_normalized_geometry_candidate.glb` |
| P14 | 284 | 400 | 2 x 3 x 1 | rear-center | `assets/cleaned/P14/P14_normalized_geometry_candidate.glb` |
| P16 | 376 | 500 | 3 x 3 x 2 | floor-center | `assets/cleaned/P16/P16_normalized_geometry_candidate.glb` |
| I01 | 264 | 300 | 3 x 2 x 0.3 | upper-hinge | `assets/cleaned/I01/I01_normalized_geometry_candidate.glb` |
| I04 | 414 | 650 | 3 x 4 x 1.5 | rear-center | `assets/cleaned/I04/I04_normalized_geometry_candidate.glb` |
| I05 | 580 | 800 | 3 x 4 x 2 | floor-center | `assets/cleaned/I05/I05_normalized_geometry_candidate.glb` |

## DCC art-detail follow-up

Created separate repaired candidates for the six flagged assets while preserving their Tripo originals and the earlier normalized GLBs. The repairs add a broad-leaf P12 cluster, rebuild P13 as a wall-mounted lamp core, add P14 socket/status geometry, separate I01's fixed hinge mount from the swinging sign, add four I04 indicators and a dial, and add I05's distinct status insert and front state bar.

| ID | Repaired candidate | Tris / cap | Re-imported dimensions | Pivot |
|---|---|---:|---|---|
| P12 | `assets/cleaned/P12/P12_art_repair_candidate.glb` | 380 / 550 | 3 x 3 x 4 | floor-center |
| P13 | `assets/cleaned/P13/P13_art_repair_candidate.glb` | 312 / 500 | 1.5 x 1.5 x 2 | rear-center |
| P14 | `assets/cleaned/P14/P14_art_repair_candidate.glb` | 396 / 400 | 2 x 1 x 3 | rear-center |
| I01 | `assets/cleaned/I01/I01_art_repair_candidate.glb` | 260 / 300 | 3 x 0.3 x 2 | upper-hinge |
| I04 | `assets/cleaned/I04/I04_art_repair_candidate.glb` | 648 / 650 | 3 x 1.5 x 4 | rear-center |
| I05 | `assets/cleaned/I05/I05_art_repair_candidate.glb` | 756 / 800 | 3 x 2 x 4 | floor-center |

Blender 5.2.2 re-import checks pass for dimensions, pivot anchor, UV presence and triangle cap on all six exports. The project owner reviewed the candidates and approved their art direction, with the I05 podium detail contact fix requested and completed. The six are art-reviewed DCC candidates; Roblox Studio import, collision/interface review and runtime acceptance remain open. They stay in `assets/cleaned/` until those checks pass.

Evidence: `docs/evidence/dcc-normalization/art-review-approval.md`, `docs/evidence/dcc-normalization/art-repair-candidates.json`, `docs/evidence/dcc-normalization/art-repair-export-inspection.json`, and `tools/inspect_candidate_repairs.py`. Earlier normalized geometry evidence remains in `docs/evidence/dcc-normalization/remaining-batch.json` and `docs/evidence/dcc-normalization/remaining-batch-export-inspection.json`; raw metrics remain in `docs/evidence/b11/remaining-batch-geometry-inspection.json`.
