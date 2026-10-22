# Workshop playable milestone

Continue the supplied v0.2 artbook/atlas direction: the instrument leads, then a short discovery route, then personal restoration. This implementation batch covers H01 controls, H06 modular graybox, I01-I03 discoveries, I04 personal restoration, U01/U02/U04, T01-T04/G01/G03/G04 source graphics, S01/S02 original synthesized sources, and optimized exports of the 20 accepted models.

## Design

- Two independently occupied creation stations. Server checks proximity, station ownership, message shape, limits, and sample unlocks. Closing the interface or leaving the station releases it.
- A personal 16-pad / 16-step pattern, 60-180 BPM. Select a pad, toggle its steps, audition with touch or the canonical keyboard grid, play/stop, mute pads, and assign collected sounds. Playback uses a server-time transport anchor; animation never drives sequencing.
- Three reusable discovery interactions: metal, vent, robot. Collect once per player; preview remains available. Personal workshop restoration follows the three discoveries plus a nonempty pattern, independently of other players.
- Manual save/restore. Studio defaults to an honestly labeled session save; published servers use a revision-checked DataStore. Failed loads cannot be overwritten by defaults, and concurrent-server revisions cannot silently overwrite each other.
- Responsive teal/cream workstation with explicit selected, step, muted, playing, occupied, audio-unavailable, and save states. Text stays in UI. Reduced-effects and mute controls remain available.
- Imported models live in `ServerStorage/AssetLibrary`, named by canonical ID. Missing imports use identified geometry proxies. Decoration never owns collision; proxies and navigation are authored separately.
- Shared authored maps and graphics are generated locally with recorded provenance. Optimized models preserve source geometry and functional parts, group static dressing, and consolidate per-face appearance through a shared atlas with explicit UV remapping. No blind decimation or model regeneration.
- Four saved device finish presets share the same UV layout. Device, item and character-clothing slots are distinct so future equipment/character systems can reuse material sets. Character-specific UVs, face/skin textures, rigs and item ownership are later work. Roblox swaps precomposed maps; masks remain editable offline sources.

## Delivery boundary

Local sources, map files, masks, original audio, model exports, static measurements, and a Rojo place build are deliverables. Real Roblox image/audio/mesh uploads, permissions, Studio imports, two-player interaction, device timing, and runtime performance remain separate acceptance steps. No new provider spend or production publishing is part of this batch.
