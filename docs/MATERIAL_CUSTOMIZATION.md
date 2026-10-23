# Shared materials and customization

## Source library

`assets/production/materials/layout.json` defines one 4 x 4 atlas with 16 slots: primary paint, secondary paint, trim, accent, amber, wood, stone, graphite, bare metal, foliage, canvas, rubber, ceramic, leather, cloth and cloth trim.

Four palettes share that exact UV layout: `quay`, `chalk`, `coral`, `afterhours`. Each has a 1024 base-color atlas and a 512 derivative. Roughness and metalness are shared at both sizes. Runtime presets swap these precomposed maps; they do not duplicate geometry or perform pixel painting.

The optimized 20-model library consolidates 75 mesh objects and 79 material primitives to 32 parts/primitives. All 15,432 triangles are preserved. The layout has an eight-pixel gutter at 1024 resolution. Functional groups remain separate. Inspect `docs/evidence/optimized-assets.json` for per-model details; this is structural optimization, not a measured frame-rate improvement.

## Editable outputs

- `materials/sets/<finish>/`: precomposed base-color atlases.
- `materials/shared/`: roughness and metalness maps.
- Material tiles, masks and layout metadata under `materials/`: reusable source for new models, items and clothing. The RGB tint mask and individual slot masks remain offline authoring inputs.
- `graphics/`: UI icon atlas and individual SVGs, panel nine-slice, pad/display/device-face masks, and record sleeve motifs. Text remains in native UI.
- `audio/`: 19 original synthesized mono WAV sources with provenance; these are not connected to runtime audio IDs yet.
- `source-manifest.json`: generator inputs, hashes and provenance. Regenerate with `tools/build_content_sources.py`, then regenerate optimized GLBs with `tools/build_optimized_assets.py` when the UV/material layout changes.

## Future devices, items and characters

1. Add device models with the same atlas UV slots and record their texture-layout version. Keep controls, screens, knobs and motion groups separate from cosmetic shells.
2. Give items explicit material roles. Ceramic, leather, canvas, rubber and metal already have reusable slots; ownership/equip rules still need server implementation.
3. Reuse the palette and cloth/trim roles for clothing. Each character needs authored UVs, rigging, skin/face treatment and deformation review. This library is not a ready-to-equip avatar texture package.
4. Keep device, item and clothing eligibility separate in `CosmeticCatalog`. A saved device finish does not grant an item or alter another player's character.
5. Version changed UV layouts instead of applying an atlas to an incompatible mesh. Never promote optimized appearance to art-approved based on the source model's earlier approval.

## Uploaded bindings

The A01-07 continuation adds scoped finish rendering, lifecycle checks and a separate original material candidate. See [verification and review images](A01_07_VERIFICATION.md). That earlier tactile candidate was not promoted. The subsequent approved Assets-folder application is recorded below.

The user approved the Assets-folder revision derived from retained 16-bit wood and scratch sources. Ten changed maps are now production inputs with real uploaded IDs; both identical metalness maps and both UI IDs are reused. Eight authored real-ID surface templates are included in the repository build. See [application, runtime fix and acceptance limits](A01_07_APPLIED_FINISHES.md) and [original source review](A01_07_ASSETS_FOLDER.md).

Four color sets at two sizes, two shared channels at two sizes, and two UI images account for the approved 14 images. IDs are in `data/content-ids.json`; original receipts are in `docs/evidence/private-uploads` and replacement receipts are in `docs/evidence/a01-07-application`. All IDs were returned by Studio MCP. The first string-only preload check failed; a follow-up through ImageLabel instances returned Success for all 14, and the actual UI images report loaded. Temporary H01 art passed the workshop visual review; permanent native mesh import/reopen remains pending. Avoid duplicate uploads.
