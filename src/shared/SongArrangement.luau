local Sequence = require(script.Parent.MusicSequence)
local Song = {}

function Song.new(id, name, bpm)
    return {
        id = id,
        revision = 1,
        name = name or "New song draft",
        steps = {},
        tempoMode = "sequence",
        bpm = bpm or 96,
        savedRevision = 0,
    }
end

function Song.summarize(project, draft)
    local result = {
        id = draft.id,
        name = draft.name,
        revision = draft.revision,
        savedRevision = draft.savedRevision or 0,
        totalBars = 0,
        duration = 0,
        tempoMode = draft.tempoMode,
        bpm = draft.bpm,
        steps = {},
    }
    for index, step in draft.steps do
        local sequence = project.sequences[step.sequenceId]
        if not sequence then
            return nil, "Song step references a missing sequence."
        end
        local override = if draft.tempoMode == "song" then draft.bpm else nil
        local duration = Sequence.secondsAt(
            sequence,
            sequence.bars * Sequence.TicksPerBar,
            override
        ) * step.repeats
        table.insert(result.steps, {
            stepId = step.stepId,
            index = index,
            sequenceId = sequence.id,
            name = sequence.name,
            repeats = step.repeats,
            bars = sequence.bars,
            effectiveBpm = override or sequence.bpm,
            hasTempoMap = override == nil and #sequence.tempoMap > 0,
            startBar = result.totalBars + 1,
            startAt = result.duration,
            duration = duration,
        })
        result.totalBars += sequence.bars * step.repeats
        result.duration += duration
    end
    return result
end

function Song.validate(project, draft, limits)
    if
        type(draft) ~= "table"
        or type(draft.id) ~= "string"
        or type(draft.name) ~= "string"
        or #draft.name < 1
        or #draft.name > 80
        or not Sequence.integer(draft.revision, 1, 1e12)
        or type(draft.steps) ~= "table"
        or #draft.steps > limits.SongSteps
        or (draft.tempoMode ~= "sequence" and draft.tempoMode ~= "song")
        or not Sequence.integer(draft.bpm, 60, 180)
    then
        return false, "Invalid song draft or song-step budget exceeded."
    end
    local ids = {}
    for index, step in draft.steps do
        if
            not Sequence.integer(index, 1, #draft.steps)
            or type(step) ~= "table"
            or type(step.stepId) ~= "string"
            or #step.stepId < 1
            or #step.stepId > 96
            or ids[step.stepId]
            or not project.sequences[step.sequenceId]
            or not Sequence.integer(step.repeats, 1, limits.Repeats)
        then
            return false, "Invalid song step. Repeats must be 1–32; one means one complete play."
        end
        ids[step.stepId] = true
    end
    local summary, message = Song.summarize(project, draft)
    if not summary then
        return false, message
    end
    if summary.totalBars > limits.SongBars or summary.duration > limits.SongSeconds then
        return false,
            "Arrangement exceeds its expanded bar/duration budget; the ending was preserved."
    end
    return true
end

-- Conversion expands repeats only in the new sequence. A tempo/mute conflict is
-- refused rather than flattening musical intent to a different result.
function Song.convert(project, draft, id, name, clone, limits)
    local summary, message = Song.summarize(project, draft)
    if not summary then
        return nil, message
    end
    if #draft.steps == 0 then
        return nil, "Add a sequence before converting this song."
    end
    if summary.totalBars > limits.ConversionBars then
        return nil, "Conversion exceeds the 1,024-bar sequence budget."
    end
    local bpm = if draft.tempoMode == "song"
        then draft.bpm
        else project.sequences[draft.steps[1].sequenceId].bpm
    local result = Sequence.new(id, name or (draft.name .. " sequence"), bpm, summary.totalBars)
    result.converted = true
    result.import = { kind = "song_conversion", draftId = draft.id, draftRevision = draft.revision }
    local offset, counter = 0, 0
    for _, step in draft.steps do
        local source = project.sequences[step.sequenceId]
        if draft.tempoMode ~= "song" then
            if source.bpm ~= bpm then
                return nil,
                    "Multi-tempo conversion is unavailable. Use Song tempo or retain this arrangement."
            end
            for _, point in source.tempoMap do
                if point.bpm ~= bpm then
                    return nil,
                        "Multi-tempo conversion is unavailable. The arrangement is unchanged."
                end
            end
        end
        for _ = 1, step.repeats do
            for trackId, events in source.trackEvents do
                local track = project.tracks[trackId]
                local muted = source.trackMutes[trackId]
                if muted == nil then
                    muted = track.mix.muted
                end
                local hasSolo = false
                for _, candidate in project.tracks do
                    hasSolo = hasSolo or candidate.mix.solo
                end
                local target = result.trackEvents[trackId] or {}
                result.trackEvents[trackId] = target
                for _, event in events do
                    local padMuted = source.trackPadMutes[trackId]
                        and source.trackPadMutes[trackId][tostring(event.pad)]
                    local copy = clone(event)
                    counter += 1
                    copy.eventId, copy.tick = id .. "_event_" .. counter, offset + event.tick
                    copy.muted = event.muted == true
                        or muted == true
                        or padMuted == true
                        or (hasSolo and not track.mix.solo)
                    table.insert(target, copy)
                    if counter > limits.EventsPerSequence then
                        return nil,
                            "Expanded events exceed the sequence budget; no conversion was created."
                    end
                end
            end
            offset += source.bars * Sequence.TicksPerBar
        end
    end
    -- Event mute captures section-specific mute intent while retaining every note.
    for _, events in result.trackEvents do
        Sequence.sort(events)
    end
    return result
end

return Song
