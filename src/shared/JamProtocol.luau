local Project = require(script.Parent.MusicProject)
local Sequence = require(script.Parent.MusicSequence)
local Transport = require(script.Parent.MusicTransport)
local Catalog = require(script.Parent.SampleCatalog)
local PadSound = require(script.Parent.PadSound)
local Set = require(script.Parent.StreetSet)
local Attribution = require(script.Parent.MusicAttribution)
local Jam =
    { Schema = 3, Lead = 0.75, TrackGain = 0.05, Voices = 16, MaxEvents = 2048, MaxBytes = 350000 }

-- Musical roles describe audible contribution, never the visible A-D pad bank.
Jam.Roles = { "rhythm", "hook" }
Jam.RoleLabels = { rhythm = "RHYTHM / DRUMS + BASS", hook = "HOOK / TEXTURE" }
function Jam.roleValid(role)
    return role == "rhythm" or role == "hook"
end
function Jam.opposite(role)
    return if role == "rhythm" then "hook" else "rhythm"
end
function Jam.roleAllows(role, event)
    local category = Set.role(event)
    return if role == "rhythm" then category == "drums" or category == "bass"
        elseif role == "hook" then category == "hook" or category == "harbour"
        else false
end

-- A declaration of source settings, never a claim of verified musical tuning.
local function declaredContext(project, sequenceId, role, schedule)
    local sequence = project and project.sequences[sequenceId]
    if not sequence or not Jam.roleValid(role) then return nil end
    local offsets, seen, assignments, mixed = {}, {}, {}, false
    for _, event in schedule.events do
        local sample = Catalog.ById[event.sampleId]
        mixed = mixed or not sample or sample.pack ~= Catalog.PlannedPack.id
        local pitch = event.settings.pitch
        if not seen[pitch] then seen[pitch] = true; table.insert(offsets, pitch) end
        assignments[event.trackId .. ":" .. tostring(event.pad)] = {
            sampleId = event.sampleId, trackId = event.trackId, pad = event.pad, pitch = pitch,
        }
    end
    table.sort(offsets)
    local values = {}
    for _, pitch in offsets do table.insert(values, string.format("%+g", pitch)) end
    local changed, declarations = {}, {}
    for _, assignment in assignments do
        if assignment.pitch ~= 0 then
            table.insert(changed, string.format("Part %d / %s / pad %d %+g st",
                table.find(project.trackOrder, assignment.trackId) or 1,
                Catalog.ById[assignment.sampleId] and Catalog.ById[assignment.sampleId].label or "Unavailable sound", assignment.pad, assignment.pitch))
        end
        table.insert(declarations, assignment)
    end
    table.sort(changed)
    table.sort(declarations, function(a, b) return a.trackId .. ":" .. a.pad < b.trackId .. ":" .. b.pad end)
    return { token = table.concat({ project.id, project.revision, sequenceId, sequence.revision, role }, ":"),
        role = role, plannedKey = if mixed then "Mixed / unavailable palette" else Catalog.PlannedPack.key,
        tuningVerified = false, pitchOffsets = offsets, pitchAssignments = declarations,
        signature = (if mixed then "mixed" else Catalog.PlannedPack.key) .. "|" .. table.concat(changed, "|"),
        label = (if mixed then "Mixed / unavailable palette" else "Planned " .. Catalog.PlannedPack.key)
            .. " / tuning not listening-verified / pitch offsets "
            .. (if #values > 0 then table.concat(values, ", ") .. " st" else "none")
            .. (if #changed > 0 then " / modified: " .. table.concat(changed, "; ") else "")
            .. " / no automatic retuning" }
end

local function selectRole(schedule, role)
    if not Jam.roleValid(role) then
        return nil, "Choose Rhythm or Hook / Texture before sharing a part."
    end
    local events = {}
    for _, event in schedule.events do
        if Jam.roleAllows(role, event) then
            if event.ready ~= true then
                return nil, "Your " .. role .. " part uses unavailable audio. Choose another ready sound."
            end
            table.insert(events, event)
        end
    end
    if #events == 0 then
        return nil, "This Sequence has no audible " .. role .. " notes. Add that role in your own editor first."
    end
    schedule.events = events
    schedule.expandedEvents = #events
    schedule.unavailable, schedule.unavailableCount, schedule.unavailableReasons = {}, 0, {}
    return schedule
end

-- Context and capture share the exact audible resolver/role/readiness policy.
-- includeUnavailable keeps genuinely needed missing audio visible to selectRole,
-- which rejects it; muted/solo-excluded/zero-gain notes never enter this schedule.
local function resolveRole(project, sequenceId, unlocked, bpm, role)
    local sequence = project and project.sequences[sequenceId]
    if not sequence then
        return nil, "Choose a named Sequence before joining."
    end
    if Sequence.countEvents(sequence) > Jam.MaxEvents then
        return nil, "This Sequence exceeds the 2,048-event jam budget."
    end
    local schedule, message = Transport.resolve(
        project,
        { kind = "sequence", id = sequenceId, revision = sequence.revision },
        nil,
        {
            bpm = bpm,
            -- Filter to the selected role without silently admitting other roles.
            includeUnavailable = true,
            ready = function(id)
                return Catalog.isPlaybackReady(id, unlocked)
            end,
        }
    )
    if not schedule then
        return nil, message
    end
    return selectRole(schedule, role)
end

function Jam.context(project, sequenceId, role, unlocked, bpm)
    local schedule, problem = resolveRole(project, sequenceId, unlocked, bpm, role)
    if not schedule then return nil, problem end
    return declaredContext(project, sequenceId, role, schedule)
end

-- Session tempo adapts playback only; saved notes and source BPM never change.
function Jam.capture(project, sequenceId, unlocked, bpm, role, creator)
    local schedule, message = resolveRole(project, sequenceId, unlocked, bpm, role)
    if not schedule then return nil, message end
    local sequence = project.sequences[sequenceId]
    local attribution, creditProblem
    if creator then
        attribution, creditProblem = Attribution.capture(project, sequence, creator)
        if not attribution then return nil, creditProblem end
    end
    -- Export only the musical dependency fields. Stored private names and
    -- unrelated project metadata never become another player's jam text.
    local copy = { id = project.id, revision = project.revision, name = "Shared jam part",
        ppq = project.ppq, defaultBpm = project.defaultBpm, nextId = project.nextId,
        tracks = {}, trackOrder = Project.clone(project.trackOrder), programs = {},
        sequences = {}, sequenceOrder = { sequenceId }, drafts = {}, draftOrder = {},
        sampleVersions = project.sampleVersions and {} or nil }
    copy.attribution = attribution and Project.clone(attribution)
    local selected = {}
    for _, event in schedule.events do
        selected[event.programId] = selected[event.programId] or {}
        selected[event.programId][tostring(event.pad)] = true
    end
    for index, trackId in project.trackOrder do
        local original = project.tracks[trackId]
        copy.tracks[trackId] = { id = original.id, revision = original.revision, name = "Part " .. index,
            programId = original.programId, mix = Project.clone(original.mix) }
        local originalProgram = project.programs[original.programId]
        if not copy.programs[original.programId] then
            local program = { id = originalProgram.id, revision = originalProgram.revision, name = "Shared kit", pads = {} }
            for address, pad in originalProgram.pads do
                local used = selected[original.programId] and selected[original.programId][address]
                program.pads[address] = if used then { sampleId = pad.sampleId, settings = Project.clone(pad.settings) }
                    else { sampleId = "", settings = PadSound.sanitize(nil) }
                if used and copy.sampleVersions then copy.sampleVersions[pad.sampleId] = Project.clone(project.sampleVersions[pad.sampleId]) end
            end
            copy.programs[original.programId] = program
        end
    end
    local section = {}
    for _, key in { "id", "revision", "bars", "bpm", "meter", "trackEvents", "trackMutes", "trackPadMutes", "tempoMap", "savedRevision", "converted" } do
        section[key] = Project.clone(sequence[key])
    end
    section.name = "Shared section"
    copy.sequences[sequenceId] = section
    schedule.title = Jam.RoleLabels[role]
    for _, sectionInfo in schedule.sections do sectionInfo.name = "Shared section" end
    -- The network snapshot exports only the chosen musical part, never other
    -- private notes that happen to exist in the player's current Sequence.
    local audibleEventIds = {}
    for _, event in schedule.events do
        audibleEventIds[event.eventId] = true
    end
    for trackId, events in copy.sequences[sequenceId].trackEvents do
        local selected = {}
        for _, event in events do
            if audibleEventIds[event.eventId] then
                table.insert(selected, event)
            end
        end
        copy.sequences[sequenceId].trackEvents[trackId] = selected
    end
    local allowed = {}
    for _, event in schedule.events do
        allowed[event.sampleId] = true
    end
    local snapshot = {
        schema = Jam.Schema,
        project = copy,
        ref = { kind = "sequence", id = sequenceId, revision = sequence.revision },
        title = Jam.RoleLabels[role],
        context = declaredContext(project, sequenceId, role, schedule),
        role = role,
        sourceBpm = sequence.bpm,
        bars = sequence.bars,
        schedule = schedule,
        allowedSamples = allowed,
    }
    local bytes, problem = Project.serializedBytes(snapshot, Jam.MaxBytes)
    if not bytes then
        return nil, problem
    end
    return snapshot
end

function Jam.schedule(snapshot, bpm)
    if type(snapshot) ~= "table" or snapshot.schema ~= Jam.Schema then
        return nil, "Unsupported jam snapshot version."
    end
    local schedule, problem = Transport.resolve(snapshot.project, snapshot.ref, nil, {
        bpm = bpm,
        includeUnavailable = true,
        ready = function(id)
            return snapshot.allowedSamples[id] == true
                and Catalog.isPlaybackReady(id, { I01 = true, I02 = true, I03 = true })
        end,
    })
    if not schedule then
        return nil, problem
    end
    return selectRole(schedule, snapshot.role)
end

function Jam.boundary(anchor, bpm, now)
    local bar = 240 / bpm
    return anchor + math.max(0, math.floor((now + Jam.Lead - anchor) / bar) + 1) * bar
end

function Jam.request(packet, generation, revision, now)
    return type(packet) == "table"
        and packet.schema == Jam.Schema
        and packet.generation == generation
        and packet.revision == revision
        and type(packet.at) == "number"
        and packet.at == packet.at
        and packet.at >= now - 0.35
        and packet.at <= now + 0.05
end

function Jam.resolve(session, now)
    if type(session) ~= "table" or session.schema ~= Jam.Schema then
        return nil
    end
    local bpm, anchor = session.bpm, session.anchor
    if session.tempo and now >= session.tempo.applyAt then
        bpm, anchor = session.tempo.bpm, session.tempo.applyAt
    end
    local tracks = {}
    for slot = 1, 2 do
        local track, pending = session.tracks[tostring(slot)], session.pending[tostring(slot)]
        if track then
            tracks[slot] = {
                ownerUserId = track.ownerUserId,
                name = track.name,
                version = track.version,
                snapshot = track.snapshot,
                sinceAt = track.sinceAt,
                phaseTick = track.phaseTick or 0,
            }
            if pending and now >= pending.applyAt then
                if pending.remove then
                    tracks[slot] = nil
                else
                    tracks[slot].snapshot, tracks[slot].version, tracks[slot].sinceAt =
                        pending.snapshot, pending.version, pending.applyAt
                    tracks[slot].phaseTick = 0
                end
            end
            if tracks[slot] and session.tempo and now >= session.tempo.applyAt then
                tracks[slot].sinceAt = session.tempo.applyAt
                tracks[slot].phaseTick = session.tempo.phaseTicks[tostring(slot)] or 0
            end
        end
    end
    return bpm, anchor, tracks
end

return Jam
