-- A mutually approved, session-local copy of two *current* pinned jam parts.
-- This is not a recorder for the historical live exchange: it takes the
-- currently accepted contribution snapshots at the next shared bar.
local Project = require(script.Parent.MusicProject)
local Sequence = require(script.Parent.MusicSequence)
local Song = require(script.Parent.SongArrangement)
local Transport = require(script.Parent.MusicTransport)
local Jam = require(script.Parent.JamProtocol)
local Attribution = require(script.Parent.MusicAttribution)
local Versions = require(script.Parent.SampleVersions)
local Copy = { Schema = 1 }
local TICKS = Sequence.TicksPerBar

local function gcd(a, b)
    while b ~= 0 do a, b = b, a % b end
    return a
end

local function same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in a do
        if not same(value, b[key]) then return false end
    end
    for key in b do if a[key] == nil then return false end end
    return true
end

function Copy.capture(session, now, id)
    if not session or session.schema ~= Jam.Schema or not session.bpm
        or session.tempo or session.tempoOffer or session.roleOffer
        or session.leadPending or next(session.pending) then
        return nil, "Wait until the duet's accepted bar and tempo changes finish."
    end
    local boundary = Jam.boundary(session.anchor, session.bpm, now)
    local sources, bars = {}, 1
    for slot = 1, 2 do
        local track = session.tracks[tostring(slot)]
        if not track or not track.snapshot or not Jam.roleValid(track.role) then
            return nil, "Two live contributed roles are needed for a joint copy."
        end
        local snapshot = track.snapshot
        local valid, problem = Project.validate(snapshot.project)
        if not valid then return nil, problem end
        local schedule, message = Jam.schedule(snapshot, session.bpm)
        if not schedule then return nil, message end
        if #schedule.events == 0 then return nil, "Both roles need audible notes." end
        local total = snapshot.bars * TICKS
        local phase = ((track.phaseTick or 0)
            + (boundary - track.sinceAt) * session.bpm * Sequence.PPQ / 60) % total
        local barPhase = math.floor(phase / TICKS + 0.5)
        local errorTicks = math.abs(phase - barPhase * TICKS)
        errorTicks = math.min(errorTicks, total - errorTicks)
        if errorTicks > 0.05 then
            return nil, "A part is off the shared bar grid. Rejoin at a clean bar before copying."
        end
        bars = bars * snapshot.bars / gcd(bars, snapshot.bars)
        if bars > Project.Limits.SequenceBars then
            return nil, "The combined phrase exceeds 64 bars. Shorten a source Sequence explicitly."
        end
        table.insert(sources, {
            ownerUserId = track.ownerUserId, name = track.name,
            role = track.role, version = track.version,
            snapshot = Project.clone(snapshot),
            phaseBars = barPhase % snapshot.bars,
        })
    end
    if sources[1].ownerUserId == sources[2].ownerUserId then
        return nil, "Joint copies require two different contributors."
    end
    local take = {
        schema = Copy.Schema, id = id, title = "Back-to-Back Jam",
        bpm = session.bpm, bars = bars, sources = sources,
        contributors = {
            { userId = sources[1].ownerUserId, name = sources[1].name, role = sources[1].role },
            { userId = sources[2].ownerUserId, name = sources[2].name, role = sources[2].role },
        },
        recordedAtBar = boundary,
        -- Pinned phrase, not proof of an earlier take; no audio recording.
        kind = "joint_phrase_snapshot",
    }
    local attributes = {}
    for _, member in sources do
        if member.snapshot.project.attribution then table.insert(attributes, member.snapshot.project.attribution) end
    end
    local credits, creditProblem = Attribution.merge(attributes,
        { userId = sources[1].ownerUserId, name = sources[1].name }, take.contributors)
    if not credits then return nil, creditProblem end
    take.attribution, take.contributors = credits, Project.clone(credits.contributors)
    local bytes, problem = Project.serializedBytes(take, Project.Limits.MusicBytes)
    return if bytes then take else nil, problem
end

local function prefixFor(project)
    while project.nextId < 1e12 do
        project.nextId += 1
        local prefix = "duet_" .. project.nextId .. "_"
        local collision = false
        for _, map in { project.sequences, project.drafts, project.tracks, project.programs } do
            for id in map do collision = collision or id:sub(1, #prefix) == prefix end
        end
        if not collision then return prefix end
    end
    return nil
end

local function soloPredicate(project)
    for _, track in project.tracks do
        if track.mix.solo then return true end
    end
    return false
end

function Copy.materialize(take, current, ready)
    if type(take) ~= "table" or take.schema ~= Copy.Schema or #take.sources ~= 2
        or not Sequence.integer(take.bars, 1, Project.Limits.SequenceBars)
        or not Sequence.integer(take.bpm, 60, 180) then
        return nil, "Invalid temporary joint copy. Your music is unchanged."
    end
    if current.revision >= 1e12 or #current.sequenceOrder >= Project.Limits.Sequences
        or #current.draftOrder >= Project.Limits.Drafts then
        return nil, "Sequence, Draft or revision capacity is full. The joint copy is retained."
    end
    local candidate = Project.clone(current)
    local prefix = prefixFor(candidate)
    if not prefix then return nil, "ID capacity reached; the temporary copy remains." end
    local resultId = prefix .. "sequence"
    local draftId = prefix .. "draft"
    local merged = Sequence.new(resultId, "Back-to-Back / Both parts", take.bpm, take.bars)
    merged.collaboration = { id = take.id, kind = take.kind,
        contributors = Project.clone(take.contributors), bars = take.bars }
    merged.attribution = Project.clone(take.attribution)
    local used, programs, trackMap, expected = {}, {}, {}, {}
    local targetSolo = soloPredicate(candidate)
    local programCount = 0
    for _ in candidate.programs do programCount += 1 end
    local noteCount = 0
    for sourceIndex, member in take.sources do
        local source = member.snapshot
        local valid, problem = Project.validate(source.project)
        if not valid then return nil, problem end
        local pins, versionProblem = Versions.merge(candidate.sampleVersions, source.project.sampleVersions)
        if not pins then return nil, versionProblem end
        candidate.sampleVersions = pins
        local schedule, scheduleProblem = Jam.schedule(source, take.bpm)
        if not schedule then return nil, scheduleProblem end
        if take.bars % source.bars ~= 0 then
            return nil, "Source bar counts cannot be represented without shortening."
        end
        local sourceProject = source.project
        local sourceTracks = {}
        for _, event in schedule.events do
            sourceTracks[event.trackId] = true
        end
        local ids = {}
        for id in sourceTracks do table.insert(ids, id) end
        table.sort(ids)
        for index, id in ids do
            if #candidate.trackOrder >= Project.Limits.Tracks then
                return nil, "Not enough isolated track slots; both source projects are retained."
            end
            local original = sourceProject.tracks[id]
            local oldProgram = original.programId
            local mapKey = tostring(sourceIndex) .. ":" .. oldProgram
            if not programs[mapKey] then
                programCount += 1
                if programCount > Project.Limits.Programs then
                    return nil, "No available kit slots. The joint copy is retained."
                end
                local newProgramId = prefix .. "program_" .. sourceIndex .. "_" .. index
                local program = Project.clone(sourceProject.programs[oldProgram])
                program.id, program.name, program.revision =
                    newProgramId, "Duet kit " .. sourceIndex .. "/" .. index, 1
                candidate.programs[newProgramId] = program
                programs[mapKey] = newProgramId
            end
            local newTrackId = prefix .. "track_" .. sourceIndex .. "_" .. index
            local track = Project.clone(original)
            track.id, track.name, track.revision = newTrackId,
                member.role .. " / " .. member.name, 1
            track.programId = programs[mapKey]
            -- Solo/mute state from the source is already resolved into audible
            -- notes. Match the destination project's global solo predicate without
            -- modifying existing tracks.
            track.mix.muted, track.mix.solo = false, targetSolo
            candidate.tracks[newTrackId] = track
            table.insert(candidate.trackOrder, newTrackId)
            trackMap[tostring(sourceIndex) .. ":" .. id] = newTrackId
            merged.trackEvents[newTrackId] = {}
        end
        local sourceTicks = source.bars * TICKS
        local phaseTicks = member.phaseBars * TICKS
        for eventIndex, event in schedule.events do
            local newTrackId = trackMap[tostring(sourceIndex) .. ":" .. event.trackId]
            if not newTrackId then
                return nil, "Captured part has an unknown routing dependency."
            end
            local tickInCycle = (event.tick - phaseTicks) % sourceTicks
            for repeatIndex = 0, take.bars / source.bars - 1 do
                noteCount += 1
                if noteCount > Project.Limits.EventsPerSequence then
                    return nil, "Merged event budget reached. No partial copy was installed."
                end
                local tick = tickInCycle + repeatIndex * sourceTicks
                local eventId = prefix .. "note_" .. string.format("%05d", noteCount)
                if event.durationTicks and event.durationTicks > take.bars * TICKS then
                    return nil, "A note duration exceeds the merged Sequence budget."
                end
                local note = {
                    eventId = eventId, tick = tick, pad = event.pad,
                    velocity = event.velocity,
                }
                if event.durationTicks then note.durationTicks = event.durationTicks end
                table.insert(merged.trackEvents[newTrackId], note)
                expected[eventId] = {
                    tick = tick, at = tick * 60 / (take.bpm * Sequence.PPQ),
                    sampleId = event.sampleId, pad = event.pad,
                    velocity = event.velocity, durationTicks = event.durationTicks,
                    pan = event.pan, settings = event.settings,
                    trackId = newTrackId,
                }
            end
        end
    end
    for _, notes in merged.trackEvents do Sequence.sort(notes) end
    candidate.sequences[resultId] = merged
    table.insert(candidate.sequenceOrder, resultId)
    local draft = Song.new(draftId, "Back-to-Back / Joint Draft", take.bpm)
    draft.tempoMode = "song"
    draft.steps = { { stepId = prefix .. "step_1", sequenceId = resultId, repeats = 1 } }
    draft.contributors = Project.clone(take.contributors)
    draft.attribution = Project.clone(take.attribution)
    draft.collaboration = { id = take.id, source = take.kind,
        recordedAtBar = take.recordedAtBar, bars = take.bars }
    candidate.drafts[draftId] = draft
    table.insert(candidate.draftOrder, draftId)
    candidate.revision += 1
    local valid, problem = Project.validate(candidate)
    if not valid then return nil, problem end
    local schedule, playbackProblem = Transport.resolve(candidate,
        { kind = "song", id = draftId }, nil,
        { requireReady = true, ready = ready })
    if not schedule then return nil, playbackProblem end
    if #schedule.events ~= noteCount or schedule.totalBars ~= take.bars
        or math.abs(schedule.duration - take.bars * 240 / take.bpm) > 1e-6 then
        return nil, "Joint draft differs from the pinned phrase. No project was changed."
    end
    local checked = {}
    for _, event in schedule.events do
        local want = expected[event.eventId]
        if not want or checked[event.eventId] or event.tick ~= want.tick
            or math.abs(event.at - want.at) > 1e-6
            or event.sampleId ~= want.sampleId or event.pad ~= want.pad
            or event.velocity ~= want.velocity or event.durationTicks ~= want.durationTicks
            or event.pan ~= want.pan or event.trackId ~= want.trackId
            or not same(event.settings, want.settings) then
            return nil, "Joint draft replay would change a pinned note. Nothing was imported."
        end
        checked[event.eventId] = true
    end
    if noteCount == 0 then return nil, "Nothing audible was captured." end
    return candidate, nil, {
        sequenceId = resultId, draftId = draftId,
        trackId = candidate.trackOrder[#candidate.trackOrder],
    }
end

return Copy
