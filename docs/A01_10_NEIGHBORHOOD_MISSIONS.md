# Neighborhood jobs and virtual recorder

23 October 2026. Source implementation from synchronized `dc7a0b9`. **#12 stays open.** Studio MCP initially had no instances; a later connection exposed a start page with no place open. No project was modified through Studio and no Studio test or visual/runtime acceptance is claimed for this batch. No foreground application launch, desktop input, uploads, generation or spending.

## Mission map

The existing workshop, three-object sound alley and courtyard define this section. No new district, NPC mesh, popularity gate or chapter finale is added. Mica's original first courtyard quest retains its original acceptance, discovery, saved-pattern and one-loop performance rules.

| Job | Musical action on a successfully saved shelf | Personal reward |
| --- | --- | --- |
| metal_pulse / A pulse for the quay | I01 collected; at least two distinct audible metal-hit steps | Quay pulse light |
| vent_duet / An alley duet | Previous job; I01/I02 collected; audible metal and vent notes in the same pattern | Alley duet light |
| helper_reply / A reply for Mica | Previous job; I03 collected; two different audible chirp rhythms in saved patterns | Helper reply light |

The original Mica request must be accepted before any new job can be awarded. A single save may satisfy more than one job if its captured shelf already contains the needed music. The helper job compares note positions, so copying the same rhythm to another pad or changing tempo alone does not qualify. Muted notes cannot satisfy a job. The player chooses their rhythms; there is no prescribed track or tempo beyond the existing instrument contract.

Completing all three jobs **and** the existing first courtyard quest marks the section prepared for a future chapter concert. It does not complete the chapter or the game. #13 implements that later encounter separately.

## Recorder and ownership

DiscoveryCatalog retains canonical I01 metal_hit, I02 vent_thump and I03 robot_chirp. Sources are virtual game-world provenance: quay metal strike, alley vent thump and helper speaker chirp. They reuse existing prerecorded authorized assets. No actual microphone input, continuous audio recording or player upload is added or implied.

Discovery prompts identify virtual collection. The collapsible Virtual recorder guide in Sounds explains each source, collected status, how to select the Needle Quay kit and assign sounds to an existing pad, job requirements and rewards. The existing assignment path still enforces sample unlocks on the server. Opening the guide sends no music command, and Play remains a fixed sixteen-pad page.

MusicService sends only each player's read-only job summary through its existing private state event. There is no client completion/unlock/grant command. Three fixed non-colliding, non-touching, non-querying inserts on existing I05 show personal job progress through the existing Client restoration path. Effects OFF uses static color without emission. Other players' music, ledger and public environment state are not replaced. These source guarantees still require actual multiplayer/visual testing.

## Save contract

ProfileStore captures a sanitized independent shelf snapshot before storage can yield. The evaluator examines that snapshot, not unsaved working notes or later edits. It commits earned flags to the live profile only after successful session storage or cloud UpdateAsync. Failed/conflicted saves do not grant new rewards; later edits retain existing dirty/version behavior. Existing earned flags are monotonic. Music Restore preserves them and keeps dirty status when they differ from the saved snapshot.

The optional neighborhood ledger uses stable IDs inside existing schema 2. Legacy profiles default to no new jobs; unknown/nonboolean/out-of-order ledger values are rejected. Existing namespace, schema guards and revision protection are retained. This is source review, not a real cloud migration/rejoin result.

## Authority and assets

Refreshed `C:/Users/slavd/OneDrive/Pictures/Assets` before visual-related changes. No external file was newly consumed; native UI and deterministic feedback inserts reuse the existing palette, material references and canonical podium. Existing copies of approved wood/scratch sources remain in the repository. The supplied board, artbook, production atlas and register remain authority. The production atlas I04 contract requires restoration to avoid permanently altering the public hub for others; the inserts update on the Client only. No asset stage was promoted and no map, sample binding, geometry source or asset ID was changed.

## Validation

- Pinned Selene, StyLua and Rojo build pass. Six existing offline content-binding safety tests pass; approved-map verification still preserves all 100 audio IDs and eight authored surface templates.
- Independent read-only source review found no material save/authority/Mica compatibility issues. A diagnostic arrow encoding regression was identified and corrected before push.
- NeighborhoodMissions and RecorderGuide Studio tests were authored first but **not executed**. Their coverage includes malformed/legacy ledgers, musical rules, unlock/mute guards, failed/conflicted writes, snapshot races, restore retention, original Mica eligibility and guide layout/disclosures. Existing contract, milestone, room and fixed-pad/UI regressions also remain unexecuted for this change.
- No new screenshot, listening result, physical input result, cloud/rejoin result or full neighborhood playthrough is claimed. A novice's understanding of provenance and progression is still pending.

[Evidence and build status](evidence/a01-10/) distinguish local static checks from unavailable Studio checks. Keep #12 open until real Studio tests, visual/multiplayer playthrough, source comprehension and dependent audio/private-experience checks pass.

## Resume Studio verification

Use the repository-built place and identify its Studio ID before syncing. The generated runners are explicit QA files outside the default project:

```powershell
python -B tools/prepare_mission_checks.py --model Server
python -B tools/prepare_mission_checks.py --model Client
python -B tools/drive_studio.py --studio-id <project-studio-id> sources src
python -B tools/drive_studio.py --studio-id <project-studio-id> code work/mission-server-checks.luau --model Server
python -B tools/drive_studio.py --studio-id <project-studio-id> code work/mission-client-checks.luau --model Client
```

Run in the correct Play datamodels, record actual results, inspect expanded guide and effects-on/off indicators, then verify independent players and successful-save progression. Do not run against an unidentified start page or treat a build as Studio acceptance.
