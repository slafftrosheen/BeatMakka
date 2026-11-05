-- Exact catalogue versions accompany copied music. No fallback/substitution.
local Catalog = require(script.Parent.SampleCatalog)
local Versions = {}
local function short(value)
    return type(value) == "string" and #value > 0 and #value <= 128
end
function Versions.current(id)
    local sample = Catalog.ById[id]
    local pack = sample and (Catalog.PackById[sample.pack] or Catalog.LocalPackById[sample.pack]
        or (Catalog.PlannedPack.id == sample.pack and Catalog.PlannedPack))
    return if pack then { packId = pack.id, revision = tostring(pack.mappingRevision) } else nil
end
function Versions.valid(pins)
    if pins == nil then return true end
    if type(pins) ~= "table" then return false end
    local count = 0
    for id, pin in pins do
        count += 1
        if count > 1536 or not short(id) or type(pin) ~= "table"
            or not short(pin.packId) or not short(pin.revision) then return false end
    end
    return true
end
function Versions.capture(project, historical, routedOnly)
    local result = {}
    local routed = {}
    for _, track in project.tracks do routed[track.programId] = true end
    for id, program in project.programs do
        if routedOnly and not routed[id] then continue end
        for _, pad in program.pads do
            if pad.sampleId ~= "" then
                local pin = project.sampleVersions and project.sampleVersions[pad.sampleId]
                local packId = program.sourcePackId or program.packId
                local sample = Catalog.ById[pad.sampleId]
                if not pin and type(packId) == "string" and program.mappingRevision ~= nil
                    and (not sample or sample.pack == packId) then
                    pin = { packId = packId, revision = tostring(program.mappingRevision) }
                end
                local previous = result[pad.sampleId]
                local current = pin or (if historical then { packId = sample and sample.pack or "unavailable", revision = "unverified" }
                    else Versions.current(pad.sampleId)) or { packId = "unavailable", revision = "unknown" }
                if previous and (previous.packId ~= current.packId or previous.revision ~= current.revision) then
                    return nil, "One sample has conflicting pack versions; no release was created."
                end
                result[pad.sampleId] = if pin then table.clone(pin)
                    else current
            end
        end
    end
    return result
end
function Versions.unverified(pins)
    if pins == nil then return true end
    for _, pin in pins do if pin.revision == "unverified" or pin.revision == "unknown" then return true end end
    return false
end
function Versions.merge(target, incoming)
    local result = {}
    for id, pin in target or {} do result[id] = table.clone(pin) end
    for id, pin in incoming or {} do
        local old = result[id]
        if old and (old.packId ~= pin.packId or old.revision ~= pin.revision) then
            return nil, "Copied music conflicts with a retained sample version: " .. id .. ". Both sources are unchanged."
        end
        result[id] = table.clone(pin)
    end
    return result
end
function Versions.matches(id, pins)
    if pins == nil then return true end
    local pin, current = pins[id], Versions.current(id)
    return pin ~= nil and current ~= nil and pin.packId == current.packId and pin.revision == current.revision
end
function Versions.label(pins)
    local seen, result = {}, {}
    for _, pin in pins or {} do
        local label = pin.packId .. " / " .. pin.revision
        if not seen[label] then seen[label] = true; table.insert(result, label) end
    end
    table.sort(result)
    return if #result > 0 then table.concat(result, "; ") else "No sample pack"
end
return Versions
