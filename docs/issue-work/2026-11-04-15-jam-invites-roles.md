# Issue #15 — invited two-person jam / roles / handovers
Date: 2026-11-04. Base: `bf68e6d26edc80b95fedde1ad4a1d4fe78abb958`.
Scope: first cooperative interaction batch; the existing `JamProtocol`, `JamService`, `JamView`, `JamPlayback` and shared musical clock remain the implementation foundation.

## Implemented code
- A station owner starts a solo duet explicitly, chooses Rhythm (drums+bass) or Hook/Texture (hook+harbour), then invites a specific other nearby sampler owner. It is no longer possible to occupy the partner's seat by simply pressing Join.
- A target sees the inviter, invited musical role and expiry, then may Accept or Decline. Invitation expiry, stale revision/session, unavailable player, occupied/releasing seat, request cooldown, failure to resolve role-ready audio and disconnect do not steal or change either personal project. A role is a source-sound classification, **not a pad bank**; A–D selection continues independently.
- Captured and rendered shared snapshots contain only playable notes in the selected musical role, not other unrelated private events from the author's source Sequence. Source sample IDs, velocity, settings, track routing and source BPM remain intact. When a role is empty, or its audio is unavailable, the server states why; it never substitutes a retired/test pack.
- A guest joins on the existing shared bar boundary. Tempo is common for playback and never rewritten into personal sequence data. While solo, the conductor can queue tempo at a bar; with a partner, it becomes a proposal requiring explicit acceptance/decline before boundary scheduling.
- Mutual role exchange can be offered by either player. Both role-filtered snapshots must be valid; Accept schedules two changes for **one shared boundary** or neither. Original sequences remain personal. The conductor may also offer a separate lead/baton handover; the partner accepts/declines and leadership updates at a boundary.
- When a member leaves, loses their station or disconnects, their ownership ends immediately but already accepted notes are removed at the next shared bar if a partner remains. The surviving player keeps the common timeline and conductor rights; a vacated seat can be invited again. Session and invitations are ephemeral, never saved as personal progress.
- `JamPlayback` understands pending role replacement and departure without treating a scheduled removal as a playable snapshot. The client routes all new jam control values through the existing bounded, versioned Command RemoteEvent. No added RemoteEvent, clock, codec, storage schema, assets, provider, CI or dependency.
- Native partner page shows role choice, eligible invite targets, incoming offer and accept/decline, both channels and their current/queued state, tempo consent, conductor pass and role exchange. Buttons remain selectable and use the existing MK-I skin.

## Data ownership and constraints
The shared packet still uses JamProtocol schema 3, 2 tracks, the current source sample catalogue and configured voice/mix budget. Role assignments are per contribution and are not A/B/C/D banks, per-project Song drafts or public releases. The current catalog's single final-pack key/pitch plan is not an automatic transposition. The project source BPM remains unchanged even when the agreed playback BPM differs.

This batch **does not yet implement the credited joint-copy action**. It remains a code task for the next #15 batch, not a request for the user's local agent. Do not mark #15 complete until that action and actual two-client/drift/mix/novice acceptance are addressed.

## Source verification and runtime boundary
Source-level checks performed: baseline fetch and exact blob read-back, anchored changes, role-filtered snapshot visibility, membership/invite/tempo/lead/swap request identity and server ownership paths, deferred departure resolution, voice renderer removal handling and packet-value routing. No Luau runtime, Rojo build, StyLua/Selene, Studio, live listening or device run in this environment. Earlier in-repo Jam QA fixtures target the retired four-style-kit/Pattern protocol, so they are historical and are **not evidence for this new workflow**; do not claim they passed.

User-local acceptance (not performed here):
1. With two owned samplers, host Rhythm, explicitly invite Hook, Accept, and verify first audible guest contribution at the next bar; try reverse role selection, invitation expiry/decline and non-invited Join.
2. Use A–D bank switching while recording/playing; confirm role filtering uses underlying sample identity rather than the selected bank and leaves both personal projects unchanged.
3. Offer/accept/decline a tempo change, then exchange roles at the same boundary; ensure an unavailable counterpart role refuses **both** changes without cutting the music. Transfer lead and verify only the new conductor can propose tempo.
4. Disconnect or Release a participant mid-bar, including the original conductor. Inspect pending removal, continuous survivor transport, empty-seat re-invite, late/stale packets and eventual cleanup. Check that solo creation/show still work without a friend.
5. Inspect narrow portrait and short landscape with touch and controller, actual audio source readiness and a real two-client clock/drift/jitter trace. These are not inferred from server timestamps.
6. Retain all existing profile and library music; no public upload, experience publication or hosted save acceptance is claimed.

## Follow-up code ownership
Next code batch: offer/countersign and import a credited joint musical copy as an editable Draft Song under the existing save/undo/model limits. Keep existing original music and credits intact; do not silently autosave or publish a release.
