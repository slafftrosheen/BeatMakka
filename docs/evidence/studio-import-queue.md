# Roblox Studio import queue — B11-B20 repairs

Prepared 2026-10-22. All rows are `NOT_IMPORTED`; this file is an import handoff, not Studio evidence. P12, P14 and I05 use newer closed-geometry candidates after the earlier GLBs showed open or broken-looking surfaces. These three replacements still need visual/art review.

Follow the detailed [Studio GLB import guide](../../STUDIO_IMPORT_GUIDE.md) for importer settings, dimension/pivot checks, collision guidance, and evidence capture.

| ID | GLB | Expected size W x H x D (studs) | Pivot | Triangles | Review focus |
|---|---|---:|---|---:|---|
| P12 | `assets/cleaned/P12/P12_solid_repair_candidate.glb` | 3 x 4 x 3 | Floor-center | 460 | Confirm closed leaf volumes, silhouette and no collision on leaves. |
| P13 | `assets/cleaned/P13/P13_art_repair_candidate.glb` | 1.5 x 2 x 1.5 | Rear-center wall mount | 312 | Confirm wall plate faces the wall and light core points into the room. |
| P14 | `assets/cleaned/P14/P14_solid_repair_candidate.glb` | 2 x 3 x 1 | Rear-center wall mount | 304 | Inspect the closed cabinet, socket/status inserts and imported part hierarchy. |
| I01 | `assets/cleaned/I01/I01_art_repair_candidate.glb` | 3 x 2 x 0.3 | Upper hinge | 260 | Confirm fixed mount and sign remain separate and pivot at the hinge. |
| I04 | `assets/cleaned/I04/I04_art_repair_candidate.glb` | 3 x 4 x 1.5 | Rear-center wall mount | 648 | Confirm all four indicators and tuning dial remain distinct. |
| I05 | `assets/cleaned/I05/I05_solid_repair_candidate.glb` | 3 x 4 x 2 | Floor-center | 484 | Confirm closed podium surfaces, top controls and front status bar. |

## Import acceptance steps

1. Import each GLB into a temporary Studio place, keeping the candidate ID in the model name.
2. Inspect the resulting Model/mesh hierarchy, orientation, size, pivot and material assignments. The GLBs intentionally contain separate meshes; collapse or merge only if the intended detail and part boundaries remain correct.
3. Add only contract-appropriate collision proxies. Keep foliage and small decorative details non-colliding; keep the sign's target area query-only.
4. Capture Explorer hierarchy, import settings and viewport screenshots for each asset. Record any fixes and repeat the size/pivot checks after changes.
5. Do not publish or bind production asset IDs as part of this review. Only move an asset into `assets/approved/` after the Studio and runtime checks pass.

No Studio import, collision setup, runtime check, ownership verification or publishing has been performed yet. P13, I01 and I04 remain the prior art-reviewed candidates. P12, P14 and I05 geometry evidence is in `solid-repair-candidates.json`; their visual/art approval is pending. Prior candidate measurements and approval are recorded in `art-repair-export-inspection.json` and `art-review-approval.md`.
