# Needle Quay — sky, architecture and local PBR

Continues the artbook correction pass against the three gaps identified in the preceding review. Everything remains local. No asset uploads, publication, Tripo work, commits or pushes.

## Reference and implementation

The approved Needle Quay board remains the visual authority. The five individual building concept sheets supply their architecture. World Artbook v2, the Environment/Quest Artbook Vol.01 and the MK-I performance proposal retain the palette, material roles and interface direction recorded in the preceding comparison. The user asset folder was inventoried again; unrelated new ornament assets were excluded. Existing supplied assets retain their provenance.

| Previous gap | Current implementation |
| --- | --- |
| Procedural cloud field | A new panorama referenced to the approved board, projected into six cubemap faces in Blender. The source panorama, prompt/provenance, packed Blender file and face hashes are in `assets/production/needle-quay/sky-artbook/`. The old procedural sky is preserved as history and excluded from Current. The additional Terrain cloud layer is removed. |
| Supplemental building blocks | Five replacement DCC buildings, NQ-BLD-09–13, and three reusable façades with recessed windows, shutters, doors, handles, softened edges, copings, roof equipment, pipes and building-specific details. The cold store has insulated doors and a condenser; the laundry has three washer drums; the relay has service equipment; the depot has braced timber loading doors and a hoist. Ten backstreet houses and the distant shore use these source meshes. |
| Color-only local material path | Shared local SurfaceAppearance templates bind color, normal, roughness and metalness content. Existing material atlases and environment/character data maps are used. Paving and dock boards have UV-scaled PBR planes over their original collision parts. Device finish changes and companion skins use the same local PBR path. |
| Overlapping façade decoration | Rebuilt architecture owns its signs, lamps and roof equipment. Generic windows/pipes/roof boxes and the old raster nameplates are skipped for these buildings. Names use native TextLabels at exported fascia anchors. |
| Excessive orange wash and window glow | Cooler ambient fill, reduced haze/tint, panorama orientation and quieter amber glass retain sunset warmth without the previous yellow window glare. |
| Stale packaged assets | Current resolves overridden building IDs before collecting content. Superseded meshes and the earlier procedural sky are excluded from the active manifest; originals remain in the repository. |

The architecture generator is `tools/build_quay_authored_architecture.py`. Its authored Blender scenes, source hashes, concept references, measurements and export metadata live in `assets/production/needle-quay/architecture-artbook/manifest.json`. Canonical IDs, registered envelopes, floor pivots, collision and mission anchors are preserved. These revisions are not automatically promoted to final art approval.

## Material meaning and local boundary

This is rendered PBR in local Studio, using [AssetService.CreateSurfaceAppearanceAsync](https://create.roblox.com/docs/reference/engine/classes/AssetService) with EditableImage content. No cloud TexturePack asset is created or published. The local package reconstructs these surfaces when Play starts; it does not contain a published Roblox TexturePack ID.

Environment/character maps retain their authored normal and roughness detail. The hardware uses its existing roughness/metalness atlas. Supplied assets that contain only base color and constant roughness keep that declared material response: flat normal, roughly 0.9 roughness and zero metalness, rather than invented detail derived from color. Brick, wood, plaster, glass and metal in the new architecture have separate material roles. Native Part materials remain native Roblox materials.

The paving implementation releases mutable mesh capacity before display and shares compact templates by dimensions/UV density. It uses the existing mesh queue so ground construction cannot reserve the editable capacity needed by resident skinning. Source parts continue to own collision and navigation.

## Local review

Evidence and package receipts: `docs/evidence/needle-quay-artbook-finish/`. The preceding UI/state review remains in `needle-quay-pixel-polish/`; this pass also rechecks Groovebox presentation with the restored PBR path. Source lint, local build and package integrity are separate from visual inspection; no test suite was added or run.

The current package is `output/needle-quay-demo/NeedleQuay-Current.zip`. Extract it and run the included launcher to install its exact local content and open the place. The current scene must finish loading its art and materials before comparison captures are taken.

Observed in the final local Studio run:

- 83/83 art entries loaded; 93/93 authored tiled surfaces have PBR planes; zero unbound material-key meshes, zero unconverted paving textures and zero procedural cloud layers.
- 1,416 SurfaceAppearance instances at the final snapshot. All sampled material roles had local object-backed color/normal/roughness/metalness maps. Counts vary with streamed/cloned scene objects.
- Resident skin construction completed, with 26 weighted skin parts visible in the review. A separate Alissia selection produced four PBR mesh parts and `SuppliedSkinReady = true`.
- All ten GRA-01–10 graphics were bound. Five rebuilt canonical façades and the backstreet/harbor were captured. Laundry drying now sits on a supported rooftop line, clear of the sign and washer display.
- Native clicks enabled sequencer steps 1 and 5, started playback and stopped it. Undo history recorded both edits. At a simulated 400×777 phone viewport, all sixteen pads remained visible at 65×65 pixels.
- No project-script exceptions, material failures or mesh-memory warnings appeared in the final run. The existing external `203785492` asset-type warning remains.
- Source lint: zero errors, warnings or parse errors. Eight DCC exports passed source/mesh hash, triangle, normal-length and registered-envelope checks; seven reference hashes matched. The package passed CRC/content checks for all 931 files and matched the changed source modules and launch README.

ZIP SHA-256: `9fc2fa9276f081f94c0d98383b81cd2febe7254a37ec07c89220d65d660dad39`. Screenshots: [cold store](../evidence/needle-quay-artbook-finish/cold-final.png), [flats](../evidence/needle-quay-artbook-finish/flats.png), [laundry](../evidence/needle-quay-artbook-finish/laundry.png), [relay](../evidence/needle-quay-artbook-finish/relay.png), [depot](../evidence/needle-quay-artbook-finish/depot.png), [backstreet](../evidence/needle-quay-artbook-finish/backstreet.png), [harbor](../evidence/needle-quay-artbook-finish/harbor.png), [Groovebox](../evidence/needle-quay-artbook-finish/ui.png), [phone](../evidence/needle-quay-artbook-finish/phone.png).

Final human art approval remains a separate gate. A generated reference illustration is not a registered camera/render specification, so this report does not certify literal per-pixel equality across every view. The three earlier implementation gaps have been replaced rather than carried forward as accepted limitations.
