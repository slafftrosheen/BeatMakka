# Companion implementation refresh — 28 October 2026

The user-designated `BeatMakka_Companions_v1` folder is the companion design reference for this revision. Its PDF, written brief, turnarounds and world scenes are preserved in `assets/references/companions/provided-pack-v1`; exact source/copy hashes are recorded in `assets/references/companions/artbook-refresh-provenance.json`. Earlier generated v2/v3 artbooks document earlier candidates; they do not supersede the supplied art direction.

Repository base after `git pull --ff-only`: `8e8b91f6a5472eb6200599e60932e45a8c9ea56b` (already up to date). Existing gameplay and asset work was uncommitted at the start and remains preserved.

## Implementation

- Alissia: open faded-teal jacket over a cream music shirt, lapels and pockets, coral backpack straps and buckles, cream/coral satchel, fuller tied hair and braid, retained coral glasses.
- Nikolas: rounded open teal vest, folded hood, cream rhythm shirt, backpack straps, swept blond hair, cargo pockets attached to the moving upper legs, and a larger cream/amber dial on the teal rhythm counter.
- Both: softened collar/clothing, restrained eyes and small smile, teal sneakers with cream toes/soles and coral trim. Warm matte shared-atlas materials remain; no photographic face textures.
- Existing 16-joint structure, ten source actions, canonical IDs and follower/portrait integration are retained. No new quest, reward, music-editing or microphone authority.
- Companion cards stack the portrait above the text below 420 pixels of available width, with resize cleanup on destruction.
- `refresh_companion_bindings.py` refreshes content-hashed runtime paths, production data and only the companion entries in the local installer manifests. Older mesh files remain available for historical packages.

## Local outputs

Sources and renders: `assets/production/needle-quay/companions/ALISSIA/` and `NIKOLAS/` contain `.blend`, `.glb`, front/side/back/isometric and gesture views. `src/shared/CompanionModels.luau` points to this revision's local mesh content. Current measurements belong to `data/companion-production.v1.json`.

Authored LOD triangles: Alissia **4100 / 1490 / 441**; Nikolas **3968 / 1424 / 410**. Targets remain **4500 / 2000 / 800** per the companion brief. Each character retains one 512×512 atlas and 16 joints. These are export measurements, not performance evidence.

The shared user asset folder was inventoried; none of its materials were needed. All visual refinement was deterministic local Blender authoring based on the supplied artwork. No paid provider operations, uploaded assets, new dependencies, commits or pushes.

## Acceptance and existing packages

This revision is **DCC_CANDIDATE_PENDING_ART_REVIEW**. Tests, lint/build verification, Studio play, phone, multiplayer, cloud persistence and artist acceptance were **NOT_RUN**. No earlier runtime receipt establishes acceptance of these new meshes or the responsive card change.

Existing development/demo ZIPs and packaged places remain **pre-refresh snapshots**. Use the current repository source and refreshed local content manifests for the next local package build; do not treat an older ZIP as this revision. The supplied artbook remains unchanged.

Reproduction, from repository root:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --factory-startup -b --python tools/build_companion_candidates.py
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --factory-startup -b --python tools/render_companion_details.py
python tools/refresh_companion_bindings.py
```
