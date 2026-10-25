# Needle Quay — demo implementation batches (WORLD v1)
**24 October 2026. Codex/Roblox Studio handoff. Design package, no runtime claims.**

**Superseding environment supplement:** use [Environment Production Register v1.0](needle-quay/README.md) and `data/needle-quay-environment.v1.json` for building/venue names, materials, NPC and quest production scope. Parking IDs P1–P4 are retained, respectively Dockside Exchange, Repair Alley, Vinyl Market, Breakwater Steps; the finale is The Lantern Room. The older Rusty Workshop/Vinyl Corner/Echo Pier/Lighthouse wording below describes the previous proposal, not current canonical display names. The separate blockout scene does not implement B01–B08 gameplay.

## Target playable experience
A new player sees eleven mapped city districts but can only enter **Needle Quay**. They can immediately play the real **MK-I 4×4** and save to **Beat Shelf ×6**; use a personal customizable van **The Roamer** as their home, choose one of four authored parking venues, complete four meaningful solo-capable story activities, collect the existing I01–I03 virtual sound sources, prepare a saved beat and finish the existing **six-phase** chapter in a Lighthouse-themed club. Other players may voluntarily watch or join queued mini-performances. The player's map and restoration are personal; public venues are shared.

## What's really implemented already
- The repo contains 10 genre kits ×16 and one original sampler bank. 160 derivative WAVs exist and 100 genre IDs are bound; 60 style IDs + 24 original-source audio uploads remain pending (see `docs/STYLE_STARTER_PACKS.md`).
- `BeatBook` owns A–D 16-step patterns and six saved shelf positions; ProfileStore schema 2 protects saves; Mica, three discovery nodes, mission ledger, six-phase courtyard ChapterConcert and voluntary StageQueue have test evidence.
- Owned workshop bays, visual finish controls and multi-client scenarios exist, **not** a mobile van. Real two-player synchronized jam `#15` is **not implemented**.
- Studio owner playback is not a substitute for published experience audio access, calibrated mobile latency or public license rights. Original I01/I02/I03 are not yet audibly accepted. Place/Universe IDs were zero in the last audit; cloud rejoin and permanent native mesh imports are not verified.

## Engineering decisions
- Preserve canonical H01 dimensions `6 x 1.25 x 4 studs`, 16 fixed physical targets, 4500-triangle assembled cap and 1024 texture cap; leave MK-I transport screens untouched during map work.
- Do **not** story-lock the choice of Hip Hop/Reggae/etc. District unlocks gate geography, quests and additional sound discoveries; any unconfigured sound must show an honest not-ready state.
- Use `data/world-districts.v1.json` for proposed stable IDs, labels, polygons and thematic links. All player unlock authority belongs to server-owned profile snapshots.
- Van parking is a safe server-validated teleport/transition between four fixed anchor points (short fade), **not** a physical car simulation. Owner/visitor isolation reuses existing workshop principles.
- Small public concerts use existing queue + opt-in listening. Solo completion never requires a human teammate. `#15` live jam is deferred until verified.
- Virtual recorder uses developer-created/prerecorded licensed sources only; no child mic recording, uploads, arbitrary asset IDs, or unscreened voices.
- Scene reactions for restored districts must be local/personal (client-side projection of authoritatively granted status). A player cannot overwrite a public global district state.
- Persist optional bounded world state via explicit, tested schema-2-compatible record or documented migration: district unlocks, cleared stops, selected parking, van finish and chapter. Snapshot state before async writes, keep monotone rewards across music Restore, reject malicious client-award requests.

## Work packages and verification gates
| Batch | Work | Acceptance |
|---|---|---|
| B00 Source contracts | Re-read HEAD and existing source, freeze kit IDs/H01–H06; add district manifest. | 11 defined areas, 10 actual style slugs + one original; canonical IDs unchanged. |
| B01 CityMapView | Map menu, polygons, tooltips, initial locked state; mobile/gamepad, localization-ready. | One open/ten closed, visible on phone, client cannot unlock by sending intent. |
| B02 VanService exterior | Blockout van, four static parking anchors, owner/proximity guards, transition. | Foreign van locked; safe move/reset/respawn; work-in-progress beat protected. |
| B03 Interior + MK-I | Existing owner workshop as van interior; 4 finishes; 6 beat shelf slots, storage. | Owner/visitor isolation; save/restore and pattern slots remain intact. |
| B04 P1/P2 | Rusty workshop ordered repair and Vinyl Corner listening/browsing. | Real server-owned saved-pattern evidence; H03/I01 compatibility. |
| B05 P3/P4 | Harbor Market preparation w/ NPC fallback, Echo Pier virtual found sounds. | Solo progress; two clients independent; microphone never requested. |
| B06 Lighthouse | Convert courtyard presentation to club; reuse six-phase ChapterConcert and server-clock checks. | Complete single-player chapter, stop/mute/replay/range/effects OFF, personal crowd. |
| B07 Art+audio acceptance | Upload only with explicit scope; verify 24 originals, remaining 60, private permissions, native GLB imports. | I01–I03 audible in actual test experience; IDs/permissions/source rights logged; saved/reopened imported models. |
| B08 Private integration | Cloud namespace/migration, device tests, two independent clients and novice playtest. | Exit/rejoin, conflict/failure behavior, real phone controls/latency, clear uncoached first beat. |

**Sequencing:** B01-B06 can proceed source-only with transparent audio gating; **B07 and B08 are blockers for an honest playable release**. User has not authorized any new Roblox asset uploads, private-experience creation, publishing, or Tripo paid operations in this documentation batch.

## Required source and acceptance paths
Inspect `src/server/WorldBuilder.luau`, `ProfileStore`, `MusicService`, `ChapterConcert`, `StageQueue`, `ListeningSession`, `BeatBook`, `AssetSpawner`, `src/client` instrument/room UIs, `data/assets.json`, `data/content-ids.json`, `docs/MILESTONE_VERIFICATION.md` and the latest dated receipts. Names must be re-confirmed before creating modules.

New modules are *proposed*, not present:
`src/shared/WorldDistrictCatalog.luau`,
`src/shared/VanTypes.luau`,
`src/shared/QuayStopContracts.luau`,
`src/server/DistrictProgressService.luau`,
`src/server/VanService.luau`,
`src/server/QuayStopService.luau`,
`src/client/CityMapView.luau`,
`src/client/VanPresentation.luau`,
`src/client/QuayStopsView.luau`.

## Minimal acceptance matrix
1. Fresh profile: N00 available, all other district shapes visible but locked.
2. A selected genre of a locked area is still selectable if its bound audio loads.
3. Unbound audio is explicitly unavailable, not falsely marked heard.
4. Two owners cannot change each other's van, saved beats or restoration.
5. Every stop including Harbor Market can be completed solo.
6. I01–I03 reward from authoritative server/saved beat, not client-provided unlock flags.
7. Virtual recorder plainly discloses preauthored game sound sources.
8. Finale has six checked phases and respects earlier Mica/mission saves.
9. Audio/listening are voluntary, with fixed mute and leave affordances on mobile.
10. Effects OFF still communicates progress without emissive-only cues.
11. Live test experience survives save/exit/rejoin and schema migration.
12. Native model import reopens correctly, real audio plays with current permissions; human listening and novice comprehension checks passed.

## Separate blockers
Source archive publisher license/redistribution verification; pending style/original audio upload permissions/quota; permanent native mesh IDs; real cloud experience; uncoached player comprehension and actual device latency. No issue closed by this document alone.

**Official Roblox references:** https://create.roblox.com/docs/audio/assets ; https://create.roblox.com/docs/reference/engine/classes/AudioRecorder ; https://create.roblox.com/docs/cloud-services/data-stores .
