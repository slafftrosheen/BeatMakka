# After winning a prize or finishing a set

Base main: `d4e009e995694f3018da4a3f5c029b381cd734ac`. User authorized continued code implementation and direct main delivery, with testing later.

## Set finish pictures

ListeningSession now produces a session-local finish receipt for Full Songs and stopped Practice loops, alongside the existing Spotlight result. Receipts carry the session revision, mode and performed title. Full Song completion uses the existing server schedule end; stopping early and stopping a loop are shown as stopped. Spotlight capture/retention and its existing result fields are preserved. This is not a saved song, performance reward, vote, credit or quest award; no profile format changed.

The stage opens a compact finish picture above the next controls rather than returning immediately to the music picker and burying the result. A check marks completed playback; a stop picture marks interrupted playback/loop stop. The persistent footer offers Again (return to the chooser), Studio (existing guarded own-studio route) and Out (existing stage departure). Again does not prepare or start playback. Closing/leaving acknowledges that result locally so reopening the board returns to setup. A later set has a new receipt identity. Source inspection waits until the finish panel is dismissed.

Temporary takes appear before the picker, with Take / Draft / Save pictures and a short unsaved/server-exit warning. An imported draft that is no longer in this workspace points to Find instead of implying it can be saved here. Save/session status continues to come from the existing take summary. Keep uses a draft sleeve picture; discard uses a trash picture; each changes to a check only for the existing second confirmation. Context identity, five-second confirmation, save guards, Undo/Redo, source preservation and explicit instrument saving remain intact. Full capture/error details remain available. Controller focus on finishing prefers the retained take's Keep control when available; otherwise it lands on Again.

## After a fair reward

The acknowledged receipt keeps its deliberate Wear or Show/See/People action prominently highlighted. Its former generic OK action now pictures the next useful destination: another owned/unworn or affordable prize, a game with coin heats remaining, or Out. Choosing another prize only opens its existing owned receipt or focuses its unclaimed row; it never claims or equips it. The chosen unclaimed row also becomes the local picture target so the next-action highlight agrees with the selection. Play only follows the existing route; the game still requires explicit start. Showing an owned title uses its badge picture and the short Show label before returning to the world.

Pending equipment/claim acknowledgement disables both receipt actions, while the existing close/recovery path and bounded pending-intent tracking remain. Prices, earned coins, ownership, equipment, save notices, standalone prize selection and free practice remain unchanged.

## Review and limits

One independent read-only source review found no important correctness defects in the receipt lifecycle, set/capture controls or prize routes. A final source pass aligned the Next-prize highlight/focus with its destination and acknowledged a finish receipt on explicit departure. Static literal-reference inspection resolved 28 module references across four changed Luau files. Whitespace and exact Git scope checks passed. The new picture helper imports only existing UI utilities and adds no dependency cycle. These are source checks, not Luau compilation, rendering or runtime acceptance.

No tests/test suites, builds, lint, Studio/device sessions, installs, paid assets, Roblox uploads or Experience publishing ran. Pinned Rokit/Rojo/Luau remain unavailable. Later user testing needs natural Full Song/Spotlight completion, early Stop, stopped loops, leaving/reopening, Again source choice, own-studio availability, capture Keep/Discard confirmation/import/save/undo, pending prize acknowledgements and Next/Play/Out with mixed ownership/balances. Phone/gamepad layout, multiplayer, sound, save/rejoin and hosted acceptance remain unverified.

The required `C:/Users/slavd/OneDrive/Pictures/Assets` folder and `/mnt/c/...` counterpart remain unavailable after refresh. Existing approved art, native glyphs and palette were reused. No asset files, canonical IDs, production stages or Roblox bindings changed. Replacement art and acceptance remain in [issue #25](https://github.com/slafftrosheen/BeatMakka/issues/25).
