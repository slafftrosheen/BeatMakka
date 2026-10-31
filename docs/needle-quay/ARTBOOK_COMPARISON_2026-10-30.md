# Artbook comparison — 30 October 2026

## Source precedence

The original approved style board and `01_Visual_Artbook.pdf` establish the warm, repaired, tactile direction. World Artbook v2, pp. 12–13, retains that material language and the MK-I product identity. Needle Quay Environment/Quest Artbook Vol.01, pp. 77–78 and its graphic register, supplies material roles and graffiti locations. The user-supplied `BeatMakka_Companions_v1` artbook, p. 2, remains the companion direction per the 28 October refresh; the older files named v2/v3 are candidate history, not superseding approval.

Exact source hashes: `docs/evidence/needle-quay-liftup/artbook-sources.json`.

| Artbook requirement | Implementation |
| --- | --- |
| Teal, faded teal, cream, paper, coral, amber, walnut, stone, graphite, dark screen | Existing theme retained; paper and screen tokens now match World v2. Cream performance pads and amber selection clarify the instrument. |
| Shared materials, restrained surface wear | Supplied buildings, dressing, vehicles and imported material maps pass through one bounded, cached artbook palette treatment. Strong blue/green moves toward faded teal, red toward dusty coral, yellow toward amber, neutrals toward warm paper. Source detail/luminance and alpha remain. Existing authored maps stay intact. |
| Matte paint, cloth, soft rubber | Supplied surfaces reuse existing matte roughness maps. No extra glossy/neon grading. Clothing variation is restricted by skin weights to torso/upper limb areas, retaining face/hair/hand/shoe texture color. |
| Canonical people and companions remain recognizable | Only generic residents select randomized appearance, outfit palette/pattern, scale, phase, pace and pause duration. Hosts and supplied Alissia/Nikolas design are retained. |
| GRA-01–10 in specific neighborhood contexts | Warehouse, club approach, main wall, promenade, breakwater, Signal House, market, repair alley, small tags and district-history mural now receive the existing artbook graphics. Sizes follow available wall bounds. |
| Interactive text belongs in native UI | Shop names, transport controls, state and help are native Roblox UI. Original supplied decorative textures remain preserved; new gameplay text is not generated into textures. |
| Fixed 16-pad identity; clear mobile controls | The 4×4 grid remains. Portrait uses an explicit pad/editor switch, keeping the pad bank stationary during performance. Short portrait puts Street Speaker in Setup and Exit beside transport to recover pad space. Pages retain their own scrolling. Short landscape uses a minimum-height workspace and still needs physical device review. |
| Readable walkways and separate collision | New shops avoid the existing connecting walks. Vehicles are noncolliding presentation. New closed scenic shops use deterministic proxies; street art is noncolliding. |

Material-by-material coverage is in `data/needle-quay-artbook-treatment.v1.json`. Normal, roughness, metalness, sky, authored UI/graphics and the approved material atlas are not indiscriminately recolored. This preserves their meaning and avoids tinting faces or technical maps.

These are implementation decisions checked against the documents and viewed artwork. They are **not** a claim that every rendered surface has passed final visual acceptance. The subsequent Current Studio review and generated UI/RPG pass are recorded in `ARTBOOK_POLISH_2026-10-30.md`. That pass replaces local PBR compilation with color-map/matte rendering while retaining authored technical maps; the roughness-map descriptions above describe the initial liftup, not the final local rendering path. Full facade/graffiti adhesion and final art acceptance remain open.

API references used for the local implementation: [EditableMesh vertex colors](https://create.roblox.com/docs/reference/engine/classes/EditableMesh), [EditableImage pixel buffers](https://create.roblox.com/docs/reference/engine/classes/EditableImage), [SurfaceAppearance](https://create.roblox.com/docs/reference/engine/classes/SurfaceAppearance).
