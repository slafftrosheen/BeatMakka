# Chosen fair prizes, coin slots and indoor set queues

Base main: `4d530b5e07e8ece3c84592d8c72f84fe27e9969d`. Continued user-authorized direct implementation on main; user testing remains later. All changes are client presentation and local guidance.

## Chosen prize continuity

Choosing Play on an unaffordable prize now keeps that specific prize as a local picture target. Round results show its picture and coin slots, and suggest further coin-awarding games until that prize is affordable. A cheaper unrelated prize no longer diverts that suggestion. The counter scrolls to the target on return; a small flag marks the chosen prize. The player can still choose any other prize, wear an owned reward, leave or practice. The target clears when the server reports ownership; it is neither a saved quest nor a reserved purchase.

The existing server balance, unique ownership, three rewarded heats per game, prices and claim/equip acknowledgements remain unchanged. This local target never grants coins, buys a prize or equips anything. Receipt pictures now show Get / Wear / See, with the final picture matching the Roamer, companion or title destination. Normal counter guidance continues to show Play / Get / Wear.

## Coin pictures

FairCoinSlots replaces the color-only coin progress at booths, prize rows and tall result layouts. A filled coin and an empty outlined slot differ by shape as well as color. One slot represents one ten-coin heat; costs and balance remain numerically visible in their existing locations. Owned prize rows retain their ownership check, and their price slots remain filled. All-prize practice still shows no new coin award. Compact result layouts keep their existing large next-action pictures without squeezing in the goal strip.

## Indoor set queue

StageQueuePictures uses the existing public queue summary: one current performer and up to four queued entries, matching the current server limit. The player's position has an amber backing, outline and hand. When their turn is offered, their picture switches to Play with the remaining seconds from the existing server deadline. These are passive pictures; Prepare, Play and Listen still require the existing explicit actions and server checks. No audio is joined automatically.

The default queue display drops the repeated paragraphs and full list in favor of this picture strip. Full performer/title rows remain available in Details. Listen has an explicit headphone picture and concise label; its accessible description preserves the voluntary listening meaning. Set sources, queue capacity/expiry, permissions, music, capture, credits and save contracts are unchanged.

## Evidence and acceptance

Source inspection resolved 71 literal module references across eight changed Luau files. New display helpers depend only on existing shared/client utilities and introduce no new dependency cycle. Whitespace and exact Git-scope checks passed; these are not compilation or rendered evidence. One independent source review caught that viewing or wearing an unrelated owned prize cleared the current target. The bounded fix preserves the target through those actions; only choosing another unowned prize replaces it, and authoritative target ownership clears it.

No tests/test suites, builds, lint, Studio/device sessions, installs, dependencies, CI, billable work, Roblox uploads or Experience publishing were run. Rokit/Rojo/Luau remain unavailable. Later user acceptance should cover choosing Fair Lights before enough coins, earning past cheaper prizes, changing targets, claiming/equipping with delayed acknowledgements, coin shapes on phone sizes, queue positions one through four, turn expiry, Details, explicit Listen and actual indoor camera/device/multiplayer behavior.

Neither `C:/Users/slavd/OneDrive/Pictures/Assets` nor its `/mnt/c/...` counterpart was available at the start of this visual pass. Existing approved art, native glyphs and palette were preserved. No asset file, production stage or canonical binding changed. Remaining art and acceptance stay in [issue #25](https://github.com/slafftrosheen/BeatMakka/issues/25).
