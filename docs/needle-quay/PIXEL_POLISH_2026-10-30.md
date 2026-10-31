# Needle Quay and MK-I — local visual correction pass

Historical review: the three implementation gaps at the end of this report are superseded by [the subsequent sky, architecture and PBR revision](ARTBOOK_FINISH_2026-10-30.md).

Continues the user's artbook-led visual and interaction polish. All changes remain local; no Roblox publication, uploads, Tripo requests, Git commit or push. Existing unrelated gameplay work remains intact.

## Comparison sources

The external `C:/Users/slavd/OneDrive/Pictures/Assets` inventory was refreshed before visual work. The newest ornamental materials belong to another visual direction and were not added. This pass reuses the already-vendored local assets and generated MK-I material images, with their existing provenance; no new external image is introduced.

Authority remains the approved `assets/references/needle-quay-approved-style-board.png`, the original Visual Artbook/Production Atlas, World v2 and the 25 October environment volume. MK-I Alpha 01 page 12, **Performance Screen**, and its hardware hero supply the specific UI comparison. That page is a design proposal, not runtime acceptance. Source hashes are in `docs/evidence/needle-quay-pixel-polish/source-review.json`.

| Reference / visible mismatch | Correction |
| --- | --- |
| MK-I performance proposal: cream pads on dark inset panels; runtime used broad cream page backgrounds | Dark green pad-bank and performance insets; native cream labels; quieter enamel faceplate. Paper remains on the existing library/settings editors. |
| Pad names were centered monospaced blocks, with duplicate outlines | Separate native pad number, bold sound name, shortcut/mute label and selected marker; remove the redundant decorative stroke. |
| Skin hid the first UIStroke, which was the actual focus ring | Preserve the cream focus ring and replace the default blue selection image on pads and FX dials. |
| Muted, selected and playing pads shared ambiguous treatment | Stone muted pads, an explicit mute label, amber selection and coral hits; programmed steps are amber and the playhead coral. |
| Long names split mid-word on small pads | Compact sound names on phones and measured word-fit sizing; selected-pad editor retains the full sound name. |
| World v2 palette / approved board: paving too brown, purple-gray haze | Stop multiplying the already-colored stone map by a second stone tint; lighter neutral stone and warmer haze, smaller sun disc. |
| Backstreet shells lacked entrances and window depth | Recessed doors, glazing, handles, thresholds, sills, transoms, base courses and rainwater pipes on ten supplemental houses; sills/transoms on five canonical shells. Canonical footprints, IDs and mission anchors stay fixed. |
| Life interactions said only Interact; small favors used a large finish flash | Listen/Tend/Pick up/Deliver labels, completion-aware Recall/Check/Thank labels, touch-specific prompts and a smaller, softer favor effect. |

## Review and delivery

The review used only the separately opened `NeedleQuay-Current.rbxlx` Studio session authorized by the user. Baseline and revised captures are in `docs/evidence/needle-quay-pixel-polish/`. Final source/runtime and package receipts are stored alongside them. The pre-pass source snapshot is `work/pixel-polish-baseline-2026-10-30/src`.

Focused source lint and a local Rojo build are separate from visual observation; no test suite was added or run. The generated package remains `output/needle-quay-demo/NeedleQuay-Current.zip`, launched by the adjacent `Launch-NeedleQuay.cmd`. Package hashes and file counts are recorded in `local-package.json` and `package-integrity.json`.

Observed in Studio:

- 80/80 local art entries loaded, zero local texture failures, resident skins ready, and all ten GRA-01–10 artwork images bound to EditableImage content.
- Native step clicks set steps 1 and 5. Mute changed the label to MUTED. SelectedObject rendering showed the cream focus outline with the default blue selection image removed; this is not physical-controller validation.
- Final desktop pads were 97×97 pixels. Simulated phone portrait pads were 65×65 at a 400×777 viewport; landscape pads were 47×47 at 749×381. All sixteen remained visible. Compact labels and word-fit sizing removed the observed Tambourine/CHORD mid-word breaks. Portrait editing retained the four-column, 44-pixel-high step controls.
- Tending the cafe garden raised XP from 25 to 45. The smaller halo was observed at 0.89 transparency while expanding toward five studs. Returning to the planter showed **Check flowers**, kept XP at 45 and did not create another halo.
- The known `rbxassetid://203785492` asset-type warning remained; no project-script exceptions appeared in the reviewed console.
- Focused Selene checks: zero errors, warnings or parse errors. Package CRC, all 1,054 content hashes, the packaged README/place and all 11 modified Luau sources matched. ZIP SHA-256: `90efbd892f3c4418c288ff7f63d90fa9429a9746194a4a703b6b79c6d4574162`.
- Studio was returned to Edit mode with the default device viewport. No other Studio session was changed.

This is a focused correction pass, not a claim that every asset and camera angle is pixel-perfect. The retained Blender-authored sky still uses a detailed procedural cloud field, several buildings are supplemental procedural scenery rather than final authored architecture, and the shipped local material path uses color maps rather than compiled PBR. Physical touch/controller operation, audio/latency, multiplayer, cloud save/rejoin and final human art approval remain outside this visual review. Existing asset stages are unchanged.

Simulator reference: [Roblox StudioDeviceSimulatorService](https://create.roblox.com/docs/reference/engine/classes/StudioDeviceSimulatorService).
