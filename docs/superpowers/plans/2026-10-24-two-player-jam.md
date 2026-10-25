# Two-player jam implementation plan

Baseline 60d648b0e223d1d788b56f9ad00f128929e5a54e. User authorizes implementation, Studio MCP verification and push without desktop control; close #15 only after all readiness checks pass. Existing audio/cloud/device issues remain independent.

## Protocol/design

One shared two-slot jam, each slot owned by its actual player and occupied sampler. Joining is explicit and keeps that player's editable pattern/shelf/progress intact. The first participant sets the initial BPM from their pattern and becomes conductor. The second uses the same timeline and a compatible configured kit. Only the conductor may request BPM changes; everyone publishes only their own sanitized active pattern. No other player's target, arbitrary timestamp, continuous audio stream, SDK, economy or extra venue.

Common server clock, 16-step bars, 60–180 BPM. Initial anchor is at least 0.75 seconds in the future. Join/replacement/tempo proposals carry a session generation and base revision, copied on receipt, and apply atomically at a server-assigned boundary at least 0.75 seconds ahead. At most one pending proposal per owner and one tempo proposal; stale/wrong-generation/late-base requests reject. A tempo change preserves phase by rebasing to its boundary. Disconnect removes only that track and pending work; surviving track keeps its timeline. Conductor transfers to the remaining participant. Leaving and rejoining cannot resurrect stale proposals.

Each published track is limited to four audible pads from one fully configured style kit; the session uses that same kit so tuning/cohesion is bounded. Other silent pad assignments are not played or loaded into the jam bus. If a pattern is incompatible, reject with preparation guidance, never rewrite notes or substitute samples. Sample IDs are existing configured assets. Two voices per active bank, two tracks, .7 voice gain and .05 gain per jam track give an authored worst-case music sum bound of .56 (16 voices); this is not an acoustic mix or latency guarantee. No solo transport/record/live audition during active jam; edits remain personal until Publish.

Jam controls open from the owned sampler (Settings or J/gamepad R2): Join, Publish own active pattern, conductor BPM request, Mute, Leave, and Back to sampler. Editing existing 16 pads remains unchanged. Other exclusive music modes/station loss/death/disconnect/focus loss/teardown leave the jam. Jam state is ephemeral, never cloud progress. Client renderer uses server anchors, never catches up with a burst of late hits, ignores old revisions, and reports local scheduled-onset error/skips separately from network arrival lead.

## Acceptance measurements

Authored prototype targets to validate, not platform promises: 2 clients use identical scheduled anchors/BPM/revisions; proposals arrive at least .25s before their apply boundary in the local Studio run; submitted musical hits are <min(80ms, .8 step) late; stale updates never alter ownership/timeline; no per-hit remotes; state packets bounded by discrete commands/tick-applies. Report actual min/p50/p95/max scheduling lateness, inter-client anchor drift and message counts. A skipped hit is recorded, not hidden as a success. Network impairment and acoustic/physical budgets remain separate if not measured.

## Work

- [ ] Shared JamProtocol contracts first: kit/pad limits, immutable copying, future boundary and revision guards. Run red in Studio before implementation.
- [ ] Server JamService with sampler ownership, generations/revisions, scheduled proposals and lifecycle. Integrate prompt and MusicService routing.
- [ ] Client JamPlayback/JamView and bounded AudioEngine options; native Settings entry; preserve solo/listening/chapter behavior and data.
- [ ] Studio contract/UI checks, actual two-client lifecycle and scheduling telemetry, stale/late/tempo/change/disconnect tests; source review and fixes.
- [ ] Push sources and traceable measurements. Close only if listed criteria pass, otherwise state the exact remaining gap.

Assets folder refreshed; no fresh external art is needed. No dependencies, production publish, API-services changes, paid generation or uploads.
