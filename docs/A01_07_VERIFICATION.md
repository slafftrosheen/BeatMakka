# A01-07 finish isolation and material candidates

23 October 2026. Issue #8 remains open for human art approval, persistent imported mesh acceptance and real-player/cloud finish persistence.

## Runtime correction

The previous renderer traversed every MeshPart under the occupied sampler when Art existed. A functional mesh outside Art could therefore lose its authored surface. The new Studio regression reproduced this failure before implementation.

Finish changes now target only the matching station's compatible Art subtree. Four finish IDs, geometry, pivots, collision flags and functional surfaces remain unchanged. Resolution is restricted to the authored 512/1024 choices, with incompatible layout/resolution changes restoring originals. Original SurfaceAppearance instances are detached and retained rather than cloned. Leaving a station or destroying the renderer restores them and clears proxy tints.

Owned async templates are cached and destroyed on teardown; borrowed prepared library surfaces remain borrowed. Late results arriving after destruction are destroyed rather than repopulating the cache. Failed loads stay bounded until a fresh session. Preview messages distinguish selected/loading/unavailable instead of claiming an unsaved choice was saved. The main client refreshes that status and destroys its renderer during teardown.

## Original material study

[tactile-v1](../assets/candidates/materials/tactile-v1/manifest.json) is a separate candidate. The existing production maps and fourteen uploaded image bindings are unchanged. The study uses the four existing palettes and identical FZ_MaterialAtlas_v1 layout, with 1024/512 base-color maps and shared roughness/metalness. There are twelve maps and the unchanged layout copy. Fixed mathematical synthesis provides broad wood grain, restrained paint handling marks, brushed satin metal and dense matte rubber. No provider media, baked light, labels, normal maps or paid operations are used.

The approved style board and Artbook pages 4/7/9 guide this study. Shared UV tiles cannot place convincing object-specific edge wear; those authored details still need per-asset review. These maps have not been promoted to production, uploaded or art-approved.

Reproduce with the existing project Python/Pillow/NumPy runtime:

```powershell
python -B tools/build_finish_candidates.py
python -B tools/build_finish_candidates.py --verify
```

Build refuses an existing candidate directory. Verification checks the exact file roster, hashes, map modes/sizes, production input agreement and unchanged bindings. A separate ignored reproduction matched all thirteen roster files byte-for-byte. Negative checks rejected a tampered map and an unlisted file. Input JSON hashes normalize LF; candidate hashes pin exact bytes through Git attributes.

## Inspection and Studio evidence

[Neutral front/rear comparison](evidence/a01-07/neutral-contact.png) renders the actual existing H01 housing geometry with candidate PBR maps. Blender runs headlessly on CPU with two threads. [Material detail comparison](evidence/a01-07/material-comparison.png) shows original/candidate flat color tiles. These do not constitute human art approval.

Studio MCP also created four isolated temporary H01 EditableMesh previews with candidate 512 maps: 2,088 triangles per housing, four color maps and shared roughness/metalness. [Front](evidence/a01-07/studio-front.jpg) and [rear](evidence/a01-07/studio-rear.jpg) captures show them in Studio. The temporary models were removed and original Lighting restored. No real asset IDs or persistent imports resulted.

Preparation: run `python -B tools/prepare_finish_review.py`, then use the existing `drive_studio.py code` bridge on `work/finish-review.luau` in Edit mode. `prepare_finish_review.py --cleanup` produces explicit cleanup code; run it after capture or any partial failure. The helper verifies the pinned H01 source hash and triangle count before preparing the isolated review.

[Receipts](evidence/a01-07/): finish fixtures pass all four sets, control/other-station isolation, geometry/collision/pivot preservation, incompatible layout/resolution rejection, exact original-instance restoration and idempotent destruction. Async loading fixtures pass pending status, single creation/cache, bounded failure, owned-template disposal and late-result disposal. Controlled factories establish lifecycle behavior, not real cloud permissions. Existing eight Contracts, eight Milestone groups and six-size UI checks pass. Pinned Selene reports zero errors/warnings/parse errors; StyLua, Rojo build and whitespace checks pass. Independent read-only review found no blockers; helper provenance/cleanup limitations were addressed.

No foreground desktop/browser automation, duplicate uploads, production map changes, dependencies or charges occurred. Cloud rejoin, real two-player rendering, dusk/gameplay-distance and final art approval remain unverified. Keep #8 open.
