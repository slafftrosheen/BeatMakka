# Needle Quay — current local build

> Historical `NeedleQuay-Current` package guide from before the v3 integration. Its musical slot/Shelf controls and acceptance claims apply to that package only. Use [MPC v3](MPC_V3_README.md) for the current named-sequence, Song Mode and Finished Song workflow.

Extract the entire ZIP and run `Launch-NeedleQuay.cmd` or `Launch-NeedleQuay.ps1`. The launcher verifies and installs the local content for the current Studio version, then opens `NeedleQuay-Current.rbxlx`. Press Play in Studio. Rerun the launcher after Studio updates.

This revision includes:

- A new artbook-referenced panorama sky, five rebuilt canonical buildings and three reusable authored façades. Original DCC files and provenance remain local. Native signs and aligned lamps replace overlapping generic window/roof decorations.
- Local PBR color/normal/roughness/metalness surfaces for the environment, hardware and characters, including 93 tiled paving/dock surfaces. Superseded building meshes and the previous procedural sky are excluded from Current.
- A further artbook polish pass: dark MK-I performance insets, clear pad numbers/names/shortcuts, separate selected/muted/hit states, amber programmed steps and visible cream keyboard/controller focus. Compact pad labels fit phone layouts.
- Stone paving, balanced sunset fill, recessed windows, shutters, detailed backstreet doorways and rainwater pipes. Neighborhood prompts name the action and reflect completed favors; small favors use a restrained completion effect.
- Three supplied storefronts, a varied back street, crossings, taxi/post van/bus traffic and all ten authored neighborhood graffiti designs.
- Six resident appearance sources, six clothing palettes, subtle pattern variations and varied size, walking pace and pauses. Story hosts retain their identities.
- A MK-I Groovebox with generated enamel, rubber-pad and rotary-knob assets; native labels, animated pad presses, note activity, six live sound controls and Dry/Tape/Dub/Air presets. Selected-pad focus, note previews, tap tempo, undo/redo, row copy/paste, shift/reverse/clear and the 1–16-hit rhythm builder remain available.
- A LIFE journal with five neighborhood ranks, six collectible sound postcards, three gardens, a record-sleeve delivery favor and relationship labels derived from completed favors and quests. Collected postcards can be opened again to recall their story.
- Upper-storey facade details, a continuous harbor water backdrop and seawall, distant buildings, bunting and seven local seabirds. Tended gardens gain personal flowers and a brief watering effect.
- Shared artbook material treatment for supplied assets. Authored palette maps, companion design, UVs, alpha and data maps remain preserved.

Undo/redo stops playback and is session-only, bounded to 24 edits per slot. Copy/paste transfers notes only. Rhythm builder replaces the selected row and can be undone. Pattern slots A–D and the existing six-slot Beat Shelf remain the save workflow. Studio may use session-only saving; read the in-game save status.

Portrait screens switch between pads and editing. On short portrait screens, Street Speaker is in Setup and Exit is beside transport. Compact landscape keeps all sixteen pads on screen, places slot controls in Beats and pad mode/Street Speaker in Setup. Tap the tempo digits to set BPM from your taps.

Traffic is cosmetic, yields to the local player and does not collide. Effects OFF hides passing traffic and birds and disables bunting/pad motion. The activity meter represents triggered notes, not measured audio loudness.

The local Studio build creates SurfaceAppearance materials from shared EditableImage color, normal, roughness and metalness maps. Source materials with constant roughness retain that declared response. No cloud TexturePack ID is created or uploaded. The old remote appearance library is preserved as source material but excluded from the local place. Allow the art and material load to finish before reviewing the scene.

The Current build has received a single-player Studio visual review, including desktop and simulated phone layouts, local PBR, companion skinning, live sequencer actions and the previously reviewed postcard/garden/delivery loop. See `docs/needle-quay/ARTBOOK_FINISH_2026-10-30.md` for this revision, `PIXEL_POLISH_2026-10-30.md` for the UI comparison and `ARTBOOK_POLISH_2026-10-30.md` for the feature review. Physical multitouch, audible output, multiplayer, cloud persistence and final art approval remain separate. The existing `203785492` asset-type warning is still present.

Everything remains local. No assets or Experience were uploaded or published.
