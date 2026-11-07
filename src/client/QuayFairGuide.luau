-- Suggestions only: the server still owns coins, prices, claims and equipped rewards.
local Fair = require(game.ReplicatedStorage.Shared.QuayFair)
local Guide = {}
function Guide.nextGame(fair, preferred)
    local clears = fair and fair.clears or {}
    if Fair.isGame(preferred) and (clears[preferred] or 0) < Fair.Heats then return preferred end
    for _, id in Fair.Games do
        if (clears[id] or 0) < Fair.Heats then return id end
    end
    return nil
end
function Guide.prize(fair, rewards, preferred)
    if not fair then return nil end
    local target = Fair.find(preferred)
    if target and not fair.prizes[target.id] then
        return if fair.balance >= target.cost then target else nil
    end
    for _, prize in Fair.Prizes do
        if fair.prizes[prize.id] and (rewards or {})[prize.category] ~= prize.id then return prize end
    end
    for _, prize in Fair.Prizes do
        if not fair.prizes[prize.id] and fair.balance >= prize.cost then return prize end
    end
    return nil
end
function Guide.goal(fair, preferred)
    local target = Fair.find(preferred)
    if target and (not fair or not fair.prizes[target.id]) then return target end
    for _, prize in Fair.Prizes do
        if not fair or not fair.prizes[prize.id] then return prize end
    end
    return nil
end
function Guide.afterRound(fair, rewards, current, preferred)
    local prize = Guide.prize(fair, rewards, preferred)
    if prize then return { kind = "prize", prize = prize, icon = prize.icon, caption = "PRIZE" } end
    local gameId = Guide.nextGame(fair, current)
    if gameId then return { kind = "game", id = gameId, caption = if gameId == current then "PLAY" else "NEXT" } end
    return { kind = "done", icon = "door", caption = "DONE" }
end
return Guide
