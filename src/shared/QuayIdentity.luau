-- Server-authored milestone ledger. XP is derived from bounded, unique events;
-- clients never supply XP, grants, ownership, or arbitrary reward identifiers.
local Wardrobe = require(script.Parent.WardrobeCatalog)
local Identity = {
    Version = 1,
    TrackOrder = { "listener", "beatmaker", "neighbour" },
    TrackLabels = { listener = "Listener", beatmaker = "Beatmaker", neighbour = "Neighbour" },
    TrackLevels = { 0, 30, 75, 130 },
    TrackLevelLabels = { "Curious", "Practising", "Finding your voice", "Quay regular" },
    Ranks = {
        { xp = 0, label = "New Voice" },
        { xp = 70, label = "Quay Regular" },
        { xp = 180, label = "Beat Explorer" },
        { xp = 340, label = "Neighbourhood Artist" },
        { xp = 500, label = "Lantern Resident" },
    },
    TitleOrder = { "new_voice", "sound_scout", "beat_builder", "good_neighbour", "quay_original" },
    Titles = {
        new_voice = { label = "New Voice" },
        sound_scout = { label = "Sound Scout", track = "listener", minimumXP = 75 },
        beat_builder = { label = "Beat Builder", track = "beatmaker", minimumXP = 75 },
        good_neighbour = { label = "Good Neighbour", track = "neighbour", minimumXP = 75 },
        quay_original = { label = "Quay Original", award = "quest:NQ-Q12" },
    },
    Awards = {
        ["quest:NQ-Q00"] = { neighbour = 10 },
        ["quest:NQ-Q01"] = { neighbour = 20 },
        ["quest:NQ-Q02"] = { beatmaker = 30 },
        -- An invitation or a skip is not musical evidence and earns no XP.
        ["quest:NQ-Q03"] = {},
        ["quest:NQ-Q04"] = { neighbour = 20, listener = 10 },
        ["quest:NQ-Q05"] = { beatmaker = 40 },
        ["quest:NQ-Q06"] = { listener = 30 },
        ["quest:NQ-Q07"] = { beatmaker = 20 },
        ["quest:NQ-Q08"] = { neighbour = 30 },
        ["quest:NQ-Q09"] = { listener = 30 },
        ["quest:NQ-Q10"] = { neighbour = 25 },
        ["quest:NQ-Q11"] = { neighbour = 20 },
        ["quest:NQ-Q12"] = { listener = 20, beatmaker = 30, neighbour = 30 },
        ["discovery:I01"] = { listener = 20 },
        ["discovery:I02"] = { listener = 20 },
        ["discovery:I03"] = { listener = 20 },
        ["activity:memory_walk"] = { listener = 30, neighbour = 10 },
        ["activity:sound_safari"] = { listener = 30, beatmaker = 10 },
        ["activity:pattern_bench"] = { beatmaker = 40 },
        ["activity:sleeve_studio"] = { beatmaker = 10, neighbour = 20 },
    },
}

local function outfit(raw)
    local result = {}
    if type(raw) == "table" then
        for _, slot in Wardrobe.Slots do
            local id = raw[slot]
            local item = type(id) == "string" and Wardrobe.Items[id]
            if item and item.slot == slot then
                result[slot] = id
            end
        end
    end
    return result
end

local function sameOutfit(a, b)
    for _, slot in Wardrobe.Slots do
        if a[slot] ~= b[slot] then
            return false
        end
    end
    return true
end

function Identity.supported(raw)
    return raw == nil
        or (type(raw) == "table" and (raw.version == nil or raw.version == Identity.Version))
end

function Identity.sanitize(raw)
    raw = if type(raw) == "table" then raw else {}
    local result = {
        version = Identity.Version,
        awards = {},
        equipped = outfit(raw.equipped),
        -- Dense arrays preserve all three appearance presets, even if slot 3 is used first.
        outfits = { false, false, false },
        title = "new_voice",
    }
    for id in Identity.Awards do
        if type(raw.awards) == "table" and raw.awards[id] == true then
            result.awards[id] = true
        end
    end
    if type(raw.outfits) == "table" then
        for index = 1, Wardrobe.OutfitCapacity do
            if type(raw.outfits[index]) == "table" then
                result.outfits[index] = outfit(raw.outfits[index])
            end
        end
    end
    if type(raw.title) == "string" and Identity.Titles[raw.title] then
        result.title = raw.title
    end
    return result
end

function Identity.equal(a, b)
    a, b = Identity.sanitize(a), Identity.sanitize(b)
    if a.title ~= b.title or not sameOutfit(a.equipped, b.equipped) then
        return false
    end
    for id in Identity.Awards do
        if a.awards[id] ~= b.awards[id] then
            return false
        end
    end
    for index = 1, Wardrobe.OutfitCapacity do
        local left, right = a.outfits[index], b.outfits[index]
        if type(left) ~= type(right) or (type(left) == "table" and not sameOutfit(left, right)) then
            return false
        end
    end
    return true
end

local function experience(identity)
    local totals = { listener = 0, beatmaker = 0, neighbour = 0 }
    for id, points in Identity.Awards do
        if identity.awards[id] then
            for track, amount in points do
                totals[track] += amount
            end
        end
    end
    return totals
end

local function earned(definition, identity, totals)
    if definition.award then
        return identity.awards[definition.award] == true
    elseif definition.track then
        return totals[definition.track] >= definition.minimumXP
    end
    return true
end

local function ownership(identity, totals, verifiedPasses)
    local owned = {}
    for id, item in Wardrobe.Items do
        owned[id] = if item.source == "premium"
            then type(verifiedPasses) == "table" and verifiedPasses[item.bundle] == true
            else earned(item, identity, totals)
    end
    return owned
end

local function activeOutfit(selected, owned)
    local result = {}
    for _, slot in Wardrobe.Slots do
        local id = selected[slot]
        if id and owned[id] then
            result[slot] = id
        end
    end
    return result
end

function Identity.reconcile(profile)
    local previous = Identity.sanitize(profile.identity)
    local current = Identity.sanitize(previous)
    local completed = (profile.quay and profile.quay.completed) or {}
    for index = 0, 12 do
        local id = string.format("NQ-Q%02d", index)
        if completed[id] == true then
            current.awards["quest:" .. id] = true
        end
    end
    for _, id in { "I01", "I02", "I03" } do
        if profile.unlocked and profile.unlocked[id] == true then
            current.awards["discovery:" .. id] = true
        end
    end
    local activities = (profile.experience and profile.experience.activities) or {}
    for _, id in { "memory_walk", "sound_safari", "pattern_bench", "sleeve_studio" } do
        if activities[id] == true then
            current.awards["activity:" .. id] = true
        end
    end
    profile.identity = current
    return not Identity.equal(previous, current)
end

function Identity.summary(profile, verifiedPasses)
    local current = Identity.sanitize(profile.identity)
    local totals = experience(current)
    local owned = ownership(current, totals, verifiedPasses)
    local equipped = activeOutfit(current.equipped, owned)
    local tracks, total = {}, 0
    for _, id in Identity.TrackOrder do
        local xp, level = totals[id], 1
        total += xp
        for index, threshold in Identity.TrackLevels do
            if xp >= threshold then
                level = index
            end
        end
        table.insert(tracks, {
            id = id,
            label = Identity.TrackLabels[id],
            xp = xp,
            level = level,
            levelLabel = Identity.TrackLevelLabels[level],
            nextAt = Identity.TrackLevels[level + 1],
        })
    end
    local rank = 1
    for index, definition in Identity.Ranks do
        if total >= definition.xp then
            rank = index
        end
    end
    local titles = {}
    for _, id in Identity.TitleOrder do
        local definition = Identity.Titles[id]
        table.insert(titles, {
            id = id,
            label = definition.label,
            owned = earned(definition, current, totals),
        })
    end
    local title = if earned(Identity.Titles[current.title], current, totals)
        then current.title
        else "new_voice"
    local items = {}
    for _, id in Wardrobe.Order do
        local item = Wardrobe.Items[id]
        table.insert(items, {
            id = id,
            label = item.label,
            slot = item.slot,
            description = item.description,
            source = item.source,
            bundle = item.bundle,
            owned = owned[id],
            equipped = equipped[item.slot] == id,
            unlockHint = item.unlockHint,
        })
    end
    local outfits = {}
    for index = 1, Wardrobe.OutfitCapacity do
        table.insert(outfits, { index = index, saved = type(current.outfits[index]) == "table" })
    end
    return {
        tracks = tracks,
        rank = {
            level = rank,
            label = Identity.Ranks[rank].label,
            xp = total,
            nextAt = Identity.Ranks[rank + 1] and Identity.Ranks[rank + 1].xp,
        },
        title = title,
        titleLabel = Identity.Titles[title].label,
        titles = titles,
        owned = owned,
        equipped = equipped,
        outfits = outfits,
        items = items,
    }
end

function Identity.equip(profile, id, verifiedPasses)
    local item = type(id) == "string" and Wardrobe.Items[id]
    if not item then
        return false, "Choose an item from your wardrobe."
    end
    local current = Identity.sanitize(profile.identity)
    if not ownership(current, experience(current), verifiedPasses)[id] then
        return false, item.unlockHint
    end
    if current.equipped[item.slot] == id then
        return false, item.label .. " is already equipped."
    end
    current.equipped[item.slot] = id
    profile.identity = current
    return true, item.label .. " equipped. Your Roblox avatar stays yours."
end

function Identity.clear(profile, slot)
    if slot ~= "all" and not Wardrobe.validSlot(slot) then
        return false, "Choose a wardrobe slot to clear."
    end
    local current = Identity.sanitize(profile.identity)
    local changed = false
    for _, key in Wardrobe.Slots do
        if (slot == "all" or slot == key) and current.equipped[key] ~= nil then
            current.equipped[key] = nil
            changed = true
        end
    end
    profile.identity = current
    return changed,
        if slot == "all" then "BeatMakka accessories removed." else "Wardrobe slot cleared."
end

local function validOutfitIndex(index)
    return type(index) == "number"
        and index == math.floor(index)
        and index >= 1
        and index <= Wardrobe.OutfitCapacity
end

function Identity.saveOutfit(profile, index)
    if not validOutfitIndex(index) then
        return false, "Choose one of your three outfit slots."
    end
    local current = Identity.sanitize(profile.identity)
    if current.outfits[index] and sameOutfit(current.outfits[index], current.equipped) then
        return false, "That outfit is already kept in this slot."
    end
    current.outfits[index] = outfit(current.equipped)
    profile.identity = current
    return true, "Outfit " .. index .. " kept. All three slots are free."
end

function Identity.loadOutfit(profile, index, verifiedPasses)
    if not validOutfitIndex(index) then
        return false, "Choose one of your three outfit slots."
    end
    local current = Identity.sanitize(profile.identity)
    local saved = current.outfits[index]
    if not saved then
        return false, "Keep an outfit in this slot first."
    end
    local owned = ownership(current, experience(current), verifiedPasses)
    -- Do not delete or partly overwrite a purchased look during an entitlement outage.
    for _, id in saved do
        if not owned[id] then
            return false, "An item in this outfit is not available yet. Your saved outfit is safe."
        end
    end
    if sameOutfit(current.equipped, saved) then
        return false, "You are already wearing this outfit."
    end
    current.equipped = outfit(saved)
    profile.identity = current
    return true, "Outfit " .. index .. " equipped."
end

function Identity.setTitle(profile, id)
    local definition = type(id) == "string" and Identity.Titles[id]
    local current = Identity.sanitize(profile.identity)
    if not definition or not earned(definition, current, experience(current)) then
        return false, "That title is still waiting for its story."
    end
    if current.title == id then
        return false, "That is already your title."
    end
    current.title = id
    profile.identity = current
    return true, "Your title is now " .. definition.label .. "."
end

return Identity
