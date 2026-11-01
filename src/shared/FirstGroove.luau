-- First Groove is authored musical data, not another sequencer or audio engine.
local Catalog = require(script.Parent.SampleCatalog)
local Sequence = require(script.Parent.MusicSequence)
local Groove = { TemplateId = "needle_quay_first_groove_v1", Bars = 2 }

Groove.Roles = {
    { id = "drums", label = "DRUMS", pad = 1, choices = { 1, 2 }, hint = "Choose a kick, then change its rhythm." },
    { id = "bass", label = "BASS", pad = 17, choices = { 17, 19 }, hint = "Choose a bass sound. Leave room between hits." },
    { id = "hook", label = "HOOK", pad = 33, choices = { 33, 34 }, hint = "Try a vocal hook, or mute it to hear the difference." },
    { id = "quay", label = "HARBOUR", pad = 58, choices = { 58, 57 }, hint = "Add a little harbour texture, not a wall of sound." },
}

-- Sixteenth-note positions across two bars. These are ordinary absolute-pad
-- events at 960 PPQ; A-D remain sample banks, never sequence identities.
local parts = {
    { pad = 1, velocity = 108, steps = { 1, 9, 16, 17, 25 } },
    { pad = 5, velocity = 100, steps = { 5, 13, 21, 29 } },
    { pad = 9, velocity = 66, steps = { 3, 7, 11, 15, 19, 23, 27, 31 } },
    { pad = 17, velocity = 92, steps = { 1, 17 } },
    { pad = 33, velocity = 82, steps = { 9 } },
    { pad = 58, velocity = 58, steps = { 25 } },
}

function Groove.address(pad)
    return string.format("%s%02d", string.char(65 + math.floor((pad - 1) / 16)), (pad - 1) % 16 + 1)
end

function Groove.isStarter(sequence)
    local source = sequence and sequence.firstGroove
    return type(source) == "table" and source.templateId == Groove.TemplateId
end

function Groove.availability(unlocked)
    local localPreview = false
    for _, part in parts do
        local sample = Catalog.List[part.pad]
        if not sample or not Catalog.isPlaybackReady(sample.id, unlocked) then
            return false,
                "Example needs " .. Groove.address(part.pad) .. " / "
                    .. (sample and sample.label or "missing sample")
                    .. ". Start blank or use the full instrument; no replacement sound was chosen."
        end
        if not Catalog.isReady(sample.id, unlocked) then
            localPreview = true
        end
    end
    return true, nil, localPreview
end

-- Mutates only the caller's newly allocated candidate. The server validates
-- and captures the complete candidate before admitting it to the live profile.
function Groove.populate(project, mode, unlocked)
    if mode ~= "example" and mode ~= "blank" then
        return false, "Choose Example loop or Start blank."
    end
    if mode == "example" then
        local ready, problem = Groove.availability(unlocked)
        if not ready then
            return false, problem
        end
    end
    local sequence = project.sequences[project.sequenceOrder[1]]
    local trackId = project.trackOrder[1]
    local track = project.tracks[trackId]
    local program = project.programs[track.programId]
    project.name = if mode == "example" then "First Groove - example" else "My first groove"
    project.defaultBpm = Catalog.PlannedPack.bpm
    sequence.name = if mode == "example" then "Example - Harbour Pulse" else "My first loop"
    sequence.bpm, sequence.bars = project.defaultBpm, Groove.Bars
    sequence.firstGroove = { templateId = Groove.TemplateId, mode = mode }
    track.name = "First Groove"
    program.name = Catalog.PlannedPack.label
    program.packId, program.mappingRevision = Catalog.PlannedPack.id, Catalog.PlannedPack.mappingRevision
    local events = {}
    if mode == "example" then
        for _, part in parts do
            local sample = Catalog.List[part.pad]
            if program.pads[tostring(part.pad)].sampleId ~= sample.id then
                return false, "The starter kit mapping changed; previous work is unchanged."
            end
            for _, step in part.steps do
                project.nextId += 1
                table.insert(events, {
                    eventId = "event_" .. project.nextId,
                    tick = (step - 1) * (Sequence.PPQ / 4),
                    pad = part.pad,
                    velocity = part.velocity,
                })
            end
        end
    end
    sequence.trackEvents[trackId] = Sequence.sort(events)
    return true
end

return Groove
