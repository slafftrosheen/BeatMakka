# Issue #3 — captured input voices and truthful audio readiness

The input path previously retained an absolute pad and musical route but never retained the actual playback voice. Ending or cancelling a token only cleared visual/hold state. This batch connects each input token to the exact local voice generations it triggered, including note-repeat hits.

## Implementation

- `AudioEngine.play` returns its existing success boolean plus a local handle containing the engine, voice, generation, sample identity and originating route. Existing callers consuming only the boolean remain compatible.
- `AudioEngine.release(handle, cancelled)` accepts only the handle currently owning that voice. Voice stealing, choking, global stop and disposal invalidate earlier handles, so releasing an older input cannot stop a newer use of the same Sound.
- Ordinary finger-up releases input ownership and lets the authored one-shot envelope/tail finish. Cancellation stops only the matching captured voice. The existing instrument has timed one-shot envelopes, not a new indefinite hold/sustain playback mode.
- PadInput tracks a capture per input token. DeviceGrooveboxView stores the captured musical context and a bounded set of current voice handles per token; two touches on the same absolute pad no longer overwrite each other's held context. Bank navigation does not change those captures. Explicit cancelled-input states, focus/viewport/workspace cleanup and teardown use the same cancellation path.
- The coordinating batch connects the client entry point: `AudioEngine.play`'s second return becomes the third result of `tap` (`submitted, submittedAt, handle`), and the view's `releaseVoice` callback reaches `audio:release`.

## Related readiness correction (#5)

Requested stable identities now remain visible even when no voice can be allocated. AudioEngine status and diagnostics count the union of requested selection/schedule identities, including unavailable schedule dependencies, instead of counting only successfully admitted banks. Diagnostics distinguish missing content, unapproved admission, missing/invalid bindings, version mismatch, exhausted voice capacity, loading, failure and timeout. No fallback sample is selected.

`AudioEngine.setSelection(assignments, mask, pins)` accepts optional stored version pins. Schedule diagnostics also consume `unavailableReasons`. The coordinating batch adds these to the client projection and caller integration.

## Evidence and limits

Read the current issue briefs and traced input begin/end/cancel, note-repeat, voice stealing/choking, selection preparation and shared playback consumers. Scoped `git diff --check` passed. No test suite, Studio session, device interaction, listening, latency measurement or hosted operation was performed. Natural one-shot tails remain intentional; source-level ownership does not establish acoustic timing or physical-device acceptance.

No dependency, asset, upload, publication, spending, commit or push was introduced by this batch.

Integration review also moved focused gamepad ButtonA to input-down capture, with matching release/cancel and duplicate Activated suppression. Live pad/Sound auditions check the captured version pins independently of valid public/world schedules using the same sample ID.
