# Studio QA — banks, sequences and Song Mode

**Subsequent verification:** the remaining asset-type warning was traced to Rojo's notification-sound preloader and fixed locally. A fresh Studio MCP run passed all 9 server and 3 client UI checks with empty output. See [the warning fix and retest report](../rojo-preload-warning-fix-2026-10-30/README.md). The account below records the earlier run before that correction.

Local Studio Play testing completed on 30 October 2026 in `NeedleQuay-MPC-v3.rbxlx`. The user explicitly authorized testing and error fixes. Studio is left open in Play with a session-only five-sequence project and a saved Song draft for inspection.

## Errors reproduced and fixed

1. **Closing the journal raised a nil string-method error.** `QuayDemoView.render` called `open:sub` when `quay.open` was nil. Added the string guard and reproduced close/reopen/enter again without the error.
2. **Song resume switched into the editor sequence.** Space paused the Song snapshot, but a second Space started a Sequence because resume compared the transport reference with the editor selection. The regression failed before the fix. Play now resumes the pinned transport reference and offset; live Space and the Song page's pause/resume button both passed.
3. **Song position was invisible on its own page.** Added a live Song position line and persistent context showing step, section, repetition, bar/beat and elapsed/total time, plus a touch-accessible Play/pause control.
4. **Arrangement labels became detached from their controls.** Event, arrangement and library lists now explicitly sort by authored layout order. Native Studio capture confirmed headings paired with each step's controls.
5. **Bar, velocity, swing and Song BPM inputs could show stale server values.** Inputs synchronize when their selected object/value changes, while avoiding replacement of text currently being edited.

Source fixes are limited to `src/client/QuayDemoView.luau`, `src/server/MusicWorkspace.luau` and `src/client/MusicWorkspaceView.luau`. A pre-QA source backup is at `C:/Users/slavd/.codex/backups/BeatMaka/mpc-studio-qa-20261030-145128`.

## Actual runtime evidence

- **9/9 server regression tests passed** in the real Studio Server DataModel: 64-pad identity/settings; more than four sequences; independent variations; multibar edits/history; delayed recording and stale epochs; pinned recording dependencies/event IDs; Song references/repeats/tempo; finite schedules and seek; resume; accepted/failed storage; immutable snapshot fixtures; conversion; all six legacy shelf bundles.
- **3/3 client UI checks passed** after failing before the UI fixes: visible Song position/pause control, authored step ordering, and accurate selected bar/Song BPM fields.
- Native UI clicks created a named sequence and added notes at **A01, B01, C01 and D01** within one sequence. Switching banks retained all four events.
- A real keyboard **Two** input while Bank D was recording produced an absolute **D02 / pad 50** event at velocity **73**, acknowledged through `MusicNetwork.Delta`.
- The client/server command path created and selected a fifth sequence, saved the draft for the Studio session, and preserved a step's original sequence when its repeat count changed while a different sequence was selected for editing.
- A live arranged preview advanced through Intro, Main repetition 1 and Main repetition 2. Its musical duration was **4.0 seconds**; with the authored **2.0-second tail**, the server stopped it at an observed **6.107 seconds**. This is transport/state timing, not acoustic timing.
- Finish & Save Song correctly rejected pending audio and left the Finished Songs library empty.
- Final project Lua output contained no project script errors. Studio still logged three asset-type warnings for `rbxassetid://203785492`. A read-only product lookup identifies that asset as **Pop Close Sound**, audio type 3; no reference was found in project source/manifests or inspected runtime asset properties. Its origin remains unresolved. One intermediate restart also emitted Roblox CoreGui startup timeouts; those did not recur on the final restart. Roblox's internal scripts were not modified.

Machine-readable results, including before/after failures, are in `results.json`. Repeatable probes are in `tools/qa/mpc_studio_regression.luau`, `tools/qa/mpc_client_probe.luau` and `tools/qa/mpc_ui_assertions.luau`; they execute through Studio MCP and are outside the production Rojo source tree. Test fixtures use private Lua tables. The immutable snapshot fixture uses an explicitly synthetic readiness callback, which does not admit audio or alter the runtime catalog.

Native capture IDs: `mpc-v3-initial`, `mpc-v3-instrument`, `mpc-v3-bank-controls`, `mpc-v3-song-status-before-fix`, `mpc-v3-song-mode-fixed`.

## Validation and boundaries

Pinned StyLua checks and Selene passed on the three modified source files and three QA probes: **0 errors, 0 warnings, 0 parse errors**. Rojo rebuilt the local place successfully. The local ZIP/launcher was refreshed after these fixes.

The written 64-slot map and all pending audio decisions remain intact. These checks do not establish audible one-shot quality, acoustic latency, final admitted-audio performance, two-client/device behavior or durable cloud rejoin. No Roblox uploads/publication, purchases, commerce activation, generation spending, commits or pushes occurred. The asset installer was run for the explicitly requested local Studio launch; it verified 752 active local files and retired only exact hash-matching legacy payloads according to its existing manifest policy.
