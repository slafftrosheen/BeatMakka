# Cleaned asset surface review

Reviewed 20 production-facing assets and all 51 GLBs present before repair. The raw Tripo outputs and earlier candidates remain unchanged. The current import paths below point to repaired outputs where needed. Blender 5.2.2 re-import preserved each repaired asset's bounds, mesh count and UV presence; open boundaries were patched only where their surface was expected to be closed.

| ID | Current GLB | Action | Surface result |
|---|---|---|---|
| H01 | `assets/cleaned/H01/H01_sampler_shell_surface_repaired.glb` | Normal repair + boundary patches | 28 boundary edges and 14 non-manifold edges remain in DCC audit; user confirmed asset is acceptable. |
| H02 | `assets/cleaned/H02/H02_compact_speaker_stack_surface_repaired.glb` | Normal repair + four speaker-face caps | Closed after re-import; zero open/non-manifold edges. |
| H03 | `assets/cleaned/H03/H03_vinyl_crate_shell_surface_repaired.glb` | Normal repair | Closed after re-import; zero open/non-manifold edges. |
| H04 | `assets/cleaned/H04/H04_maintenance_helper_robot_surface_repaired.glb` | Normal repair | Closed after re-import; zero open/non-manifold edges. |
| H05 | `assets/cleaned/H05/H05_curved_street_lamp_scaled_surface_repaired.glb` | Normal repair + lamp-base cap | Closed after re-import; zero open/non-manifold edges. |
| P01 | `assets/cleaned/P01/P01_studio_workbench_surface_repaired.glb` | Normal repair + two surface patches | Closed after re-import; zero open/non-manifold edges. |
| P02 | `assets/cleaned/P02/P02_round_workshop_stool_surface_repaired.glb` | Normal repair + four joint caps | Closed after re-import; zero open/non-manifold edges. |
| P03 | `assets/cleaned/P03/P03_listening_bench_surface_repaired.glb` | Normal repair + surface patch | Closed after re-import; zero open/non-manifold edges. |
| P04 | `assets/cleaned/P04/P04_record_browsing_bin_surface_repaired.glb` | Normal repair | Closed after re-import; zero open/non-manifold edges. |
| P05 | `assets/cleaned/P05/P05_wall_shelf.glb` | No repair needed | Closed and winding-consistent in audit. |
| P06 | `assets/cleaned/P06/P06_normalized_geometry_candidate_surface_repaired.glb` | Normal repair | Closed after re-import; zero open/non-manifold edges. |
| P07 | `assets/cleaned/P07/P07_normalized_geometry_candidate_surface_repaired.glb` | Normal repair | Closed after re-import; zero open/non-manifold edges. |
| P11 | `assets/cleaned/P11/P11_normalized_geometry_candidate_surface_repaired.glb` | Normal repair | Closed after re-import; zero open/non-manifold edges. |
| P12 | `assets/cleaned/P12/P12_solid_repair_candidate.glb` | Rebuilt ten leaves as closed thin volumes | Closed; zero open/non-manifold edges. |
| P13 | `assets/cleaned/P13/P13_art_repair_candidate.glb` | No repair needed | Closed and winding-consistent in audit. |
| P14 | `assets/cleaned/P14/P14_solid_repair_candidate.glb` | Rebuilt cabinet and details as closed solids | Closed; zero open/non-manifold edges. |
| P16 | `assets/cleaned/P16/P16_normalized_geometry_candidate_surface_repaired.glb` | Normal repair | 32-edge hood mouth remains open by design; user confirmed asset is acceptable. |
| I01 | `assets/cleaned/I01/I01_art_repair_candidate.glb` | No repair needed | Closed and winding-consistent in audit. |
| I04 | `assets/cleaned/I04/I04_art_repair_candidate.glb` | No repair needed | Closed and winding-consistent in audit. |
| I05 | `assets/cleaned/I05/I05_solid_repair_candidate.glb` | Rebuilt podium as closed solids | Closed; zero open/non-manifold edges. |

## Audit evidence

- Full pre/post file inventory and edge counts: `glb-surface-audit.json`.
- Face winding repairs: `glb-normal-repair.json`.
- Confirmed open-surface patches: `open-surface-repair.json`.
- Three later solid-geometry replacements for P12, P14 and I05: `dcc-normalization/solid-repair-candidates.json`.

## User review

On 2026-10-22, the user confirmed all 20 production assets are acceptable. This closes the visual acceptance review, including H01's residual DCC topology flags and P16's intentional hood opening. The numerical DCC audit remains unchanged. Roblox Studio import hierarchy and runtime behavior have not been independently recorded here.
