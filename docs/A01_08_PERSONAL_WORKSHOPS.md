# Personal workshop customization

23 October 2026. Implementation starts from synchronized `6355d5c`. #11 remains open for real cloud rejoin and final room art acceptance. #8 remains open independently. No production publishing, paid generation, new uploads or desktop control.

## Owned space and visibility

Two fixed bays share the existing workshop shell. A loaded player receives one free bay for their connected session. This claim is independent of temporary instrument occupancy: Release, leaving listening and character death do not transfer the workshop. Disconnect resets its native sign, finish and fixed decor, then assigns a free bay to a waiting visitor. More than two connected players can visit; visitors cannot edit a bay. The saved profile contains cosmetic choices, not a permanent claim on a numbered server location. Rejoin should apply saved choices to whichever bay becomes available; actual cloud rejoin is not yet verified.

All connected clients see the same server-authored signs and decor. Room commands contain only a catalog field/value. The server resolves the sender's claim and living-character proximity (15 studs), then checks the catalog and server-owned discovery unlock. Client-supplied room IDs, owner IDs, placements, text and unlocks are not accepted. Existing command rate limits apply.

## Bounded choices and art stage

- Four finish IDs: quay, chalk, coral, afterhours. Instrument finish remains independent.
- Two fixed native sign phrases: RECORD SHOP and BEAT WORKSHOP, plus the owner's Roblox DisplayName. No arbitrary custom text or localization baked into maps.
- Fixed shelf decor: none or canonical H03 vinyl crate, unlocked by existing I01 Quay metal discovery. Selecting a finish/sign never grants a discovery or item. No economy or purchases.

Inspected the current user Assets folder before visual work. Reused the already retained approved wood/scratch material revision, shared Theme/CosmeticCatalog, canonical P05 shelf and H03 crate sources. No new source file was consumed outside the repository. The board/artbook/atlas remain authority. Canonical M16 remains a roof parapet; the native sign instead has an exact non-colliding backing.

The renderer applies the authored eight SurfaceAppearance templates only to imported Art with matching FZ_MaterialAtlas_v1 and 512/1024 resolution metadata. Deterministic placeholders use palette colors and retain Placeholder/UsesImportedArt status. The current Studio AssetLibrary is empty, so the new room's shelf/crate art remains placeholders. This does not establish permanent imported PBR art acceptance. The approved map pixels, IDs and source copies are unchanged.

Signs, backing and shelves are mounted behind/above the instrument; the crate is restricted to its fixed wall shelf. Cosmetic parts are anchored and non-colliding, non-touching and non-querying. No pads, collision proxies, prompt targets, stage, portals, safe routes or existing functional geometry are moved by appearance changes.

## Saves and recovery

The existing schema-2 profile gains a sanitized optional `room` record. Old schema-1/2 saves receive defaults; unknown/locked values do not grant access. The DataStore namespace, schema compatibility, revision-conflict and failed-load/write protection remain in place. Save profile captures choices with music/progress in one snapshot. Studio states explicitly say session-only; unavailable storage retains current work.

Restore slots is a music action: it keeps the current workshop choices. If those differ from the saved snapshot, dirty status remains set. Loading a saved beat likewise does not replace the room. Disconnect does not auto-save unsaved selections; the UI directs the player to Save profile.

## Verification and limits

[Source refresh and reused assets](evidence/a01-08/source-inventory.json). Explicit tests live outside the default game build. `Rooms.spec.luau` covers malformed/locked data, old-profile migration, injected storage round trips, failed writes, music restore dirty state, independent owners, no-bay visitors, reassignment and safe fixed decor. Injected storage does not prove a real Roblox cloud save.

Seven room contract groups, eight Contracts and eight Milestone groups pass ([Studio receipt](evidence/a01-08/studio-server-checks.json)). The room tests also guard against sampler/room identity collisions and verify the compatible imported-map path without claiming imported fixture geometry as real art.

A fresh rerun exposed a proximity-dependent failure when the fixture moved only the Client character. The final test uses the explicitly installed Server-only `RoomRuntimeMove` fixture for bounded bay/discovery/station positioning; it does not bypass any production command, unlock or ownership checks. The fixture is removed after the run. Failed and successful results are retained separately.

The final real single-client/server network flow passed **19 checks**: all four finishes, locked/foreign/far requests, native I01 and instrument prompts, session Save and music Restore preserving dirty workshop edits ([receipt](evidence/a01-08/studio-runtime.json)).

The three-client harness exercises real RemoteEvents and replicated world state with two owners plus a visitor. Initial runs are retained as failures: one reached the save phase without proving instrument occupation; another timed out during client startup. These are not counted as passing acceptance. A subsequent launch remained unresolved and the final launch returned `Failed to start the test because a previous one is still in progress` ([receipt](evidence/a01-08/studio-three-client.json)). No full three-client pass is claimed. Temporary Edit QA drivers/result holders were removed and the local single-client Play returned to Edit; the prior StudioTestService session outcome remains unknown. No native process termination or desktop input was used. Final results and screenshots are stored under [evidence](evidence/a01-08/), with a [hashed index](evidence/a01-08/evidence-index.json) and [validation summary](evidence/a01-08/validation.json).

Follow-up independent review found a real regression: assigning StationId to bay roots let the instrument renderer treat them as samplers. Reproduced the failure, then changed the association to RoomStationId with a contract guard ([red result](evidence/a01-08/studio-room-identifier-red.json)). Canonical sampler IDs remain unchanged.

Native UI checks cover owner/visitor and locked controls, catalog callbacks, readable status and reachable scrolling settings at phone, short-landscape, tablet and desktop sizes. Existing fixed 16-pad layout and server contract/milestone regressions are rerun. Four room Settings sizes and six existing fixed-pad layouts pass ([receipt](evidence/a01-08/studio-client-checks.json)). These checks do not establish physical touchscreen or audible latency.

[Neutral](evidence/a01-08/workshop-neutral.jpg) and [dusk](evidence/a01-08/workshop-dusk.jpg) views were inspected. Owner signs use larger native text with LightInfluence=0. Sampler status billboards are limited to eight studs so they do not cover room signs at workshop viewing distance; existing native device displays still show transport. [Settings capture](evidence/a01-08/settings.jpg) uses an explicit QA view bound to the actual server profile; its audio-loading label is unconnected QA-view text, not an audio readiness result. Camera/UI/lighting and that QA view were restored/removed.

Remaining acceptance: a complete final-source three-client pass; actual private experience cloud rejoin (#5/#10); permanent shelf/crate mesh import and reopen (#9); human review of the new bounded workshop layout. No source or Studio fixture can substitute for those checks. Keep #11 open.

## Reproduce

Use pinned Rokit tools from the repository root. Sync sources with the existing explicit Studio MCP helper, run the contract modules in Server/Client respectively, and install `tools/prepare_room_acceptance.py` only for the RoomAcceptance suite. Launch StudioTestService with three clients and `{suite="RoomAcceptance"}`, collect its bounded result, then run the generated cleanup request. Default Rojo builds include no QA drivers. Do not change API-services settings or publish to obtain a passing result.
