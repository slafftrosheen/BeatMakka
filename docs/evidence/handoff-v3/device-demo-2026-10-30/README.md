# Needle Quay device, native kit and mesh repair

Current local place: `output/needle-quay-demo/NeedleQuay-Device-v3.rbxlx`.
SHA-256: `4e4230dd574db1a54684ffd984c01d3daf844c3b1f02586469ec2cd0e7357025`.
Studio MCP target: `5ddc3c93-7109-4122-811b-104c152004fc`.

## Delivered

- Physical split groovebox: fixed 4×4 pads, four graphic bank keys, six rotary controls, persistent transport and an LCD editor. Portrait stacks the halves; short landscape relocates banks/transport to retain usable targets.
- Four generated, locally installed assets: faceplate, rubber pad, rotary knob and journal. Native code supplies all text, icons, controls, digital numerals, signal history, step/pad lights, focus and press motion. Original prompts and provenance are in `assets/production/needle-quay/ui-device-v3/`.
- Graphic journal/activity/identity/shop/mission views, readable paper margins, native semantic icons, card/progress views and an on-demand wardrobe mirror. Commerce remains disabled.
- Pack-native 64-slot order selected by the user: A drums, B bass, C vocals, D harbour FX/melodics. Fifty-six original WAVs are unchanged; seven all-zero sources have documented reproducible DSP substitutes, and A15 has an amplitude-only derivative. Originals remain preserved.
- Fixed transport stopping erasing the personal pad audition selection. Local reassignment and loading a new native kit preserve earlier edited programs.
- Real 64-bin peak envelopes and duration metadata for all 64 installed WAVs. Sounds opens directly on kit/waveform controls; locked FX lessons follow them.
- Corrected the reflected mesh basis for 522 meshes / 83 canonical assets, including skins, centers, door offsets and 16 animation clips. Original images/UV corner associations and 96 source files are unchanged. Eight graffiti panels bind measured mesh walls instead of bounding boxes.

## Verification

Roblox Studio was operated through Roblox MCP. No computer-use automation was used.

`results.json` retains tool results, scopes and independent checks. Seven formal probes contain 30 passing assertions: nine sequence/Song/migration checks; three identity checks; five native-kit/private-readiness checks; two graffiti checks; four actual Sound-voice checks; three UI checks; four presentation checks. The ordinary client command flow additionally created five sequences and a saved session draft.

Actual Sound voices loaded and started for every local sample. The waveform probe checks all 64 real durations and nonzero peak arrays. Mute/stop and the transport-stop selection regression pass. Separate public/approved readiness still rejects local previews.

Direct MCP input checks cover mouse playback in A/B/C/D, keyboard playback, pad playback on all five editor tabs, six rotary drags changing server-owned settings, and cancellation when switching banks during a drag. Song playback started from its actual UI button, ran its four-second test arrangement and reached its finite end.

Final resize checks inspect 279 buttons: zero duplicate action glyphs on desktop, iPhone 17 Pro portrait and landscape. Pad targets measure 92 px desktop, 47 px phone portrait and 51 px phone landscape; phone rotary targets are 44 px. The final waveform is visible on entering Sounds. The latest inspected game console is empty.

All 216 built script sources match the Studio DataModel after normalizing CRLF/trailing whitespace, using byte length and rolling fingerprints; `built-script-fingerprints.json` also records SHA-256 for each built source. The staged file replaced the generated local artifact only after this parity check and an unchanged-old-file SHA check. Every replaced artifact was retained under the task's `.codex/backups/BeatMaka/device-ui-20261030-184603` directory. Studio was not closed.

Source/package audio guards pass, including exact mapping/hashes, all-zero rejection, missing/duplicate source rejection and distinct local versus approved readiness. Mesh source checks cover all 528,833 triangles and 229,840 animation bone frames. The original record-store GLB comparison measured maximum position error below 9e-7 studs and UV error below 5e-8. Graffiti support checks cover 24,180 surface rays with zero gaps/foreground intersections; fresh Studio bindings also pass.

Screenshots are adjacent: `device-desktop.jpg`, `device-phone-portrait.jpg`, `device-phone-landscape.jpg`, `sample-waveform.jpg`, `song-cards.jpg`, `journal.jpg`, `graffiti-mesh-wall.jpg`, `corrected-ferry-door.jpg`, `corrected-shop.jpg`. The live session contains a small editable Harbour Groove example; a new launch starts a clean editable project.

## Remaining acceptance

Local technical playback is verified. Human listening/art approval, approved Finished Song/public performance readiness and the pending discovery-role recordings remain separate. No vocal or bell is falsely substituted for I01/I02/I03. Full musical quest/finale acceptance, real devices, independent multiplayer and durable cloud persistence are not claimed. Studio saves are session-only.

No assets/place were uploaded, no Experience was published, no Tripo operation was submitted, and no commit/push was performed. Cleanup archives old generated build files with receipts; an already open old Studio document is left intact. Use the **NeedleQuay-Device-v3** window and launcher.
