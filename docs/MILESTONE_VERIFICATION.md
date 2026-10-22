# Four patterns, beat shelf and Mica: Studio verification

23 October 2026. User explicitly authorized Studio MCP testing, fixes, commit and push of all pending changes, including the audio/content continuation. Base checkout and fetched `origin/main` were both `dc898d887e5f147d95e728040a20a035a1e24c08`.

## Results

The current 30 source scripts were synchronized into the existing `FrequencyZero-Complete.rbxlx` local review session. Its previous three source roots were preserved in `ServerStorage.BeforeMilestoneQA_20261023`. Test drivers stayed outside `default.project.json` and were removed after testing. Avatar appearance loading was restored, Play stopped, and Studio reset to its default viewport.

| Check | Result |
| --- | --- |
| Existing contract suite in Studio Play | 8/8 groups passed, including save conflicts, load failure protection and listening cleanup. |
| New milestone contracts in Studio Play | 8/8 groups passed: four-slot isolation, deep shelf snapshots, stale versions, six-position limits, schema-1 migration/schema-2 round trip, future/corrupt revision protection, failed shelf saves, restore preservation and exact saved-loop quest qualification. Storage was injected, not live cloud storage. |
| Two actual simulated clients | 26/26 integration checks passed: station contention, personal slots/shelf/quest, Mica acceptance, discovery-sound shelf save, short-performance cancellation, stale deadline rejection, complete-loop quest save without an audience, listener opt-in, distance exit, performer respawn and actual client disconnect. |
| Sampler mouse/keyboard | Actual F accepted Mica's request; actual clicks selected the discovered chirp, enabled a step, switched to B, saved to the shelf and confirmed a load. A–D retained distinct BPMs/notes. Switching slots stopped Play/Record. A load's first click retained edits; its second restored the saved snapshot. A stale overwrite command was rejected. |
| Confirmation deadline regression | A fresh client integration check passed: replacement requires two clicks, expiry clears its text after five seconds, an expired confirmation cannot authorize a write, and editing cancels a pending load. |
| Phone layout | iPhone 17 Pro at 401×778 portrait and 750×381 landscape: no measured text-height overflow; slot/shelf/action buttons were at least 44 logical pixels high. Core TouchGui stayed disabled while editing. Portrait shelf visually inspected and captured. This is Studio simulation, not physical touchscreen acceptance. |
| Unconfigured audio and teardown | 24 personal banks and 19 courtyard banks, zero Sound voices allocated with current unbound IDs. Courtyard omitted cues/ambience, unconfigured playback returned false, mute status remained explicit, and destroying both test engines restored SoundService child count. Configured/failed/denied real audio still needs separate acceptance. |
| Offline content-binding tests | 5/5 Python tests passed: all 14 image bindings retained on an empty Audio update, malformed/duplicate/unknown inputs rejected, explicit rebind protection, temporary staged writes and concurrent-change protection. No project bindings were written. |
| Pinned tools | Selene: zero errors/warnings/parse errors. StyLua check passed. Rojo built `work/FrequencyZero-Milestone.rbxlx`. Whitespace check passed. |

Raw receipts, including failed exploratory attempts, are in [milestone-20261023.json](evidence/milestone-20261023.json). The final UI is captured in [milestone-portrait.jpg](evidence/milestone-portrait.jpg).

## Fixes and test-driver corrections

The replacement confirmation used to expire logically at five seconds while its label waited for a one-second UI refresh. A confirmation-bound deadline callback now updates the label at expiry; cancelled/replaced confirmations cannot clear a newer one.

Early injected checks exposed test-driver assumptions: an offscreen sound button needed scrolling before clicking; a 0.2-second prompt wait could inspect state before the prompt became visible; and two avatars at identical approach coordinates blocked each other's line of sight. A diagnostic ray hit `Workspace.Player1.Head`. The multiplayer driver now uses distinct approaches, waits for real PromptShown/PromptHidden state, and retains diagnostics. Those failed attempts are not counted as passing checks. One later inspection selected the station Model instead of its BasePart; that AssistantCommand error was corrected without a gameplay change.

The earlier source review also fixed the full-loop timing gap and ensured quest completion starts its save attempt immediately, or drains it after an already-running save. The multiplayer checks exercise cancellation and completion with these fixes in place.

The captured console contains Roblox's existing avatar asset-type warning for `203785492`, Assistant camera-reset notices and the injected inspection error above. No project-source Luau exception was observed. This is not a warning-free platform-log claim.

## Reproduce

Run pinned tools from the repository root:

```powershell
selene src tests
stylua --check src tests
rojo build default.project.json --output work/FrequencyZero-Milestone.rbxlx
python -B -m unittest discover -s tests -p test_content_binding.py -v
python -B tools/configure_content.py data/content-ids.json
```

Through Studio MCP, install `tests/Contracts.spec.luau` and `tests/Milestone.spec.luau` as temporary ModuleScripts under ServerStorage and invoke each returned function in Server Play. Invoke `tests/MilestoneUi.spec.luau` as a temporary client ModuleScript. For multiplayer, install the two `tests/Multiplayer` drivers only in the local review place and use `StudioTestService:ExecuteMultiplayerTestAsync(2, {suite = "BeatMakaDocs"})` from Edit. Remove the drivers afterward; do not add them to the production project.

## Remaining acceptance

No new audio/image/mesh upload, provider job or place publishing was performed. Existing fourteen image IDs and zero audio IDs remain unchanged. Audible loading/permissions/loudness, persistent mesh imports, final rig/atlas art approval, live published cloud persistence, physical devices and measured performance remain open. Storage migration/conflict tests used injected stores and Studio session saves. No asset acceptance stage was promoted.
