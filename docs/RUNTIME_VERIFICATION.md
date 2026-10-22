# First-zone runtime verification

22 October 2026. User-authorized code completion, tests and fixes through Studio MCP. No Tripo work, new dependencies, asset upload, place publishing, commit or push.

## Implementation

[Implementation coverage](IMPLEMENTATION_COVERAGE.md) maps all 74 package IDs to concrete sources. Code now includes all 24 exact geometry constructors; modular shop/roof/portal/awning/door/shutter sources; accessible workshop and listening-stage approaches; safe waterfront bounds; distant backdrop; functional lamp/record/plant sockets; rigid robot and speaker targets; local pad, discovery, restoration and music response; effects/quality fallbacks; original G02 artwork; and S03/S04 cue/ambience source and runtime bindings.

The original imported masters are preserved. Where imported content is missing, articulated robot/speaker proxies provide independently moving targets. A fused imported shell is never animated as a separate head or speaker cone. Final DCC rigs and their art acceptance remain distinct.

The live source is synchronized to the local `FrequencyZero-Complete.rbxlx` Studio session. The original `BeatMakaAssetReview.rbxl` file was not overwritten. The generated source place preserves source/UI bindings but does not embed or claim to import the GLBs.

## Checks and fixes

| Check | Evidence / result |
| --- | --- |
| Pinned Selene and StyLua | Zero lint warnings/errors and clean formatting after source edits. |
| Rojo packaging | `work/FrequencyZero-Complete.rbxlx` builds from the root project. |
| Eight contract groups | `evidence/docs-first-pass-0.json`: pattern validation/unlocks, independent pad rows, transport wrap/pre-roll, save/restore snapshots, failed cloud load protection, cloud revision conflicts with a fake store, opt-in listening and 24 exact constructors all passed in Studio Play. No live DataStore was contacted. |
| Final contract/scene recheck | `evidence/docs-final-contracts-scene.json`: 8/8 groups passed again. Source-proxy scene: 372 BaseParts, 32 pad targets, two shadow-casting lights, zero decorative proxy collision violations. These are scene counts, not FPS/triangle measurements or imported-mesh acceptance. |
| Two actual simulated clients | `evidence/docs-multiplayer-final.json`: 16/16 integration checks passed, including same-clock opt-in transport, contention, personal state, distance exit, performer respawn and actual client disconnect cleanup. |
| Actual mouse and keyboard sampler | Four enabled steps; a fifth note recorded on pad 2 using keyboard input; Play and Record returned to stopped. |
| Actual save → clear → restore | `evidence/docs-save-restore.json`: four steps and the Chalk finish restored; session save mode explicit and dirty false. |
| Discoveries and restoration | I01, I02 and I03 unlocked their matching samples. Four personal indicators lit after all discoveries plus a nonempty pattern. |
| Listening and range exit | Podium started a snapshot, host controls appeared and leaving range returned the podium to idle. |
| Effects disabled | `evidence/docs-effects-off.json`: all six practical lights and the ambient emitter were disabled; Effects OFF text remained explicit. |
| Workshop/stage approach | No-jump PathfindingService routes succeeded with 15 and 6 waypoints. MCP character navigation reached within interaction range of the sampler. These are simulated navigation checks, not human camera/art approval. |
| Phone portrait / landscape | iPhone 17 Pro simulator at 401 x 778 and 750 x 381 logical viewport: no text-height overflow in the workstation descendants. Landscape capture: `evidence/docs-landscape.jpg`. |
| Device switch while editing | Found and fixed core TouchGui being re-enabled over the sequencer. `evidence/docs-phone-fixed.json` confirms it remains disabled across a desktop → phone switch while open, with no text overflow. `evidence/docs-phone-exit.json` confirms it restores on exit. Final portrait capture: `evidence/docs-portrait.jpg`. |
| Stable input targets | HUD buttons now have explicit Sound/Effects instance names. Added gamepad X/Y/B and Escape transport/leave bindings. |
| Virtual gamepad | MCP X/Y input entered playing/recording state; B closed the sampler and released the station. This verifies the bindings through injected input, not a physical controller. |
| Final console | `evidence/docs-final-console.json`: no project Luau exception. Roblox's avatar asset `203785492` reports a type mismatch; Assistant camera-reset notices also remain. No claim of a warning-free platform log. |

The phone emulator's MCP mouse actions sometimes returned Success without activating the requested control. Successful desktop control checks and measured phone layouts are recorded separately; this does not establish physical touchscreen operation. The emulator setter also required selecting a phone before setting portrait orientation, despite the connected skill suggesting the opposite order.

Multiplayer is exercised through `StudioTestService:ExecuteMultiplayerTestAsync` with two actual simulated clients, default Studio avatars, and isolated test-only scripts in `tests/`. Early harness failures were retained: client readiness before character spawn, a shared camera/approach position that obstructed the second player's prompt, and checking a kick before actual removal. The harness now waits for characters, uses distinct per-player approaches/cameras and the official client LeaveTest API. All 16 final checks passed; earlier failed attempts are not passing evidence. Avatar appearance loading was restored after the run.

## Remaining acceptance

- Audio IDs remain empty: 24 original WAVs and cue/ambience bindings exist, but audible playback, moderation, permission checks and loudness/listening review require actual authorized uploads. Fourteen existing image bindings validate; no duplicate upload was made.
- Native persistent mesh imports and final atlas/rig art review are still open. No candidate, DCC or art-approved status was promoted from these code tests.
- Cloud conflict/load failure paths were tested against injected in-memory stores. Published-experience persistence has not been exercised.
- Physical mobile/console input, sample-accurate timing, target-device FPS/memory and human visual approval are not established by these checks.
- The approved full style board remains absent. The supplied v0.2 PDFs and preserved authored register govern this implementation.

Test drivers are kept out of `default.project.json` and removed from the interactive place after the run. Source build artifacts are local and ignored by Git.
