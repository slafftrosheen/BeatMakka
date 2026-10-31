local Project = require(script.Parent.MusicProject)
local Transport = require(script.Parent.MusicTransport)
local Finished = {}

-- Capture is synchronous. The storage service must commit the returned object
-- before adding it to the advertised library or reporting a successful finish.
function Finished.capture(
    project,
    draftId,
    expectedDraftRevision,
    expectedProjectRevision,
    metadata,
    ready
)
    metadata = metadata or {}
    local valid, message = Project.validate(project)
    if not valid then
        return nil, message
    end
    local draft = project.drafts[draftId]
    if
        not draft
        or draft.revision ~= expectedDraftRevision
        or project.revision ~= expectedProjectRevision
    then
        return nil,
            "The draft or its instruments changed. Review it and finish the current revision."
    end
    if
        type(metadata.id) ~= "string"
        or #metadata.id < 1
        or #metadata.id > 96
        or type(metadata.requestId) ~= "string"
        or #metadata.requestId < 1
        or #metadata.requestId > 96
        or (metadata.revision ~= nil and metadata.revision ~= 1)
        or type(metadata.title or draft.name) ~= "string"
        or #(metadata.title or draft.name) > 80
    then
        return nil, "A stable finish request, song ID and title are required."
    end
    local schedule, resolveMessage = Transport.resolve(
        project,
        { kind = "song", id = draftId, revision = draft.revision },
        nil,
        { requireReady = true, ready = ready }
    )
    if not schedule then
        return nil, resolveMessage
    end
    if #schedule.events == 0 then
        return nil, "Add at least one available audible sound before finishing this song."
    end
    local dependency = Project.clone(project)
    dependency.drafts = { [draftId] = Project.clone(draft) }
    dependency.draftOrder = { draftId }
    dependency.sequences, dependency.sequenceOrder = {}, {}
    local seen = {}
    for _, step in draft.steps do
        if not seen[step.sequenceId] then
            seen[step.sequenceId] = true
            dependency.sequences[step.sequenceId] =
                Project.clone(project.sequences[step.sequenceId])
            table.insert(dependency.sequenceOrder, step.sequenceId)
        end
    end
    -- All stable tracks are retained: even a soloed track with no notes can
    -- affect another part. Programs are copied once, never mutable references.
    local programs = {}
    for _, track in dependency.tracks do
        programs[track.programId] = dependency.programs[track.programId]
    end
    dependency.programs = programs
    local result = {
        schema = 1,
        kind = "FinishedSong",
        id = metadata.id,
        revision = 1,
        title = metadata.title or draft.name,
        requestId = metadata.requestId,
        draftId = draftId,
        draftRevision = draft.revision,
        dependencyRevision = project.revision,
        sourceProjectId = project.id,
        project = dependency,
        duration = schedule.duration,
        totalBars = schedule.totalBars,
        tempoSchedule = Project.clone(schedule.tempoSchedule),
        cover = Project.clone(if metadata.cover ~= nil then metadata.cover else draft.cover),
        createdAt = metadata.createdAt or 0,
        audioTailSeconds = Transport.AudioTailSeconds,
        localOnly = schedule.localOnly == true,
        listeningReview = if schedule.localOnly then "pending" else nil,
    }
    -- Cover belongs to this captured revision, including an explicitly copied
    -- Sleeve Studio design; today's design cannot change an earlier song.
    result.project.drafts[draftId].cover = Project.clone(result.cover)
    local bytes, byteMessage = Project.serializedBytes(result, Project.Limits.ProjectBytes)
    if not bytes then
        return nil, byteMessage
    end
    return result
end

function Finished.ready(snapshot, ready)
    if type(snapshot) ~= "table" then
        return false, "Choose a saved Finished Song."
    end
    local schedule, message = Transport.resolve(
        snapshot.project,
        { kind = "finished", id = snapshot.id, revision = snapshot.revision },
        { [snapshot.id] = snapshot },
        { requireReady = true, ready = ready }
    )
    if not schedule then
        return false, message
    end
    if #schedule.events == 0 then
        return false, "This song has no available audible events."
    end
    return true, nil, schedule
end

function Finished.summary(snapshot, ready)
    local available, message = Finished.ready(snapshot, ready)
    return {
        id = snapshot.id,
        revision = snapshot.revision,
        title = snapshot.title,
        duration = snapshot.duration,
        totalBars = snapshot.totalBars,
        cover = Project.clone(snapshot.cover),
        ready = available,
        readinessError = message,
        createdAt = snapshot.createdAt,
        localOnly = snapshot.localOnly == true,
        listeningReview = snapshot.listeningReview,
    }
end

function Finished.editCopy(snapshot, projectId)
    local copy = Project.clone(snapshot.project)
    copy.id, copy.name, copy.revision =
        projectId or (snapshot.id .. "_edit"), snapshot.title .. " edit", 1
    for _, sequence in copy.sequences do
        sequence.savedRevision = 0
    end
    for _, draft in copy.drafts do
        draft.savedRevision = 0
    end
    copy.import = {
        kind = "finished_edit_copy",
        finishedSongId = snapshot.id,
        finishedSongRevision = snapshot.revision,
    }
    return copy
end

return Finished
