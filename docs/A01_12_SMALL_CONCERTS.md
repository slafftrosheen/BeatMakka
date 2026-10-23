# Small courtyard concerts

23 October 2026, source checkpoint from synchronized 752f5ac870d1a2ac39133bb1941c18548c4aab92. #14 remains open. Studio MCP currently lists no connected instances. None of the new contracts, UI checks or multiplayer scenarios has executed. Prior issue test results are not evidence for this change.

## First format and roles

The existing courtyard has one voluntary stage board, G / gamepad R1, beside the existing Share prompt and separate Chapter concert prompt. This board extends ListeningSession; it does not replace snapshot listening, create a second music engine or gate Mica behind the chapter finale. Existing Share remains the fast path when the stage has no queued request. Restored districts can later supply venues with the same anchor/prompt contract; only this existing courtyard is implemented.

Prepare my current loop copies the requester's active pattern with sanitized assignments/unlocks. It does not replace working slots, shelf beats, another player's data or progress. A prepared request is not audio membership. Up to four copied sets may wait. The first request reserves the next idle turn; only that requester can explicitly start it. A live performer cannot be displaced or stopped by another participant. Stop ends that set for everyone; the next requester receives an offer but no automatic playback or audience.

The offer expires after 30 idle seconds. Requests also expire after 120 total seconds, or when the player leaves the 32-stud participation range, dies or disconnects. Opening the board requires the existing short 11-stud server proximity/living-player check. Limits are authored product policy, not platform limits. The UI counts down using a server-clock deadline; rights are enforced server-side. Cancel/close removes only the caller's request. Idle cancel/close calls do not broadcast fake queue changes. Board prompts have a half-second per-player throttle; existing RemoteEvent budgets still apply.

## Listening and immediate exit

Join explicitly opts into the existing shared snapshot. The stage board shows whether the caller is performing, listening, waiting or not listening, plus actual local audio readiness while joined. Both the board and compact listening panel have fixed 44-pixel mute and leave/stop controls. Long status text scrolls above those controls. Mute is local; it does not stop the performer for anyone else.

Leaving the full board cancels the caller's request and leaves audio. The compact listening exit also clears stage participation. Workstation entry, personal chapter entry, range, death and disconnect remove pending participation. Focus loss and client teardown send StageClose. The full board borrows and restores mobile movement-control ownership; compact listening permits movement so walking away remains possible. Competing hub/listening panels hide while the board is open. Controller selection moves to an enabled visible stage action and restores visible focus on close.

Nothing in this stage queue awards chapter progress, requires listeners, ranks popularity or exposes moderation privileges. Mica's existing exact saved-loop eligibility and first-loop completion callback remain in ListeningSession.start. The new StageQueue owns only ephemeral rights, queue snapshots and board state; ProfileStore/schema/bindings are unchanged.

## Current verification

Pinned format/lint/build and six offline binding safety checks pass. Approved-material verification preserves 12 maps, eight templates and all 100 configured audio bindings. Independent source review found a hidden controller-focus path; it was corrected and re-reviewed. Studio execution remains unavailable, so no red/green, rendered layout, real gamepad, actual multiplayer, audio balance or runtime acceptance is claimed.

SmallConcert contracts are authored for snapshot isolation, four-entry bounds, reservation/start/stop authority, explicit opt-in, own leave/cancel, deterministic offer/request expiry and range/departure cleanup. StageUi covers routing, layout at three sizes, fixed mute/leave and hidden-focus cleanup. Existing Mica/listening/chapter/mission/room/UI regressions are included in opt-in runners. All remain unexecuted for this change.

The user Assets folder was refreshed before UI work. No fresh external asset was consumed. Native controls, existing palette and existing podium were reused; no art-stage promotion, asset upload, paid generation, dependency, CI, API-services setting change or publishing.

## Resume through Studio MCP

Identify the intended named local review place and mode. Sync current sources with the existing explicit MCP helper; the build excludes all QA modules.

Prepare `tools/prepare_stage_checks.py --model Server` and `--model Client`, then run the generated `work/stage-server-checks.luau` and `work/stage-client-checks.luau` in their respective Play datamodels. Record actual results, fix failures and preserve failed attempts. Prepared files do not mean tests passed.

The separately authorized real multiple-client scenario must then cover two prepared performers and an independent listener: no unsolicited audio, reserved-turn theft rejection through both board and legacy Share, copied snapshots unchanged after edits, explicit listening and mute/leave, no listener project/progress mutation, owner-only stop, explicit next start without carrying the audience, expired offers, range/death/disconnect/teardown and controller/touch focus. Preserve original Mica completion and personal chapter regression. Use existing opt-in test-driver patterns, bounded StudioTestService deadlines and cleanup. No three-client result is claimed yet.

Keep #14 open until its real multiple-client criterion and other readiness checks pass. The missing original-audio IDs and unverified private/cloud prerequisites of #12/#13 remain separate blockers; this source checkpoint does not close them.

[Availability and source validation](evidence/a01-12-stage/)
