local Sequence = require(script.Parent.MusicSequence)
local Project = require(script.Parent.MusicProject)
local Catalog = require(script.Parent.SampleCatalog)

local Transport = { Schema = 1, AudioTailSeconds = 2 }

function Transport.isReady(sampleId, callback)
    if type(sampleId) ~= "string" or sampleId == "" then
        return false
    end
    local ready = callback or Catalog.isPlaybackReady or Catalog.isReady or Catalog.isPlayable
    if type(ready) ~= "function" then
        return false
    end
    -- Readiness callbacks are local manifest checks and must never yield.
    local ok, result = pcall(ready, sampleId)
    return ok and result == true
end

local function kindOf(reference)
    local kind = reference.kind
    if kind == "Sequence" then
        return "sequence"
    end
    if kind == "Song" or kind == "SongDraft" then
        return "song"
    end
    if kind == "FinishedSong" then
        return "finished"
    end
    return kind
end

local function addSection(schedule, project, sequence, override, step, repetition, index, options)
    local at = schedule.duration
    local duration = Sequence.secondsAt(sequence, sequence.bars * 3840, override)
    local section = {
        at = at,
        endAt = at + duration,
        duration = duration,
        stepId = step and step.stepId,
        step = index,
        stepIndex = index,
        repetition = repetition,
        repeats = if step then step.repeats else 1,
        sequenceId = sequence.id,
        sequenceRevision = sequence.revision,
        name = sequence.name,
        bars = sequence.bars,
        bpm = override or sequence.bpm,
        startBar = schedule.totalBars + 1,
        startTick = schedule.totalBars * 3840,
        tempoMap = if override then {} else Project.clone(sequence.tempoMap),
    }
    table.insert(schedule.sections, section)
    local anySolo = false
    for _, track in project.tracks do
        anySolo = anySolo or track.mix.solo
    end
    for _, trackId in project.trackOrder do
        local track = project.tracks[trackId]
        local muted = sequence.trackMutes[trackId]
        if muted == nil then
            muted = track.mix.muted
        end
        local program = project.programs[track.programId]
        for _, event in sequence.trackEvents[trackId] or {} do
            schedule.expandedEvents += 1
            if schedule.expandedEvents > Project.Limits.ExpandedEvents then
                return false, "Expanded event budget exceeded."
            end
            local definition = program.pads[tostring(event.pad)]
            local padMuted = sequence.trackPadMutes[trackId]
                and sequence.trackPadMutes[trackId][tostring(event.pad)]
            if
                not muted
                and not padMuted
                and not event.muted
                and (not anySolo or track.mix.solo)
                and track.mix.gain > 0
                and definition.settings.gain > 0
            then
                local ready = Transport.isReady(definition.sampleId, options.ready)
                if not ready then
                    schedule.unavailableCount += 1
                    schedule.unavailable[definition.sampleId] = true
                    if options.requireReady then
                        return false,
                            "This song uses unavailable audio: " .. (if definition.sampleId
                                    == ""
                                then "empty pad"
                                else definition.sampleId)
                    end
                end
                if ready or options.includeUnavailable then
                    local settings = Project.clone(definition.settings)
                    settings.gain *= track.mix.gain
                    local localPreview = not Catalog.isReady(definition.sampleId)
                        and Catalog.isPreviewAvailable(definition.sampleId)
                    if localPreview then
                        schedule.localPreview = true
                        schedule.localOnly = true
                        schedule.previewStatus = "Local Studio playback; listening review pending"
                    end
                    table.insert(schedule.events, {
                        eventId = event.eventId,
                        at = at + Sequence.secondsAt(sequence, event.tick, override),
                        tick = section.startTick + event.tick,
                        sequenceTick = event.tick,
                        pad = event.pad,
                        absolutePad = event.pad,
                        velocity = event.velocity,
                        durationTicks = event.durationTicks,
                        sampleId = definition.sampleId,
                        settings = settings,
                        pan = track.mix.pan,
                        mix = Project.clone(track.mix),
                        trackId = trackId,
                        programId = program.id,
                        sequenceId = sequence.id,
                        section = #schedule.sections,
                        ready = ready,
                        localPreview = localPreview or nil,
                        localOnly = localPreview or nil,
                        route = {
                            projectId = project.id,
                            trackId = trackId,
                            programId = program.id,
                            pad = event.pad,
                            absolutePad = event.pad,
                            key = project.id
                                .. ":"
                                .. trackId
                                .. ":"
                                .. program.id
                                .. ":"
                                .. tostring(event.pad),
                        },
                    })
                end
            end
        end
    end
    -- Each tempo segment is explicit, so duration/cursor never assume first BPM.
    local changes = { { tick = 0, bpm = override or sequence.bpm } }
    if not override then
        for _, point in sequence.tempoMap do
            if point.tick == 0 then
                changes[1].bpm = point.bpm
            else
                table.insert(changes, Project.clone(point))
            end
        end
    end
    for changeIndex, point in changes do
        local endTick = if changes[changeIndex + 1]
            then changes[changeIndex + 1].tick
            else sequence.bars * 3840
        table.insert(schedule.tempoSchedule, {
            at = at + Sequence.secondsAt(sequence, point.tick, override),
            endAt = at + Sequence.secondsAt(sequence, endTick, override),
            tick = section.startTick + point.tick,
            endTick = section.startTick + endTick,
            bpm = point.bpm,
            section = #schedule.sections,
        })
    end
    schedule.duration += duration
    schedule.totalBars += sequence.bars
    if
        schedule.duration > Project.Limits.SongSeconds
        or schedule.totalBars > Project.Limits.SongBars
    then
        return false, "Playback exceeds the expanded duration/bar budget."
    end
    return true
end

-- Resolves a complete immutable schedule without yielding. Playback consumers
-- use this one schedule, never the mutable editor after start.
function Transport.resolve(project, reference, finishedSongs, options)
    options = options or {}
    if type(reference) ~= "table" or type(reference.id) ~= "string" then
        return nil, "Choose a typed music object."
    end
    local kind = kindOf(reference)
    local snapshot
    if kind == "finished" then
        snapshot = finishedSongs and finishedSongs[reference.id]
        if
            not snapshot
            and type(project) == "table"
            and project.project
            and project.id == reference.id
        then
            snapshot = project
        end
        if
            type(snapshot) ~= "table"
            or snapshot.schema ~= 1
            or not snapshot.project
            or (reference.revision ~= nil and snapshot.revision ~= reference.revision)
        then
            return nil, "That saved Finished Song revision is unavailable."
        end
        project = snapshot.project
    end
    local valid, message = Project.validate(project, true)
    if not valid then
        return nil, message
    end
    local schedule = {
        schema = Transport.Schema,
        source = {
            kind = kind,
            id = reference.id,
            revision = reference.revision,
            projectId = project.id,
            projectRevision = project.revision,
        },
        title = snapshot and snapshot.title,
        events = {},
        sections = {},
        tempoSchedule = {},
        duration = 0,
        totalBars = 0,
        expandedEvents = 0,
        unavailable = {},
        unavailableCount = 0,
        audioTailSeconds = Transport.AudioTailSeconds,
    }
    if options.bpm ~= nil and not Sequence.integer(options.bpm, 60, 180) then
        return nil, "Unsupported shared tempo."
    end
    if kind == "sequence" then
        local sequence = project.sequences[reference.id]
        if
            not sequence or (reference.revision ~= nil and sequence.revision ~= reference.revision)
        then
            return nil, "That sequence revision changed."
        end
        schedule.title, schedule.source.revision = sequence.name, sequence.revision
        local ok, errorMessage =
            addSection(schedule, project, sequence, options.bpm, nil, 1, 1, options)
        if not ok then
            return nil, errorMessage
        end
    elseif kind == "song" or kind == "finished" then
        local draft = project.drafts[if snapshot then snapshot.draftId else reference.id]
        if not draft or #draft.steps == 0 then
            return nil, "Add a sequence to start your song."
        end
        if
            kind == "song"
            and reference.revision ~= nil
            and draft.revision ~= reference.revision
        then
            return nil, "That song draft revision changed."
        end
        schedule.title = if snapshot then snapshot.title else draft.name
        schedule.source.revision = if snapshot then snapshot.revision else draft.revision
        local override = options.bpm or (if draft.tempoMode == "song" then draft.bpm else nil)
        for index, step in draft.steps do
            for repetition = 1, step.repeats do
                local ok, errorMessage = addSection(
                    schedule,
                    project,
                    project.sequences[step.sequenceId],
                    override,
                    step,
                    repetition,
                    index,
                    options
                )
                if not ok then
                    return nil, errorMessage
                end
            end
        end
    else
        return nil, "Unsupported music reference type."
    end
    table.sort(schedule.events, function(a, b)
        if a.at ~= b.at then
            return a.at < b.at
        end
        if a.section ~= b.section then
            return a.section < b.section
        end
        if a.trackId ~= b.trackId then
            return a.trackId < b.trackId
        end
        if a.eventId ~= b.eventId then
            return a.eventId < b.eventId
        end
        return a.pad < b.pad
    end)
    schedule.endAt = schedule.duration
    schedule.completeAt = schedule.duration + schedule.audioTailSeconds
    local bytes, byteMessage = Project.serializedBytes(schedule, Project.Limits.ScheduleBytes)
    if not bytes then
        return nil, "Playback schedule exceeds its transfer budget. " .. byteMessage
    end
    return schedule
end

function Transport.cursor(schedule, seconds)
    seconds = math.clamp(seconds, 0, schedule.duration)
    local ended = seconds >= schedule.duration
    local selected = schedule.sections[#schedule.sections]
    for _, section in schedule.sections do
        if seconds >= section.at and seconds < section.endAt then
            selected = section
            break
        end
    end
    if not selected then
        return { seconds = seconds, ended = true, progress = 1, bar = 1, beat = 1 }
    end
    local segment = schedule.tempoSchedule[#schedule.tempoSchedule]
    for _, candidate in schedule.tempoSchedule do
        if seconds >= candidate.at and seconds < candidate.endAt then
            segment = candidate
            break
        end
    end
    local absoluteTick = if ended
        then schedule.totalBars * 3840
        else segment.tick + (seconds - segment.at) * segment.bpm * 960 / 60
    local localTick = absoluteTick - selected.startTick
    return {
        seconds = seconds,
        ended = ended,
        progress = if schedule.duration > 0 then seconds / schedule.duration else 1,
        section = table.find(schedule.sections, selected),
        sequenceId = selected.sequenceId,
        sequenceName = selected.name,
        step = selected.step,
        stepIndex = selected.stepIndex,
        repetition = selected.repetition,
        repeats = selected.repeats,
        tick = absoluteTick,
        sequenceTick = localTick,
        bpm = segment.bpm,
        bar = math.min(selected.bars, math.floor(localTick / 3840) + 1),
        beat = math.floor(localTick % 3840 / 960) + 1,
        startBar = selected.startBar,
    }
end

-- [from, to) makes an event on a section boundary belong to exactly one pass.
function Transport.eventsBetween(schedule, from, to)
    local events = {}
    local source = schedule.events
    -- Schedules are sorted once when resolved. Seek directly to this frame's
    -- first event instead of rescanning the elapsed song on every heartbeat.
    local low, high = 1, #source + 1
    while low < high do
        local middle = math.floor((low + high) / 2)
        if source[middle].at < from then
            low = middle + 1
        else
            high = middle
        end
    end
    for index = low, #source do
        local event = source[index]
        if event.at >= to then
            break
        end
        table.insert(events, event)
    end
    return events
end

function Transport.newState(epoch)
    return { epoch = epoch or 0, status = "stopped", position = 0, anchorAt = 0, looped = false }
end

function Transport.position(state, now, schedule)
    local seconds = state.position
    if state.status == "playing" then
        seconds += math.max(0, now - state.anchorAt)
    end
    if state.looped and schedule.duration > 0 then
        return seconds % schedule.duration
    end
    return math.clamp(seconds, 0, schedule.duration)
end

function Transport.start(state, now, schedule, fromStart, looped)
    state.epoch += 1
    if fromStart or state.position >= schedule.duration then
        state.position = 0
    end
    state.anchorAt, state.status, state.looped = now, "playing", looped == true
    return state.epoch
end

function Transport.pause(state, now, schedule)
    state.position = Transport.position(state, now, schedule)
    state.epoch += 1
    state.status = "paused"
    return state.epoch
end

function Transport.stop(state, now, schedule, reset)
    state.position = if reset then 0 else Transport.position(state, now, schedule)
    state.epoch += 1
    state.status = "stopped"
    return state.epoch
end

function Transport.seek(state, seconds, now, schedule)
    if
        type(seconds) ~= "number"
        or seconds ~= seconds
        or seconds < 0
        or seconds > schedule.duration
    then
        return false, "Invalid transport position."
    end
    state.epoch += 1
    state.position, state.anchorAt = seconds, now
    return true
end

function Transport.recordTick(sequence, anchorAt, now, input, epoch, options)
    options = options or {}
    if
        type(input) ~= "table"
        or input.transportEpoch ~= epoch
        or type(input.at) ~= "number"
        or input.at ~= input.at
        or input.at < now - 0.35
        or input.at > now + 0.05
    then
        return nil, "Stale recording input."
    end
    local seconds = math.min(input.at, now) - anchorAt + (options.offsetSeconds or 0)
    if seconds < 0 then
        return nil, "Count-in is still running."
    end
    local duration = Sequence.secondsAt(sequence, sequence.bars * 3840, options.bpm)
    if options.looped then
        seconds %= duration
    elseif seconds >= duration then
        return nil, "Recording reached the sequence end."
    end
    local tick = Sequence.tickAt(sequence, seconds, options.bpm)
    return Sequence.quantize(tick, options.quantizeTicks, options.swing, sequence.bars * 3840)
end

return Transport
