local Music = require(script.Parent.QuayMusicEvidence)
-- Only ProfileStore evaluates rewards against captured, successfully saved music.
local Missions = {
    Order = { "metal_pulse", "vent_duet", "helper_reply" },
    Definitions = {
        metal_pulse = {
            title = "A pulse for the quay",
            objective = "Collect Quay metal. Put it on two different unmuted steps and save the named sequence.",
            reward = "Quay pulse light repaired.",
        },
        vent_duet = {
            title = "An alley duet",
            objective = "Collect Vent thump. Save a sequence with audible metal and vent notes together.",
            reward = "Alley duet light repaired.",
        },
        helper_reply = {
            title = "A reply for Mica",
            objective = "Collect Helper chirp. Save two sequences with different audible chirp rhythms.",
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

function Missions.awarded(snapshot)
    local result = Missions.sanitize(snapshot.neighborhood)
    if not snapshot.quest.accepted then
        return result
    end
    -- Snapshot is captured by ProfileStore only after a successful storage write.
    local profile = {
        saved = { music = snapshot.music },
        music = snapshot.music,
        unlocked = snapshot.unlocked,
    }
    local metal, duet, chirps = false, false, {}
    for _, evidence in Music.savedSequences(profile) do
        local positions = evidence.positions
        local count = 0
        for _ in positions.I01 or {} do
            count += 1
        end
        metal = metal or count >= 2
        duet = duet or (count > 0 and next(positions.I02 or {}) ~= nil)
        local ticks = {}
        for tick in positions.I03 or {} do
            table.insert(ticks, tick)
        end
        table.sort(ticks)
        if #ticks > 0 then
            chirps[table.concat(ticks, ",")] = true
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
            else "This courtyard is ready. Visit the Chapter concert prompt beside the listening podium to perform your own finished song.",
    }
end

return Missions
