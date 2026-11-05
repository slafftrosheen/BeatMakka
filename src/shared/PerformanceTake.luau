-- Capture uses server-owned, accepted bars. Output is ordinary sequences and a Song draft.
-- This module never mutates the input project, performance, profile or saved song.
local Project = require(script.Parent.MusicProject)
local Sequence = require(script.Parent.MusicSequence)
local Song = require(script.Parent.SongArrangement)
local Transport = require(script.Parent.MusicTransport)
local Set = require(script.Parent.StreetSet)
local Attribution = require(script.Parent.MusicAttribution)
local Versions = require(script.Parent.SampleVersions)
local Take = {}

local function maskKey(mutes)
    local key = ""
    for _, role in Set.RoleOrder do
        key ..= if mutes[role] then "1" else "0"
    end
    return key
end

local function same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in a do
        if not same(value, b[key]) then return false end
    end
    for key in b do
        if a[key] == nil then return false end
    end
    return true
end

function Take.capture(performance, now, id)
    if not performance.captureProject then
        return nil, "Take capture was off."
    end
    local bars = math.min(performance.bars,
        math.floor(math.max(0, now - performance.startedAt) * performance.bpm / 240))
    if bars < 1 then
        return nil, "No complete bar was captured. Partial bars are not padded or invented."
    end
    local timeline = {}
    for _, change in performance.timeline do
        if change.bar <= bars then
            table.insert(timeline, Project.clone(change))
        end
    end
    local prefix = table.clone(performance)
    prefix.bars = bars
    local schedule, problem = Set.render(prefix, timeline)
    if not schedule then return nil, problem end
    local sources = {}
    for _, source in performance.sources do
        table.insert(sources, { ref = Project.clone(source.ref), bars = source.bars })
    end
    local result = {
        schema = 1, id = id, title = performance.sources[1].title,
        project = Project.clone(performance.captureProject),
        sourceDraftId = performance.captureDraftId,
        sources = sources, timeline = timeline, schedule = schedule,
        bpm = performance.bpm, bars = bars, plannedBars = performance.bars,
        partial = bars < performance.bars, localOnly = schedule.localOnly == true,
    }
    local bytes, message = Project.serializedBytes(result, Project.Limits.MusicBytes)
    return if bytes then result else nil, message
end

local function sourceBars(take, source)
    local project, result = take.project, {}
    local function append(sequenceId, repeats)
        local sequence = project.sequences[sequenceId]
        if not sequence then return false end
        for _ = 1, repeats do
            for bar = 1, sequence.bars do
                table.insert(result, { sequenceId = sequenceId, bar = bar })
            end
        end
        return true
    end
    if source.ref.kind == "sequence" then
        if not append(source.ref.id, 1) then return nil end
    else
        local draft = project.drafts[take.sourceDraftId]
        if source.ref.kind ~= "finished" or not draft then return nil end
        for _, step in draft.steps do
            if not append(step.sequenceId, step.repeats) then return nil end
        end
    end
    return if #result == source.bars then result else nil
end

local function segments(take)
    local maps, result, index = {}, {}, 1
    for sourceIndex, source in take.sources do
        maps[sourceIndex] = sourceBars(take, source)
        if not maps[sourceIndex] then return nil, "The pinned take source is unavailable." end
    end
    for bar = 1, take.bars do
        while take.timeline[index + 1] and take.timeline[index + 1].bar <= bar do index += 1 end
        local change = take.timeline[index]
        local map = maps[change.source]
        local item = map[(bar - change.originBar) % #map + 1]
        local previous = result[#result]
        local mask = maskKey(change.mutes)
        if previous and previous.sequenceId == item.sequenceId and previous.mask == mask
            and previous.firstBar + previous.bars == item.bar then
            previous.bars += 1
        else
            table.insert(result, {
                sequenceId = item.sequenceId, firstBar = item.bar, bars = 1,
                mask = mask, mutes = Project.clone(change.mutes),
            })
        end
    end
    return result
end

local function anySolo(project)
    for _, track in project.tracks do
        if track.mix.solo then return true end
    end
    return false
end

local function prefixFor(project)
    while project.nextId < 1e12 do
        project.nextId += 1
        local prefix = "take_" .. project.nextId .. "_"
        local occupied = false
        for _, map in { project.sequences, project.drafts, project.tracks, project.programs } do
            for id in map do
                occupied = occupied or id:sub(1, #prefix) == prefix
            end
        end
        if not occupied then return prefix end
    end
    return nil
end

local function matches(expected, actual, tracks, programs)
    if actual.totalBars ~= expected.totalBars or math.abs(actual.duration - expected.duration) > 1e-7
        or #actual.events ~= #expected.events then
        return false
    end
    -- Preserve simultaneous trigger ordering as well as event multisets: chokes
    -- and repeated voices can make a reordered same-tick hit audibly different.
    for index, event in expected.events do
        local copy = actual.events[index]
        if event.tick ~= copy.tick or math.abs(event.at - copy.at) > 1e-7
            or event.sampleId ~= copy.sampleId or event.pad ~= copy.pad
            or event.velocity ~= copy.velocity or event.durationTicks ~= copy.durationTicks
            or event.pan ~= copy.pan or not same(event.settings, copy.settings)
            or tracks[event.trackId] ~= copy.trackId or programs[event.programId] ~= copy.programId then
            return false
        end
    end
    return true
end

function Take.materialize(take, current, ready)
    if type(take) ~= "table" or take.schema ~= 1
        or not Sequence.integer(take.bars, 1, 24) then
        return nil, "Unsupported temporary take. Current music is unchanged."
    end
    local valid, problem = Project.validate(take.project)
    if not valid then return nil, problem end
    if current.revision >= 1e12 or #current.draftOrder >= Project.Limits.Drafts then
        return nil, "Draft/revision capacity reached. The temporary take is still retained."
    end
    local runs, message = segments(take)
    if not runs then return nil, message end
    local candidate = Project.clone(current)
    local prefix = prefixFor(candidate)
    if not prefix then return nil, "ID capacity reached. The take is retained." end
    local source, used = take.project, {}
    local pins, pinProblem = Versions.merge(candidate.sampleVersions, source.sampleVersions)
    if not pins then return nil, pinProblem end
    candidate.sampleVersions = pins
    for _, run in runs do
        local sequence = source.sequences[run.sequenceId]
        local from, finish = (run.firstBar - 1) * Sequence.TicksPerBar,
            (run.firstBar - 1 + run.bars) * Sequence.TicksPerBar
        for trackId, events in sequence.trackEvents do
            for _, event in events do
                if event.tick >= from and event.tick < finish then used[trackId] = true end
            end
        end
    end
    local trackIds = {}
    for trackId in used do table.insert(trackIds, trackId) end
    -- The resolver orders simultaneous hits by track ID, not trackOrder.
    table.sort(trackIds)
    if #candidate.trackOrder + #trackIds > Project.Limits.Tracks then
        return nil, "Not enough track slots for isolated take copies. The take and music are unchanged."
    end
    local trackMap, programMap, programCount = {}, {}, 0
    for _ in candidate.programs do programCount += 1 end
    local targetSolo, sourceSolo = anySolo(candidate), anySolo(source)
    for index, id in trackIds do
        local original = source.tracks[id]
        if not programMap[original.programId] then
            programCount += 1
            if programCount > Project.Limits.Programs then
                return nil, "Kit capacity reached. The take is retained."
            end
            local programId = prefix .. "kit_" .. string.format("%02d", index)
            local program = Project.clone(source.programs[original.programId])
            program.id, program.revision = programId, 1
            program.name = "Take kit " .. index
            candidate.programs[programId], programMap[original.programId] = program, programId
        end
        local newId = prefix .. "track_" .. string.format("%02d", index)
        local track = Project.clone(original)
        track.id, track.revision, track.name = newId, 1, "Take part " .. index
        track.programId = programMap[original.programId]
        -- Preserve the target's pre-existing global solo predicate. Original
        -- sequences have no notes on these new tracks, so their sound is unchanged.
        -- Captured source solo/mute intent is explicit in each copied sequence.
        track.mix.muted, track.mix.solo = false, targetSolo
        candidate.tracks[newId], trackMap[id] = track, newId
        table.insert(candidate.trackOrder, newId)
    end
    local draft = Song.new(prefix .. "draft", "Street take " .. (#candidate.draftOrder + 1), take.bpm)
    draft.tempoMode = "song"
    draft.takeSource = { id = take.id, projectId = source.id, revision = source.revision,
        bars = take.bars, partial = take.partial, localOnly = take.localOnly }
    local variants, variantCount, attributes = {}, 0, {}
    for _, run in runs do
        local key = run.sequenceId .. ":" .. run.firstBar .. ":" .. run.bars .. ":" .. run.mask
        local sequenceId = variants[key]
        if not sequenceId then
            if #candidate.sequenceOrder >= Project.Limits.Sequences then
                return nil, "Sequence capacity reached. No partial draft was created; the take is retained."
            end
            variantCount += 1
            sequenceId = prefix .. "seq_" .. string.format("%02d", variantCount)
            variants[key] = sequenceId
            local original = source.sequences[run.sequenceId]
            local copy = Project.clone(original)
            local originalCredits = original.attribution or source.attribution
            local creditOwner = originalCredits and originalCredits.creator
                or (original.collaboration and original.collaboration.contributors and original.collaboration.contributors[1])
            if creditOwner then
                local credits, creditProblem = Attribution.capture(source, original, creditOwner)
                if not credits then return nil, creditProblem end
                copy.attribution = credits
                table.insert(attributes, credits)
            end
            copy.id, copy.name, copy.revision, copy.savedRevision = sequenceId, "Take section " .. variantCount, 1, 0
            copy.bars, copy.bpm, copy.tempoMap = run.bars, take.bpm, {}
            copy.trackEvents, copy.trackMutes, copy.trackPadMutes = {}, {}, {}
            copy.takeSource = { id = take.id, sequenceId = original.id,
                revision = original.revision, firstBar = run.firstBar, roleMutes = Project.clone(run.mutes) }
            local ids, rank = {}, {}
            for _, events in original.trackEvents do
                for _, event in events do table.insert(ids, event.eventId) end
            end
            table.sort(ids)
            for index, id in ids do rank[id] = index end
            local from, finish = (run.firstBar - 1) * Sequence.TicksPerBar,
                (run.firstBar - 1 + run.bars) * Sequence.TicksPerBar
            for _, oldId in trackIds do
                local newId, track = trackMap[oldId], source.tracks[oldId]
                local muted = original.trackMutes[oldId]
                if muted == nil then muted = track.mix.muted end
                copy.trackMutes[newId] = muted or (sourceSolo and not track.mix.solo)
                local mutes = Project.clone(original.trackPadMutes[oldId] or {})
                local program = source.programs[track.programId]
                for pad = 1, 64 do
                    if run.mutes[Set.role({ sampleId = program.pads[tostring(pad)].sampleId })] then
                        mutes[tostring(pad)] = true
                    end
                end
                copy.trackPadMutes[newId] = mutes
                local events = {}
                for _, event in original.trackEvents[oldId] or {} do
                    if event.tick >= from and event.tick < finish then
                        if event.durationTicks and event.durationTicks > run.bars * Sequence.TicksPerBar then
                            return nil, "A note duration exceeds its copied section's supported length. The complete take is retained, not truncated."
                        end
                        local note = Project.clone(event)
                        note.tick = event.tick - from
                        note.eventId = sequenceId .. "_note_" .. string.format("%05d", rank[event.eventId])
                        table.insert(events, note)
                    end
                end
                copy.trackEvents[newId] = Sequence.sort(events)
            end
            candidate.sequences[sequenceId] = copy
            table.insert(candidate.sequenceOrder, sequenceId)
        end
        local previous = draft.steps[#draft.steps]
        if previous and previous.sequenceId == sequenceId and previous.repeats < Project.Limits.Repeats then
            previous.repeats += 1
        else
            if #draft.steps >= Project.Limits.SongSteps then return nil, "Song step capacity reached; take retained." end
            table.insert(draft.steps, { stepId = prefix .. "step_" .. (#draft.steps + 1), sequenceId = sequenceId, repeats = 1 })
        end
    end
    if #attributes > 0 then
        local credits, creditProblem = Attribution.merge(attributes, attributes[1].creator, {})
        if not credits then return nil, creditProblem end
        draft.attribution, draft.contributors = credits, Project.clone(credits.contributors)
    end
    candidate.drafts[draft.id] = draft
    table.insert(candidate.draftOrder, draft.id)
    candidate.revision += 1
    valid, problem = Project.validate(candidate)
    if not valid then return nil, problem end
    local schedule, playbackProblem = Transport.resolve(candidate, { kind = "song", id = draft.id }, nil,
        { requireReady = true, ready = ready })
    if not schedule then return nil, playbackProblem end
    if not matches(take.schedule, schedule, trackMap, programMap) then
        return nil, "The editable draft would differ from the captured timeline. No music changed; the take is retained."
    end
    return candidate, nil, { draftId = draft.id, sequenceId = draft.steps[1].sequenceId,
        trackId = trackMap[trackIds[1]] or candidate.trackOrder[1] }
end

return Take
