# Needle Quay — local memory fix and vintage Roamers

Run Launch-NeedleQuay.cmd to install the local content into the selected Studio version and open the demo. Play saves are session-only. Nothing is uploaded or published.

## Changes
- Bounded, content-addressed runtime texture copies: 256px environmental/color maps, 128px normal/roughness/metalness maps, 512px companion atlases. Authored images, UVs and supplied GLBs remain intact. The generated URI map is used by scenery, companions, portraits and the hardware faceplate.
- Both parked Roamers use the supplied vintage van. Uniform fit, preserved UVs, rotation toward the interaction side, new body collision and an entrance target at the open counter. A pivot offset preserves the existing parking/return/cosmetic coordinate contract.
- Signal House's obstructing lamp moved ten studs along the street, including its visual model, post, arm and light.
- Pads remain visible and playable alongside Sounds/Steps/Beats/Settings. Pad release restores readable label contrast.

## Validation
Studio Play evidence is in docs/evidence/needle-quay-memory-fix. The fresh official StudioMCP connection was used because this chat's registered connection remained stale.

The first repaired Play run loaded all seven building materials with zero material failures, built 26 resident skins and built the continuous skinned forms of both supplied companions. All seven entrance approaches reached their targets with clear sight, and the server opened each corresponding building interaction. Avatar-sized perimeter sweeps clear all seven buildings after relocating the lamp; rays hit their solid body proxies. Actual Humanoid walking around all four sides of each building is recorded separately. These are exterior storefronts; entering a building's activity does not imply a newly modeled walk-in interior.

The vintage van's entrance reached Station_1 and opened the groovebox. Mouse input on Sounds and pad 04 kept the pad bank visible and changed the editor to Open hat; screenshots show the two panes and waveform. Additional UI, companion and van checks are recorded in the evidence folder. These checks do not establish every mission/reward branch, every screen size or multiplayer acceptance.

No dependency additions, paid generation, Roblox uploads, publishing, Git commit or push.
