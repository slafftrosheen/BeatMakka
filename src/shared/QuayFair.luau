-- Bounded local fair economy. Free skill games; no purchases, random rewards or transfers.
local Fair = {
    Games = { "targets", "bells", "rings" },
    Heats = 3,
    CoinsPerHeat = 10,
    DemoSeconds = 90,
    RoundSeconds = 45,
    Windows = { targets = 2.6, bells = 1.6 },
    RingPeriod = 2.4,
    RingLow = 0.35,
    RingHigh = 0.65,
    PrizePosition = Vector3.new(624, 2, -21),
    Prizes = {
        { id = "fair_friend", category = "title", label = "FAIR FRIEND", icon = "badge", cost = 20 },
        { id = "fair_bell", category = "companion", label = "BEAT BELL", icon = "bell", cost = 30 },
        { id = "fair_glow", category = "roamer", label = "FAIR LIGHTS", icon = "van", cost = 40 },
    },
}
function Fair.find(id)
    for _, prize in Fair.Prizes do
        if prize.id == id then return prize end
    end
    return nil
end
function Fair.isGame(id)
    return table.find(Fair.Games, id) ~= nil
end
function Fair.sanitize(raw)
    raw = if type(raw) == "table" then raw else {}
    local value = { clears = {}, prizes = {} }
    for _, id in Fair.Games do
        local count = type(raw.clears) == "table" and raw.clears[id]
        value.clears[id] = if type(count) == "number" and count == count
            then math.clamp(math.floor(count), 0, Fair.Heats) else 0
    end
    local earned, spent = 0, 0
    for _, count in value.clears do earned += count * Fair.CoinsPerHeat end
    -- A corrupt/old payload cannot manufacture ownership beyond its earned coins.
    for _, prize in Fair.Prizes do
        if type(raw.prizes) == "table" and raw.prizes[prize.id] == true
            and spent + prize.cost <= earned then
            value.prizes[prize.id] = true
            spent += prize.cost
        end
    end
    return value
end
function Fair.equal(a, b)
    a, b = Fair.sanitize(a), Fair.sanitize(b)
    for _, id in Fair.Games do if a.clears[id] ~= b.clears[id] then return false end end
    for _, prize in Fair.Prizes do if a.prizes[prize.id] ~= b.prizes[prize.id] then return false end end
    return true
end
function Fair.summary(raw)
    local value = Fair.sanitize(raw)
    local earned, spent = 0, 0
    for _, count in value.clears do earned += count * Fair.CoinsPerHeat end
    for _, prize in Fair.Prizes do if value.prizes[prize.id] then spent += prize.cost end end
    return { clears = value.clears, prizes = value.prizes, earned = earned, balance = earned - spent }
end
return Fair
