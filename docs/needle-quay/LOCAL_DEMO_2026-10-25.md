> Historical snapshot. The user rejected this scene as insufficiently faithful to the artbook. See [the current revision](ARTBOOK_REVISION_2026-10-25.md); this document is not current art acceptance.

# Needle Quay local final-art demo

25 October 2026. Final art is accepted by the user's direct instruction. The local demo now uses exact source meshes, local materials and local audio. No Roblox uploads or publishing occurred.

Run `output/needle-quay-demo/Launch-NeedleQuay.ps1`, then press Play. The portable `NeedleQuay-Local-Demo.zip` includes the place, launcher, manifest and all 546 companion files. The launcher checks SHA-256 and writes only Studio's `content/needle-quay` namespace. Reinstall after a Studio version update. The original `small-concerts.rbxlx` was not edited.

## Delivered

- Thirteen authored buildings, six authored NPC meshes plus H04/Mica, two detailed Roamers, four parking venues, eleven-district map and Q00-Q12 with the six-phase concert.
- Forty exact asset definitions: 112,436 unique source triangles, preserving normals, UVs and source hashes. Runtime scene includes repeated benches, plants, lamps and activity props: 407 MeshParts / 196,490 triangles. No visible ArtProxy or Placeholder geometry remains. Invisible deterministic collision shapes are retained deliberately.
- Eight local PBR templates using EditableImages and CreateSurfaceAppearanceAsync; 138 scene surfaces. Raw local SurfaceAppearance file URIs proved unsupported and were removed from the runtime route. No uploaded map IDs were substituted.
- All 184 WAVs resolve locally. The three discovery sounds load and advance during playback. Cloud ContentIds remain unchanged. This is engine playback evidence, not a claim of human listening review.
- Source sign graphics on all thirteen buildings, named NPC idle joint motion, reduced-effects support, authored planter/bench/lamp dressing and personal cleanup props. The Roamer source is an editable Blender file with a reproducible generator; its complete exterior is exactly 22 x 9 x 10 studs.
- Existing sampler, pattern slots, Beat Shelf, workshop finishes, owner-associated van entry, parking, respawn, progression checks and session saving remain integrated. Other city districts stay locked; music genres are not story-locked.

## How to play

1. Close the welcome journal and talk to Tori at Dockside Exchange. Stow the three marked crates. Enter your Roamer to make music immediately.
2. Assign Quay metal to a pad and enable four different steps. Return to Tori and select **Check my music**. The public performance invitation can be skipped.
3. Park at Repair Alley. Use repair controls 1, 2, 3. Make different playable A and B patterns in the sampler, store them to Beat Shelf, then return to Ivo for the check.
4. At Vinyl Market, match kick/pulse, hat/texture, melody/tune. Check your successfully saved shelf beat and clear the three marked stage cases. No other player is required.
5. At Breakwater Steps, collect the virtual Helper chirp, put it on steps 1/5/9/13, then return to Mica for the check and use the radio console.
6. Visit Ronan at The Lantern Room. Bring a saved beat with two playable parts, a different pattern, and a collected sound layered with another part. Enter the concert; perform rhythm, support, break, return, switch and feature, waiting for each full loop.

## Evidence and boundaries

`docs/evidence/needle-quay-demo/studio-walkthrough.json` records the earlier single-client Q00-Q12 walkthrough: real server-clock concert phases, saved A/B and shelf evidence, rejected wrong repair/order/destination requests, actual own-van UI entry, and P4 respawn. No completion flags or elapsed concert time were injected. Avatar placement between stations was assisted. The art pass retained that gameplay logic and received focused loading, geometry, material, animation and audio inspection rather than another full route run.

`docs/evidence/needle-quay-demo/final-local-art.json` records the final scene. All 281 exported mesh bounds matched within 0.002 studs; 40 assets loaded, eight local finish templates became ready, NPC motion was observed and 184/184 audio files loaded with no failed sample. Local content installation and the standalone PowerShell install path both passed checksum verification. The only observed console warning is the pre-existing `rbxassetid://203785492: Asset type does not match requested type`; no new script or local material errors remained.

No automated test suites were added or run. Two independent players, real phone/gamepad, cloud save/rejoin and an uncoached player review are not claimed. This unpublished PlaceId=0 build uses session saves; persistence across Studio restarts requires the later deployment/account work. Local EditableImages are rebuilt each play session. Each Studio installation needs the companion content, so the place file alone is not a portable deliverable.

## Sources and acceptance

The supplied books, canonical register and approved board remain authoritative. The user Assets directory was refreshed; already-vendored repository sources were reused. `assets/local-demo/mesh-manifest.json` retains source paths, source hashes, exact mesh hashes and joint metadata. `content-provenance.json` records original audio/graphics/material paths. `FINAL_LOCAL_ART_APPROVAL_2026-10-25.json` records the user's approval against the current source hashes. Local Studio import/inspection is distinct from Roblox-hosted asset deployment. Earlier native-proxy reports remain historical evidence and are superseded for this named local build.

No Tripo calls/spend, credentials, uploads, publishing, new dependencies, CI workflows or pushes. New art assets and production sources were preserved in scoped local commits; gameplay changes remain separate and uncommitted. Pre-existing jam/audio/gameplay work is preserved; packaging it does not imply new multiplayer acceptance.

## Rebuild

Use the repository's Rokit-pinned tools from its root:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python tools/build_local_roamer.py --python tools/export_local_demo_meshes.py
python tools/package_local_demo_content.py
rojo build default.project.json --output output/needle-quay-demo/NeedleQuay-Local-Final.rbxlx
python tools/package_needle_quay_demo.py
./output/needle-quay-demo/Launch-NeedleQuay.ps1
```

The generated bounds records supply collision only; visible art comes from the exact local meshes. `tools/prepare_needle_quay_demo.py` is an optional loopback source-sync helper for the dedicated Studio demo. No HTTP server is needed at game runtime. Package hashes are recorded in `docs/evidence/needle-quay-demo/local-package.json`.
