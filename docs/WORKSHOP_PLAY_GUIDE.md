# Workshop milestone: setup and current status

For the subsequent complete first-zone source batch, current checks and fixes, see [implementation coverage](IMPLEMENTATION_COVERAGE.md) and [runtime verification](RUNTIME_VERIFICATION.md). The upload outcomes below remain asset-stage evidence, not a substitute for those runtime checks.

## What is implemented

Needle Quay has two sampler stations, a 16-pad/16-step editor, tempo and transport controls, quantized recording, pad mute/clear, sound assignments, three discovery interactions, personal restoration indicators, and manual save/restore. Four device finishes are saved with the pattern. The server checks station ownership, distance, command shape, rates and unlocks.

The [next playable milestone](NEXT_PLAYABLE_MILESTONE.md) adds four independent pattern slots A–D, six personal beat shelf positions, and Mica's request ending in a full courtyard loop. The subsequent [Studio verification](MILESTONE_VERIFICATION.md) covers its build, contracts, two-client gameplay and phone layouts. Earlier receipts cover the earlier source only.

The current build is a local development milestone. Audio playback requires uploaded sound IDs. The 19 playable samples, four interface cues and one ambience WAV exist but are not uploaded. Courtyard snapshot sharing has a [source implementation and player flow](LISTENING_MILESTONE.md), with its simulated multiplayer checks recorded separately. Character equipment, item ownership, final character rigs and character-specific textures remain future implementation.

## Open the source build

From `C:\Users\slavd\BeatMaka`:

```powershell
rokit install
rojo build default.project.json --output work\FrequencyZero-Workshop.rbxlx
rojo serve default.project.json
```

Open the generated place, or connect the Rojo plugin in the existing review place. `ServerStorage.AssetLibrary`, `ReplicatedStorage.AppearanceLibrary` and `UiImageLibrary` preserve manually imported instances during sync. A fresh source build uses visible geometry proxies until the asset library is imported; it does not embed the GLBs.

## Play

1. Start Play and walk up the ramp into the workshop.
2. Approach a sampler and hold its interaction prompt. One player can occupy each station.
3. Tap a pad, then toggle its numbered steps. The selected pad and ON/OFF states are written explicitly.
4. Press Play or Space. Press Record or T, then tap pads to record to the nearest step.
5. Use `1 2 3 4 / Q W E R / A S D F / Z X C V` to audition pads while the sampler is open. Those keys are captured by the instrument.
6. Choose a collection entry to assign it to the selected pad. Locked entries require their discovery interaction.
7. Change tempo, mute/clear a pad, or cycle Finish. Finish selection is personal.
8. Choose A–D in the Patterns section. Each slot keeps its own steps, sounds, mutes and tempo; switching stops transport and recording. Use the on-screen slot buttons: the letter keys still audition pads.
9. Select a position on Your Beat Shelf, then Save to shelf. Each beat stores all four slots. Replacing an occupied position or loading a beat requires pressing the same confirmation button twice within five seconds. Loading replaces working slots A–D and leaves the shelf intact.
10. Save profile saves current slots, shelf, discoveries, finish and quest progress. Restore slots reloads saved working slots and finish while retaining discoveries, shelf work and earned quest progress. Studio session saves are discarded when Play ends. Cloud saving still needs live acceptance; a failed save keeps current work in memory and marks it unsaved.
11. Meet Mica, the helper robot in the sound alley, using Talk to Mica (F or gamepad Y). Collect all three discovery sounds, place at least one discovery sound on an enabled, unmuted step, and save that beat to the shelf. Select the saved pattern you want to perform before leaving the sampler.
12. Share your loop at the courtyard podium and remain there for one complete sixteen-step loop. Mica's quest requires no audience. Stopping, dying or leaving before the loop ends cancels that attempt. Completion requests one profile save; check the save notice and dirty status if storage is unavailable.
13. Sound and Effects controls are available. This preview has no uploaded audio bank, so pattern editing currently runs silently. Audio availability and local mute do not block Mica's quest.

## Asset upload outcome, 22 October 2026

The user approved 32 mesh parts and 14 shared images under the signed-in Studio account.

- **14 image uploads returned asset IDs.** `data/content-ids.json` records the binding keys; `docs/evidence/private-uploads/image-bindings.json` records source SHA-256 hashes and IDs. The runtime module is generated with `python tools/configure_content.py data/content-ids.json --write`.
- MCP upload receipts do not independently prove experience permissions. Metadata checks for two images confirmed Image type, the signed-in creator, and `IsPublicDomain=false`.
- A first string-only preload check returned `Failure`; a follow-up using ImageLabel instances returned `Success` for all 14 exact IDs. The actual UI panel and icons report `IsLoaded=true`. Both receipts are preserved. Texture fetch success is established in this local Play session; 3D PBR appearance, reopened-place persistence and published-experience permissions still require acceptance. Do not reupload these images.
- **0 mesh uploads confirmed.** The first call returned `CreateAssetAsync and CreateAssetVersionAsync are not available yet`. The batch stopped immediately. No mesh submission is being retried.
- Local EditableMesh/EditableImage previews and opaque DataModel content disappear when copied from Edit into Play. The runtime now detects missing mesh content and uses visible proxies. This is not an accepted production import.
- No game was published, no audio was uploaded, and no new Tripo credits were spent in this development batch.

## Finish the mesh import

Use Studio's [Importer](https://create.roblox.com/docs/studio/importer), since this installation's automated mesh publishing API is unavailable.

1. Save the review place locally. The initial scene backup is in `work/studio-review-backup` and `ServerStorage.InitialReviewScene`.
2. Use **File > Import**. Select an optimized GLB from `assets/optimized/<ID>/<ID>_atlas_v1.glb`. All 20 current paths, part groups, dimensions and source hashes are in `docs/evidence/optimized-assets.json`.
3. Use the signed-in creator as owner. For the approved persistent import, enable **Upload to Roblox**. Do not list the assets for distribution or publish the place.
4. Review every importer warning. Keep separate controls, lenses and functional pieces. Preserve authored dimensions and pivots; reject importer unit changes that alter the measured contract. The project faces -Z; the local review bridge rotates the GLB 180 degrees around Y. Check front-facing orientation in the native importer rather than applying that rotation twice.
5. Record returned mesh IDs and imported part counts. Keep decoration anchored and noncolliding; gameplay uses separate authored collision proxies. Use Automatic render fidelity.
6. Move the imported root into `ServerStorage.AssetLibrary`, name it exactly its canonical ID, and retain any earlier local review model separately until the imported replacement is confirmed. Do not retain two masters with the same ID.
7. For atlas exports set root attributes `TextureLayout = FZ_MaterialAtlas_v1` and `TextureResolution = 1024` for heroes or `512` for props, matching the optimized report. Inspect `CosmeticCatalog.TextureLayout` before applying; the string must match the actual source value.
8. After source sync, run `tools/studio_bind_uploaded_images.luau` in Edit through Studio MCP to install eight SurfaceAppearance templates and two UI image templates using existing IDs. This script does not upload anything.
9. Start Play and inspect every side, underside, moving piece, surface map and collision. Stop/reopen the saved place and repeat. Record warnings, permission failures and screenshots separately from art approval. The new atlas treatment still needs visual review.

## Evidence and limits

- `optimized-assets.json`: 20 GLBs, 32 mesh parts, 15,432 triangles. Static object/material consolidation preserves triangle count and measured bounds.
- `studio-ui-session-save.json`, `studio-ui-cleared.json`, `studio-ui-restored.json`: actual UI save, clear and restoration of four enabled steps. `studio-ui-finish.json`: finish selection marks the profile dirty.
- `studio-ui-desktop-inspection.json`, screenshots: actual running workstation. The MCP multi-click tool can scroll to targets between clicks; the final save/clear/restore/finish checks used individual clicks.
- `studio-ui-phone-inspection.json`: phone portrait layout and text fit. Movement controls initially overlapped the interface; the client now hides them while a station is active and restores the previous state on leaving.
- `studio-workshop-console.json`: no project Lua exception in that captured run; a default avatar asset type warning remains.
- Real audio, persisted mesh rendering, final 3D PBR appearance, cloud saves, two-player contention, physical-device timing and measured performance remain unverified. No automated test suite was added or run.

The dated upload evidence above is historical. Current milestone verification and delivery scope are recorded in [Studio verification](MILESTONE_VERIFICATION.md).
