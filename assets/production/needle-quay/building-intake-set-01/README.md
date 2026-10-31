# Updated building models — set 01

Eight supplied files, seven unique candidates. Both repair-shop files have identical SHA-256 hashes. Original files copied unchanged with provenance; Blender sources retain original transforms and packed textures. All eight imported and rendered with Blender 5.2.2. No tests, Studio import, uploads, commits or gameplay replacement performed.

| Candidate | Proposed canonical building | Triangles |
|---|---|---:|
| record-store | NQ-BLD-02 | 8,494 |
| lantern-room | NQ-BLD-01 | 7,692 |
| seaside-shop | NQ-BLD-08 | 8,380 |
| ferry-booth | NQ-BLD-07 | 8,629 |
| cafe | NQ-BLD-06 | 8,328 |
| steampunk-shop | NQ-BLD-05 | 8,818 |
| repair-shop-variant | NQ-BLD-03 | 7,882 |
| repair-shop | NQ-BLD-03 | 7,882 |

Each unique model has one mesh, one material and one embedded 1024×1024 image. No geometry reduction or rescaling applied. Measured original bounds are in inspection.json.

Visual review against the approved board: coherent teal/cream/coral palette, worn storefront detail and strong shop identities. Café has a visible dark roof gap; inspect and repair roof geometry before acceptance. Record-store roof also has an angular shaded patch to inspect from above. Single textured meshes include doors, signs and street dressing: keep interactive controls, collision proxies and localized signage separate. Existing baked lettering may need masking in an adapted texture; preserve originals.

Mappings for seaside shop → Quay Supply & Tackle and antenna-topped steampunk shop → Signal House are proposed from visible props. Canonical dimensions remain unchanged. Needle Records already has a documented scale conflict (proposed 24×18×19 vs canonical 32×16×24); intake does not resolve it by stretching geometry.

Next preparation: inspect roof topology and rear views, prepare bottom-center pivots and fitted placement while preserving proportions, author deterministic entrance/collision proxies, then local Studio import and visual/runtime acceptance. Stage remains candidate; Blender import alone does not establish DCC-clean or art-approved status.
