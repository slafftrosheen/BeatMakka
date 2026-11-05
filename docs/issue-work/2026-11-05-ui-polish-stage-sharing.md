# Stage, jam and record-sharing polish

Base main: `6bea4ad`. User requests continued implementation on main, less text and more visual guidance, with testing later. Preserve existing music, ownership, permissions, credits, explicit saves and approved art. The Windows asset directory was checked and is not mounted. Approved local board and historical stage captures remain visual references; no new asset/binding is needed.

## Plan

- [x] Stage: illustrated Choose / Prepare / Play, compact source/queue state, only relevant take controls, optional help and clearer live layers/requests.
- [x] Jams: direct Duet / Partner / Help navigation, illustrated role/invitation flow, current actions before optional copy/help detail. Mandatory pitch-context and double-press confirmations remain intact.
- [x] Records: full-screen bounded native dialogs; Music / Sleeve / Share grouping; visible creator, storage and permission state; full credits/details on demand; stable explicit recipients and direct navigation from a saved release to inviting.
- [x] Private listening: artwork and illustrated invitation/listening/remix flow, short essential scope and playback progress, full source details available. Preserve local mute, explicit acceptance, separate unsaved remix and original-work protection.
- [x] Review source integration/focus/lifetimes/narrow layout and run permitted source checks. Delivery uses a guarded direct-main commit; the final chat gives its hash.

No tests, builds/lint, dependencies, CI, uploads/publication, paid assets, profile-schema or reward changes. Studio/device/acoustic/hosted acceptance remains unavailable and unclaimed. One source review and fix pass, then finish.

## Source behavior

Stage presents source and mode first, structured queue rows, a passive bar timeline for Spotlight, and only actual retained/imported take state. Empty take/result placeholders no longer consume the setup page. Full explanatory text and exact NPC request wording remain in details; live suggestions stay visible. Prepared queue titles come from the accepted snapshot rather than a later editor selection.

Jams expose direct pages and role glyphs. Pitch declarations expand automatically for acknowledgements and incoming context/role proposals; compact viewing never bypasses the original context token or confirmation. Optional joint-copy controls are separate, retained credits stay readable, and imported draft save state remains explicit. Recipients are selected by user ID; two occupied seats do not look like a free invitation slot during a pending transition. Context/copy confirmation captions expire without changing any server action.

Record dialogs use the existing ScreenGui bounds instead of the small library viewport. Their original owner controls visibility/lifetime, so page/station exit still closes them. Music / Sleeve / Share separates normal continuation, local sleeve choices and deliberate releases/invitations. A stable explicitly chosen recipient cannot silently change when the roster changes. Creator/storage/current permission remain visible, complete credits/source lineage stay in details, and an acknowledged last release can be opened directly for sharing. Private listening shows artwork, accepted-schedule progress and clear preview/Draft/Finished distinctions; acceptance and remix still use existing guarded commands. Public Spotlight is no longer labelled a Sequence loop or full Finished Song.

## Review and evidence

One independent source review found a focus-restoration helper shadowed by the `show()` boolean parameter; the helper was renamed. The fix pass also routes INVITE directly to Share, explains empty jam partner state without blocking solo play, starts record focus on visible task controls instead of the bottom Close button, retains pinned prepared mode labels, measures the stage clock for narrow widths and gives an empty stage an enabled focus target. Existing-copy rights remain visible at the permission action.

Whitespace and static relative/Shared module-reference/cycle checks pass for nine changed files, eight of them Luau. No unresolved static require or new dependency cycle was found; the pre-existing lazy GuiFactory/DeviceSkin/GameIcons cycle remains. The web-oriented mechanical detector returned an empty list, which does not validate native Roblox layout. No asset/data/output, audio/model/texture/binding or packaged-place paths changed. Git delivery checks every staged blob and exact file scope, then checks remote main and aligns the local checkout without dropping changes.

Rokit/Rojo/StyLua/Selene/Luau remain unavailable. No compiler/build/lint, test suite, gameplay/Studio/device/listening/hosted run occurred. Later user acceptance: stage mode/source pinning, queue/start/ending, role/request/take controls; two-client jam context and copy confirmations; recipient roster changes and invitation expiry; public versus private mute/stop; full-screen dialog focus/page/station teardown; exact releases, complete credits and saved/unsaved remix rejoin. Historical screenshots are references only. No Roblox upload/publication, paid assets, new dependencies or CI ran.
