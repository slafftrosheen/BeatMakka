# Small concerts implementation plan

Start from synchronized 752f5ac870d1a2ac39133bb1941c18548c4aab92. Standing user authorization covers implementation, Studio MCP tests and push, without desktop control or repeated design approval. #12/#13 stay open. Studio currently reports no connected instances.

## Design

Extend the existing ListeningSession transport, snapshot, membership and original Mica lifecycle. Keep one existing courtyard venue; future restored venues are a later extension, not new geometry or a chapter gate. The public concert is independent of the personal NPC chapter.

A nearby stage board (G / gamepad R1) shows current performer and at most four prepared snapshots. Preparing copies the requester's current active pattern and never edits their project or joins their audio automatically. The first queued player gets the next idle slot and explicitly starts it; nobody else can take it. An idle offer expires after 30 seconds, and queued requests expire after 120 seconds or on range/death/disconnect. These are authored product limits, not platform limits. No host moderation/voting/ranking, no automatic audio or role transfer. Stop releases all listeners; the next performer starts a new opt-in session.

The existing Share prompt keeps its original idle behavior when no one is queued, and its join/leave behavior while a set is live. Queued reservations prevent stage theft. Board join is explicit. Only the performer can stop the set; any participant can leave, mute locally or cancel their own request. Leaving the board cancels the request and leaves listening. Close/focus loss/death/disconnect/range clean up participation. Queue and listening remain ephemeral and are not written to cloud/profile progress.

Use native scrolling stage controls with fixed mute/leave actions, hide competing HUD/panels, and suppress/restore mobile movement controls only while the full stage board owns input. The compact listener panel has its own mute and leave controls and can coexist with movement. No fresh assets or textures are necessary; Assets folder refreshed before UI work. Existing art/IDs preserved.

## Steps

- [x] Author server contract tests for queue bounds, owned snapshots, reservation/start, opt-in, stop authority, expiry, range/lifecycle cleanup and project isolation; retain original Mica regressions. Execution pending.
- [x] Extend ListeningSession with stage board state/commands and a separate StageQueue for bounded ephemeral rights. Integrate MusicService routing/world prompt without a second audio engine.
- [x] Add StageView, listener mute and client policy/lifecycle integration; author native layout and command-routing regressions. Execution pending.
- [x] Run pinned format/lint/build/binding/material checks and independent source review; correct/re-review controller focus and broadcast boundaries.
- [ ] Run Studio contracts/UI/multiplayer against an identified connected project. No Studio instances are currently available.
- [ ] Push source/evidence; keep #14 open unless actual authorized multiple-client and all other readiness criteria are verified.

No dependencies, production publishing, paid generation or desktop automation. Red/green execution is not claimed while Studio is unavailable.
