local Project = require(script.Parent.MusicProject)
local Sequence = require(script.Parent.MusicSequence)
local Transport = require(script.Parent.MusicTransport)
local Catalog = require(script.Parent.SampleCatalog)
local Jam =
    { Schema = 3, Lead = 0.75, TrackGain = 0.05, Voices = 16, MaxEvents = 2048, MaxBytes = 350000 }

-- Session tempo adapts playback only; saved notes and source BPM never change.
function Jam.capture(project, sequenceId, unlocked, bpm)
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
            requireReady = true,
            ready = function(id)
                return Catalog.isPlaybackReady(id, unlocked)
            end,
        }
    )
    if not schedule then
        return nil, message
    end
    if #schedule.events == 0 then
        return nil, "Add an available audible note before joining."
    end
    local copy = Project.clone(project)
    copy.sequences = { [sequenceId] = Project.clone(sequence) }
    copy.sequenceOrder, copy.drafts, copy.draftOrder = { sequenceId }, {}, {}
    local allowed = {}
    for _, event in schedule.events do
        allowed[event.sampleId] = true
    end
    local snapshot = {
        schema = Jam.Schema,
        project = copy,
        ref = { kind = "sequence", id = sequenceId, revision = sequence.revision },
        title = sequence.name,
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
    return Transport.resolve(snapshot.project, snapshot.ref, nil, {
        bpm = bpm,
        requireReady = true,
        ready = function(id)
            return snapshot.allowedSamples[id] == true
                and Catalog.isPlaybackReady(id, { I01 = true, I02 = true, I03 = true })
        end,
    })
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
                tracks[slot].snapshot, tracks[slot].version, tracks[slot].sinceAt =
                    pending.snapshot, pending.version, pending.applyAt
                tracks[slot].phaseTick = 0
            end
            if session.tempo and now >= session.tempo.applyAt then
                tracks[slot].sinceAt = session.tempo.applyAt
                tracks[slot].phaseTick = session.tempo.phaseTicks[tostring(slot)] or 0
            end
        end
    end
    return bpm, anchor, tracks
end

return Jam
