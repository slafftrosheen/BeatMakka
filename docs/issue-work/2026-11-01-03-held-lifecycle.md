# Issue #3 — held-note lifecycle follow-up

The previous bank-switch patch kept held tokens during the immediate bank command, but the subsequent acknowledged server state still cancelled them because `routeChanged` treated bank changes as a new route. This revision removes the bank from the ownership boundary. A bank is a pad viewport, not a new project/track/program/sequence.

Transport epoch and playback-state notifications now clear transient flashes without discarding held live-pad tokens. Explicit Stop, route changes, focus loss, modal opening, station exit and teardown still cancel input through the existing paths.

## Studio acceptance (not performed remotely)

1. Hold A01, switch to B, release A01: no stuck note or B01 release; verify note repeat stops.
2. Hold a pad while playback starts/pauses and while a bank acknowledgement arrives; confirm input lifetime remains coherent.
3. Stop while held; verify cancellation and no later repeat.
4. Test mouse, multi-touch and gamepad on actual devices; record acoustic timing separately from submission metrics.

This is source-only implementation, not target-device or hosted acceptance.
