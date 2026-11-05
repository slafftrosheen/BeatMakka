# Fair reward acknowledgements and indoor set setup

Base main: `861c5831f8dc3277cfad41f7e9ae4a1b4cf1650a`. User requested continued direct implementation/commit on main, picture-led next actions and later user testing. The required source asset folder was refreshed at the supplied Windows path and `/mnt/c/...`; neither is mounted. Existing local art remains the authority; no external/generated asset was used. Missing replacement art and acceptance remain in [issue #25](https://github.com/slafftrosheen/BeatMakka/issues/25).

## Rewards

Prize cards now picture the destination of the reward: a title above an avatar, a charm on an optional companion, or Roamer trim. Play / Get / Wear pictures show the current path. A claim receipt appears only after the server reports ownership for the specifically pending claim. Wearing remains a separate explicit action, with its own acknowledgement. No optimistic reward ownership, automatic equipment, new spend or changed coin cap/cost is introduced.

The receipt leads from Wear to seeing the Roamer lights, opening the optional People controls for a companion charm, or returning to the world for the title. Alone remains available and unchanged; no companion is selected automatically. Fair Friend gains a native badge picture above the avatar title so the visual does not rely solely on the words. Beat Bell uses the bell glyph consistently. Acknowledgement previews are local native interface drawings, not art-approved replacement meshes.

The busy indicator permits close/recovery and times out without resubmitting a claim/equip. A separate bounded acknowledgement map survives that timeout; an already worn reward can also reopen its destination receipt. Existing affordability, unique claims, saved ownership, reward equipment and save/session/unavailable notices remain authoritative.

## Indoor sets

The existing common StageView now has direct music rows with source-type pictures and small pages. Short and Loop/Song are direct choices. The selected source can show a sixteen-cell overview of its opening bar and actual resolved layer roles. These cells summarize positions into display bins; they never quantize, move or write source notes. Prepared previews come from the accepted snapshot and are sent only to its owner. Other queued players retain the existing title/venue listing.

A new `StageInspect` read-only request resolves the selected source/mode through the existing preparation contract with capture forced OFF. It does not enqueue, play audio, arm/retain a take, save or mutate the musical project. A context token invalidates its result when the project identity/revision, saved music snapshot, workspace generation or sound unlocks change. Only the small visual summary/problem is returned. Real Prepare and Start still revalidate the actual source, audio readiness and snapshot with their existing rules. Optional capture remains explicit, with existing retained-take and Keep/Discard confirmation guards.

Prepare, Play, Stop and Cancel have distinct pictures and a large primary action. The offered Play turn is visually prominent. Whole Song and Practice loop use a passive run rail and clock from the existing server start/duration; Spotlight keeps its actual bar timeline and live layer controls. Full explanations, capture controls and exact request wording remain in details; active take/capture state stays visible.

Make opens the player's own available studio from an open nearby stage. The server checks stage/range, rejects a hosting or queued performer, checks owned bay and station availability, then uses the existing teleport/release/enterStation path. The client never supplies coordinates or another player's station. This adds a visible recovery action when no music is available or the selected source cannot prepare. It does not create notes or save/finish a song for the player.

## Review and evidence

One independent source review and bounded fix pass, then whitespace, static module-reference/cycle and exact Git-scope checks. Review found that a slow reward acknowledgement could lose its destination action and an odd source page could briefly overlap later controls. Acknowledgement tracking now survives the two-second busy state, equipped rewards can reopen their destination, and source pages reserve fixed row slots. Static source checks found no unresolved module reference or new dependency cycle across eleven changed Luau files; the pre-existing lazy GuiFactory/DeviceSkin/GameIcons cycle remains. Existing music/save/credit/asset contracts remain unchanged. No new top-level profile field/version or runtime asset binding is required; inspection/receipt state is session-local.

Rokit/Rojo/StyLua/Selene/Luau remain unavailable. No installs, test suites, builds/lint, Studio/device/audio/hosted/rejoin acceptance, Roblox uploads/publishing, paid assets, dependencies or CI ran. Source checks are not Luau compilation or rendered UI evidence.

Later user acceptance: claim/equip latency and expiry, session/unavailable save notices, all three reward pictures and world destinations; Alone/optional companions; opening an empty/unready stage and Make ownership/occupancy; source paging/selection/mode inspection, saved-song revision and pack readiness changes; pinned Prepare → offered Play; full/loop/Spotlight stop/leave/mute; capture confirmation/import/save; phone portrait/landscape, controller focus, actual room camera/walking and two clients. Existing asset/release gates stay open.
