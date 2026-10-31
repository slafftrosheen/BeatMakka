# Local source-basis repair

The local export route used `(x, z, y)` for Blender positions and normals.
This swaps two axes and has determinant **-1**: it reflects the entire model.
The exporter also reversed triangle winding, which repaired front-face culling
without removing the reflection. Baked storefront words and asymmetric details
therefore appeared mirrored even though the texture coordinates were correct.

The corrected map is `(-x, z, y)`, determinant **+1**. It retains Blender's
`-Y` frontage as Roblox `-Z`, retains up, and preserves handedness. The equivalent
conversion directly from glTF is the proper rotation `(-X, Y, -Z)`, consistent
with the already-correct `tools/prepare_studio_payloads.py` review route.

## UV evidence

The original `assets/supplied/buildings/set-01/record-store.glb` first triangle
uses indices `[1, 4, 54]` and these native glTF coordinates:

| Original corner | U | V |
| --- | --- | --- |
| 1 | 0.5004373193 | 0.5280945301 |
| 4 | 0.4893125296 | 0.5285859108 |
| 54 | 0.4700852633 | 0.5639885664 |

The previous `.mesh` file retained Blender's bottom-origin V. Root's Studio MCP
probe of `NQ-BLD-02_0_f1e16ca14687.mesh` read UVs matching the native glTF values
(with the previous reversed corner order). Roblox's legacy `.mesh` reader already
performs the required V conversion. A further U/V flip would corrupt atlas
sampling; this repair changes neither U nor V at an original vertex.

Direct comparison of all **8,494** record-store triangles to the original GLB
after correction measured maximum position error **8.98e-7 studs** and maximum
native-UV error **5.00e-8**. The new file is
`rbxasset://needle-quay/buildings-set-01/NQ-BLD-02_0_61f7a54824d3.mesh`.

The [glTF specification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html)
defines right-handed coordinates and a texture-coordinate origin at the image's
upper-left corner. The actual imported UV probe above verifies the local engine
boundary rather than inferring it from that convention alone.

## Applied scope and invariants

`tools/repair_local_mesh_handedness.py --write` migrated generated local copies:
522 mesh payloads, 528,833 triangles, 83 canonical asset IDs, and 16 supplied
animation modules. Original generated mesh files remain available. New files
have new content hashes and matching catalog URIs. Canonical IDs, source GLB and
BLEND bytes, source texture images, source hashes, and acceptance stages remain
unchanged. Every record carries `coordinate_basis = blender_to_roblox_front_minus_z_v2`.

- Positions, normals, part centers, bone/joint pivots, skin-weight lookup points,
  authored light locations, and native nameplate positions use the same basis.
- Sizes remain positive and unchanged. Existing world pivots and deterministic
  collision envelopes keep their dimensions; source-derived door X offsets
  change sign so entrance prompts follow the corrected doors.
- Each triangle's vertex/normal/UV corners move together. Winding changes with
  the relative reflection, preserving front faces and normal orientation.
- Supplied rest and animation frames are conjugated by `diag(-1,1,1)`:
  translation `(-tx,ty,tz)`, quaternion `(qx,-qy,-qz,qw)`. Reflecting only skin
  positions would break the original motion; both geometry and frames change.
- Future Blender exporters use the proper rotation directly and retain normal
  triangle order. Their generated dimensions remain unsigned.
- Native SurfaceGui text and graffiti images do not receive texture flips.
  Reviewed graffiti anchors are regenerated separately against the corrected
  meshes, including left/right wall ownership and fresh support-mesh hashes.
- `LocalMutableMesh` copies imported corner UVs faithfully. `LocalMaterials`
  loads images without mirroring. Native PBR paving is independently generated
  and does not use the reflected Blender conversion; these routes need no flip.

## Reproduction and acceptance

Run `python tools/qa/check_local_mesh_basis.py` for original/generated mesh hashes,
all-corner UV/geometry invariants, preserved source bytes, supplied skin weights,
animation frames, and the independent original-GLB comparison. Running
`python tools/repair_local_mesh_handedness.py` after migration reports zero writes.

The migration receipt is `docs/evidence/local-mesh-basis-v2.json`. Local package
manifests/installations must be refreshed through the existing packaging tools.
Source verification does not promote assets to runtime-verified. Root owns fresh
Studio inspection of storefront words, ferry door/prompt alignment, van and
scenic-shop details, supplied companion poses, and regenerated graffiti panels.
No uploads or provider operations are part of this repair.
