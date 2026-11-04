# Issue #11 — Roamer identity, customization and Beat Shelf
Date: 2026-11-04. Base commit: `d7eed506f78c89f2171930c63a25d2932bbd3079`.

## Purpose
The Roamer is the existing player-owned portable studio, but on the inspected main branch its visual binding used only `profile.room.finish`; the saved workshop `sign` and `decor` choices never reached it. The journal exposed only a generic MY STUDIO entry, not a direct Beat Shelf. This source batch connects existing saved room identity to the Roamer, avoiding a second cosmetic database or a new music shelf.

## Implemented code paths
1. `RoomCatalog` remains the sole whitelist for the existing stable `finish`, `sign`, `decor` IDs. There is no schema migration: old profile snapshots already contain `room`; legacy/absent fields continue to be normalized by the existing `RoomCatalog.sanitize` path. The four approved device/room finishes, two vetted sign phrases, and none/vinyl decoration are reused. Unlock of vinyl still derives from I01.
2. `RoamerIdentity` adds a fixed, replicated owner name/sign and an optional bounded vinyl emblem to the *assigned* Roamer model. All added geometry is anchored to the parent model's pivot and explicitly noncolliding, nonqueryable, nontouchable and nonshadowing. It uses text and primitives, not unapproved imported art, textures or another collision assembly. It does not change the workbench, functional pads, NPC prompts or player movement.
3. `QuayDemoService.updateVan` reapplies identity from the player's room choices when ownership changes, parking changes or respawning. Unchanged signatures are idempotent. On disconnect/reassignment, the old display is destroyed, tags cleared, tint reset to the approved default, and the next owner's saved choices are applied. Every player sees the replicated owner identity; there are no visitor edit permissions.
4. `QuayRoamerSet` uses the existing `RoomService:change` transaction and `RoomCatalog.allowed` checks. Its optional proximity anchor is **server-derived** from the player's assigned Roamer door; the server checks bay ownership, Roamer owner UserId, proximity and request cooldown. Direct Room edits at the existing workshop remain unchanged. Only the owning player near their own van can edit; no arbitrary strings, spawn targets or asset identifiers are accepted.
5. `QuayRoamerPanel` is embedded into the existing Style tab (not an additional top-level app). It shows room settings and save/status constraints, offers the same approved finish/sign/decor choices and calls the existing profile save route. Locked vinyl and unavailable Roamers disable their controls. This retains the current UI theme/controls without new image assets.
6. A second explicit route, **OPEN MY BEAT SHELF**, appears beside MY STUDIO when near the owned Roamer and in the Style tab. Its server action reuses the original ownership/nearby/teleport/station-claim logic, then increments a **transient** library-open request. The client routes that new one-shot token into the *existing* workstation Library, preserving its Sequences, Drafts, Finished and Archives. There is no parallel inventory, project copy or transport restart.
7. An over-frequent QuaySave request now gives an explicit notice instead of silently doing nothing. Save or room edits are never represented as a successful hosted persistence test before receiving the existing save acknowledgement.

## Responsibility boundaries
- `src/server/RoamerIdentity.luau`: fixed art-safe cosmetic display and ownership teardown.
- `src/server/QuayDemoService.luau`: physical owner/parking lifecycle, secure Roamer commands, transient Library request and cleanup.
- `src/server/RoomService.luau`: one optional trusted Roamer proximity anchor for the existing saved room choice transaction.
- `src/client/QuayRoamerPanel.luau`: readable native Style/Room controls and truthful status.
- `src/client/QuayDemoView.luau`: existing journal integration and direct shelf action.
- `src/client/init.client.luau`: one-shot library page request through the existing DeviceGrooveboxView screen API.

## Source review and unperformed runtime acceptance
Read current `RoomCatalog`, `RoomBuilder`, `RoomService`, `QuayDemoService`, `NeedleQuayDemoWorld`, `QuayExperiencePanel`, `QuayDemoView`, `DeviceGrooveboxView`, `ProfileStore` and MusicService command/state projection. Verified that the room already uses stable profile fields, the world has two canonical Roamers indexed by workshop assignment, and the workstation provides `showPage("Library")`.

Changes are anchored in the exact inspected branch. Blob hashes/commit scope and the guarded non-force remote branch read-back are delivery checks. Source inspection is **not** a Roblox Studio or device acceptance. No tests, Luau compilation/lint, runtime visual review, multi-client play, device frame rate, cloud rejoin, imported-mesh verification or actual asset acceptance have been performed. AGENTS.md's no-test-suite and no-upload/publish constraints remain in force.

User-local acceptance (no programming delegated):
- With owner A and owner B, set different finishes/signs/decors at their respective Roamers. Walk away, change parking, return, die/respawn, release/enter and compare their own versus the other player's replicated sign and visual. Save and reopen within the session; hosted rejoin is #10.
- Try owner A at owner B's Roamer, visitors and occupied/overflow states, out-of-range packets, unsupported keys, locked vinyl and rapid edits. Confirm denial and zero mutation.
- Disconnect owner A, assign a previously waiting visitor to the vacated workshop/Roamer, and confirm all prior owner signage/tint/decor is gone before visitor's own saved choices appear. The room workshop should retain its independent owner reconciliation.
- Inspect actual model signage near entrance and under approved dusk lighting; the sign/emblem are intentionally simple fixed cosmetic primitives, not claims of final art. Confirm all pads, collision, interaction raycasts, Roamer door, I01 prompts and walkways remain unobstructed.
- Near the own Roamer, press OPEN MY BEAT SHELF; verify the real Library opens with unfinished named sequences and Draft Songs. Back out/re-enter normally; no unintended auto-navigation should recur.
- Try Studio session save, unavailable save and save cooldown; verify honest pending/failure notices, no cloud claims from local evidence.

#11 remains open for actual two-client/respawn/parking and target-device art/input evidence. #8's approved finishes are reused without regenerating maps. #9 permanent mesh and #10 hosted persistence remain separate acceptance gates.
