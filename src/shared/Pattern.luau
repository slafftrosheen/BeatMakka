local Catalog = require(script.Parent.SampleCatalog)
local Pattern = { Pads = 16, Steps = 16, MinBpm = 60, MaxBpm = 180 }

function Pattern.integer(value, minimum, maximum)
    return type(value) == "number"
        and value == value
        and value % 1 == 0
        and value >= minimum
        and value <= maximum
end

function Pattern.new()
    local pattern = { bpm = 96, rows = {}, assignments = {}, muted = {} }
    for pad = 1, 16 do
        pattern.rows[pad] = table.create(16, false)
        pattern.assignments[pad] = Catalog.List[pad].id
        pattern.muted[pad] = false
    end
    return pattern
end

function Pattern.sanitize(raw, unlocked)
    local result = Pattern.new()
    if type(raw) ~= "table" then
        return result
    end
    if Pattern.integer(raw.bpm, Pattern.MinBpm, Pattern.MaxBpm) then
        result.bpm = raw.bpm
    end
    for pad = 1, 16 do
        if type(raw.rows) == "table" and type(raw.rows[pad]) == "table" then
            for step = 1, 16 do
                result.rows[pad][step] = raw.rows[pad][step] == true
            end
        end
        if
            type(raw.assignments) == "table"
            and type(raw.assignments[pad]) == "string"
            and Catalog.isUnlocked(raw.assignments[pad], unlocked)
        then
            result.assignments[pad] = raw.assignments[pad]
        end
        result.muted[pad] = type(raw.muted) == "table" and raw.muted[pad] == true
    end
    return result
end

function Pattern.hasNotes(pattern)
    for _, row in pattern.rows do
        for _, enabled in row do
            if enabled then
                return true
            end
        end
    end
    return false
end

function Pattern.stepDuration(bpm)
    return 60 / bpm / 4
end

function Pattern.position(bpm, startedAt, now)
    local absolute = math.floor((now - startedAt) / Pattern.stepDuration(bpm))
    return absolute, absolute % Pattern.Steps + 1
end
return Pattern
