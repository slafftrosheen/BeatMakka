local HttpService = game:GetService("HttpService")
local Sequence = require(script.Parent.MusicSequence)
local Song = require(script.Parent.SongArrangement)
local PadSound = require(script.Parent.PadSound)
local Catalog = require(script.Parent.SampleCatalog)

local Project = {}
Project.Limits = {
    Sequences = 32,
    Tracks = 8,
    Programs = 24,
    Drafts = 8,
    SongSteps = 128,
    Repeats = 32,
    SequenceBars = 64,
    ConversionBars = 1024,
    SongBars = 4096,
    SongSeconds = 7200,
    EventsPerSequence = 8192,
    TotalEvents = 16384,
    ExpandedEvents = 65536,
    ScheduleBytes = 750000,
    ProjectBytes = 1200000,
    MusicBytes = 2800000,
    FinishedSongs = 16,
    Archives = 6,
    History = 24,
}

function Project.clone(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, item in value do
        copy[Project.clone(key, seen)] = Project.clone(item, seen)
    end
    return copy
end

local function identifier(value)
    return type(value) == "string"
        and #value > 0
        and #value <= 96
        and value:match("^[%w_%-%.:]+$") ~= nil
end

local function name(value)
    return type(value) == "string" and #value > 0 and #value <= 80 and value:find("%S") ~= nil
end

local function finite(value, minimum, maximum)
    return type(value) == "number" and value == value and value >= minimum and value <= maximum
end

local function newId(project, prefix)
    project.nextId += 1
    return prefix .. "_" .. tostring(project.nextId)
end

function Project.program(id, label, assignments)
    local program = { id = id, revision = 1, name = label or "Harbour kit", pads = {} }
    for pad = 1, 64 do
        local sampleId = assignments and (assignments[tostring(pad)] or assignments[pad])
        if type(sampleId) == "table" then
            sampleId = sampleId.sampleId or sampleId.id
        end
        program.pads[tostring(pad)] = {
            sampleId = if type(sampleId) == "string" then sampleId else "",
            settings = PadSound.sanitize(nil),
        }
    end
    return program
end

function Project.new(id, label)
    local assignments = Catalog.DefaultPadIds
    if not assignments then
        assignments = {}
        for pad = 1, 64 do
            local sample = Catalog.List[pad]
            assignments[pad] = if sample then sample.id else ""
        end
    end
    return {
        id = id or "project_main",
        revision = 1,
        name = label or "My music",
        ppq = 960,
        defaultBpm = 96,
        nextId = 3,
        programs = { program_1 = Project.program("program_1", "Harbour kit", assignments) },
        tracks = {
            track_2 = {
                id = "track_2",
                revision = 1,
                name = "Drums / samples",
                programId = "program_1",
                mix = { muted = false, solo = false, gain = 1, pan = 0 },
            },
        },
        trackOrder = { "track_2" },
        sequences = { seq_3 = Sequence.new("seq_3", "First idea", 96, 4) },
        sequenceOrder = { "seq_3" },
        drafts = {},
        draftOrder = {},
    }
end

local function orderValid(objects, order, maximum)
    if type(objects) ~= "table" or type(order) ~= "table" or #order > maximum then
        return false
    end
    local seen, count = {}, 0
    for index, id in order do
        if
            not Sequence.integer(index, 1, #order)
            or not identifier(id)
            or seen[id]
            or type(objects[id]) ~= "table"
            or objects[id].id ~= id
        then
            return false
        end
        seen[id] = true
    end
    for id, object in objects do
        count += 1
        if not seen[id] or type(object) ~= "table" then
            return false
        end
    end
    return count == #order
end

function Project.serializedBytes(value, maximum)
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(value)
    end)
    if not ok then
        return nil, "Music contains unsupported or cyclic storage data."
    end
    local bytes = #encoded
    if maximum and bytes > maximum then
        return nil,
            string.format(
                "Music needs %d bytes; this record's budget is %d. Your previous work is unchanged.",
                bytes,
                maximum
            )
    end
    return bytes
end

function Project.validate(project, skipBytes)
    if
        type(project) ~= "table"
        or not identifier(project.id)
        or not name(project.name)
        or project.ppq ~= 960
        or not Sequence.integer(project.revision, 1, 1e12)
        or not Sequence.integer(project.defaultBpm, 60, 180)
        or not Sequence.integer(project.nextId, 0, 1e12)
        or type(project.programs) ~= "table"
        or not orderValid(project.tracks, project.trackOrder, Project.Limits.Tracks)
        or not orderValid(project.sequences, project.sequenceOrder, Project.Limits.Sequences)
        or not orderValid(project.drafts, project.draftOrder, Project.Limits.Drafts)
    then
        return false, "Unsupported or invalid project; existing musical data has been preserved."
    end
    local programCount = 0
    for id, program in project.programs do
        programCount += 1
        if
            not identifier(id)
            or type(program) ~= "table"
            or program.id ~= id
            or not name(program.name)
            or not Sequence.integer(program.revision, 1, 1e12)
            or type(program.pads) ~= "table"
        then
            return false, "Invalid kit."
        end
        local count = 0
        for key, pad in program.pads do
            count += 1
            local address = tonumber(key)
            if
                type(key) ~= "string"
                or not Sequence.integer(address, 1, 64)
                or tostring(address) ~= key
                or type(pad) ~= "table"
                or type(pad.sampleId) ~= "string"
                or #pad.sampleId > 128
                or type(pad.settings) ~= "table"
            then
                return false, "A kit must have exactly 64 explicit pad definitions."
            end
            for setting, spec in PadSound.Spec do
                if not finite(pad.settings[setting], spec[1], spec[2]) then
                    return false, "Invalid pad playback setting."
                end
            end
            if pad.settings.finish < pad.settings.start + 0.02 - 1e-9 then
                return false, "Sample end must follow its start."
            end
        end
        if count ~= 64 then
            return false, "A kit must preserve all 64 pad definitions."
        end
    end
    if programCount > Project.Limits.Programs then
        return false, "Kit budget exceeded."
    end
    for _, track in project.tracks do
        if
            not name(track.name)
            or not Sequence.integer(track.revision, 1, 1e12)
            or not project.programs[track.programId]
            or type(track.mix) ~= "table"
            or type(track.mix.muted) ~= "boolean"
            or type(track.mix.solo) ~= "boolean"
            or not finite(track.mix.gain, 0, 1.5)
            or not finite(track.mix.pan, -1, 1)
        then
            return false, "Invalid track routing or mix."
        end
    end
    local events = 0
    for _, sequence in project.sequences do
        local valid, message = Sequence.validate(sequence, project.tracks, Project.Limits)
        if not valid then
            return false, message
        end
        events += Sequence.countEvents(sequence)
    end
    if events > Project.Limits.TotalEvents then
        return false, "Project event budget exceeded; no notes were removed."
    end
    for _, draft in project.drafts do
        local valid, message = Song.validate(project, draft, Project.Limits)
        if not valid then
            return false, message
        end
    end
    if not skipBytes then
        local bytes, message = Project.serializedBytes(project, Project.Limits.ProjectBytes)
        if not bytes then
            return false, message
        end
    end
    return true
end

local function findEvent(sequence, trackId, eventId)
    for index, event in sequence.trackEvents[trackId] or {} do
        if event.eventId == eventId then
            return event, index
        end
    end
    return nil
end

local function erase(order, id)
    local index = table.find(order, id)
    if index then
        table.remove(order, index)
    end
end

local function bump(object)
    object.revision += 1
end

-- A pure edit transaction. Callers keep bounded undo snapshots and save state.
-- Caller-owned text filtering and ownership checks occur before public sharing.
function Project.apply(source, operation, payload)
    payload = payload or {}
    if type(payload) ~= "table" then
        return nil, "Invalid music operation."
    end
    if payload.expectedRevision ~= nil and payload.expectedRevision ~= source.revision then
        return nil, "This project changed. Refresh it before editing."
    end
    local project = Project.clone(source)
    local sequence = project.sequences[payload.sequenceId]
    local track = project.tracks[payload.trackId]
    local program = project.programs[payload.programId or (track and track.programId)]
    local draft = project.drafts[payload.draftId]
    local detail = {}
    local changedSequence, changedTrack, changedProgram, changedDraft
    local function fail(message)
        return nil, message
    end
    if operation == "SequenceNew" then
        if #project.sequenceOrder >= Project.Limits.Sequences then
            return fail("This project already has 32 sequences.")
        end
        local id = newId(project, "seq")
        sequence = Sequence.new(
            id,
            payload.name or ("Sequence " .. (#project.sequenceOrder + 1)),
            payload.bpm or project.defaultBpm,
            payload.bars or 4
        )
        project.sequences[id] = sequence
        table.insert(project.sequenceOrder, id)
        detail.id, detail.sequenceId = id, id
    elseif operation == "SequenceRename" then
        if not sequence then
            return fail("Choose a sequence.")
        end
        sequence.name, changedSequence = payload.name, sequence
    elseif operation == "SequenceDuplicate" then
        if not sequence then
            return fail("Choose a sequence to duplicate.")
        end
        if #project.sequenceOrder >= Project.Limits.Sequences then
            return fail("This project already has 32 sequences.")
        end
        local id = newId(project, "seq")
        local copy = Project.clone(sequence)
        copy.id, copy.revision, copy.savedRevision, copy.name =
            id, 1, 0, payload.name or (sequence.name .. " variation")
        project.sequences[id] = copy
        table.insert(project.sequenceOrder, id)
        detail.id, detail.sequenceId = id, id
    elseif operation == "SequenceDelete" then
        if not sequence then
            return fail("Choose a sequence.")
        end
        if #project.sequenceOrder <= 1 then
            return fail("Keep at least one editable sequence.")
        end
        for _, song in project.drafts do
            for _, step in song.steps do
                if step.sequenceId == sequence.id then
                    return fail(
                        "A song draft uses this sequence. Remove or replace its steps first."
                    )
                end
            end
        end
        project.sequences[sequence.id] = nil
        erase(project.sequenceOrder, sequence.id)
    elseif operation == "SequenceLength" then
        if not sequence then
            return fail("Choose a sequence.")
        end
        if
            not Sequence.integer(
                payload.bars,
                1,
                if sequence.converted
                    then Project.Limits.ConversionBars
                    else Project.Limits.SequenceBars
            )
        then
            return fail("Choose a supported whole number of bars.")
        end
        for _, events in sequence.trackEvents do
            for _, event in events do
                if event.tick >= payload.bars * 3840 then
                    return fail(
                        "Shortening would remove notes. Clear/copy that material explicitly first; Undo preserves the edit."
                    )
                end
            end
        end
        for _, point in sequence.tempoMap do
            if point.tick >= payload.bars * 3840 then
                return fail("Shortening would remove tempo changes. Remove them explicitly first.")
            end
        end
        sequence.bars, changedSequence = payload.bars, sequence
    elseif operation == "SequenceTempo" then
        if not sequence then
            return fail("Choose a sequence.")
        end
        sequence.bpm, changedSequence = payload.bpm, sequence
        if payload.tempoMap ~= nil then
            sequence.tempoMap = Project.clone(payload.tempoMap)
        end
    elseif operation == "SequenceDouble" then
        if not sequence then
            return fail("Choose a sequence.")
        end
        local oldEnd = sequence.bars * 3840
        sequence.bars *= 2
        for _, events in sequence.trackEvents do
            local copies = {}
            for _, event in events do
                local copy = Project.clone(event)
                copy.tick, copy.eventId = copy.tick + oldEnd, newId(project, "event")
                table.insert(copies, copy)
            end
            for _, event in copies do
                table.insert(events, event)
            end
            Sequence.sort(events)
        end
        local tempo = Project.clone(sequence.tempoMap)
        table.insert(sequence.tempoMap, { tick = oldEnd, bpm = sequence.bpm })
        for _, point in tempo do
            table.insert(sequence.tempoMap, { tick = point.tick + oldEnd, bpm = point.bpm })
        end
        -- A point at zero already restores the initial tempo at the copied boundary.
        if #tempo > 0 and tempo[1].tick == 0 then
            table.remove(sequence.tempoMap, #tempo + 1)
        end
        changedSequence = sequence
    elseif operation == "SequenceClear" then
        if not sequence then
            return fail("Choose a sequence.")
        end
        if payload.trackId then
            if not track then
                return fail("Choose a track.")
            end
            if payload.pad then
                local kept = {}
                for _, event in sequence.trackEvents[track.id] or {} do
                    if event.pad ~= payload.pad then
                        table.insert(kept, event)
                    end
                end
                sequence.trackEvents[track.id] = kept
            else
                sequence.trackEvents[track.id] = {}
            end
        else
            sequence.trackEvents = {}
        end
        changedSequence = sequence
    elseif operation == "EventPut" or operation == "EventToggle" then
        if not sequence or not track then
            return fail("Choose a sequence and track.")
        end
        if not Sequence.integer(payload.pad or payload.absolutePad, 1, 64) then
            return fail("Choose an absolute program pad 1–64.")
        end
        local pad = payload.pad or payload.absolutePad
        local tick = payload.tick
        if not Sequence.integer(tick, 0, sequence.bars * 3840 - 1) then
            return fail("The note is outside this sequence.")
        end
        if payload.quantizeTicks ~= nil then
            tick =
                Sequence.quantize(tick, payload.quantizeTicks, payload.swing, sequence.bars * 3840)
            if not tick then
                return fail("Unsupported timing correction or swing.")
            end
        end
        local events = sequence.trackEvents[track.id] or {}
        sequence.trackEvents[track.id] = events
        local existing, index
        if payload.eventId then
            existing, index = findEvent(sequence, track.id, payload.eventId)
        end
        if operation == "EventToggle" and not existing then
            for i, candidate in events do
                if candidate.pad == pad and candidate.tick == tick then
                    existing, index = candidate, i
                    break
                end
            end
        end
        if existing and operation == "EventToggle" then
            table.remove(events, index)
            detail.removed = existing.eventId
        else
            local event = {
                eventId = if existing
                    then existing.eventId
                    else (payload.newEventId or newId(project, "event")),
                tick = tick,
                pad = pad,
                velocity = payload.velocity or 127,
                durationTicks = payload.durationTicks,
                muted = payload.muted,
            }
            if existing then
                events[index] = event
            else
                table.insert(events, event)
            end
            Sequence.sort(events)
            detail.eventId = event.eventId
        end
        changedSequence = sequence
    elseif operation == "EventRemove" or operation == "EventVelocity" then
        if not sequence or not track then
            return fail("Choose a sequence and track.")
        end
        local event, index = findEvent(sequence, track.id, payload.eventId)
        if not event then
            return fail("That note no longer exists.")
        end
        if operation == "EventRemove" then
            table.remove(sequence.trackEvents[track.id], index)
        else
            event.velocity = payload.velocity
        end
        changedSequence = sequence
    elseif operation == "Quantize" then
        if not sequence then
            return fail("Choose a sequence.")
        end
        for trackId, events in sequence.trackEvents do
            if payload.trackId == nil or payload.trackId == trackId then
                for _, event in events do
                    if payload.pad == nil or payload.pad == event.pad then
                        local tick = Sequence.quantize(
                            event.tick,
                            payload.quantizeTicks,
                            payload.swing,
                            sequence.bars * 3840
                        )
                        if not tick then
                            return fail("Unsupported timing correction or swing.")
                        end
                        event.tick = tick
                    end
                end
                Sequence.sort(events)
            end
        end
        changedSequence = sequence
    elseif operation == "PadMute" then
        if
            not sequence
            or not track
            or not Sequence.integer(payload.pad, 1, 64)
            or type(payload.muted) ~= "boolean"
        then
            return fail("Choose a track, absolute pad and explicit mute state.")
        end
        sequence.trackPadMutes[track.id] = sequence.trackPadMutes[track.id] or {}
        sequence.trackPadMutes[track.id][tostring(payload.pad)] = payload.muted or nil
        changedSequence = sequence
    elseif operation == "SequenceTrackMute" then
        if
            not sequence
            or not track
            or (payload.muted ~= nil and type(payload.muted) ~= "boolean")
        then
            return fail("Choose a valid sequence track mute.")
        end
        sequence.trackMutes[track.id], changedSequence = payload.muted, sequence
    elseif operation == "TrackNew" then
        if #project.trackOrder >= Project.Limits.Tracks then
            return fail("This project already has eight tracks.")
        end
        local id = newId(project, "track")
        project.tracks[id] = {
            id = id,
            revision = 1,
            name = payload.name or ("Track " .. (#project.trackOrder + 1)),
            programId = payload.programId or project.tracks[project.trackOrder[1]].programId,
            mix = { muted = false, solo = false, gain = 1, pan = 0 },
        }
        table.insert(project.trackOrder, id)
        detail.id, detail.trackId = id, id
    elseif
        operation == "TrackRename"
        or operation == "TrackProgram"
        or operation == "TrackMix"
        or operation == "TrackMute"
        or operation == "TrackSolo"
    then
        if not track then
            return fail("Choose a track.")
        end
        if operation == "TrackRename" then
            track.name = payload.name
        elseif operation == "TrackProgram" then
            track.programId = payload.programId
        elseif operation == "TrackMute" then
            track.mix.muted = payload.muted
        elseif operation == "TrackSolo" then
            track.mix.solo = payload.solo
        else
            for key, value in payload.mix or {} do
                if key ~= "muted" and key ~= "solo" and key ~= "gain" and key ~= "pan" then
                    return fail("Unsupported mixer setting.")
                end
                track.mix[key] = value
            end
        end
        changedTrack = track
    elseif operation == "ProgramFromPack" then
        if not track or type(payload.assignments) ~= "table" then
            return fail("Choose a track and a complete kit.")
        end
        local count = 0
        for _ in project.programs do
            count += 1
        end
        if count >= Project.Limits.Programs then
            return fail("This project already has 24 kits; previous kits are retained.")
        end
        for pad = 1, 64 do
            local sampleId = payload.assignments[pad] or payload.assignments[tostring(pad)]
            if type(sampleId) ~= "string" or sampleId == "" then
                return fail("A kit must provide all 64 sound identities.")
            end
        end
        local id = newId(project, "program")
        local created = Project.program(id, payload.name, payload.assignments)
        created.sourcePackId, created.mappingRevision = payload.packId, payload.mappingRevision
        project.programs[id] = created
        track.programId, changedTrack = id, track
        detail.id, detail.programId = id, id
    elseif operation == "ProgramDuplicate" then
        if not program then
            return fail("Choose a kit.")
        end
        local id = newId(project, "program")
        local copy = Project.clone(program)
        copy.id, copy.revision, copy.name = id, 1, payload.name or (program.name .. " copy")
        project.programs[id] = copy
        if track then
            track.programId, changedTrack = id, track
        end
        detail.id, detail.programId = id, id
    elseif operation == "ProgramRename" then
        if not program then
            return fail("Choose a kit.")
        end
        program.name, changedProgram = payload.name, program
    elseif operation == "ProgramPad" then
        if not program or not Sequence.integer(payload.pad or payload.absolutePad, 1, 64) then
            return fail("Choose a kit and absolute pad.")
        end
        local pad = program.pads[tostring(payload.pad or payload.absolutePad)]
        if payload.sampleId ~= nil then
            pad.sampleId = payload.sampleId
        end
        if payload.settings ~= nil then
            if type(payload.settings) ~= "table" then
                return fail("Invalid pad settings.")
            end
            for key, value in payload.settings do
                if not PadSound.Spec[key] then
                    return fail("Unsupported pad setting.")
                end
                pad.settings[key] = value
            end
        end
        changedProgram = program
    elseif operation == "SongNew" then
        if #project.draftOrder >= Project.Limits.Drafts then
            return fail("This project already has eight song drafts.")
        end
        local id = newId(project, "song")
        project.drafts[id] = Song.new(
            id,
            payload.name or ("Song draft " .. (#project.draftOrder + 1)),
            payload.bpm or project.defaultBpm
        )
        table.insert(project.draftOrder, id)
        detail.id, detail.draftId = id, id
    elseif operation == "SongRename" then
        if not draft then
            return fail("Choose a song draft.")
        end
        draft.name, changedDraft = payload.name, draft
    elseif operation == "SongDuplicate" then
        if not draft then
            return fail("Choose a song draft.")
        end
        if #project.draftOrder >= Project.Limits.Drafts then
            return fail("This project already has eight song drafts.")
        end
        local id, copy = newId(project, "song"), Project.clone(draft)
        copy.id, copy.revision, copy.savedRevision, copy.name =
            id, 1, 0, payload.name or (draft.name .. " copy")
        for _, step in copy.steps do
            step.stepId = newId(project, "step")
        end
        project.drafts[id] = copy
        table.insert(project.draftOrder, id)
        detail.id, detail.draftId = id, id
    elseif operation == "SongDelete" then
        if not draft then
            return fail("Choose a song draft.")
        end
        project.drafts[draft.id] = nil
        erase(project.draftOrder, draft.id)
    elseif operation == "SongStepInsert" or operation == "SongStepDuplicate" then
        if not draft then
            return fail("Choose a song draft.")
        end
        local position = payload.index or (#draft.steps + 1)
        if not Sequence.integer(position, 1, #draft.steps + 1) then
            return fail("Choose a valid song-step position.")
        end
        local step = {
            stepId = newId(project, "step"),
            sequenceId = payload.sequenceId,
            repeats = payload.repeats or 1,
        }
        if operation == "SongStepDuplicate" then
            local original
            for _, candidate in draft.steps do
                if candidate.stepId == payload.stepId then
                    original = candidate
                    break
                end
            end
            if not original then
                return fail("Choose a song step to duplicate.")
            end
            step.sequenceId, step.repeats = original.sequenceId, original.repeats
        end
        table.insert(draft.steps, position, step)
        detail.stepId, changedDraft = step.stepId, draft
    elseif
        operation == "SongStepUpdate"
        or operation == "SongStepMove"
        or operation == "SongStepRemove"
    then
        if not draft then
            return fail("Choose a song draft.")
        end
        local selected, at
        for index, step in draft.steps do
            if step.stepId == payload.stepId then
                selected, at = step, index
                break
            end
        end
        if not selected then
            return fail("That song step no longer exists.")
        end
        if operation == "SongStepUpdate" then
            if payload.sequenceId ~= nil then
                selected.sequenceId = payload.sequenceId
            end
            if payload.repeats ~= nil then
                selected.repeats = payload.repeats
            end
        elseif operation == "SongStepMove" then
            if not Sequence.integer(payload.index, 1, #draft.steps) then
                return fail("Choose a valid destination step.")
            end
            table.remove(draft.steps, at)
            table.insert(draft.steps, payload.index, selected)
        else
            table.remove(draft.steps, at)
        end
        changedDraft = draft
    elseif operation == "SongTempo" then
        if not draft then
            return fail("Choose a song draft.")
        end
        draft.tempoMode = payload.tempoMode or draft.tempoMode
        draft.bpm, changedDraft = payload.bpm or draft.bpm, draft
    elseif operation == "SongCover" then
        if not draft then
            return fail("Choose a song draft.")
        end
        draft.cover, changedDraft = Project.clone(payload.cover), draft
    elseif operation == "SongConvert" then
        if not draft then
            return fail("Choose a song draft.")
        end
        if #project.sequenceOrder >= Project.Limits.Sequences then
            return fail("Make room for the converted sequence first.")
        end
        local id = newId(project, "seq")
        local converted, message =
            Song.convert(project, draft, id, payload.name, Project.clone, Project.Limits)
        if not converted then
            return fail(message)
        end
        project.sequences[id] = converted
        table.insert(project.sequenceOrder, id)
        detail.id, detail.sequenceId = id, id
    else
        return fail("Unsupported music operation: " .. tostring(operation))
    end
    local changedSequences = {}
    if changedSequence then
        changedSequences[changedSequence.id] = true
    end
    if changedTrack then
        bump(changedTrack)
    end
    if changedProgram then
        bump(changedProgram)
    end
    if changedTrack or changedProgram then
        for id, candidate in project.sequences do
            for trackId, routedTrack in project.tracks do
                local used = candidate.trackEvents[trackId] ~= nil
                    or candidate.trackMutes[trackId] ~= nil
                    or candidate.trackPadMutes[trackId] ~= nil
                local trackChanged = changedTrack and changedTrack.id == trackId
                local programChanged = changedProgram and changedProgram.id == routedTrack.programId
                -- Solo is a project mixer decision, including when the soloed
                -- track contains no events in this particular section.
                local soloChanged = changedTrack
                    and (changedTrack.mix.solo ~= source.tracks[changedTrack.id].mix.solo)
                if soloChanged or (used and (trackChanged or programChanged)) then
                    changedSequences[id] = true
                    break
                end
            end
        end
    end
    for id in changedSequences do
        bump(project.sequences[id])
    end
    local changedDrafts = {}
    if changedDraft then
        changedDrafts[changedDraft.id] = true
    end
    for id, candidate in project.drafts do
        for _, step in candidate.steps do
            if changedSequences[step.sequenceId] then
                changedDrafts[id] = true
                break
            end
        end
    end
    for id in changedDrafts do
        bump(project.drafts[id])
    end
    bump(project)
    local valid, message = Project.validate(project)
    if not valid then
        return fail(message)
    end
    return project, "Music updated.", detail
end

function Project.select(project, sequenceId, trackId, draftId)
    local sequence = project.sequences[sequenceId or project.sequenceOrder[1]]
    local track = project.tracks[trackId or project.trackOrder[1]]
    return {
        sequence = Project.clone(sequence),
        track = Project.clone(track),
        program = Project.clone(track and project.programs[track.programId]),
        draft = Project.clone(project.drafts[draftId]),
        sequenceId = sequence and sequence.id,
        trackId = track and track.id,
        draftId = draftId,
    }
end

function Project.summary(project)
    local result = {
        id = project.id,
        name = project.name,
        revision = project.revision,
        sequences = {},
        tracks = {},
        programs = {},
        drafts = {},
        limits = Project.clone(Project.Limits),
    }
    for _, id in project.sequenceOrder do
        local sequence = project.sequences[id]
        table.insert(result.sequences, {
            id = id,
            name = sequence.name,
            revision = sequence.revision,
            savedRevision = sequence.savedRevision or 0,
            bars = sequence.bars,
            bpm = sequence.bpm,
            events = Sequence.countEvents(sequence),
            hasTempoMap = #sequence.tempoMap > 0,
        })
    end
    for _, id in project.trackOrder do
        table.insert(result.tracks, Project.clone(project.tracks[id]))
    end
    for id, program in project.programs do
        local uses = 0
        for _, track in project.tracks do
            if track.programId == id then
                uses += 1
            end
        end
        table.insert(
            result.programs,
            { id = id, name = program.name, revision = program.revision, sharedBy = uses }
        )
    end
    table.sort(result.programs, function(a, b)
        return a.id < b.id
    end)
    for _, id in project.draftOrder do
        table.insert(result.drafts, Song.summarize(project, project.drafts[id]))
    end
    return result
end

return Project
