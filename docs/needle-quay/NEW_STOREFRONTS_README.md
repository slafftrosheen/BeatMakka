# Needle Quay — updated storefronts and solid scenery

Run Launch-NeedleQuay.cmd from this extracted folder, then Play in local Studio. This retains the voiced commissions and all prior gameplay. Nothing is uploaded or published.

## Replacements
Lantern Room, Needle Records, Morrow Repairs, Signal House, Warm Current Cafe, North Slip Ferry Office and Quay Supply & Tackle use the seven unique user-supplied buildings. The two supplied repair GLBs were identical; only one is instantiated. Original GLBs, hashes and attribution remain in assets/supplied/buildings/set-01.

The cafe's apparent roof hole was a black baked artifact on a flat deck. A closed six-face roof cap now covers it while preserving the vents and parapet. Adapted Blender files and measured export provenance are in assets/production/needle-quay/models/supplied-buildings. Original UVs and 1024px color maps are preserved. No paid generation, decimation or nonuniform scaling.

Each building is uniformly fitted within its authored footprint, grounded and aligned to its previous street frontage. Old duplicate windows, roof pipes, signs, vines, record-shop dressing and cafe ledge were omitted for replaced storefronts. Visit points follow the new door positions; all building IDs, host links, repair controls and existing Roamer/Lantern interior transitions remain routed through existing services. These are exterior storefront models; no new interior geometry was supplied.

## Collision and occlusion
Solid static scenery now collides, participates in ray queries and casts shadows. Buildings use independent body/plinth collision proxies; source decoration does not become a single giant collidable mesh box. Existing Roamer collision is retained. Characters, moving fan blades, water and nonphysical effects are exceptions. Cleared personal crates disable local collisions/queries along with their visuals; the server sight check ignores crates already stowed for that player.

Custom quay interactions require a clear ray from both the player's head and camera. The server also checks player-to-target sight for quay actions. World labels and route beacons respect depth; global and local-light shadows are enabled, with reduced ambient fill. Existing embedded sampler prompts retain their own-pad visibility exception. No unsupported per-object ambient-occlusion API is claimed.

## Verification
PASS: Blender imported/exported seven candidates; reviewed repaired cafe render.
PASS: exact source hashes, canonical envelope fit, frontage alignment, 2.5-stud minimum approach clearance outside art bounds, no pairwise building footprint overlap.
PASS: focused pinned Selene check — zero errors, warnings and parse errors.
PASS: pinned Rojo build and checksum-verified local content package/install.
BLOCKED: Studio tools and a fresh official StudioMCP both returned an empty studios list, even after Studio was launched and the user reported connection. Live doorway traversal, all mission interactions, rendered occlusion and device performance have not been verified. The collision pass especially needs a Play traversal before runtime acceptance.

No Git commit/push. Art and runtime acceptance remain pending; local build/package evidence does not promote them.
