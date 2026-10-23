# Neighborhood missions implementation plan

Baseline: synchronized dc7a0b9. User authorizes continuing issues, Studio MCP tests and push without confirmation or desktop control. Studio MCP currently returns no connected instances; do not claim runtime acceptance or reopen foreground applications.

## Design

Extend the existing I01/I02/I03 and Mica loop within the same workshop, alley and courtyard. A native virtual-recorder guide explains the authored sample sources and how to assign them through the existing Sounds library. No microphone, recording/upload pipeline, new world area, paid assets or dependencies.

Separate neighborhood jobs from FirstPerformanceQuest. Stable job IDs: metal_pulse (save two distinct metal-hit steps), vent_duet (save metal+vent together), helper_reply (save two different audible robot-chirp rhythms). Require the existing Mica request to be accepted, canonical discoveries unlocked, and the previous job earned. Each successful profile save evaluates its captured shelf, not unsaved working music. Commit rewards only if that exact snapshot save succeeds. A failed/conflicted save cannot award progress. Jobs never change the player's music, revoke discoveries or depend on spectators. Restore music keeps earned jobs and dirty status where appropriate. Legacy profiles default to no earned jobs; the original Mica quest conditions remain unchanged.

Three small native feedback inserts on the existing I05 podium show personal job completion. They are fixed/non-colliding and updated on the Client only. The section is the existing workshop/alley/courtyard; preparation requires all three jobs plus the original courtyard quest. Preparation is not the chapter concert/completion from #13.

Alternative rejected: putting new requirements into FirstPerformanceQuest would revoke compatibility; adding new districts/NPC meshes expands scope and art acceptance. Use a separate saved ledger and existing canonical assets instead.

## Steps

- [x] Author Studio contracts first: legacy/malformed ledgers, exact musical conditions, locked/unsaved rejection, failure/conflict retention, captured-snapshot races, restore preservation and original Mica compatibility.
- [x] Implement shared discovery metadata and neighborhood job evaluator, wire sanitized capture/load and successful-save ledger commit into ProfileStore, and send read-only summary from MusicService.
- [x] Add native recorder/mission guide to scrolling Sounds and personal feedback inserts to the existing podium. Preserve fixed Play pads, routes and existing quest behavior.
- [ ] Run pinned source/format/build/binding checks and independent review. Studio tests are pending until MCP has a connected instance; no new test runner or dependency is introduced to disguise that limit.
- [ ] Record evidence/limits, push, update #12 and keep it open unless all acceptance is verified.

TDD execution limit: tests are authored before production code, but the requested Studio runner is disconnected. No red/green execution is claimed. Both new and regression modules must be run through Studio before completion.

## Outcome

Source implementation, pinned lint/format/build, six binding checks, unchanged asset/material checks and independent source review completed. Studio later connected only a start page: no place open, no Studio test execution or screenshots. Runners prepared for Server and Client. Runtime, source comprehension, multiplayer, visual acceptance and dependencies remain pending; #12 stays open.
