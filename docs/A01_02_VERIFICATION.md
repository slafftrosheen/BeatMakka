# A01-02 / issue #3 — source and Studio portion

23 October 2026. Follows pushed A01-01 `ffd41cbd04064dc60b55c0d6a20e252beeae8e08`. **Issue remains open.** The user confirmed no physical device is available; real multitouch, device latency/jitter budgets and audible sound/visual/recording agreement cannot be accepted in this run.

## Implementation

`PadInput` owns input tokens independently. A mouse/touch begin hits once immediately; end/cancel releases its held indicator without truncating one-shot percussion tails. Multiple fingers on one pad retain independent lifetimes. Mouse/touch `Activated` cannot generate another hit on release; keyboard/gamepad/accessibility activation retains its path. Pad hits omit the generic UI tap cue.

The fixed Play surface owns performance input. Leaving Play clears held tokens; it preserves transport so sounds/steps/shelf can be used during playback. Station loss, viewport change, window focus loss, text entry and destruction cancel held input. Interruptions request idempotent Stop even while a start reply is in flight. Local playback is suppressed immediately while the Stop is in flight. Teardown stops and releases before state/audio/UI destruction. Global input and per-token subscriptions are disconnected.

Recording sends a server-clock timestamp and acknowledged transport epoch. Server-owned BPM/start remain authoritative. The accepted authored window is 350ms past / 50ms future, with small future clock skew clamped to receipt time; older/forged/NaN/wrong-epoch events are rejected. Legacy timestamp-free calls retain receipt-time behavior. Quantization stays nearest sixteenth across 60–180 BPM and wraps sixteen steps. These bounds are implementation choices, not measured physical/network guarantees.

Recording taps use a separate bounded 96-event burst / 96-per-second refill; controls retain the existing 36-event burst / 24-per-second bucket. Dense hits cannot consume Stop's bucket. Identical already-recorded cells cause no edit/version increment. Notes apply immediately; chord state feedback coalesces at approximately 30Hz rather than broadcasting a full profile for every note. Unrecorded local hits do not send redundant Tap requests.

Settings reports hit count, successful local playback submissions, unavailable/muted count and, when real playback submission succeeds, bounded last-128 handler-to-`Sound:Play` submission timings. This boundary excludes hardware touch latency, mixer/audio-device buffering and acoustic onset. It never substitutes for audible latency. With the current unconfigured bank the observed submission count is zero and no latency number is reported.

## Studio evidence

Receipts: [a01-02](evidence/a01-02/). Local Studio instance `f060d05e-09bc-466c-8945-37cb780e5bb8`.

- PadInput: sixteen simultaneous tokens, duplicate begin suppression, sixty-four same-pad repeats, two tokens on one pad, cancellation/destruction; 82 expected hits, zero unavailable-audio submissions.
- Timing: 25 checks across 60/96/180 BPM, nearest step, loop wrap, pre-roll, 200ms arrival-delay correction, stale epoch and forged timestamps.
- Real client/server: sixteen pads recorded into step 1, then a 160-event tap flood followed by Stop; all notes present and transport stopped. A stopped late hit did not edit the pattern; repeated Stop stayed stopped.
- Lifecycle: page exit, hidden-page rejection, interruption clear, safe-root size change cancelling tokens, station release and connection destruction passed.
- Actual main-client teardown: start Record, destroy Client script, observe server stopped/released and UI destroyed; passed.
- Desktop MCP input: mouse-down showed Held before release; mouse-up removed Held with exactly one total hit. Two keyboard keys held pads independently and released; three total hits after the mouse and keyboard chord. A final mouse down/up rerun after subscription cleanup again produced exactly one hit.
- A01-01 regression: six layout sizes still pass, including the short safe-root case. Existing 8 Contracts and 8 Milestone groups passed. Selene reported zero errors/warnings/parse errors; StyLua, Rojo build and diff whitespace checks passed.

Independent review identified the pending-start interruption race and teardown transport gap; both were fixed. The focused follow-up found no remaining concrete issue. Studio was returned to Edit with its default viewport.

## Still unverified — do not close #3

- Physical simultaneous touch/rolls, cancelled gestures and physical rotation/focus behavior.
- Real sound bank readiness/permissions and audible onset, tails, recording/playhead agreement.
- Device-specific latency/jitter measurements and agreed acceptance budgets.
- Real gamepad activation. MCP ButtonA injection did not activate the selected button; keyboard/mouse and input-owner evidence do not establish controller acceptance.

The pre-existing image asset-type warning for `203785492` persists. No new assets, external dependencies, uploads, publishing, CI or Tripo operations were introduced; spend remains zero.

Next acceptance step: finish the audio admission/private-experience dependency and run the named physical-device matrix when a device is available. Retain #3 open and the source work pushed; the ordered issue-completion loop cannot truthfully advance past its remaining physical/audio criteria.
