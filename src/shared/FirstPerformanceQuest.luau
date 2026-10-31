local Music = require(script.Parent.QuayMusicEvidence)
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

function Quest.usesQuaySound(evidence)
    return evidence ~= nil and evidence.discovery == true
end

function Quest.canPerform(profile, reference)
    if
        not profile.quest.accepted
        or profile.quest.completed
        or Quest.discoveryCount(profile) < 3
    then
        return false
    end
    -- This remains an optional single-loop activity, separate from Finished Songs.
    if
        type(reference) ~= "table"
        or (reference.kind ~= "sequence" and reference.kind ~= "Sequence")
        or type(reference.id) ~= "string"
        or type(reference.revision) ~= "number"
        or reference.revision ~= reference.revision
        or reference.revision % 1 ~= 0
        or reference.revision < 1
        or reference.revision > 1e12
    then
        return false
    end
    for _, evidence in Music.savedSequences(profile) do
        if
            evidence.id == reference.id
            and evidence.sequence.revision == reference.revision
            and Quest.usesQuaySound(evidence)
        then
            return true
        end
    end
    return false
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
        for _, evidence in Music.savedSequences(profile) do
            local sequence = profile.music and profile.music.project.sequences[evidence.id]
            ready = ready
                or Quest.canPerform(profile, {
                    kind = "sequence",
                    id = evidence.id,
                    revision = sequence and sequence.revision,
                })
        end
        result.stage = if ready then "perform" else "save"
        result.objective = if ready
            then "Choose a saved quay-sound sequence, then share one full loop at the courtyard podium."
            else "Put a ready collected sound in a named sequence, then Save Sequence and wait for confirmation."
    end
    return result
end

return Quest
