# Issue #23 — record shelf, release and remix implementation plan

Base: `ea3fb496e20ee8484e25ae0dcc9658f4261e9e85`. User requests direct implementation and a scoped commit on main; no additional design/approval pause or test suite. Implementation uses the current Luau project, transport, library, Roamer entry and ProfileStore contracts.

## Design

Use the existing CRATES/Beat Shelf for Pattern/Loop, Draft Song and Finished Song. Selecting an item reveals its type, credits, pack versions and actual save state; Continue opens unfinished music directly. Reuse the authored waves/lantern/steps and teal/coral/amber sleeves. Releases live inside the existing music document, alongside finished songs and archives, under the same whole-profile byte and storage-conflict gates.

A release is a separately identified immutable revision of musical dependencies and sleeve. Listen-only/remix permission is separate mutable metadata. Release creation and permission changes become visible only after the existing persistence callback accepts them. No public feed, asset upload, new backend, economy or new audio format.

Same-server invitations identify one release and one recipient. Acceptance, decline, expiry, departure and replay are explicit. Only the consenting recipient receives a playback schedule; private project tables never cross that boundary. Public titles are filtered server-side at release creation and again before each invitation; internal custom names are replaced by fixed section/part/kit labels in the public copy. Failure closes sharing. Existing personal transport and mute preferences survive decline/leave; accepting is refused while another musical activity owns playback.

A permitted remix opens a new owned project containing exact copied notes, routing, mix, arrangement, sound IDs and pinned pack versions. The recipient's current workspace is preserved using WorkspaceState before activation. Original creator, contributors and release/version lineage persist in project metadata and later releases/Finished Songs. A repeated request cannot create a second copy from the same listening session. Remix permission is rechecked immediately before import, and revocation affects future copies only.

## Tasks and verification

- [x] Add bounded attribution/sample-version contracts and pure release capture/resolution/validation. Review identity, ordered events, tempo maps, copies, metadata bounds and missing audio behavior.
- [x] Upgrade profile 3/music 1 to profile 4/music 2 by cloning and adding empty release indexes; reject unsupported or malformed stored data without overwriting it. Keep legacy archives, recovery, finished songs and receipts intact.
- [x] Add one server record session service behind current command payload/rate/ownership checks. Persist release and permission transactions; bind invitations and imports to exact identities/revisions; clean up on expiry/departure and reject busy/stale actions.
- [x] Extend the existing library with recognizable sleeves, explicit Continue/details and Releases. Add native invitation/listening/remix controls and a separate SchedulePlayback consumer without changing editor transport or global mute.
- [x] Review the complete diff and integration contracts, run whitespace/source checks and check pinned-tool availability. Do not add or run test suites. Document concrete runtime scenarios and all unavailable acceptance. Delivery uses a guarded direct-main commit with remote scope/hash read-back; the final chat supplies its resulting commit link.

## Review focus

Storage callbacks while normal edits continue; permission changes during pending invitations; stale recipient confirmations after workspace edits; source/recipient departures; pack-version mismatch or missing samples; full archive/library/byte budgets; repeated remix requests; raw stored text reaching another player; preview/full-song distinction; retaining the recipient's paused transport and global mute on listen/leave.

Studio execution, actual listening, phone/controller layout, multiplayer and hosted rejoin/durability cannot be claimed from source review. Issue #23 remains open for those acceptance observations. The Windows supplied-assets directory is unavailable on this Linux host; this batch reuses repository-authored sleeve choices and adds no imported imagery.

Implementation details and review resolutions are recorded in `2026-11-05-23-records.md`. The review found three integration gaps, all addressed in source: selected joint-loop/dependency credits, an explicit accepted-record transition to the recipient's assigned workbench, and copying the invitation's freshly filtered title into remix project/draft names. Personal sleeves also use the normal project edit/Undo and explicit Save contracts.
