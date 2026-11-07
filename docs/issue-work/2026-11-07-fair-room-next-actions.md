# Fair, rewards and indoor sets: picture-led next actions

Base main: `b8e34912960c33c49997cb73e2caa3e5d4f6edbf`. User authorized continued code implementation and direct commit to main, with testing later. This is a client-only refinement of the existing fair and stage contracts.

## Fair and prize handoff

A new read-only `QuayFairGuide` chooses suggestions from the server's fair summary and equipped rewards. After a win, an owned unworn prize or an affordable prize leads to the counter. Otherwise, the primary action offers another coin-awarding round at the current booth, then the next booth with remaining coins. Once all coins and prizes are complete, Done returns to the world; the separate replay control remains available. Replaying starts the existing demonstration, never automatically starts the timed game.

The win screen replaces inactive targets with an earned coin/check, a right-pointing arrow and the actual next prize/game/exit picture. Filled and empty coin slots show progress toward the first unowned prize on taller displays. Compact displays keep the larger handoff pictures without overlapping price slots. Zero-coin practice uses a check, Practice label and Fun/replay picture rather than implying another coin award. This preserves the existing three rewarded heats per game and all prices.

The counter outlines one useful owned/affordable prize and marks its action with a hand. Opening scrolls to that row and gives it controller focus; if nothing is ready, the Play button highlights the next game with coins remaining. After all coin heats, it says Practice and retains an explicit no-more-coins accessible description. Equipped rows retain the actual avatar/companion/Roamer destination picture. Recommendations do not claim or equip anything. Server acknowledgements, separate Wear action, pending-intent tracking, receipt destinations and save/session/unavailable notices remain unchanged.

## Rooms and sets

Each selected Play/Look/Out room action now has a matching local destination billboard at its server-supplied position. The marker turns amber with a hand when within the existing client action distance. It remains visible if pathfinding cannot supply breadcrumbs; it disappears with the room controls during another activity or on leaving. The invisible marker cannot collide, touch or intercept queries; marker/UI and heartbeat are cleaned up on destruction. Room guidance updates at ten times per second instead of every frame. Selected button text now has dark-on-amber contrast. Server distance, room identity and activity guards remain unchanged.

Stage setup highlights Prepare only after the existing source inspection reports ready, with a matching hand cue. Missing/unready music highlights Make and the Roamer picture; gamepad fallback can focus Make. The picture steps advance to Prepare when inspection is ready. Default instructions are short action labels instead of a repeated text arrow chain. Exact errors, turn timing, consent and capture confirmations remain visible through the existing controls/details.

Live set layers show their actual ON/OFF state with the role picture and amber/dark controls; absent roles are hidden. Idle boundary explanation is removed, while pending bar changes stay visible. Local Preview remains explicit. No note, arrangement, source, queue, listening consent, capture, credit or persistence behavior changes.

## Source review and limitations

One independent read-only source review found an upward arrow between horizontally arranged outcome pictures. It now points right and is vertically centered. A bounded source inspection also kept compact outcome price slots hidden. Literal module-reference inspection resolved 59 references across six changed Luau sources. The new guide depends only on existing shared QuayFair and introduces no module cycle. Whitespace and exact Git scope checks passed. These are source checks, not compilation or runtime evidence.

No tests/test suites, builds, lint, Studio or device sessions were run. Rokit/Rojo/Luau are unavailable here; no tools or dependencies were installed. Phone portrait/landscape layout, gamepad navigation, actual booth/room sightlines, timing, audio, multiplayer, save/rejoin and hosted acceptance remain for later user testing. In particular, verify first win with insufficient coins, affordable/owned prizes, a capped booth with another booth remaining, all-prize practice, room destination selection, and empty/ready/listening/hosting stage states.

The required user asset folder was refreshed at `C:/Users/slavd/OneDrive/Pictures/Assets` and `/mnt/c/Users/slavd/OneDrive/Pictures/Assets`; neither is mounted on this host. The approved local style board was inspected and the existing native glyphs/palette reused. No art files, canonical IDs, production stages, Roblox bindings or approved assets changed. Missing replacement art and acceptance remain in [issue #25](https://github.com/slafftrosheen/BeatMakka/issues/25). No spend, Roblox uploads or Experience publishing occurred.
