-- Stored musical authorship. Names here are server-sourced Roblox names, not titles.
local Attribution = { Limit = 16 }
local function stringValue(value, maximum)
    return type(value) == "string" and #value > 0 and #value <= maximum
end
local function person(value)
    return type(value) == "table" and type(value.userId) == "number"
        and value.userId % 1 == 0 and math.abs(value.userId) <= 1e12
        and stringValue(value.name, 64)
end
function Attribution.valid(value)
    if value == nil then return true end
    if type(value) ~= "table" or value.schema ~= 1 or not person(value.creator)
        or type(value.contributors) ~= "table" or #value.contributors > Attribution.Limit
        or type(value.sources) ~= "table" or #value.sources > Attribution.Limit then return false end
    local seen = {}
    for index, author in value.contributors do
        if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #value.contributors
            or not person(author) or not stringValue(author.role, 40) or seen[author.userId] then return false end
        seen[author.userId] = true
    end
    if not seen[value.creator.userId] then return false end
    for index, source in value.sources do
        if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #value.sources
            or type(source) ~= "table" or not stringValue(source.releaseId, 96)
            or source.revision ~= 1 or not person(source.creator) then return false end
    end
    return true
end
function Attribution.capture(project, object, owner)
    local prior = project.attribution
    if not Attribution.valid(prior) or not person(owner) then return nil, "Invalid music credits; originals retained." end
    local objectAttribution = object and object.attribution
    if not Attribution.valid(objectAttribution) then return nil, "Invalid object credits; originals retained." end
    local result = { schema = 1, creator = table.clone((objectAttribution and objectAttribution.creator) or (prior and prior.creator) or owner),
        contributors = {}, sources = {} }
    local seen = {}
    local seenSources = {}
    local function addSources(attribution)
        for _, source in attribution and attribution.sources or {} do
            local key = source.releaseId .. ":" .. source.revision .. ":" .. source.creator.userId
            if not seenSources[key] then
                if #result.sources >= Attribution.Limit then return false end
                seenSources[key] = true
                table.insert(result.sources, { releaseId = source.releaseId, revision = source.revision,
                    creator = table.clone(source.creator) })
            end
        end
        return true
    end
    local function add(author, fallback)
        if not person(author) then return false end
        if not seen[author.userId] then
            if #result.contributors >= Attribution.Limit then return false end
            seen[author.userId] = true
            table.insert(result.contributors, { userId = author.userId, name = author.name,
                role = if stringValue(author.role, 40) then author.role else fallback })
        end
        return true
    end
    if not add(result.creator, "Original creator") then return nil, "Credit capacity reached." end
    for _, author in (prior and prior.contributors or {}) do
        if not add(author, "Contributor") then return nil, "Credit capacity reached; nobody was dropped." end
    end
    local function collect(selected)
        if not selected then return true end
        local attribution = selected.attribution
        if not Attribution.valid(attribution) or not addSources(attribution) then return false end
        local collaboration = selected.collaboration
        if collaboration ~= nil and type(collaboration) ~= "table" then return false end
        if selected.contributors ~= nil and type(selected.contributors) ~= "table" then return false end
        if collaboration and collaboration.contributors ~= nil and type(collaboration.contributors) ~= "table" then return false end
        local lists = { selected.contributors or {}, collaboration and collaboration.contributors or {},
            attribution and attribution.contributors or {} }
        for _, list in lists do
            if type(list) ~= "table" or #list > Attribution.Limit then return false end
            for _, author in list do if not add(author, "Collaborator") then return false end end
        end
        return true
    end
    if not collect(object) then return nil, "Unsupported or excessive collaborator credits; originals retained." end
    -- A freshly arranged draft can contain a credited joint loop without having
    -- top-level contributors of its own. Gather only its selected dependencies.
    if object and type(object.steps) == "table" and project.sequences then
        for _, step in object.steps do
            if not collect(project.sequences[step.sequenceId]) then
                return nil, "Dependency credit capacity reached; nobody was dropped."
            end
        end
    end
    if not add(owner, if prior then "Remixer" else "Creator") then return nil, "Credit capacity reached." end
    if not addSources(prior) then return nil, "Source lineage capacity reached; originals retained." end
    return result
end
function Attribution.merge(attributes, owner, contributors)
    local result, problem = Attribution.capture({}, { contributors = contributors }, owner)
    if not result then return nil, problem end
    local primary
    for _, attribution in attributes do
        primary = primary or attribution.creator
        result, problem = Attribution.capture({ attribution = result }, { attribution = attribution }, owner)
        if not result then return nil, problem end
    end
    if primary then result.creator = table.clone(primary) end
    return result
end
function Attribution.remix(record, owner)
    local result, problem = Attribution.capture({ attribution = record.attribution }, nil, owner)
    if not result then return nil, problem end
    if #result.sources >= Attribution.Limit then return nil, "Release lineage capacity reached; credits were retained." end
    table.insert(result.sources, { releaseId = record.id, revision = record.revision,
        creator = table.clone(record.creator) })
    return result
end
return Attribution
