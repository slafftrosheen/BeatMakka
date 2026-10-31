# Supplied companions and public-space refresh — 28 October 2026

Base: `8e8b91f6a5472eb6200599e60932e45a8c9ea56b`, confirmed up to date by `git pull --ff-only`. Existing uncommitted work was preserved. No commit or push.

## Supplied character integration

- Originals copied from `C:/Users/slavd/Downloads/Alisija.glb` and `niklass.glb` to `assets/supplied/companions/`, with SHA-256 provenance.
- Blender import excludes editor-only bone display shapes. Actual geometry remains 10,295 / 10,968 triangles, with 65 skin joints per character. Original UVs and weights are preserved. Runtime color copies are capped at 1024 pixels; source textures remain embedded in the original GLBs.
- `tools/import_supplied_companions.py` exports two local mesh chunks per character, neutral portrait/fallback geometry, skin weights and sampled source clips. Original files retain all 14 / 11 clips respectively.
- `SuppliedCompanionSkin.luau` constructs local continuous skins through the existing EditableMesh approach, including bind orientations and original weights. Source clips drive idle, walking, running and celebration; root movement is removed from the horizontal plane so following owns travel. Content is local to the DataModel; no animation or mesh asset upload.
- `CompanionFollower` releases skins on switch/teardown and retains a static textured fallback if local skin creation fails. `CompanionPortrait` reuses the supplied body templates.
- Original authored triangle targets remain in `data/companion-production.v1.json`; these supplied models exceed LOD0 target and are not labeled optimized or phone-qualified.

## Environment work

Inspected the root of both `assets/` and the user's shared asset folder. Used repository-root market, electrical-box and laptop GLBs. Extracted seven reusable models with bottom-centered pivots, uniform scaling and shared content-addressed textures. Originals remain untouched. See `assets/production/needle-quay/dressing/manifest.json` for source hashes, selected object names and measured dimensions.

`QuayPublicSpaces` now authors:

- Four market counters with produce trays, striped canopies, storage crates, carts, planters and practical lights. The extension is east of Harbor Market Hall, with a broad central aisle.
- Four cafe tables with eight inward-facing chairs, small servings, perimeter planters and lights. They occupy the garden court beside the cafe rather than the main pedestrian road.
- A side repair bench with laptop/radio and wall cabinets, leaving front-door/control access clear.
- Four waterfront seating pockets and five additional planted trees.

Furniture is grounded from measured art bounds. Tabletop items are placed on the table/counter's actual upper bound. Removed duplicate cafe furniture from the older atmosphere/neighborhood layers. Resident routes now use authored per-resident waypoint rectangles near the market, cafe, dock and repair areas; they retain distance limits and the pause near players.

Canonical buildings, road network, parking, music controls and quest authorities remain in place. This is scene dressing and presentation, not a new economy or mission system.

## Delivery and evidence boundary

Pinned StyLua formatting and the Rojo artifact build completed. The local package includes 738 active content files. Source/import measurements are not runtime evidence. No test suite or Studio Play run was performed, per the project instruction requiring a user request for tests. Skin deformation, collision/traversal acceptance, full-route playback, device/multiplayer performance and art acceptance remain pending.

Latest demo: `output/needle-quay-demo/NeedleQuay-LivingQuay.zip`. Its launcher installs only the local namespace and opens the bundled place. Older demo ZIPs remain historical snapshots.

Rebuild order: run the two new Blender import tools, `python tools/package_local_demo_content.py`, format changed Luau using the Rokit-pinned StyLua, then `rojo build default.project.json --output output/needle-quay-demo/NeedleQuay-LivingQuay.rbxlx` and the local packaging tool with the Living Quay README. Do not run the earlier procedural companion generator over these supplied-model bindings.
