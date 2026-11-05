# Fair and room picture guidance polish

Base main: `e1cf8167043b8454b4429fd0c2424f37fc7b10d5`. User requested continued direct implementation on main and will test later. Preserve approved assets, existing musical snapshots/credits, deliberate listening and saved progress. The required Windows asset directory was checked again at both the supplied path and `/mnt/c/...`; neither is mounted. No new external asset was used. Replacement art stays in [issue #25](https://github.com/slafftrosheen/BeatMakka/issues/25).

## Fair: see, play, choose

Cork Gallery, Beat Bells and Ring Toss now open in a server-owned `ready` state. A local picture demonstration repeats without awarding anything. The round clock begins only after an explicit Play command carrying the current round serial, with the same ready-profile, proximity and rate checks as other game actions. A ready demonstration expires after 90 seconds; live rounds retain 45 seconds. Retry returns these three games to their demonstration. The original four street games keep their existing round behavior and view.

`QuayFairGameView` owns the three fair displays. A hand, raised target/outline and drawn pictures show the current action. Ring Toss shows the ring crossing the peg's amber window and says Wait outside it. Four native check markers reflect only server score. Three drawn coin stamps reflect saved clear counts; the win action points to the real prize counter. The game uses two rows of large targets normally and one row on a short display, with the ring rail beside its tap target when compact. Gamepad focus moves to enabled controls; keyboard numbers and touch targets remain available. Optional music knowledge stays behind the question button. Session/temporary storage scope is shown with the coin count.

The named response windows and ring timing are shared by client and server through QuayFair; values are unchanged. Existing unique awards, three coin stamps per game, 90 lifetime earned coins, fixed prize costs, saved ownership and equipment remain unchanged. The new demonstration is ephemeral, not a profile/save schema field.

Prize cards show the reward, native coin-cost tokens, actual balance and one action: Get, Wear, On or Play. An unaffordable prize leads to a fair game that still has a coin stamp available. Get remains an explicit server-validated claim. A short pending state waits for acknowledgement; it cannot manufacture ownership. Already equipped items are disabled with an enabled focus fallback. Save/temporary/session information remains available. Leaving the counter still closes the panel.

## Rooms: play, look, out

All three current rooms have matching pad / eye / doorway symbols on controls, local floor plaques and a compact action strip. Select a picture to reveal the floor route, walk to it, then tap the picture (or E/X) to act when nearby. The touch strip is raised above the normal movement controls. It hides during music/stage/jam/dialogue surfaces, and ordinary nearby-action buttons yield to it.

The server projects only the actual current room's set, activity and exit anchors. `QuayRoomAction` accepts a listed room ID and a listed action, checks proximity again, then opens the same StageQueue/ListeningSession or existing building activity. The room activity desk opens Explore directly. It never accepts a client position and does not teleport a player to a set or activity desk. Exit uses the existing guarded doorway return. Chapter requirements, opt-in listening, saved musical snapshots, queue ownership, capture and credits are untouched.

Small doorway frames and floor plaques are deterministic local construction geometry; they do not replace any approved source model. The existing interior visibility policy hides their geometry while outside, and the local picture layer follows that visibility. Their art/runtime acceptance remains pending with the rest of #25.

## Evidence and limits

One independent source review and bounded fix pass, followed by whitespace/static-reference/cycle and Git-scope checks. The review caught the exit floor plaque being placed toward the wall; its offset now points inward into the room. Static module-reference checks found no unresolved reference or new dependency cycle across 14 changed Luau files; the existing lazy GuiFactory/DeviceSkin/GameIcons cycle remains. These checks do not compile Luau, render Roblox UI, establish walking/camera sightlines or prove saved rejoin. Rokit/Rojo/StyLua/Selene/Luau remain unavailable; no installs, test suites, builds/lint, device/Studio sessions, Roblox uploads/publishing, paid assets, new dependencies or CI were performed.

Later user acceptance: opening with all reading ignored; watching/replaying each demonstration before Play; server start/expiry and four-hit wins; miss/retry and Effects OFF; coin/prize/save acknowledgement including session/unavailable storage; unaffordable prize → remaining stamp route; gamepad focus and short/portrait layouts; room play/look/out routes and E/X; stage start/listen/leave/capture; chapter gates; two clients and local package reopen. Source checks are not any of those acceptance results.
