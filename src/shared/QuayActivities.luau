-- Small authored activities; all progress is awarded by the server.
local Activities = {}

Activities.Order = { "memory_walk", "sound_safari", "pattern_bench", "sleeve_studio" }
Activities.ById = {
    memory_walk = {
        id = "memory_walk",
        title = "Nell's memory postcards",
        host = "Nell Fen",
        location = "Warm Current Cafe, Ferry Office and Lantern Room",
        description = "Find three little memories of the quay. Each neighbour remembers a different part of the same evening.",
        reward = "Listener progress and a keepsake pin",
        kind = "Explore + story",
    },
    sound_safari = {
        id = "sound_safari",
        title = "A pocketful of the quay",
        host = "Mica",
        location = "Dockside Exchange, Repair Alley and Breakwater Steps",
        description = "Collect Quay metal, Vent thump and Helper chirp. Try their different voices in your own beat.",
        reward = "Listener progress and a sound-collector bag",
        kind = "Sound discovery",
    },
    pattern_bench = {
        id = "pattern_bench",
        title = "Ivo's pattern bench",
        host = "Ivo",
        location = "Outside Morrow Repairs",
        description = "Work out what comes next in three little repeating patterns. Take your time; wrong guesses never erase your progress.",
        reward = "Beatmaker progress and a workshop keepsake",
        kind = "Untimed puzzle",
        building = "NQ-BLD-03",
    },
    sleeve_studio = {
        id = "sleeve_studio",
        title = "Your first record sleeve",
        host = "Naya",
        location = "Outside Needle Records",
        description = "Give your music a cover. Choose a printed motif and a colour, then keep it in your journal.",
        reward = "Neighbour progress and a record-maker keepsake",
        kind = "Make + customise",
        building = "NQ-BLD-02",
    },
}
Activities.Memories = {
    {
        id = "cafe",
        building = "NQ-BLD-06",
        title = "The extra cup",
        speaker = "Nell",
        text = "I used to put out one extra cup. Someone always brought a friend. The music stopped slowly; I think I stopped putting out the cup first.",
        after = "There is an extra cup again. You do not need to bring a crowd to be welcome.",
    },
    {
        id = "ferry",
        building = "NQ-BLD-07",
        title = "A ticket used as a bookmark",
        speaker = "A note from Tori",
        text = "Last ferry, front-row seat. We saved a chair for whoever finished work last. Nobody had to arrive on time to belong.",
        after = "The old ticket is tucked beside a new invitation: come when you can.",
    },
    {
        id = "lantern",
        building = "NQ-BLD-01",
        title = "The open-call card",
        speaker = "Ronan",
        text = "It says 'Bring a sound. Leave a little room.' I kept the card because I wasn't ready to throw that idea away.",
        after = "Ronan has written a second line: 'There is room for your next sound, too.'",
    },
}
Activities.MemoryById = {}
Activities.Buildings = {}
for _, memory in Activities.Memories do
    Activities.MemoryById[memory.id] = memory
    Activities.Buildings[memory.building] = true
end
for _, activity in Activities.ById do
    if activity.building then
        Activities.Buildings[activity.building] = true
    end
end
Activities.Motifs = {
    { id = "waves", label = "River waves", glyph = "WAVES" },
    { id = "lantern", label = "A welcoming light", glyph = "LANTERN" },
    { id = "steps", label = "Sixteen little steps", glyph = "STEPS" },
}
Activities.Palettes = {
    { id = "teal", label = "Workshop teal" },
    { id = "coral", label = "Faded coral" },
    { id = "amber", label = "Lantern amber" },
}
Activities.Dedications = { curiosity = true, together = true, beginnings = true }

local function contains(list, id)
    for _, item in list do
        if item.id == id then
            return true
        end
    end
    return false
end

function Activities.supported(raw)
    return raw == nil or (type(raw) == "table" and (raw.version == nil or raw.version == 1))
end

function Activities.validSleeve(motif, palette)
    return type(motif) == "string"
        and type(palette) == "string"
        and contains(Activities.Motifs, motif)
        and contains(Activities.Palettes, palette)
end

function Activities.sanitize(raw)
    raw = if type(raw) == "table" then raw else {}
    local result = {
        version = 1,
        memories = {},
        activities = {},
        dedication = "together",
        sleeve = { motif = "waves", palette = "teal" },
    }
    for _, memory in Activities.Memories do
        result.memories[memory.id] = type(raw.memories) == "table"
            and raw.memories[memory.id] == true
    end
    for _, id in Activities.Order do
        result.activities[id] = type(raw.activities) == "table" and raw.activities[id] == true
    end
    if type(raw.dedication) == "string" and Activities.Dedications[raw.dedication] then
        result.dedication = raw.dedication
    end
    if
        type(raw.sleeve) == "table" and Activities.validSleeve(raw.sleeve.motif, raw.sleeve.palette)
    then
        result.sleeve = { motif = raw.sleeve.motif, palette = raw.sleeve.palette }
    end
    return result
end

function Activities.equal(a, b)
    a, b = Activities.sanitize(a), Activities.sanitize(b)
    if
        a.dedication ~= b.dedication
        or a.sleeve.motif ~= b.sleeve.motif
        or a.sleeve.palette ~= b.sleeve.palette
    then
        return false
    end
    for _, id in Activities.Order do
        if a.activities[id] ~= b.activities[id] then
            return false
        end
    end
    for _, memory in Activities.Memories do
        if a.memories[memory.id] ~= b.memories[memory.id] then
            return false
        end
    end
    return true
end

function Activities.reconcile(profile)
    local experience = profile.experience
    local changed = false
    local allMemories = true
    for _, memory in Activities.Memories do
        allMemories = allMemories and experience.memories[memory.id] == true
    end
    local allSounds = profile.unlocked.I01 and profile.unlocked.I02 and profile.unlocked.I03
    for id, ready in { memory_walk = allMemories, sound_safari = allSounds == true } do
        if ready and not experience.activities[id] then
            experience.activities[id] = true
            changed = true
        end
    end
    return changed
end

return Activities
