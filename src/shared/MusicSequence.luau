-- Musical time is integer 960 PPQ in 4/4. Views never define storage length.
local Sequence = { PPQ = 960, TicksPerBar = 3840, MinBpm = 60, MaxBpm = 180 }

function Sequence.integer(value, minimum, maximum)
    return type(value) == "number"
        and value == value
        and value % 1 == 0
        and value >= minimum
        and value <= maximum
end

function Sequence.new(id, name, bpm, bars)
    return {
        id = id,
        revision = 1,
        name = name or "New sequence",
        bars = bars or 4,
        bpm = bpm or 96,
        meter = { 4, 4 },
        trackEvents = {},
        trackMutes = {},
        trackPadMutes = {},
        tempoMap = {},
        savedRevision = 0,
    }
end

function Sequence.countEvents(sequence)
    local count = 0
    for _, events in sequence.trackEvents do
        count += #events
    end
    return count
end

function Sequence.sort(events)
    table.sort(events, function(a, b)
        if a.tick ~= b.tick then
            return a.tick < b.tick
        end
        if a.eventId ~= b.eventId then
            return a.eventId < b.eventId
        end
        return a.pad < b.pad
    end)
    return events
end

function Sequence.validate(sequence, tracks, limits)
    if
        type(sequence) ~= "table"
        or type(sequence.id) ~= "string"
        or type(sequence.name) ~= "string"
        or #sequence.name < 1
        or #sequence.name > 80
        or not Sequence.integer(sequence.revision, 1, 1e12)
        or not Sequence.integer(
            sequence.bars,
            1,
            if sequence.converted then limits.ConversionBars else limits.SequenceBars
        )
        or not Sequence.integer(sequence.bpm, 60, 180)
        or type(sequence.meter) ~= "table"
        or sequence.meter[1] ~= 4
        or sequence.meter[2] ~= 4
        or type(sequence.trackEvents) ~= "table"
        or type(sequence.trackMutes) ~= "table"
        or type(sequence.trackPadMutes) ~= "table"
        or type(sequence.tempoMap) ~= "table"
    then
        return false,
            "Invalid sequence. Only 4/4, 60–180 BPM and the displayed bar budget are supported."
    end
    local endTick, ids, count = sequence.bars * Sequence.TicksPerBar, {}, 0
    for trackId, events in sequence.trackEvents do
        if not tracks[trackId] or type(events) ~= "table" then
            return false, "Sequence has an unknown track."
        end
        for index, event in events do
            if
                not Sequence.integer(index, 1, #events)
                or type(event) ~= "table"
                or type(event.eventId) ~= "string"
                or #event.eventId == 0
                or #event.eventId > 96
                or ids[event.eventId]
                or not Sequence.integer(event.tick, 0, endTick - 1)
                or not Sequence.integer(event.pad, 1, 64)
                or not Sequence.integer(event.velocity, 1, 127)
                or (event.durationTicks ~= nil and not Sequence.integer(
                    event.durationTicks,
                    1,
                    endTick
                ))
                or (event.muted ~= nil and type(event.muted) ~= "boolean")
            then
                return false,
                    "Invalid event; notes must remain inside the sequence and use velocity 1–127."
            end
            ids[event.eventId] = true
            count += 1
            if count > limits.EventsPerSequence then
                return false, "Sequence event budget exceeded; no notes were removed."
            end
        end
    end
    for trackId, muted in sequence.trackMutes do
        if not tracks[trackId] or type(muted) ~= "boolean" then
            return false, "Invalid sequence track mute."
        end
    end
    for trackId, mutes in sequence.trackPadMutes do
        if not tracks[trackId] or type(mutes) ~= "table" then
            return false, "Invalid pad mute track."
        end
        for pad, muted in mutes do
            local number = tonumber(pad)
            if
                type(pad) ~= "string"
                or not Sequence.integer(number, 1, 64)
                or tostring(number) ~= pad
                or type(muted) ~= "boolean"
            then
                return false, "Pad mutes require string absolute-pad keys."
            end
        end
    end
    local previous = -1
    for index, point in sequence.tempoMap do
        if
            not Sequence.integer(index, 1, #sequence.tempoMap)
            or type(point) ~= "table"
            or not Sequence.integer(point.tick, 0, endTick - 1)
            or point.tick <= previous
            or not Sequence.integer(point.bpm, 60, 180)
        then
            return false, "Invalid sequence tempo map."
        end
        previous = point.tick
    end
    return true
end

-- Swing is an offset fraction 0..0.5 of one division, on odd grid positions.
-- Quantize once when accepting input; playback never reapplies this transform.
function Sequence.quantize(tick, division, swing, endTick)
    if division == nil or division == 0 or division == "off" then
        return math.clamp(math.floor(tick + 0.5), 0, endTick - 1)
    end
    if
        not Sequence.integer(division, 40, 3840)
        or type(swing or 0) ~= "number"
        or (swing or 0) < 0
        or (swing or 0) > 0.5
    then
        return nil
    end
    local around = math.floor(tick / division)
    local best, distance = 0, math.huge
    for grid = math.max(0, around - 2), around + 2 do
        local candidate = grid * division + (if grid % 2 == 1 then division * (swing or 0) else 0)
        candidate = math.floor(candidate + 0.5)
        if candidate < endTick and math.abs(candidate - tick) < distance then
            best, distance = candidate, math.abs(candidate - tick)
        end
    end
    return best
end

function Sequence.bpmAt(sequence, tick, override)
    if override then
        return override
    end
    local bpm = sequence.bpm
    for _, point in sequence.tempoMap do
        if point.tick > tick then
            break
        end
        bpm = point.bpm
    end
    return bpm
end

function Sequence.secondsAt(sequence, tick, override)
    if override then
        return tick * 60 / (override * Sequence.PPQ)
    end
    local seconds, previous, bpm = 0, 0, sequence.bpm
    for _, point in sequence.tempoMap do
        if point.tick >= tick then
            break
        end
        seconds += (point.tick - previous) * 60 / (bpm * Sequence.PPQ)
        previous, bpm = point.tick, point.bpm
    end
    return seconds + (tick - previous) * 60 / (bpm * Sequence.PPQ)
end

function Sequence.tickAt(sequence, seconds, override)
    if override then
        return seconds * override * Sequence.PPQ / 60
    end
    local elapsed, previous, bpm = 0, 0, sequence.bpm
    for _, point in sequence.tempoMap do
        local span = (point.tick - previous) * 60 / (bpm * Sequence.PPQ)
        if seconds < elapsed + span then
            return previous + (seconds - elapsed) * bpm * Sequence.PPQ / 60
        end
        elapsed, previous, bpm = elapsed + span, point.tick, point.bpm
    end
    return previous + (seconds - elapsed) * bpm * Sequence.PPQ / 60
end

return Sequence
