# Needle Quay / MK-I artbook polish — 30 October 2026

This continues the local liftup with usable generated UI components, runtime layout corrections, more harbor detail and an optional neighborhood RPG loop. It preserves the original visual board, canonical IDs and story quest sequence. It does not declare every surface pixel-perfect or promote candidate assets to final art approval.

## Art direction and provenance

The external `C:/Users/slavd/OneDrive/Pictures/Assets` inventory was refreshed before visual work. The approved board, World Artbook v2, Needle Quay Environment/Quest Vol.01 and supplied Companion v1 material remain the source hierarchy described in `ARTBOOK_COMPARISON_2026-10-30.md`. Source hashes are retained in the earlier liftup evidence.

Three new images were generated with built-in image generation and copied into `assets/production/needle-quay/ui-mki`: quiet teal enamel, an unlabelled ivory rubber pad and an unlabelled charcoal rotary knob. `provenance.json` records full prompts, source direction and SHA-256 hashes. Runtime derivatives are packaged locally; original generated files are retained. All controls, labels, values and gameplay text are native UI. These assets remain candidates pending human art approval.

Imported color maps keep the shared warm teal/coral/amber treatment and original alpha/UVs. To avoid local PBR compilation attempting unauthorized TexturePack uploads, this build uses EditableImage on `MeshPart.TextureContent`, with matte base shading. Normal, roughness and metalness sources remain intact for a future authorized deployment. The old remote AppearanceLibrary source is preserved but excluded from this local project configuration. This is a color-map preview path, not full PBR acceptance.

## Instrument changes

- Generated enamel, pads and knobs, walnut edge details and native status labels.
- Animated pad compression and a decaying 16-note activity display. It follows actual note triggers; it is not an audio spectrum or loudness meter. Effects OFF disables motion.
- Six rotary sound controls with 44-pixel increment/decrement buttons and Dry/Tape/Dub/Air presets connected to the existing sound processor, history and save model.
- Fixed a live sequencer rounding bug that wrapped eight-step rows into seven columns and covered the last two steps.
- Portrait offers the complete 4×4 performance surface and a separate scrollable editor. Compact landscape retains all sixteen pads and moves slot controls to Beats and pad mode/Street Speaker to Setup.
- Improved footer contrast. Existing waveform/ADSR editing, samples, patterns, beat shelf, quests and jam ownership remain integrated.

## Neighborhood changes

- Six listening posts award sound postcards after staying nearby for 3.5 seconds. Collected entries can be recalled in the LIFE journal.
- Three planters award a one-time care action and gain personal flowers; new care produces a short watering effect.
- Naya's record-sleeve delivery has pickup, carried parcel and delivered states. Tori acknowledges completion.
- Five neighborhood ranks derive from saved, whitelisted quest/discovery/favor completion. No arbitrary client XP input; repeat visits do not award again. Neighbor relationship labels derive from existing progress.
- Life destinations use the existing optional waypoint guide and clear when their action completes. Original quests remain available.
- Added upper windows, trim and roof details to five bare canonical shells, continuous water and a seawall, distant harbor buildings, bunting and seven bounded local seabirds. Existing four passing vehicles now stay within the road ends.

## Local Studio review

The user explicitly approved opening Current in a separate Studio window. Only that window was used. The initial review found the sequencer wrapping defect, short-landscape clipping and failed PBR TexturePack permission requests; the local source corrections above address those findings.

Observed in a single-player Studio session:

- All 80 local art entries loaded; `LocalTextureFailures = 0`; local continuous resident skins built.
- Native step clicks changed steps 1 and 5, transport played the sequence, and Tape applied tone −0.25, drive 0.22, echo 0.08, reverb 0.08 and 0.3125-second delay at 96 BPM.
- Listening at the dock raised XP from 25 to 40; tending the cafe planter raised it to 60; pickup stored parcel state 1 and delivery stored state 2, reaching 105 XP and Familiar Face.
- The supplied Alissia companion reported `SuppliedSkinReady = true` with its clap presentation clip.
- Desktop sequencer: eight columns, 85×44-pixel steps. Simulated iPhone 17 Pro portrait: 66×66-pixel pads and four columns of 81×44-pixel steps. Both orientations are supported by `StarterGui.ScreenOrientation = Sensor`.
- The corrected phone landscape viewport measured 749×381, with all sixteen 47×47-pixel pads inside the panel. The phone LIFE journal was also opened and reviewed; its tab icons collapse at narrow widths. Small pad names are abbreviated to prevent mid-word wrapping.
- Tending the cafe garden created 15 flower petals; interacting again retained 45 XP and did not duplicate the flowers or award. All ten GRA-01–10 image labels reported bound EditableImage content; the warehouse mural was inspected on its actual wall.
- No project script exceptions were seen in the reviewed console. The existing `rbxassetid://203785492` asset-type warning remains. After the color-map refactor, no new TexturePack upload/permission failures were seen.

Screenshots and final package receipt: `docs/evidence/needle-quay-artbook-polish/`. Source lint is recorded separately from runtime observation. No automated test suite was added or run.

Studio was returned to Edit mode and the default viewport. Focused Selene checks passed with zero errors, warnings or parse errors; the scoped whitespace check passed. The final compact pad abbreviations and attached bunting-cord geometry were source/build checked after the captured views.

Physical phones, simultaneous touch input, audible output/latency, multiplayer, cloud save/rejoin, complete Q00–Q12/concert acceptance, performance budgets and final art matching remain unverified. A small set of Studio views cannot establish pixel-perfect approval of every asset and camera angle.

## Delivery and cleanup

Build from the repository root with `tools/build_current_demo.ps1`. Run `output/needle-quay-demo/Launch-NeedleQuay.cmd` to install/check local content and open Current. Extract the complete ZIP when using the packaged copy.

The rebuilt ZIP contains 1,054 local content files and 184 audio bindings, and is 128,838,739 bytes. SHA-256: `2faf2ed66a866e74efbc4b05c55ba810bf55b6451cfd23c55da3f13fb500550d`. The initial packaging attempt hit a Windows write error replacing the generated README; the packager now stages README/launcher files and the ZIP before atomic replacement. The retry succeeded. `package-integrity.json` records archive CRC, every content hash, README/place identity and selected final source comparisons.

The earlier cleanup and recovery record remains in `LIFTUP_2026-10-30.md` and its receipts. No additional cleanup of open Studio packages was attempted during this visual review. Unrelated uncommitted work is preserved. No Roblox assets or Experience were published, no paid Tripo operation was submitted, and no commit or push was made.

Local texture API reference: [MeshPart.TextureContent](https://create.roblox.com/docs/reference/engine/classes/MeshPart).
