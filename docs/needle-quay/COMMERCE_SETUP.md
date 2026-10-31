# Needle Quay cosmetic shop

Status: local implementation, sales disabled. No pass, avatar asset, place, image or audio has been uploaded or published by this change. No Roblox runtime or purchase acceptance is implied.

The repository's 2026-10-25 deployment instruction applies: production later uses the user's designated adult account under fresh explicit deployment authorization. The current testing account must not publish the experience or its assets.

## Product contract

Needle Quay sells permanent, guaranteed cosmetic sets for use inside BeatMakka. The main story, musical tools, side activities, companion relationships and RPG advancement remain available through play. Premium items give no XP, performance-score, progression or movement advantage.

The demo contains no paid random items, currency purchases, consumable retries, subscription, trading or gifting. Earned and starter wardrobe items remain available alongside the optional sets. The wardrobe saves experience-specific item IDs; a bundle does not grant ownership of a Roblox Marketplace avatar item.

| Bundle ID | Proposed default price | Guaranteed item IDs |
| --- | ---: | --- |
| `harbor_afterglow` | 99 Robux | `afterglow_headphones`, `afterglow_scarf`, `afterglow_badge` |
| `workshop_weekend` | 99 Robux | `weekend_earmuffs`, `weekend_satchel`, `weekend_patch` |

Prices are proposals for later product setup, not current purchase offers. The shop never renders `ProposedDefaultPrice`. It requests the player's actual price from Roblox.

The local deterministic accessory geometry is an implementation candidate. `AssetsApproved = false` is intentional. The shop lists contents; it does not pretend that a mannequin preview or final art review exists.

## Implementation boundaries

- `src/shared/CommerceCatalog.luau` defines the two bundles, item IDs and closed production configuration.
- `src/server/CommerceService.luau` checks pass ownership and exposes verified entitlements to wardrobe services.
- `src/client/QuayShopPanel.luau` renders the journal Shop content, reads personalized prices and opens a native purchase prompt only after the player presses Buy.
- `src/shared/WardrobeCatalog.luau` defines the actual accessories and their matching `bundle` IDs.
- `WardrobeService` must consume `commerce:verified(player)` on the server. No profile field or client-supplied ownership value is purchase evidence.

`CommerceService.new(profiles, changedCallback, notifyCallback)` invokes `changedCallback(player)` when its summary changes. The host should send a fresh profile summary and update wardrobe availability. `notifyCallback(player, message)` reports a newly verified purchase. Call `load(player)` after the profile is ready, `refresh(player)` when the player explicitly reopens the Shop, `remove(player)` on departure, and `destroy()` during teardown.

`summary(player)` returns `{ enabled, status, owned, bundles }`. Each `bundles[bundleId]` includes `status` and `available`. `verified(player)` returns a copy of the server-verified bundle map. It never persists ownership claims in the player save. Roblox remains the source of pass ownership, including purchases made outside the running session.

The panel API is `QuayShopPanel.new(parent, refreshOwnership)`, `panel:update(summary.commerce)`, `panel:destroy()`. The optional refresh callback should send the host's allowlisted `LifeRefreshShop` command; it never opens a purchase prompt. Put the panel inside the existing journal's scrolling Shop tab. Do not turn its proposed prices into static badges or buttons elsewhere in the UI.

## Ownership flow

1. After a successful profile load, the server checks each approved and configured pass through `UserOwnsGamePassAsync`.
2. While checking or after an unresolved error, a bundle cannot open a new purchase prompt.
3. A native `PromptGamePassPurchaseFinished` event on the server triggers another ownership check. It does not accept a client entitlement report.
4. A successful ownership query adds the bundle to the server's session map. The wardrobe derives item access from that map.
5. Failed lookups and post-purchase propagation delays receive at most two delayed retries. Stale replies from superseded checks or departed players are discarded.
6. Reopening the Shop can explicitly refresh ownership; server refresh calls are bounded per bundle. Rejoining restores permanent access from Roblox.

An already verified permanent pass stays available for the rest of the session if a subsequent check fails. Disabling the sales switch does not erase existing entitlements: valid production bindings still allow ownership checks. Removing a pass binding or its item definition is not a refund system; do not delete bindings for sold products.

The client never marks a purchase owned from the purchase prompt's result. Its confirmation view waits for a new server summary. Unresolved verification exposes an explicit Check ownership again action, including when a later lookup still reports no ownership; Buy remains blocked for that reported purchase until ownership is resolved or the player rejoins. Cancellation retains the player's current appearance and does not automatically reopen the prompt.

## Opening sales later

These are future release steps, not authorization to perform them now.

1. Obtain the user's explicit production deployment authorization and designated eligible account/group. Review actual account rights; do not infer them from a configured numeric ID.
2. Review and accept every listed accessory on the supported avatars and devices. The list of delivered items must match the bundle description.
3. Create two permanent passes in the intended production experience. Do not use developer products for these one-time sets.
4. Set `ProductionGameId` to the **universe ID** (`game.GameId`), `ProductionCreatorId` to the intended owner ID, and `ProductionCreatorType` to `"User"` or `"Group"`.
5. Set each real `PassId` and only then mark its `AssetsApproved = true`. Duplicate pass IDs and item/bundle mismatches are rejected by the catalog.
6. Verify ownership restoration, cancellation, purchase completion, regional price display and unavailable-service behavior in the authorized environment.
7. Set `Enabled = true` only when the shop is intended to accept purchases.

The runtime requires a matching universe and creator, approved bundle contents, a valid positive pass ID and the global sales switch before offering a purchase. Studio never opens sales. This prevents a copied configuration from opening purchases in the current testing experience. The gate is an engineering guard; it does not certify account eligibility or replace Roblox's native purchase controls.

## Pricing and official APIs

The client calls `MarketplaceService:GetProductInfoAsync(passId, Enum.InfoType.GamePass)` and uses `PriceInRobux` only when `IsForSale` is true and the price is valid. Price lookup failure disables Buy and exposes a retry. If the cached price is older than one minute when Buy is pressed, the panel refreshes it and requires another explicit click after review. The native Roblox purchase window supplies the final confirmation.

Roblox's current API reference marks `GetProductInfo` deprecated, although some tutorial examples still use it. Managed regional pricing is enabled by default for passes; hardcoded default prices can therefore disagree with checkout. Query pricing on the client for the current player.

References checked 2026-10-30:

- [Passes](https://create.roblox.com/docs/production/monetization/passes)
- [MarketplaceService API](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService)
- [Regional pricing](https://create.roblox.com/docs/production/monetization/regional-pricing)
- [Avatar Editor Service](https://create.roblox.com/docs/players/avatar-editor)

## Future developer products

There are no developer products or receipt callbacks in this demo. If a repeatable paid product is approved later, add one central server receipt processor and a trusted product-ID map. Do not grant a developer product from `PromptProductPurchaseFinished`.

The grant and its `PurchaseId` deduplication record must be durable before returning `PurchaseGranted`. Unknown products, profile unavailability and failed writes remain unresolved for retry. Use the project's actual profile/session ownership mechanism; do not add an unrelated purchase store that can acknowledge a receipt before the player grant is committed. Retryable data-store callbacks must have no external side effects and cannot yield.

References:

- [Developer products](https://create.roblox.com/docs/production/monetization/developer-products)
- [Data stores](https://create.roblox.com/docs/cloud-services/data-stores)
- [GlobalDataStore UpdateAsync](https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore)

No paid randomness is planned. If that changes, Roblox's [paid random item rules](https://create.roblox.com/docs/production/monetization/paid-random-items) also cover indirect purchases through Robux-funded currency and require outcome disclosures and per-player restrictions. That would require a separate product decision and implementation.

## Pending release acceptance

This is a future acceptance list. It has not been run as part of this source change.

- Full demo completion and earned outfits without spending Robux.
- Owned pass restoration after rejoin and purchases made outside the session.
- No entitlement from forged client ownership, arbitrary item IDs or arbitrary pass IDs.
- Correct item availability after server verification, including respawn.
- Native purchase cancellation, lookup failure, unavailable price, unavailable profile and rapid repeated clicks.
- Regional/personalized displayed price agrees with the native prompt.
- Closed sales on Studio, the wrong universe/creator, missing pass IDs, duplicate IDs, unapproved art and missing item definitions.
- Safe retry after a post-purchase ownership error, without duplicate purchase prompts.
- No sold item is removed by a routine catalog update.

The Windows user material directory named in `AGENTS.md` was not available in this Linux workspace. The panel reuses the existing code-defined `Theme` and `GuiFactory` and adds no external visual assets.
