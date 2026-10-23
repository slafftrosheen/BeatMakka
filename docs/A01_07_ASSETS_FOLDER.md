# Issue 8: materials from the user Assets folder

This is the original candidate-stage record. The user subsequently approved this revision; see [applied finishes and current acceptance](A01_07_APPLIED_FINISHES.md). The frozen candidate/source bytes remain unchanged.

23 October 2026. Candidate **assets-folder-v1** continues issue #8. It is not a production replacement or an art-approved upload. [Visual review](../output/materials-assets-folder-v1/index.html) and [neutral comparison](evidence/a01-07-assets/neutral-contact.jpg).

## Sources and treatment

Inspected `C:/Users/slavd/OneDrive/Pictures/Assets` before visual work. The Stylized Materials Library IMG files are 128px lit preview spheres, so they were excluded as texture sources. The supplied Stylized Edition library contains real 4096px 16-bit height alphas. Two exact TIFF copies are retained under [assets/sources/materials/user-assets-v1](../assets/sources/materials/user-assets-v1/provenance.json): wood_fibers_06_height.tif and metal_scratch_01_height.tif. Combined source size: 10,342,742 bytes.

The user explicitly directed use of these materials and repo copies of everything used. Their upstream license was not supplied; provenance records user authorization without claiming CC0/freeware or independent license verification. No source file was edited.

Wood uses cropped, resampled linear height detail with restrained palette and roughness variation. The scratch alpha supplies three sparse handling marks for paint and exposed metal. Other roles retain the prior deterministic detail. Full transforms, source paths, source hashes, generator dependencies and artifact hashes are in the [candidate manifest](../assets/candidates/materials/assets-folder-v1/manifest.json). Shared UVs cannot locate convincing wear at each physical object edge; these are local surface marks rather than per-object damage.

The Artbook pages 4, 7 and 9 and the approved board remain the authority: matte/satin paint, broad wood grain, dense dark rubber, simple cloth, lighting authored in the scene. Four existing palette IDs, FZ_MaterialAtlas_v1, sixteen roles, eight-pixel gutters at 1024 and all twelve 512/1024 color/roughness/metalness outputs are preserved. No normal maps, displacement, geometry edits, lettering, baked lighting, dependencies or provider calls were added. The current 100 audio and 14 image bindings are unchanged.

## Validation and Studio evidence

- Offline checks passed for exact source copies, map roster/hashes, dimensions/channel modes, atlas layout, gutters and image binding preservation. An independent build reproduced all fourteen candidate files byte-for-byte, including the manifest. Tampered and unlisted files were rejected. [Receipt](evidence/a01-07-assets/source-verification.json).
- Blender ran headlessly on CPU with two threads. Neutral front/rear views show all four finishes on the existing H01 housing and P01 workbench. Geometry was read from existing optimized GLBs and was not exported or modified. The wood fibre source is visible on the workbench. [Neutral renders](evidence/a01-07-assets/neutral/).
- Studio MCP created four temporary H01 EditableMesh previews with actual 512px candidate maps, 2,088 triangles per housing. Neutral front/rear/detail and isolated dusk/distance captures are retained. The housing-only gallery has no controls or surrounding workshop; its dusk captures do not establish full gameplay control readability. The helper removes the gallery, restores saved Lighting and explicitly destroys its seven editable resources. [Install](evidence/a01-07-assets/studio-install.json), [cleanup](evidence/a01-07-assets/studio-cleanup.json).
- The real Client finish renderer applied all four real candidate Color/Roughness/Metalness maps. Two isolated local renderers left each other's station untouched; functional surfaces, geometry, collision and original SurfaceAppearance instances were preserved. Unsupported resolution was rejected. Borrowed templates survived renderer teardown, the prior AppearanceLibrary was restored and six editable images were disposed. Existing finish lifecycle/loading checks also passed. [Runtime receipt](evidence/a01-07-assets/studio-runtime.json).
- Eight Contracts and eight Milestone groups passed in the Server datamodel with injected storage. An initial harness incorrectly attempted those server-only checks on Client; that harness target was corrected before the recorded passing checks. No cloud storage was touched. [Regression receipt](evidence/a01-07-assets/studio-regressions.json).
- Pinned Selene and StyLua passed; Rojo built the project. Independent read-only review found no actionable issues.

Studio was returned to Edit mode. No foreground input, browser automation, new uploads, charges or production binding changes occurred. The headless work used two CPU threads; no separate Blender window opened.

## Reproduction

```powershell
# Initial source import only; refuses existing sources/candidate:
python -B tools/build_assets_folder_finishes.py --import-sources
# Offline check or independent reproduction from retained repo sources:
python -B tools/build_assets_folder_finishes.py --verify
python -B tools/build_assets_folder_finishes.py --output work/new-material-reproduction
# Prepare Edit-mode Studio review and explicit cleanup:
python -B tools/prepare_finish_review.py --candidate assets-folder-v1
python -B tools/prepare_finish_review.py --cleanup
# Prepare Client runtime checks with real candidate editable maps:
python -B tools/prepare_candidate_material_runtime.py
```

Execute generated Luau only through the existing Studio MCP bridge in the named datamodel. The Blender renderer accepts `-- assets-folder-v1 H01` or `-- assets-folder-v1 P01`; run with `--background --factory-startup --disable-autoexec --threads 2`. Candidate generation refuses overwrites. Verification works without the original external Assets folder.

## Remaining acceptance

Issue #8 stays open. Human approval of the material revision, intended persistent mesh import, actual two-player rendering, full-game dusk/control readability and saved finish after a real cloud rejoin remain unverified. Two renderer instances in one Client and injected storage do not replace those checks. Production maps and existing uploaded image IDs remain unchanged until the issue's separate material review/upload acceptance.
