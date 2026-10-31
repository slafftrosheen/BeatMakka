-- Studio Server probe. Private tables only: no active player progress or cloud writes.
local Shared = game.ReplicatedStorage.Shared
local Profiles = require(game.ServerScriptService.Server.ProfileStore)
local Identity = require(Shared.QuayIdentity)
local Activities = require(Shared.QuayActivities)
local results = {}
local function check(name, action)
    local ok, detail = xpcall(action, debug.traceback)
    table.insert(results, { name = name, passed = ok, detail = tostring(detail or "ok") })
end
local function complete()
    local profile = Profiles.new()
    for index = 0, 12 do
        profile.quay.completed[string.format("NQ-Q%02d", index)] = true
    end
    for _, id in { "I01", "I02", "I03" } do
        profile.unlocked[id] = true
    end
    for _, memory in Activities.Memories do
        profile.experience.memories[memory.id] = true
    end
    for _, id in Activities.Order do
        profile.experience.activities[id] = true
    end
    Identity.reconcile(profile)
    return profile
end
check("Finite first-time ledger totals 575 XP and cannot mint replay XP", function()
    local profile = complete()
    local summary = Identity.summary(profile, {})
    assert(summary.rank.xp == 575, "Full milestone ledger must total 575 XP")
    local expected = { listener = 210, beatmaker = 180, neighbour = 185 }
    for _, track in summary.tracks do
        assert(track.xp == expected[track.id], "Unexpected XP for " .. track.id)
    end
    for _ = 1, 5 do
        Activities.reconcile(profile)
        Identity.reconcile(profile)
    end
    assert(Identity.summary(profile, {}).rank.xp == 575, "Reconciliation awarded duplicate XP")
    return "210 Listener + 180 Beatmaker + 185 Neighbour; repeated reconciliation unchanged"
end)
check("Earned history grants canonical cosmetics without creating Finished Songs", function()
    local profile = complete()
    local summary = Identity.summary(profile, {})
    assert(
        summary.owned.lantern_pin and summary.owned.memory_pin and summary.owned.pattern_patch,
        "Earned cosmetics were lost"
    )
    assert(not summary.owned.afterglow_headphones, "Earned history granted a premium cosmetic")
    assert(next(profile.music.finishedSongs) == nil, "Quest history manufactured a Finished Song")
    local ok = Identity.setTitle(profile, "quay_original")
    assert(ok, "Earned chapter title was unavailable")
    return "Earned title and accessories preserved; no premium ownership or phantom songs"
end)
check("Saved looks copy selections independently and enforce ownership", function()
    local profile = complete()
    assert(Identity.equip(profile, "quay_headphones", {}))
    for index = 1, 3 do
        assert(Identity.saveOutfit(profile, index))
    end
    Identity.clear(profile, "head")
    for index = 1, 3 do
        assert(Identity.loadOutfit(profile, index, {}))
        assert(
            Identity.summary(profile, {}).equipped.head == "quay_headphones",
            "Saved look lost its headwear"
        )
        Identity.clear(profile, "head")
    end
    assert(
        not Identity.equip(profile, "afterglow_headphones", {}),
        "Unowned premium item was equipped"
    )
    assert(not Identity.saveOutfit(profile, 4), "A fourth preset exceeded the agreed limit")
    return "Three independent presets; unavailable cosmetics and fourth preset rejected"
end)
local failures = 0
for _, result in results do
    if not result.passed then
        failures += 1
    end
end
return {
    suite = "V3 identity and preservation",
    tests = #results,
    failures = failures,
    results = results,
}
