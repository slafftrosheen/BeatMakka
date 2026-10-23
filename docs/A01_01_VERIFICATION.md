# A01-01 / issue #2 — fixed MK-I screens

23 October 2026. Base `9958913751f66798042d6e3cafa9ab471150438b`. User authorized issue-by-issue implementation, Studio MCP testing, fixes, issue closure and push.

## Screens and state

Enter sampler → Play. Persistent navigation selects Play ↔ Steps ↔ Sounds ↔ Beats ↔ Settings; Leave releases the station. Play owns the fixed sixteen pads. Steps edits the selected pad's sixteen steps; choose another pad on Play. Sounds assigns the selected pad. Beats retains A–D, all six shelf positions, confirmation and Mica's objective. Settings retains tempo, pad mute/clear, profile save/restore, sound/effects, finish and diagnostics.

Transport stays available on every page. Play/Space retains its existing toggle behavior. Record starts recording; explicit Stop ends playing/recording and remains stopped on repeated presses. Navigation never sends a music command or replaces working slots. Leaving Beats clears a pending confirmation. Re-entering a sampler opens Play.

Footer always shows active slot, BPM, loading/ready/playing/recording and saving/unsaved/saved. Notices occupy a separate header or landscape rail. Studio-session/cloud/unavailable persistence details remain in the existing shelf messages; a SAVED indication does not assert cloud acceptance.

Portrait/tablet/desktop use top navigation and transport. Short landscape uses a left navigation rail, right transport and central square pads. Below 300px safe panel height the left rail uses two columns to keep Leave in bounds. Only Sounds, Beats and Settings scroll. Play has no scrolling ancestor; swiping its surface cannot scroll or reflow pads. Safe insets and native text are retained. No textures, meshes, content IDs or dependencies changed.

## Observed Studio evidence

Studio MCP instance `f060d05e-09bc-466c-8945-37cb780e5bb8`, local `FrequencyZero-Alpha01.rbxlx`.

| Actual simulator | Camera viewport | Safe panel | Pad size |
| --- | --- | --- | --- |
| iPhone 17 Pro portrait | 401×778 | 393×712 | 89×89 |
| iPhone 17 Pro landscape | 750×381 | 742×315 | 62×62 |
| iPad Pro M5 13in landscape | 1375×1032 | 1040×850 | 158×158 |

All sixteen pads were measured inside Play in each real simulator run. [Receipts and screenshots](evidence/a01-01/). Synthetic Client integration additionally checks six panel sizes, including 740×260, exact 4×4 arrangement, all navigation bounds, no scrolling ancestor, stable pad positions across navigation, no commands from page changes, cancelled hidden confirmations, and unclipped saving/recording status while a notice is present.

Desktop MCP mouse interaction selected Beats, started recording from that page, then pressed Stop twice. Actual UI state confirmed RECORDING followed by stopped transport and Record OFF. Mouse injection did not activate phone-emulated buttons; these attempts are not counted as touch interaction evidence. Phone/tablet results establish layout, not physical multitouch or audible latency.

Existing Studio checks passed: 8 Contracts groups, 8 Milestone groups, shelf two-click replacement/expiry/edit cancellation. New GrooveboxUi check first failed on the old UI, then exposed/fixed fractional grid wrapping; the first real landscape check exposed/fixed undersized pads after insets. Final source passed pinned Selene (0 errors/warnings/parse errors), StyLua, Rojo build and diff whitespace checks. Independent review prompted status/notice separation and the shorter landscape rail correction.

The existing `rbxassetid://203785492` asset-type warning remains separate from UI acceptance. Audio uploads, cloud saves, physical input performance and persistent mesh/art acceptance remain open in their own issues. No place or production asset was published.

## Tools and spending

Connected GitHub handles issues. Studio MCP handles local runtime, screenshots and device simulation. Rokit pins Rojo/Selene/StyLua. Tripo CLI 0.7.2 is installed; read-only balance returned 210 available / 0 frozen. This issue spent 0 credits. Built-in image generation is available for later authored textures; Picsart is excluded per the user's credit constraint. Existing Blender and deterministic asset tools remain available for exact geometry and cleanup. No extra plugin installation is required for this issue.
