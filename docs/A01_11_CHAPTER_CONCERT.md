# Needle Quay chapter concert

23 October 2026. Source implementation follows `6fc38a6`. **#13 remains open.** Studio MCP detects a Studio connection but reports no place open. No test execution, rendered NPC/art acceptance, audible playback or cloud rejoin is claimed for this batch. Your desktop was not controlled.

## Solo encounter and musical ownership

The new Chapter concert prompt is beside the existing I05 listening podium (F / gamepad Y). It opens a personal concert panel and leaves other music modes; normal opt-in listening and Mica's original first-loop quest keep their separate rules. Starting requires #12's three earned jobs plus the original completed courtyard quest. No real listener, vote, popularity or audience count is required.

Choose a successfully saved shelf beat. The encounter copies and sanitizes its A–D patterns, chooses the first pattern with at least two audible pads, and checks that a different ordinary-part pattern and a reachable collected-sound layer exist. Unsaved working notes do not qualify. The set never writes arrangement changes back to working patterns or another player's profile.

| Phase | Player action | Reaction/checkpoint |
| --- | --- | --- |
| Introduction | Choose an audible pad and bring in its rhythm | Nodding after the part enters; checkpoint after a full loop |
| Layer | Choose a different low/supporting part | Small group dancing; full-loop checkpoint |
| Break | Take that support out | Space remains in the set; full-loop checkpoint |
| Return | Bring the support back | Group response; full-loop checkpoint |
| Variation | Select a different saved pattern | Lights respond; full-loop checkpoint |
| Familiar sound | Unmute a collected sound in the saved pattern | Final full loop earns this section's completion |

The player chooses musical parts and notes; no exact song, fixed bass sample or genre classification is enforced. A low/supporting part can serve the arrangement without a literal bass sample. Switching temporarily holds collected sounds back until Feature. Switch again is available when another saved pattern contains the desired source. Start rejects snapshots whose collected sounds exist only in unreachable discovery-only patterns.

## Timing, recovery and saves

Only server clock time advances earned checkpoints. Each new phase has a fresh 0.15-second transport anchor and one sixteen-step loop at the saved pattern's 60–180 BPM. A next action is rejected until the current phase has earned its complete-loop checkpoint. This is a game-clock rule, not measured audio latency or sample-accurate playback proof.

The optional sanitized chapter ledger stores bounded checkpoint/completion in existing schema 2. Source defaults preserve old profiles. Existing guarded saves carry the ledger; progress writes coalesce through the existing asynchronous progress-save queue. Manual retry has a five-second bound. Failed writes leave progress dirty/temporary. Music Restore keeps earned chapter progress. Replaying starts the arrangement again and cannot revoke banked checkpoints or completion. Normal close banks a fully elapsed loop while the player is still alive/nearby; death/distance/disconnect keep previously banked progress. Real exit/rejoin durability and timing boundaries remain unverified.

Completion is **only this neighborhood section**. Other chapters remain ahead. Stop and mute are fixed controls outside the panel's scrollable content. Closing/focus loss/script teardown stop the personal concert. Starting a workstation or listening session also stops it; starting a chapter set leaves listening. The existing listening audio engine renders the exclusive chapter/listening stream, with mode changes resetting its transport even when epoch numbers coincide. No additional audio bank is created.

## Personal scene and art stage

Three local crowd stand-ins reuse the existing H04 helper, labeled Quay crew, Vent keeper and Mica. These labels connect them to the existing job roles; new human/resident models have not been art-approved or imported. Cloned prompts/billboards and motion ownership are stripped, geometry remains non-colliding/non-querying, and the original Mica/discovery actor stays accessible. They are explicit temporary stand-ins, not a claim of final NPC production.

Quiet → nod → dance → responding lights → restored courtyard are driven by the same private concert summary. Motion references the playback server clock/BPM. Cached light/floor references avoid a world scan each frame. Effects OFF retains static colors/poses. Scene teardown destroys its clones and restores original local environment properties. No server/public environment progression is overwritten.

The user Assets folder was refreshed before visual-related work. No external file was newly used; existing H04 source art, palette and canonical I05/courtyard remain in the repo. No new textures, uploads, paid generation, dependencies, CI or production publishing. Asset IDs and approved material maps remain unchanged. The supplied board/artbook/atlas remain visual authority; no art/runtime stage is promoted here.

## Verification status

Pinned Selene/StyLua/Rojo and existing offline binding/material checks pass. Independent source review found three integration defects: blocked chapter commands without a station, a discovery-only musical dead end, and hidden mobile rejection/save notices. All were corrected and re-reviewed. Errors and saving/dirty status now appear in the scrollable concert panel, with immediate fixed Stop/Mute controls.

New ChapterConcert contracts cover timing, owned snapshots, invalid actions, failure/restore, legacy/completed round trips, rejected dead ends and service ownership/close/distance/retry. ConcertUi covers command routing and visible errors/layout at four sizes. These modules and existing mission/room/Mica/listening/UI regressions are **NOT EXECUTED for this change**. Source review and a build do not establish runtime behavior, controller input, audible timing, multiplayer isolation, exit/rejoin durability or NPC/environment readability.

[Validation and Studio status](evidence/a01-11/) record those boundaries. #12's pending Studio tests also remain pending. Keep #13 open until actual project Studio execution, gameplay/audio/cloud checks, visual approval and solo-player comprehension pass.

## Resume through Studio MCP

Open/identify the intended repository-built project before syncing. Generate the explicit Server/Client runners with `tools/prepare_concert_checks.py --model Server` and `--model Client`; use `tools/drive_studio.py` in the corresponding Play datamodels. QA runners are outside the default build. Then exercise real prompt/RemoteEvent start, all phases, forced interruptions, invalid requests, independent clients and storage failures. Inspect all reactions with effects on/off and test actual audio. Never use an unidentified start page or substitute fixture checks for a cloud/published acceptance result.
