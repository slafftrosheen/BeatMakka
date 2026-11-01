-- Discovery interactions use the existing catalogue, program and sequence IDs.
local Catalog = require(script.Parent.SampleCatalog)
local Discoveries = require(script.Parent.DiscoveryCatalog)
local Sequence = require(script.Parent.MusicSequence)
local Hunt = {
    Schema = 1,
    Order = Discoveries.Order,
    Echo = { I01 = { 1, 4, 9, 12 }, I02 = { 1, 7, 11 }, I03 = { 1, 5, 9, 13 } },
}

function Hunt.source(id)
    local discovery = Discoveries.ById[id]
    if not discovery then
        return nil
    end
    -- No fallback: Studio substitutions are explicit catalogue bindings.
    return Catalog.discoveryFor(id), discovery
end

function Hunt.pad(program, sampleId)
    if not program or not program.pads or type(sampleId) ~= "string" then
        return nil
    end
    local source = Catalog.ById[sampleId]
    local preferred = source and source.absolutePad
    local definition = preferred and program.pads[tostring(preferred)]
    if definition and definition.sampleId == sampleId then
        return preferred
    end
    for pad = 1, 64 do
        definition = program.pads[tostring(pad)]
        if definition and definition.sampleId == sampleId then
            return pad
        end
    end
    return nil
end

function Hunt.address(pad)
    return if Sequence.integer(pad, 1, 64)
        then string.format("%s%02d", string.char(65 + math.floor((pad - 1) / 16)), (pad - 1) % 16 + 1)
        else "NOT ASSIGNED"
end

function Hunt.packet(state, id, step)
    local m = state and state.music
    if not m or not m.sequence or not m.track then
        return nil
    end
    return {
        schema = Hunt.Schema,
        discoveryId = id,
        station = state.station,
        projectId = m.projectId,
        projectRevision = m.projectRevision,
        workspaceGeneration = m.workspaceGeneration or 0,
        editVersion = state.editVersion,
        sequenceId = m.sequenceId,
        trackId = m.trackId,
        bar = m.bar,
        step = step,
    }
end

-- A note-grid exercise, not a judgement of musical quality or acoustic timing.
-- It never writes notes, progress or rewards, and is never a completion gate.
function Hunt.echoMatches(sequence, trackId, pad, bar, id)
    local target = Hunt.Echo[id]
    if not target or not sequence or not Sequence.integer(bar, 1, sequence.bars) or not pad then
        return false
    end
    if sequence.trackMutes[trackId] or (sequence.trackPadMutes[trackId] or {})[tostring(pad)] then
        return false
    end
    local expected, observed = {}, {}
    for _, step in target do
        expected[(step - 1) * Sequence.PPQ / 4] = true
    end
    local start = (bar - 1) * Sequence.TicksPerBar
    for _, event in sequence.trackEvents[trackId] or {} do
        if event.pad == pad and not event.muted and event.velocity > 0
            and event.tick >= start and event.tick < start + Sequence.TicksPerBar
        then
            observed[event.tick - start] = true
        end
    end
    for tick in expected do
        if not observed[tick] then
            return false
        end
    end
    for tick in observed do
        if not expected[tick] then
            return false
        end
    end
    return true
end

return Hunt
