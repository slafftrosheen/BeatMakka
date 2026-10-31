local Http = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local Shared = game.ReplicatedStorage.Shared
local Project = require(Shared.MusicProject)
local Transport = require(Shared.MusicTransport)
local Finished = require(Shared.FinishedSong)
local Catalog = require(Shared.SampleCatalog)
local PadSound = require(Shared.PadSound)
local Profiles = require(script.Parent.ProfileStore)
local Workspace = {}
local function integer(v, lo, hi)
    return type(v) == "number" and v == v and v % 1 == 0 and v >= lo and v <= hi
end
local function now()
    return game.Workspace:GetServerTimeNow()
end
local function choose(map, order, id)
    return if map[id] then id else order[1]
end
local function editorReady(p, _reference, id)
    return Catalog.isPlaybackReady(id, p.unlocked)
end
local function markLocalPreviews(schedule)
    for _, event in schedule.events do
        if not Catalog.isReady(event.sampleId) and Catalog.isPreviewAvailable(event.sampleId) then
            event.localPreview = true
            schedule.localPreview = true
            schedule.previewStatus = "Local personal preview; listening review pending"
        end
    end
    local bytes, message = Project.serializedBytes(schedule, Project.Limits.ScheduleBytes)
    return bytes ~= nil, message
end
function Workspace.sync(p)
    local project = p.music.project
    p.sequenceId = choose(project.sequences, project.sequenceOrder, p.sequenceId)
    p.trackId = choose(project.tracks, project.trackOrder, p.trackId)
    p.draftId = choose(project.drafts, project.draftOrder, p.draftId)
    local seq = project.sequences[p.sequenceId]
    local track = project.tracks[p.trackId]
    local program = track and project.programs[track.programId]
    p.bar = math.clamp(p.bar or 1, 1, if seq then seq.bars else 1)
    -- Compatibility projection for scenery only; this is never storage or audio authority.
    local pattern =
        { bpm = if seq then seq.bpm else 96, rows = {}, assignments = {}, sounds = {}, muted = {} }
    for pad = 1, 64 do
        local def = program and program.pads[tostring(pad)]
        pattern.rows[pad] = table.create(16, false)
        pattern.assignments[pad] = if def then def.sampleId else nil
        pattern.sounds[pad] = PadSound.sanitize(def and def.settings)
        pattern.muted[pad] = seq
                and seq.trackPadMutes
                and seq.trackPadMutes[p.trackId]
                and seq.trackPadMutes[p.trackId][tostring(pad)] == true
            or false
    end
    for _, event in (seq and seq.trackEvents[p.trackId] or {}) do
        local tick = event.tick - (p.bar - 1) * 3840
        if tick >= 0 and tick < 3840 then
            pattern.rows[event.pad][math.floor(tick / 240) + 1] = true
        end
    end
    p.pattern = pattern
    p.epoch = p.epoch or 0
    p.startedAt = p.startedAt or 0
    return seq, track, program
end
function Workspace.stop(p, reset)
    p.nextSequence = nil
    local t = p.transport
    if t and p.playing then
        t.offset = math.max(0, now() - t.startedAt + (t.offset or 0))
    end
    if reset and t then
        t.offset = 0
    end
    p.playing = false
    p.recording = false
    p.epoch += 1
    if t then
        t.epoch = p.epoch
        t.playing = false
        t.recording = false
    end
end
local function start(p, ref, offset, recording, anchorAt)
    p.nextSequence = nil
    local schedule, problem = Transport.resolve(p.music.project, ref, p.music.finishedSongs, {
        ready = function(id)
            return editorReady(p, ref, id)
        end,
    })
    if not schedule then
        return false, problem
    end
    local marked, previewProblem = markLocalPreviews(schedule)
    if not marked then
        return false, previewProblem
    end
    p.epoch += 1
    p.playing = true
    p.recording = recording or false
    p.startedAt = anchorAt or (now() + 0.15)
    local seq = p.music.project.sequences[ref.id]
    if recording and p.countIn and seq and not anchorAt then
        p.startedAt += 240 / seq.bpm
    end
    p.transport = {
        epoch = p.epoch,
        ref = Project.clone(ref),
        schedule = schedule,
        startedAt = p.startedAt,
        offset = offset or 0,
        loop = ref.kind == "sequence",
        playing = true,
        recording = p.recording,
        recordSequence = if recording then Project.clone(seq) else nil,
        recordProject = if recording then Project.clone(p.music.project) else nil,
        recordTrackId = p.trackId,
    }
    return true,
        if recording
            then "Recording adds notes; existing notes are retained."
            else "Playback started."
end
local liveSequenceActions = {
    SequenceLength = true,
    SequenceTempo = true,
    SequenceDouble = true,
    SequenceClear = true,
    EventPut = true,
    EventRemove = true,
    EventToggle = true,
    EventVelocity = true,
    PadMute = true,
    SequenceTrackMute = true,
    Quantize = true,
}
local liveInstrumentActions = {
    ProgramPad = true,
    ProgramFromPack = true,
    ProgramDuplicate = true,
    TrackProgram = true,
    TrackMix = true,
    TrackMute = true,
    TrackSolo = true,
}
local function resolveEditorSchedule(p, project, reference)
    local schedule, problem = Transport.resolve(project, reference, p.music.finishedSongs, {
        ready = function(id)
            return editorReady(p, reference, id)
        end,
    })
    if not schedule then
        return nil, problem
    end
    local marked, previewProblem = markLocalPreviews(schedule)
    return if marked then schedule else nil, previewProblem
end
local function replaceSequenceSchedule(p, schedule, recordProject, cancelVoices)
    local t = p.transport
    if cancelVoices ~= false then
        p.epoch += 1
        t.epoch = p.epoch
    end
    t.schedule = schedule
    t.scheduleRevision = (t.scheduleRevision or 0) + 1
    -- Keep the anchor. Erasure cancels voices and old recording input; adding a
    -- note or editing its sound leaves existing tails alive. Neither replays hits.
    t.scheduleChangedAt = now()
    if recordProject then
        t.recordProject = recordProject
        t.recordSequence = Project.clone(recordProject.sequences[t.ref.id])
    end
end
local function preserveWorkspace(music, project)
    for _, archive in music.archives do
        if archive.project and archive.project.id == project.id then
            archive.project = Project.clone(project)
            return
        end
    end
    local key = "workspace_" .. project.id
    if not music.archives[key] then
        table.insert(music.archiveOrder, key)
    end
    music.archives[key] = {
        id = key,
        name = project.name,
        kind = "workspace",
        project = Project.clone(project),
        readOnly = false,
    }
end
local function remember(p, before)
    p.musicUndo = p.musicUndo or {}
    p.musicRedo = {}
    table.insert(p.musicUndo, before)
    if #p.musicUndo > 24 then
        table.remove(p.musicUndo, 1)
    end
end
local function edit(p, operation, payload, recording)
    local previous = p.music.project
    local accepted, nextProject, message, detail =
        pcall(Project.apply, previous, operation, payload)
    if not accepted then
        return false, "Invalid music payload; the project is unchanged."
    end
    if not nextProject then
        return false, message
    end
    local t = p.transport
    local sequenceEdit = t
        and t.ref.kind == "sequence"
        and payload.sequenceId == t.ref.id
        and liveSequenceActions[operation]
    local instrumentEdit = t
        and t.ref.kind == "sequence"
        and not p.recording
        and liveInstrumentActions[operation]
    local liveEdit = sequenceEdit or instrumentEdit
    local recordProject, recordSchedule
    if (recording or sequenceEdit) and t and p.recording and t.recordProject then
        local note = Project.clone(payload)
        note.newEventId = detail and detail.eventId or note.newEventId
        note.expectedRevision = nil
        local recordSource = t.recordProject
        if note.trackId and not recordSource.tracks[note.trackId] then
            -- New tracks can join the live sequence during overdub. Existing
            -- recorded tracks retain their original instrument settings.
            recordSource = Project.clone(recordSource)
            local addedTrack = Project.clone(nextProject.tracks[note.trackId])
            recordSource.tracks[note.trackId] = addedTrack
            table.insert(recordSource.trackOrder, note.trackId)
            if not recordSource.programs[addedTrack.programId] then
                recordSource.programs[addedTrack.programId] =
                    Project.clone(nextProject.programs[addedTrack.programId])
            end
        end
        local acceptedPinned, pinned, pinnedProblem =
            pcall(Project.apply, recordSource, operation, note)
        if not acceptedPinned or not pinned then
            return false,
                pinnedProblem
                    or "The recording snapshot reached its edit budget; previous work is unchanged."
        end
        local schedule, scheduleProblem = resolveEditorSchedule(p, pinned, t.ref)
        if not schedule then
            return false, scheduleProblem
        end
        recordProject, recordSchedule = pinned, schedule
    elseif liveEdit then
        local schedule, problem = resolveEditorSchedule(p, nextProject, t.ref)
        if not schedule then
            return false, problem
        end
        recordSchedule = schedule
    end
    if not recording or p.recordHistoryEpoch ~= p.epoch then
        remember(p, previous)
        p.recordHistoryEpoch = if recording then p.epoch else nil
    end
    p.music.project = nextProject
    p.editVersion += 1
    if not recording then
        -- A queued Tap delta was captured before this full-state edit. Emitting it
        -- with the new revision could otherwise resurrect a cleared/deleted note.
        p.noteDeltas = {}
    end
    Workspace.sync(p)
    if detail and detail.id then
        if operation:sub(1, 8) == "Sequence" or operation == "SongConvert" then
            p.sequenceId = detail.id
        elseif operation == "TrackNew" then
            p.trackId = detail.id
        elseif operation == "SongNew" or operation == "SongDuplicate" then
            p.draftId = detail.id
        end
        Workspace.sync(p)
    end
    if t and t.ref.kind == "sequence" and not nextProject.sequences[t.ref.id] then
        Workspace.stop(p, true)
        p.transport = nil
    elseif liveEdit and not recording then
        local erased = operation == "SequenceClear"
            or operation == "EventRemove"
            or (detail and detail.removed ~= nil)
            or (operation == "PadMute" and payload.muted == true)
            or (operation == "SequenceTrackMute" and payload.muted == true)
            or (
                operation == "SequenceLength"
                and nextProject.sequences[t.ref.id].bars < previous.sequences[t.ref.id].bars
            )
        replaceSequenceSchedule(p, recordSchedule, recordProject, erased)
    elseif recordProject then
        t.recordProject = recordProject
        t.schedule = recordSchedule
    end
    if p.nextSequence and not nextProject.sequences[p.nextSequence.id] then
        p.nextSequence = nil
    end
    return true, message, detail
end
local function filterName(player, text)
    if type(text) ~= "string" or #text < 1 or #text > 64 then
        return nil
    end
    -- Studio projects are session-only. Simulated Studio players can have
    -- negative IDs, which cannot be submitted to the production text filter.
    if RunService:IsStudio() then
        return text
    end
    local ok, result = pcall(function()
        return TextService:FilterStringAsync(text, player.UserId)
            :GetNonChatStringForBroadcastAsync()
    end)
    return if ok then result else nil
end
function Workspace.projection(p)
    local seq, track, program = Workspace.sync(p)
    local songs = {}
    for _, id in p.music.finishedOrder do
        local s = p.music.finishedSongs[id]
        if s then
            table.insert(
                songs,
                { id = id, revision = s.revision, title = s.title or s.name, duration = s.duration }
            )
        end
    end
    local archives = {}
    for key, value in p.music.archives do
        table.insert(
            archives,
            { id = key, name = value.name or tostring(key), readOnly = value.readOnly ~= false }
        )
    end
    local transport = p.transport and table.clone(p.transport)
    if transport then
        transport.recordSequence = nil
        transport.recordProject = nil
    end
    return {
        projectId = p.music.project.id,
        projectRevision = p.music.project.revision,
        sequenceId = p.sequenceId,
        trackId = p.trackId,
        draftId = p.draftId,
        sequence = seq,
        track = track,
        program = program,
        draft = p.music.project.drafts[p.draftId],
        library = Project.summary(p.music.project),
        finishedSongs = songs,
        archives = archives,
        hasRecovery = p.music.recoveryProject ~= nil,
        bank = p.bank,
        bar = p.bar,
        velocity = p.velocity,
        fullLevel = p.fullLevel,
        timingCorrect = p.timingCorrect,
        swing = p.swing,
        countIn = p.countIn,
        metronome = p.metronome,
        noteRepeat = p.noteRepeat,
        transport = transport,
        queued = p.nextSequence,
        selectedFinishedSongId = p.selectedFinishedSongId,
        teachingBar = p.teachingBar or 1,
        undo = #(p.musicUndo or {}),
        redo = #(p.musicRedo or {}),
    }
end
function Workspace.tick(p)
    if not p.playing or not p.transport then
        return false
    end
    local t = p.transport
    local elapsed = now() - t.startedAt + (t.offset or 0)
    if p.nextSequence and elapsed >= p.nextSequence.at then
        local id = p.nextSequence.id
        local anchor = t.startedAt + p.nextSequence.at - (t.offset or 0)
        p.nextSequence = nil
        start(p, { kind = "sequence", id = id }, 0, false, anchor)
        return true
    end
    if not t.loop and elapsed >= (t.schedule.completeAt or t.schedule.duration) then
        Workspace.stop(p, true)
        return true
    end
    return false
end
local musicActions = {
    SequenceNew = true,
    SequenceRename = true,
    SequenceDuplicate = true,
    SequenceDelete = true,
    SequenceLength = true,
    SequenceTempo = true,
    SequenceDouble = true,
    SequenceClear = true,
    EventPut = true,
    EventRemove = true,
    EventToggle = true,
    EventVelocity = true,
    TrackNew = true,
    TrackRename = true,
    TrackProgram = true,
    TrackMix = true,
    TrackMute = true,
    TrackSolo = true,
    ProgramDuplicate = true,
    ProgramRename = true,
    ProgramPad = true,
    PadMute = true,
    SequenceTrackMute = true,
    SongNew = true,
    SongRename = true,
    SongDuplicate = true,
    SongDelete = true,
    SongStepInsert = true,
    SongStepDuplicate = true,
    SongStepUpdate = true,
    SongStepMove = true,
    SongStepRemove = true,
    SongTempo = true,
    SongCover = true,
    SongConvert = true,
    Quantize = true,
}
function Workspace.handles(action)
    return musicActions[action]
        or table.find({
                "Bank",
                "Bar",
                "SequenceSelect",
                "TrackSelect",
                "SongSelect",
                "Play",
                "PlayStart",
                "Stop",
                "Record",
                "Overdub",
                "Tap",
                "NextSequence",
                "NextCancel",
                "SongPlay",
                "SongSeek",
                "Velocity",
                "FullLevel",
                "TimingCorrect",
                "Swing",
                "CountIn",
                "Metronome",
                "NoteRepeat",
                "Undo",
                "Redo",
                "Save",
                "SaveProject",
                "SaveSequence",
                "SaveDraft",
                "SongFinish",
                "FinishedSelect",
                "FinishedPlay",
                "FinishedOpen",
                "ArchiveOpen",
                "RecoveryOpen",
                "Bpm",
                "Step",
                "PadSound",
                "PadPreset",
                "MutePad",
                "ClearPad",
                "Assign",
                "Kit",
                "RowTool",
                "Rhythm",
            }, action)
            ~= nil
end
function Workspace.command(player, p, action, a, b, persist, send)
    Workspace.sync(p)
    local project = p.music.project
    local seq = project.sequences[p.sequenceId]
    local track = project.tracks[p.trackId]
    if action == "Kit" then
        local pack = if type(a) == "string" then Catalog.PackById[a] else nil
        if not pack and RunService:IsStudio() and type(a) == "string" then
            pack = Catalog.LocalPackById[a]
        end
        if not pack then
            return false, "Choose an available kit from the local or approved roster."
        end
        local assignments = {}
        for pad = 1, 64 do
            local sample = pack.samples[pad]
            if not sample or not Catalog.isLocallyPlayable(sample.id, p.unlocked) then
                return false,
                    "This kit does not have 64 available sounds; previous edits are retained."
            end
            assignments[pad] = sample.id
        end
        return edit(p, "ProgramFromPack", {
            trackId = p.trackId,
            assignments = assignments,
            packId = pack.id,
            mappingRevision = pack.mappingRevision,
            name = pack.label,
        }, false)
    elseif action == "Bank" then
        if integer(a, 1, 4) then
            p.bank = a
        end
        return true,
            "Sound bank " .. string.char(64 + p.bank) .. ". Playback and sequence are unchanged."
    elseif action == "Bar" then
        if seq and integer(a, 1, seq.bars) then
            p.bar = a
        end
        return true
    elseif action == "SequenceSelect" or action == "TrackSelect" or action == "SongSelect" then
        local map = if action == "SequenceSelect"
            then project.sequences
            elseif action == "TrackSelect" then project.tracks
            else project.drafts
        if type(a) ~= "string" or not map[a] then
            return false, "Choose an existing item."
        end
        local previousId = if action == "SequenceSelect"
            then p.sequenceId
            elseif action == "TrackSelect" then p.trackId
            else p.draftId
        if previousId ~= a then
            p.editVersion += 1
        end
        if action == "SequenceSelect" then
            p.sequenceId = a
            p.bar = 1
        elseif action == "TrackSelect" then
            p.trackId = a
        else
            p.draftId = a
        end
        Workspace.sync(p)
        return true, "Editor selection changed; the playing snapshot is unchanged."
    elseif
        action == "Play"
        or action == "PlayStart"
        or action == "SongPlay"
        or action == "Record"
        or action == "Overdub"
        or action == "FinishedPlay"
    then
        local kind = if action == "SongPlay"
            then "song"
            elseif action == "FinishedPlay" then "finished"
            else "sequence"
        local id = if kind == "song"
            then p.draftId
            elseif kind == "finished" then p.selectedFinishedSongId
            else p.sequenceId
        if not id then
            return false, "Choose music to play first."
        end
        if action == "Play" and p.playing then
            Workspace.stop(p, false)
            return true, "Paused. Play resumes this pinned snapshot."
        end
        if action == "Play" and p.transport then
            p.epoch += 1
            p.startedAt = now() + 0.15
            p.playing = true
            p.recording = false
            p.transport.startedAt = p.startedAt
            p.transport.epoch = p.epoch
            p.transport.playing = true
            p.transport.recording = false
            p.transport.scheduleChangedAt = nil
            return true, "Playback resumed."
        end
        if p.recording and (action == "Record" or action == "Overdub") then
            p.recording = false
            p.transport.recording = false
            return true, "Recording stopped; playback continues."
        end
        return start(p, { kind = kind, id = id }, 0, action == "Record" or action == "Overdub")
    elseif action == "Stop" then
        Workspace.stop(p, true)
        return true, "Stopped at the beginning."
    elseif action == "SongSeek" then
        if not p.draftId or not integer(a, 1, 128) then
            return false, "Choose a song step."
        end
        local schedule, problem =
            Transport.resolve(project, { kind = "song", id = p.draftId }, p.music.finishedSongs)
        if not schedule then
            return false, problem
        end
        local section
        for _, candidate in schedule.sections do
            if candidate.stepIndex == a then
                section = candidate
                break
            end
        end
        if not section then
            return false, "That step is unavailable."
        end
        return start(p, { kind = "song", id = p.draftId }, section.start or section.at or 0, false)
    elseif action == "NextSequence" then
        if
            not p.playing
            or not p.transport
            or p.transport.ref.kind ~= "sequence"
            or type(a) ~= "string"
            or not project.sequences[a]
        then
            return false, "Play a sequence before queueing the next section."
        end
        local elapsed = now() - p.transport.startedAt + (p.transport.offset or 0)
        local unit = if b == "bar"
            then 240 / p.transport.schedule.sections[1].bpm
            else p.transport.schedule.duration
        p.nextSequence = {
            id = a,
            at = (math.floor(math.max(0, elapsed) / unit) + 1) * unit,
            mode = if b == "bar" then "bar" else "sequence",
        }
        return true, "Next sequence queued."
    elseif action == "NextCancel" then
        p.nextSequence = nil
        return true, "Holding the current sequence."
    elseif action == "Velocity" and integer(a, 1, 127) then
        p.velocity = a
        return true
    elseif action == "FullLevel" then
        p.fullLevel = a == true
        return true
    elseif action == "TimingCorrect" and table.find({ 0, 120, 160, 240, 320, 480, 960 }, a) then
        p.timingCorrect = a
        return true
    elseif action == "Swing" and integer(a, 50, 75) then
        p.swing = a
        return true
    elseif action == "CountIn" then
        p.countIn = a == true
        return true
    elseif action == "Metronome" and table.find({ "off", "on", "record" }, a) then
        p.metronome = a
        return true
    elseif action == "NoteRepeat" then
        p.noteRepeat = a == true
        return true
    elseif action == "Undo" or action == "Redo" then
        local from = if action == "Undo" then p.musicUndo else p.musicRedo
        if not from or #from == 0 then
            return false, "No edit to " .. action:lower() .. "."
        end
        local to = if action == "Undo" then (p.musicRedo or {}) else (p.musicUndo or {})
        local restored = Project.clone(from[#from])
        restored.revision = project.revision + 1
        local t = p.transport
        local schedule, problem
        if t and t.ref.kind == "sequence" and restored.sequences[t.ref.id] then
            schedule, problem = resolveEditorSchedule(p, restored, t.ref)
            if not schedule then
                return false, problem
            end
        end
        table.insert(to, project)
        table.remove(from)
        p.music.project = restored
        p.noteDeltas = {}
        if action == "Undo" then
            p.musicRedo = to
        else
            p.musicUndo = to
        end
        p.editVersion += 1
        Workspace.sync(p)
        if t and t.ref.kind == "sequence" then
            if schedule then
                -- History restores the project as a whole, so start a fresh
                -- recording dependency snapshot while retaining the same cursor.
                replaceSequenceSchedule(p, schedule, t.recordProject and Project.clone(restored))
            else
                Workspace.stop(p, true)
                p.transport = nil
            end
        end
        if p.nextSequence and not restored.sequences[p.nextSequence.id] then
            p.nextSequence = nil
        end
        return true, action .. " applied."
    elseif action == "Tap" then
        if not p.recording or not p.playing or type(b) ~= "table" or not integer(a, 1, 64) then
            return false
        end
        local t = p.transport
        if
            not t
            or t.ref.kind ~= "sequence"
            or b.projectId ~= project.id
            or b.sequenceId ~= t.ref.id
            or b.trackId ~= t.recordTrackId
            or b.epoch ~= p.epoch
            or b.absolutePad ~= a
        then
            return false, "Stale recording identity was ignored."
        end
        if type(b.requestId) ~= "string" or #b.requestId > 80 then
            return false
        end
        p.noteRequests = p.noteRequests or {}
        if p.noteRequests[b.requestId] then
            return false
        end
        local tick = Transport.recordTick(
            t.recordSequence,
            t.startedAt,
            now(),
            { at = b.at, transportEpoch = b.epoch },
            p.epoch,
            {
                offsetSeconds = t.offset or 0,
                looped = true,
                quantizeTicks = p.timingCorrect,
                swing = ((p.swing or 50) - 50) / 50,
            }
        )
        if tick == nil then
            return false, "Recording input is outside this transport window."
        end
        p.noteRequests[b.requestId] = true
        p.noteRequestOrder = p.noteRequestOrder or {}
        table.insert(p.noteRequestOrder, b.requestId)
        if #p.noteRequestOrder > 256 then
            p.noteRequests[table.remove(p.noteRequestOrder, 1)] = nil
        end
        local ok, message, detail = edit(p, "EventPut", {
            sequenceId = t.ref.id,
            trackId = t.recordTrackId,
            pad = a,
            newEventId = "event_" .. Http:GenerateGUID(false),
            tick = tick,
            velocity = if p.fullLevel then 127 else p.velocity,
        }, true)
        if ok and detail and detail.eventId then
            detail.transportEpoch = p.epoch
            detail.sequenceId = t.ref.id
            detail.trackId = t.recordTrackId
            for _, event in p.music.project.sequences[t.ref.id].trackEvents[t.recordTrackId] do
                if event.eventId == detail.eventId then
                    detail.event = Project.clone(event)
                    break
                end
            end
            for _, event in p.transport.schedule.events do
                if event.eventId == detail.eventId then
                    detail.playbackEvent = Project.clone(event)
                    break
                end
            end
        end
        return ok, message, detail
    elseif action == "FinishedSelect" then
        if
            type(a) ~= "string"
            or not p.saved
            or not p.saved.music
            or not p.saved.music.finishedSongs[a]
        then
            return false, "Choose a successfully saved Finished Song."
        end
        if p.selectedFinishedSongId ~= a then
            p.selectedFinishedSongId = a
            p.editVersion += 1
        end
        return true, "Finished Song selected."
    elseif action == "FinishedOpen" then
        local song = p.music.finishedSongs[a]
        if not song then
            return false, "Choose a Finished Song."
        end
        p.musicUndo = p.musicUndo or {}
        remember(p, project)
        local proposed = Project.clone(p.music)
        preserveWorkspace(proposed, project)
        proposed.project = Finished.editCopy(song, "edit_" .. Http:GenerateGUID(false))
        local valid, problem = Profiles.capture(p, proposed)
        if not valid then
            return false, problem
        end
        p.music = proposed
        p.sequenceId = nil
        p.trackId = nil
        p.draftId = song.draftId
        p.editVersion += 1
        Workspace.sync(p)
        return true, "Editable copy opened; the finished revision remains unchanged."
    elseif action == "ArchiveOpen" or action == "RecoveryOpen" then
        local archive = if action == "RecoveryOpen"
            then p.music.recoveryProject
            else p.music.archives[a]
        local candidate = archive and (archive.project or archive)
        if type(candidate) ~= "table" or not candidate.sequences then
            return false, "This archive is preserved as read-only source."
        end
        local valid, problem = Project.validate(candidate)
        if not valid then
            return false, problem
        end
        -- Save the current workspace as an archive before opening another.
        local proposed = Project.clone(p.music)
        preserveWorkspace(proposed, project)
        proposed.project = Project.clone(candidate)
        local probe = Profiles.capture(p, proposed)
        if not probe then
            return false, "Archive capacity reached; save before changing workspace."
        end
        p.music = proposed
        p.sequenceId = nil
        p.trackId = nil
        p.draftId = nil
        p.editVersion += 1
        Workspace.stop(p, true)
        Workspace.sync(p)
        return true, "Imported workspace opened. Previous work is preserved in the library."
    elseif
        action == "Save"
        or action == "SaveProject"
        or action == "SaveSequence"
        or action == "SaveDraft"
    then
        local music = Project.clone(p.music)
        local target
        if action == "SaveSequence" then
            target = music.project.sequences[p.sequenceId]
        elseif action == "SaveDraft" then
            target = music.project.drafts[p.draftId]
        end
        if (action == "SaveSequence" or action == "SaveDraft") and not target then
            return false, "Choose an item to save."
        end
        if target then
            target.savedRevision = target.revision
        end
        persist(player, p, nil, music, function(ok)
            if ok and target then
                local current = if action == "SaveSequence"
                    then p.music.project.sequences[target.id]
                    else p.music.project.drafts[target.id]
                if current and current.revision == target.revision then
                    current.savedRevision = target.revision
                end
            end
        end)
        return true
    elseif action == "SongFinish" then
        if type(a) ~= "table" or type(a.requestId) ~= "string" or #a.requestId > 80 then
            return false, "Finish needs a request identity."
        end
        p.music.finishRequests = p.music.finishRequests or {}
        local previous = p.music.finishRequests[a.requestId]
        if previous then
            local old = p.music.finishedSongs[previous.songId]
            if
                old
                and old.sourceProjectRevision == a.projectRevision
                and old.sourceDraftRevision == a.draftRevision
            then
                return true, "Finished song already saved."
            end
            return false, "That finish request belongs to another revision."
        end
        if #p.music.finishedOrder >= 16 then
            return false, "The 16 Finished Song library budget is full; drafts are retained."
        end
        if p.saving then
            return false, "Wait for the current save before finishing."
        end
        local id = "song_" .. Http:GenerateGUID(false)
        local song, problem = Finished.capture(
            project,
            p.draftId,
            a.draftRevision,
            a.projectRevision,
            {
                id = id,
                revision = 1,
                title = (project.drafts[p.draftId] or {}).name,
                requestId = a.requestId,
                createdAt = os.time(),
            },
            function(sampleId)
                return Catalog.isPlaybackReady(sampleId, p.unlocked)
            end
        )
        if not song then
            return false, problem
        end
        song.sourceProjectRevision = a.projectRevision
        song.sourceDraftRevision = a.draftRevision
        local music = Project.clone(p.music)
        music.finishedSongs[id] = song
        table.insert(music.finishedOrder, id)
        music.finishRequests[a.requestId] =
            { songId = id, projectRevision = a.projectRevision, draftRevision = a.draftRevision }
        persist(
            player,
            p,
            if p.saveMode == "session"
                then "Finished song — saved for this session."
                else "Finished song saved.",
            music,
            function(ok)
                if ok then
                    p.music.finishedSongs[id] = song
                    table.insert(p.music.finishedOrder, id)
                    p.music.finishRequests[a.requestId] = {
                        songId = id,
                        projectRevision = a.projectRevision,
                        draftRevision = a.draftRevision,
                    }
                    p.selectedFinishedSongId = id
                    p.editVersion += 1
                    p.progressNeedsSave = true
                    send(
                        player,
                        if p.saveMode == "session"
                            then "Finished song — saved for this session."
                            else "Finished song saved."
                    )
                end
            end
        )
        return true
    end
    local payload = if type(a) == "table" then Project.clone(a) else {}
    payload.newEventId = nil
    if action ~= "SongStepUpdate" then
        payload.sequenceId = payload.sequenceId or p.sequenceId
    end
    payload.trackId = payload.trackId or p.trackId
    payload.draftId = payload.draftId or p.draftId
    if track then
        payload.programId = payload.programId or track.programId
    end
    if action == "Bpm" then
        action = "SequenceTempo"
        payload.bpm = a
    elseif action == "Step" and integer(a, 1, 64) and integer(b, 1, 16) then
        action = "EventToggle"
        payload.pad = a
        payload.tick = (p.bar - 1) * 3840 + (b - 1) * 240
        payload.velocity = if p.fullLevel then 127 else p.velocity
    elseif action == "MutePad" and integer(a, 1, 64) then
        action = "PadMute"
        payload.pad = a
        payload.muted = not p.pattern.muted[a]
    elseif
        action == "Assign"
        and integer(a, 1, 64)
        and Catalog.isLocallyPlayable(b, p.unlocked)
    then
        action = "ProgramPad"
        payload.pad = a
        payload.sampleId = b
    elseif
        action == "PadSound"
        and integer(a, 1, 64)
        and type(b) == "table"
        and PadSound.Spec[b.key]
        and type(b.value) == "number"
    then
        action = "ProgramPad"
        payload.pad = a
        payload.settings = PadSound.sanitize(p.pattern.sounds[a])
        payload.settings[b.key] = b.value
        payload.settings = PadSound.sanitize(payload.settings)
    elseif action == "PadPreset" and integer(a, 1, 64) then
        action = "ProgramPad"
        payload.pad = a
        payload.settings = PadSound.preset(p.pattern.sounds[a], b, seq.bpm)
        if not payload.settings then
            return false, "Unknown sound preset."
        end
    elseif action == "ClearPad" and integer(a, 1, 64) then
        action = "SequenceClear"
        payload.pad = a
    elseif action == "RowTool" or action == "Rhythm" then
        return false, "Use sequence Copy/Double/Clear and event editing in this workspace."
    end
    if action == "SequenceClear" and payload.scope == "sequence" then
        payload.trackId = nil
        payload.pad = nil
    end
    if action == "SongCover" then
        return false, "Copy an earned sleeve through Sleeve Studio."
    end
    if not musicActions[action] then
        return false, "Unsupported music command."
    end
    if payload.name ~= nil then
        local expected = project.revision
        payload.name = filterName(player, payload.name)
        if not payload.name then
            return false, "The title could not be filtered; retry before saving it."
        end
        if p.music.project.revision ~= expected then
            return false, "Project changed while checking the title; retry."
        end
    end
    if
        action == "ProgramPad"
        and payload.sampleId ~= nil
        and not Catalog.isLocallyPlayable(payload.sampleId, p.unlocked)
    then
        return false, "That sample is unavailable to this player."
    end
    return edit(p, action, payload, false)
end
return Workspace
