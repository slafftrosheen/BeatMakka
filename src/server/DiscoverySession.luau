-- Extends the existing workstation command path, not a second remote/save engine.
local Shared = game:GetService("ReplicatedStorage").Shared
local Hunt = require(Shared.SoundHunt)
local Catalog = require(Shared.SampleCatalog)
local Sequence = require(Shared.MusicSequence)
local Session = {}

function Session.handles(action)
    return action == "DiscoveryAdd" or action == "DiscoveryPreview"
end

function Session.command(player, profile, action, packet, core, persist, send)
    if type(packet) ~= "table" or packet.schema ~= Hunt.Schema
        or type(packet.discoveryId) ~= "string" or not profile.ready or not profile.station
    then
        return false, "Choose a collected sound at your instrument."
    end
    local source, discovery = Hunt.source(packet.discoveryId)
    if not discovery or profile.unlocked[packet.discoveryId] ~= true then
        return false, "Find this source in the quay first. Your music is unchanged."
    end
    if not source or not Catalog.isPlaybackReady(source.id, profile.unlocked) then
        return false, "This discovery has no available audio here. No replacement sound was used."
    end
    local project = profile.music.project
    if packet.station ~= profile.station or packet.projectId ~= project.id
        or packet.projectRevision ~= project.revision
        or packet.workspaceGeneration ~= (profile.workspaceGeneration or 0)
        or packet.editVersion ~= profile.editVersion
        or packet.sequenceId ~= profile.sequenceId or packet.trackId ~= profile.trackId
    then
        return false, "Your workspace changed. Review the selected sound and try again."
    end
    if action == "DiscoveryPreview" then
        send(player, discovery.origin, source.id)
        return true
    end
    if action ~= "DiscoveryAdd" then
        return false, "Unknown discovery action."
    end
    if profile.recording then
        return false, "Stop recording before inserting a discovery note; your take stays intact."
    end
    local sequence = project.sequences[profile.sequenceId]
    local track = project.tracks[profile.trackId]
    local program = track and project.programs[track.programId]
    if not sequence or not track or not Sequence.integer(packet.bar, 1, sequence.bars)
        or not Sequence.integer(packet.step, 1, 16)
    then
        return false, "Choose a valid bar and step in the current sequence."
    end
    local pad = Hunt.pad(program, source.id)
    if not pad then
        return false, "Assign this collected sound in Sounds first. No pad assignment was overwritten."
    end
    local tick = (packet.bar - 1) * Sequence.TicksPerBar + (packet.step - 1) * Sequence.PPQ / 4
    for _, event in sequence.trackEvents[track.id] or {} do
        if event.pad == pad and event.tick == tick then
            return false, "This sound already has a note here. Choose another step or edit the existing note."
        end
    end
    -- EventPut owns validation, bounded undo, live schedule refresh and dirty state.
    -- The immutable expected revision also makes duplicate/stale requests harmless.
    local ok, problem, detail = core.command(player, profile, "EventPut", {
        expectedRevision = project.revision,
        sequenceId = sequence.id,
        trackId = track.id,
        pad = pad,
        tick = tick,
        velocity = if profile.fullLevel then 127 else profile.velocity,
    }, nil, persist, send)
    if not ok then
        return false, problem
    end
    return true, string.format(
        "%s added at bar %d, step %d (%s). Make your rhythm, then Save. Existing notes are retained.",
        discovery.label, packet.bar, packet.step, Hunt.address(pad)
    ), detail
end

return Session
