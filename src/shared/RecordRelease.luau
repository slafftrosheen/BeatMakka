-- Immutable release dependencies; mutable invitation permission lives outside record.
local Project = require(script.Parent.MusicProject)
local Transport = require(script.Parent.MusicTransport)
local Attribution = require(script.Parent.MusicAttribution)
local Versions = require(script.Parent.SampleVersions)
local Activities = require(script.Parent.QuayActivities)
local Record = { Limit = 8, AuditionSeconds = 15 }
local types = { sequence = "Pattern/Loop", song = "Draft Song", finished = "Finished Song" }
Record.Types = types
local function identity(value)
    return type(value) == "string" and #value > 0 and #value <= 96
        and value:match("^[%w_%-%.:]+$") ~= nil
end
local function same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in a do if not same(value, b[key]) then return false end end
    for key in b do if a[key] == nil then return false end end
    return true
end
function Record.cover(value)
    return if type(value) == "table" and Activities.validSleeve(value.motif, value.palette)
        then { motif = value.motif, palette = value.palette } else { motif = "waves", palette = "teal" }
end
function Record.source(music, reference)
    if type(reference) ~= "table" or not types[reference.kind] then return nil, "Choose a typed shelf item." end
    local project = music.project
    local object
    if reference.kind == "finished" then
        local song = music.finishedSongs[reference.id]
        project = song and song.project
        object = song
    else
        object = (if reference.kind == "sequence" then project.sequences else project.drafts)[reference.id]
    end
    if not object or object.revision ~= reference.revision then return nil, "That shelf revision changed. Review it again." end
    return project, object
end
local function publicNames(project, title)
    project.name = title
    for index, id in project.sequenceOrder do project.sequences[id].name = "Section " .. index end
    for index, id in project.trackOrder do project.tracks[id].name = "Part " .. index end
    local count = 0
    for _, program in project.programs do count += 1; program.name = "Kit " .. count end
    for _, draft in project.drafts do draft.name = title end
end
function Record.capture(music, reference, metadata, ready)
    local source, object = Record.source(music, reference)
    if not source then return nil, object end
    local schedule, problem = Transport.resolve(music.project, reference, music.finishedSongs,
        { requireReady = true, ready = ready })
    if not schedule then return nil, problem end
    if #schedule.events == 0 then return nil, "Add an available audible note before releasing a copy." end
    local project = Project.clone(source)
    local target = if reference.kind == "finished" then project.drafts[object.draftId] else object
    local attribution, creditProblem = Attribution.capture(source, target, metadata.creator)
    if not attribution then return nil, creditProblem end
    project.sequences, project.sequenceOrder, project.drafts, project.draftOrder = {}, {}, {}, {}
    local selected = {}
    local ref = Project.clone(reference)
    if reference.kind == "sequence" then selected[object.id] = true else
        local draft = Project.clone(target)
        project.drafts[draft.id], project.draftOrder = draft, { draft.id }
        for _, step in draft.steps do selected[step.sequenceId] = true end
        ref = { kind = "song", id = draft.id, revision = draft.revision }
    end
    for _, id in source.sequenceOrder do
        if selected[id] then
            project.sequences[id] = Project.clone(source.sequences[id])
            table.insert(project.sequenceOrder, id)
        end
    end
    -- Retain all tracks: a silent soloed track can affect the audible parts.
    project.programs = {}
    for _, track in project.tracks do project.programs[track.programId] = Project.clone(source.programs[track.programId]) end
    project.attribution = attribution
    local pins, pinProblem = Versions.capture(project)
    if not pins then return nil, pinProblem end
    project.sampleVersions = pins
    publicNames(project, metadata.title)
    local cover = Record.cover(metadata.cover or object.cover)
    for _, draft in project.drafts do draft.cover = Project.clone(cover) end
    local record = { schema = 1, id = metadata.id, revision = 1,
        title = metadata.title, creator = Project.clone(metadata.creator),
        attribution = attribution, source = Project.clone(reference),
        sourceProjectId = source.id, sourceProjectRevision = source.revision,
        type = types[reference.kind], project = project, ref = ref, cover = cover,
        createdAt = metadata.createdAt, requestId = metadata.requestId,
        localOnly = schedule.localOnly == true }
    local valid, message = Record.validate(record)
    if valid then
        local resolved, resolveProblem = Record.resolve(record, ready, false)
        if not resolved then return nil, resolveProblem end
        if schedule.duration ~= resolved.duration or schedule.totalBars ~= resolved.totalBars
            or not same(schedule.events, resolved.events) or not same(schedule.tempoSchedule, resolved.tempoSchedule) then
            return nil, "The release would differ from this musical version. Source music is unchanged."
        end
    end
    return if valid then record else nil, message
end
function Record.validate(record)
    if type(record) ~= "table" or record.schema ~= 1 or record.revision ~= 1
        or not identity(record.id) or not identity(record.requestId)
        or type(record.title) ~= "string" or #record.title < 1 or #record.title > 80
        or type(record.creator) ~= "table" or not Attribution.valid(record.attribution)
        or not record.attribution or type(record.source) ~= "table"
        or not types[record.source.kind] or record.type ~= types[record.source.kind] or type(record.ref) ~= "table"
        or not identity(record.source.id) or type(record.source.revision) ~= "number"
        or record.source.revision % 1 ~= 0 or record.source.revision < 1 or record.source.revision > 1e12
        or not identity(record.sourceProjectId) or type(record.sourceProjectRevision) ~= "number"
        or record.sourceProjectRevision % 1 ~= 0 or record.sourceProjectRevision < 1 or record.sourceProjectRevision > 1e12
        or (record.ref.kind ~= "sequence" and record.ref.kind ~= "song")
        or type(record.createdAt) ~= "number" or record.createdAt % 1 ~= 0
        or type(record.cover) ~= "table" or not Activities.validSleeve(record.cover.motif, record.cover.palette)
        or type(record.localOnly) ~= "boolean" then return false, "Unsupported record release; original retained." end
    local credits = Attribution.capture({}, nil, record.creator)
    if not credits then return false, "Invalid release creator." end
    local valid, problem = Project.validate(record.project)
    if not valid then return false, problem end
    if record.project.sampleVersions == nil or record.project.attribution == nil then return false, "Release identity is incomplete." end
    if not same(record.attribution, record.project.attribution) then return false, "Release credits differ from their stored project." end
    local schedule, message = Transport.resolve(record.project, record.ref, nil, { includeUnavailable = true })
    return schedule ~= nil, message
end
function Record.validateLibrary(music)
    if type(music.releases) ~= "table" or type(music.releaseOrder) ~= "table"
        or type(music.releaseRequests) ~= "table" or #music.releaseOrder > Record.Limit then return false, "Invalid release library." end
    local seen, count = {}, 0
    for index, id in music.releaseOrder do
        local entry = music.releases[id]
        if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #music.releaseOrder
            or not identity(id) or seen[id] or type(entry) ~= "table" or entry.id ~= id
            or type(entry.allowRemix) ~= "boolean" or type(entry.permissionRevision) ~= "number"
            or entry.permissionRevision % 1 ~= 0 or entry.permissionRevision < 1 or entry.permissionRevision > 1e12
            or type(entry.record) ~= "table" or entry.record.id ~= id then return false, "Invalid release permission/index." end
        local valid, problem = Record.validate(entry.record)
        if not valid then return false, problem end
        seen[id] = true
    end
    for id in music.releases do count += 1; if not seen[id] then return false, "Unindexed release." end end
    if count ~= #music.releaseOrder then return false, "Invalid release count." end
    local requests = 0
    for id, releaseId in music.releaseRequests do
        requests += 1
        if not identity(id) or not seen[releaseId] or music.releases[releaseId].record.requestId ~= id then
            return false, "Invalid release receipt."
        end
    end
    if requests ~= count then return false, "Missing release receipt." end
    return true
end
function Record.resolve(record, ready, audition)
    local schedule, problem = Transport.resolve(record.project, record.ref, nil, { requireReady = true, ready = ready })
    if not schedule then return nil, problem end
    schedule.title = record.title
    if audition then
        schedule.duration = math.min(schedule.duration, Record.AuditionSeconds)
        local events = {}
        for _, event in schedule.events do if event.at < schedule.duration then table.insert(events, event) end end
        schedule.events = events
        schedule.completeAt = schedule.duration + Transport.AudioTailSeconds
    end
    return schedule
end
function Record.summary(entry)
    local r = entry.record
    return { id = r.id, revision = r.revision, title = r.title, type = r.type,
        cover = Project.clone(r.cover), attribution = Project.clone(r.attribution),
        source = Project.clone(r.source), allowRemix = entry.allowRemix,
        permissionRevision = entry.permissionRevision, localOnly = r.localOnly,
        packLabel = Versions.label(r.project.sampleVersions), createdAt = r.createdAt }
end
function Record.remix(record, owner, id, ready, filteredTitle)
    local schedule, problem = Record.resolve(record, ready, false)
    if not schedule then return nil, problem end
    local attribution, creditProblem = Attribution.remix(record, owner)
    if not attribution then return nil, creditProblem end
    local project = Project.clone(record.project)
    if type(filteredTitle) ~= "string" or #filteredTitle < 1 or #filteredTitle > 80 then
        return nil, "A currently filtered shared title is required for this copy."
    end
    local name = "Remix / " .. filteredTitle
    while #name > 80 do name = name:sub(1, utf8.offset(name, -1) - 1) end
    project.id, project.revision, project.name = id, 1, name
    project.attribution = attribution
    for _, sequence in project.sequences do sequence.savedRevision = 0 end
    for _, draft in project.drafts do draft.savedRevision, draft.name = 0, filteredTitle end
    local valid, message = Project.validate(project)
    if valid then
        local actual, resolveProblem = Transport.resolve(project, record.ref, nil, { requireReady = true, ready = ready })
        if not actual then return nil, resolveProblem end
        local expected = Project.clone(schedule.events)
        for _, event in expected do
            event.route.projectId = id
            event.route.key = id .. ":" .. event.trackId .. ":" .. event.programId .. ":" .. event.pad
        end
        if schedule.duration ~= actual.duration or schedule.totalBars ~= actual.totalBars
            or not same(expected, actual.events) or not same(schedule.tempoSchedule, actual.tempoSchedule) then
            return nil, "This remix would differ from its release. Both projects are unchanged."
        end
    end
    return if valid then project else nil, message,
        { sequenceId = project.sequenceOrder[1], draftId = project.draftOrder[1], trackId = project.trackOrder[1] }
end
return Record
