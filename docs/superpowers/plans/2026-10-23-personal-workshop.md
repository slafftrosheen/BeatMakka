# Personal workshop implementation plan

User requests implementation, Studio MCP verification and push without confirmation or desktop control. Start from synchronized `6355d5c`. #11 remains open unless every criterion is verified.

## Design and scope

Use two bounded workshop bays around the existing stations. The server assigns one free bay per connected profile until disconnect; additional players are visitors and receive a bay when one frees. Assignment is a session location, not a saved world coordinate. Visitors see the owner's replicated cosmetics but cannot edit them. Releasing an instrument or dying does not transfer workshop ownership. Disconnect clears the bay before reassignment.

Allow four approved finish IDs, two fixed sign phrases, and none/vinyl-crate decor. No arbitrary text, placement, purchases or client-supplied ownership/unlocks. The H03 crate requires I01 discovery, separate from the cosmetic selection. It sits on a fixed P05 wall shelf, away from controls and navigation. The native sign has an exact deterministic backing; canonical M16 remains a roof parapet, not a sign frame. Reuse Theme/CosmeticCatalog and existing authored SurfaceAppearance templates for compatible imported art; deterministic placeholder Parts use palette colors and retain truthful placeholder status. No new uploads, textures or provider models. Retained user source materials already back the approved atlas. Refresh Assets inventory before visual work.

Rejected approaches: private client-only rooms hide customization from visitors; free-placement/building adds navigation and access risks beyond this issue. Shared, fixed server-owned bays fit the existing workshop and keep controls untouched.

Persist a sanitized optional room field inside existing schema 2, preserving the DataStore namespace/revision protections and old profiles. Music-only Restore keeps current workshop choices and marks them dirty when different from the saved snapshot. Actual cloud rejoin is blocked by #5/#10; injected storage round trips do not establish cloud acceptance. New room art remains pending human art acceptance and permanent mesh integration.

## Tasks

- [x] Write failing Studio contracts for malformed/locked selections, access isolation, profile migration/round trip, failed writes, music restore, bay allocation/reassignment and geometry safety.
- [x] Implement shared RoomCatalog, ProfileStore capture/load support and server RoomService with bounded bay renderer; integrate allocation, commands and state in MusicService/WorldBuilder.
- [x] Add workshop settings using existing scrolling Settings page with explicit owner/visitor, locked decor and session/cloud save status. Keep Play fixed and all 16 pads intact.
- [ ] Run contracts and real two-client Studio tests for ownership, visitors, attempted foreign edits, replication, save/restore and cleanup. Capture actual workshop/UI views through Studio MCP. No foreground input.
- [ ] Run pinned lint/format/build and relevant regressions; independent review; record evidence and remaining acceptance, push, update #11 without premature closure.

## Review focus

Malformed saved tables and client payloads cannot grant items or ownership. No-bay players cannot edit anything. Releasing, dying or leaving listening cannot reset another player's room. Music restore does not silently overwrite workshop choices or clear their dirty status. Rendered decor is bounded, non-colliding/non-querying and cannot move functional controls, discovery targets, stage or passages. Unavailable storage never reports cloud success.

## Recorded outcome

Implemented and locally verified: seven room groups, nineteen single-client/server network checks, four room UI sizes and six fixed-pad layouts, eight Contracts and eight Milestone groups. Independent review found and verified the StationId collision fix. The three-client harness remains incomplete: first failed at save, second startup timeout, a subsequent unresolved session prevented final launch. No native intervention. Cloud rejoin, final-source multiplayer completion and permanent room art acceptance remain open. See docs/A01_08_PERSONAL_WORKSHOPS.md.
