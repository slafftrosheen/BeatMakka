-- Additive schema-2 field. No client award flags, genre locks or global restoration.
local Book = require(script.Parent.BeatBook)
local Pattern = require(script.Parent.Pattern)
local Quay = {}
Quay.Order = {}
for i = 0, 12 do
    table.insert(Quay.Order, string.format("NQ-Q%02d", i))
end

function Quay.sanitize(raw)
    raw = if type(raw) == "table" then raw else {}
    local result = { parking = "P1", completed = {}, dock = {}, market = {}, repair = 0, sort = 0 }
    if raw.parking == "P2" or raw.parking == "P3" or raw.parking == "P4" then
        result.parking = raw.parking
    end
    for _, id in Quay.Order do
        result.completed[id] = type(raw.completed) == "table" and raw.completed[id] == true
    end
    for i = 1, 3 do
        result.dock[i] = type(raw.dock) == "table" and raw.dock[i] == true
        result.market[i] = type(raw.market) == "table" and raw.market[i] == true
    end
    for _, key in { "repair", "sort" } do
        result[key] = if Pattern.integer(raw[key], 0, 3) then raw[key] else 0
    end
    return result
end

function Quay.equal(a, b)
    a, b = Quay.sanitize(a), Quay.sanitize(b)
    if a.parking ~= b.parking or a.repair ~= b.repair or a.sort ~= b.sort then
        return false
    end
    for _, id in Quay.Order do
        if a.completed[id] ~= b.completed[id] then
            return false
        end
    end
    for i = 1, 3 do
        if a.dock[i] ~= b.dock[i] or a.market[i] ~= b.market[i] then
            return false
        end
    end
    return true
end

function Quay.rhythm(pattern, sample)
    local steps, count = {}, 0
    for pad = 1, 16 do
        if pattern.assignments[pad] == sample and not pattern.muted[pad] then
            for step = 1, 16 do
                if pattern.rows[pad][step] then
                    steps[step] = true
                end
            end
        end
    end
    for _ in steps do
        count += 1
    end
    return steps, count
end

function Quay.evidence(profile)
    local metal, reply = false, false
    for _, pattern in profile.slots do
        local _, count = Quay.rhythm(pattern, "metal_hit")
        metal = metal or count >= 4
        local steps, hits = Quay.rhythm(pattern, "robot_chirp")
        reply = reply or (hits == 4 and steps[1] and steps[5] and steps[9] and steps[13])
    end
    local saved, variation = false, false
    for _, entry in (profile.saved and profile.saved.shelf) or {} do
        if type(entry) ~= "table" then
            continue
        end
        local a, b = entry.slots[1], entry.slots[2]
        for _, pattern in entry.slots do
            saved = saved or Book.hasPlayableNotes(pattern)
        end
        variation = variation
            or (
                Book.hasPlayableNotes(a)
                and Book.hasPlayableNotes(b)
                and not Book.samePattern(a, b)
            )
    end
    return {
        metal = metal and profile.unlocked.I01 == true,
        reply = reply and profile.unlocked.I03 == true,
        saved = saved,
        variation = variation,
    }
end

function Quay.readyForFinale(profile)
    local completed = Quay.sanitize(profile.quay).completed
    for _, n in { 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11 } do
        if not completed[string.format("NQ-Q%02d", n)] then
            return false
        end
    end
    return true
end
return Quay
