local Catalog = require(script.Parent.SampleCatalog)
local Book = require(script.Parent.BeatBook)
local Quest = { Id = "first_courtyard_set", Title = "A tune for the quay" }

function Quest.sanitize(raw)
    local completed = type(raw) == "table" and raw.completed == true
    return {
        accepted = completed or (type(raw) == "table" and raw.accepted == true),
        completed = completed,
    }
end

function Quest.discoveryCount(profile)
    local count = 0
    for _, id in { "I01", "I02", "I03" } do
        if profile.unlocked[id] then
            count += 1
        end
    end
    return count
end

function Quest.usesQuaySound(pattern)
    for pad, id in pattern.assignments do
        local sample = Catalog.ById[id]
        if sample and sample.discovery and not pattern.muted[pad] then
            for _, enabled in pattern.rows[pad] do
                if enabled then
                    return true
                end
            end
        end
    end
    return false
end

function Quest.canPerform(profile, pattern)
    return profile.quest.accepted
        and not profile.quest.completed
        and Quest.discoveryCount(profile) == 3
        and Quest.usesQuaySound(pattern)
        and Book.savedPattern(profile, pattern)
end

function Quest.summary(profile)
    local result = {
        id = Quest.Id,
        title = Quest.Title,
        accepted = profile.quest.accepted,
        completed = profile.quest.completed,
        collected = Quest.discoveryCount(profile),
    }
    if result.completed then
        result.stage = "complete"
        result.objective =
            "Your first courtyard set is complete. Make another beat whenever you like."
    elseif not result.accepted then
        result.stage = "meet"
        result.objective = "Meet Mica, the helper robot in the sound alley."
    elseif result.collected < 3 then
        result.stage = "discover"
        result.objective =
            string.format("Collect the metal, vent and robot sounds: %d/3.", result.collected)
    else
        local ready = false
        for _, pattern in profile.slots do
            ready = ready or Quest.canPerform(profile, pattern)
        end
        result.stage = if ready then "perform" else "save"
        result.objective = if ready
            then "Choose your saved quay-sound pattern, then share one full loop at the courtyard podium."
            else "Put a collected sound on an unmuted step, then save your beat to the shelf."
    end
    return result
end

return Quest
