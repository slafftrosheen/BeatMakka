# Small concert acceptance — 24 October 2026

Verified the #14 scope against synchronized source ba7143f85e0a9165c11ca45c617bd0da58e50a4b in the identified local Studio place `small-concerts.rbxlx`, instance f145fc3c-45b9-4412-b889-3db29d20dcef. No desktop control, asset upload, paid generation, API-services setting change or production publishing occurred.

## Readiness evidence

| Issue criterion | Executed evidence |
| --- | --- |
| Small-concert roles and states | Seven SmallConcert contract groups and the real three-client preparation → reservation → explicit start → join → stop → next offer flow pass. Existing courtyard only; NPC chapter remains separate. |
| Voluntary listening, immediate mute/leave and lifecycle cleanup | Three-client run proves no automatic audience or next-set subscription, owner-only stop, own leave, performer death and disconnect cleanup. Actual phone-simulator Prepare/Start/Mute/Leave button activations pass. Teardown stops the actual session and destroys its audio. |
| Personal projects/progress preserved | Three real clients keep independent patterns and progression. Snapshot equality, non-owner authority, listener preservation, replayed own pattern and death/disconnect preservation pass. |
| Separately authorized real multiple clients | Current and standing user requests explicitly authorize Studio MCP testing. StudioTestService ran three actual simulated clients; the final run passes 26 checks. Raw failures are retained separately. |

The full server runner passes 46 contract groups plus WorldEntry for both sampler entries and chapter entry. All five client suites pass, including StageUi at three sizes, routing, fixed mute/leave and focus cleanup. Existing Mica eligibility, listening, chapter, neighborhood, room, save-guard and UI regressions pass. This is local Studio acceptance of this social flow, not cloud/rejoin or physical input latency acceptance.

## Actual audio and controls

The test uses the already configured `style.pop.01` sample, asset 127048242518608, preserving all existing IDs. It loaded and entered playing state on both the performer and opted-in listener. A separate listener-local SoundGroup mix probe left performer volume unchanged. The real application Mute button was then activated through Studio's game-input tool: both local music groups reached volume zero while the set stayed live, and a second activation restored sound.

Phone simulator screenshots show actual live hosting/muted state in landscape and portrait, not a fabricated completed-state fixture. The full board hides movement controls; the actual Leave button restores them and the hub. Mute and leave remain fixed 44-pixel controls outside the scrolling status/actions. Button activation used game UI selection and Return through MCP; it is not evidence of a physical controller or touch device.

## Failed attempts and corrections

The first three-client attempt reported before the stage-open reply arrived. A separate single-client run confirmed the real prompt opened normally; the harness now waits for an actual open-state reply. It does not force a grant or bypass proximity. The second attempt observed listener playback for only three seconds and failed after 15 other checks. The diagnostic rerun used the audio engine's existing 15-second load window, and both performer/listener reported loaded one-second voices and playing state. Assertions were retained. No production behavior was changed to manufacture these results.

The original StageUi fixture selected a disabled Prepare button to test close-focus cleanup, producing an invalid-selection warning. It now selects the enabled Leave control and the full client runner passes. The final console contains the existing avatar asset-type warnings for 203785492; no project Luau exception was observed. No warning-free platform-log claim is made.

## Scope and cleanup

#14 may close: its small voluntary-concert flow and listed readiness criteria pass. #12/#13 retain their own original-sample audio, cloud, final-art and human acceptance blockers. The existing configured genre sample used here does not replace a collected original or grant those other issues acceptance. No claim of acoustic balance, sample-accurate synchronization, physical controller feel, persistent mesh import, cloud storage or release is made.

Temporary StageAcceptance server/client drivers and result holder were removed. The screenshot observer/teardown existed only in Play; Play stopped and the simulator returned to the default viewport. Default Rojo build contains 46 production source scripts and no QA drivers.

[Raw outcomes, original screenshot bytes and hashed evidence](evidence/a01-12-stage-live-20261024/).

To reproduce, prepare `tools/prepare_stage_checks.py` for Server and Client, then run through `tools/drive_studio.py` in their respective Play datamodels. `tools/prepare_stage_acceptance.py` prepares the explicit three-client drivers and cleanup. From Edit, dispatch `StudioTestService:ExecuteMultiplayerTestAsync(3, {suite="StageAcceptance"})` with a bounded asynchronous result holder; collect the terminal result before retrying or cleaning up. Do not add the drivers to the production build.
