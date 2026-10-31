-- Only ProfileStore evaluates rewards against a captured, successfully saved shelf.
local Missions = {
    Order = { "metal_pulse", "vent_duet", "helper_reply" },
    Definitions = {
        metal_pulse = {
            title = "A pulse for the quay",
            objective = "Collect Quay metal. Put it on two different unmuted steps and save a beat to the shelf.",
            reward = "Quay pulse light repaired.",
        },
        vent_duet = {
            title = "An alley duet",
            objective = "Collect Vent thump. Save a pattern with audible metal and vent notes together.",
            reward = "Alley duet light repaired.",
        },
        helper_reply = {
            title = "A reply for Mica",
            objective = "Collect Helper chirp. Save two patterns with different audible chirp rhythms.",
            reward = "Helper reply light repaired.",
        },
    },
}

function Missions.sanitize(raw)
    raw = if type(raw) == "table" then raw else {}
    local result = {}
    local previous = true
    for _, id in Missions.Order do
        result[id] = previous and raw[id] == true
        previous = result[id]
    end
    return result
end

function Missions.equal(a, b)
    a, b = Missions.sanitize(a), Missions.sanitize(b)
    for _, id in Missions.Order do
        if a[id] ~= b[id] then
            return false
        end
    end
    return true
end

function Missions.merge(a, b)
    a, b = Missions.sanitize(a), Missions.sanitize(b)
    for _, id in Missions.Order do
        a[id] = a[id] or b[id]
    end
    return a
end

local function rhythm(pattern, sample)
    local steps = table.create(16, "0")
    for pad = 1, 16 do
        if pattern.assignments[pad] == sample and not pattern.muted[pad] then
            for step = 1, 16 do
                if pattern.rows[pad][step] == true then
                    steps[step] = "1"
                end
            end
        end
    end
    local count = 0
    for _, on in steps do
        if on == "1" then
            count += 1
        end
    end
    return table.concat(steps), count
end

function Missions.awarded(snapshot)
    local result = Missions.sanitize(snapshot.neighborhood)
    if not snapshot.quest.accepted then
        return result
    end
    local metal, duet = false, false
    local chirps = {}
    for _, entry in snapshot.shelf do
        if not entry then
            continue
        end
        for _, pattern in entry.slots do
            local _, metalCount = rhythm(pattern, "metal_hit")
            local _, ventCount = rhythm(pattern, "vent_thump")
            local chirp, chirpCount = rhythm(pattern, "robot_chirp")
            metal = metal or metalCount >= 2
            duet = duet or (metalCount > 0 and ventCount > 0)
            if chirpCount > 0 then
                chirps[chirp] = true
            end
        end
    end
    local variations = 0
    for _ in chirps do
        variations += 1
    end
    local unlocked = snapshot.unlocked
    result.metal_pulse = result.metal_pulse or (unlocked.I01 == true and metal)
    result.vent_duet = result.vent_duet
        or (result.metal_pulse and unlocked.I01 == true and unlocked.I02 == true and duet)
    result.helper_reply = result.helper_reply
        or (result.vent_duet and unlocked.I03 == true and variations >= 2)
    return result
end

function Missions.summary(profile)
    local earned = Missions.sanitize(profile.neighborhood)
    local completed, nextId = 0, nil
    for _, id in Missions.Order do
        if earned[id] then
            completed += 1
        elseif not nextId then
            nextId = id
        end
    end
    local courtReady = completed == 3 and profile.quest.completed
    return {
        earned = earned,
        completed = completed,
        nextId = nextId,
        courtReady = courtReady,
        objective = if not profile.quest.accepted
            then "Meet Mica to begin the neighborhood jobs."
            elseif nextId then Missions.Definitions[nextId].objective
            elseif
                not courtReady
            then "Finish Mica's original courtyard request to prepare this section's concert."
            elseif
                profile.chapter and profile.chapter.completed == true
            then "Your chapter set restored this courtyard. Keep making music; other chapters are ahead."
            else "This courtyard is ready. Visit the Chapter concert prompt beside the listening podium to perform your own set.",
    }
end

return Missions
