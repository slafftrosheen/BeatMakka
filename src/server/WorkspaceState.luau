-- Transactional workspace boundaries shared by restore, archives and history.
-- Callers validate/capture a proposed music document before activate() mutates a profile.
local Http = game:GetService("HttpService")
local Project = require(game:GetService("ReplicatedStorage").Shared.MusicProject)
local State = {}

-- Save markers are acknowledgements, not musical content. All other fields,
-- including revision, routing, sample identities and event IDs, compare exactly.
function State.same(a, b)
    if type(a) ~= type(b) then
        return false
    end
    if type(a) ~= "table" then
        return a == b
    end
    for key, value in a do
        if key ~= "savedRevision" and not State.same(value, b[key]) then
            return false
        end
    end
    for key in b do
        if key ~= "savedRevision" and a[key] == nil then
            return false
        end
    end
    return true
end

-- Preserve a version, not merely a project ID. Different branches of the same
-- project must never overwrite one another. An editable archive can exchange its
-- slot with the current workspace: its former contents become the live project.
function State.preserve(music, project, exchangeId)
    for _, id in music.archiveOrder do
        local archive = music.archives[id]
        if archive.project and State.same(archive.project, project) then
            return true
        end
    end
    local exchange = exchangeId and music.archives[exchangeId]
    if exchange and exchange.kind == "workspace" and exchange.readOnly == false then
        exchange.project = Project.clone(project)
        exchange.name = project.name
        return true
    end
    -- The existing migration contract reserves one additional legacy archive.
    if #music.archiveOrder >= Project.Limits.Archives + 1 then
        return false, "Archive library is full. Both workspaces remain unchanged."
    end
    local id = "workspace_" .. Http:GenerateGUID(false)
    music.archives[id] = {
        id = id,
        name = project.name,
        kind = "workspace",
        project = Project.clone(project),
        readOnly = false,
    }
    table.insert(music.archiveOrder, id)
    return true
end

local function selection(objects, order, id)
    return if type(id) == "string" and objects[id] then id else order[1]
end

-- No yields. A workspace replacement has one commit point, then invalidates all
-- input/recording/history from the old workspace before it can be projected.
function State.activate(profile, music, selected)
    selected = selected or {}
    local project = music.project
    profile.music = music
    profile.sequenceId = selection(project.sequences, project.sequenceOrder, selected.sequenceId)
    profile.trackId = selection(project.tracks, project.trackOrder, selected.trackId)
    profile.draftId = selection(project.drafts, project.draftOrder, selected.draftId)
    local finished = selected.selectedFinishedSongId or profile.selectedFinishedSongId
    profile.selectedFinishedSongId = if finished and music.finishedSongs[finished]
        then finished
        else nil
    profile.bar = 1
    profile.playing = false
    profile.recording = false
    profile.noteRepeat = false
    profile.epoch = (profile.epoch or 0) + 1
    profile.startedAt = 0
    profile.transport = nil
    profile.nextSequence = nil
    profile.noteDeltas = {}
    profile.noteRequests = {}
    profile.noteRequestOrder = {}
    profile.recordHistoryEpoch = nil
    profile.musicUndo = {}
    profile.musicRedo = {}
    profile.workspaceGeneration = (profile.workspaceGeneration or 0) + 1
    profile.editVersion += 1
end

-- Undo/redo creates a new revision; it never rewinds version counters or ID
-- allocation. Otherwise a different edit could reuse a revision awaiting save.
function State.history(current, source)
    local valid, problem = Project.validate(source)
    if not valid then
        return nil, problem
    end
    if current.id ~= source.id then
        return nil, "This history belongs to another workspace. Current work is unchanged."
    end
    local revision = math.max(current.revision, source.revision)
    for _, project in { current, source } do
        for _, key in { "sequences", "drafts", "tracks", "programs" } do
            for _, object in project[key] do
                revision = math.max(revision, object.revision, object.savedRevision or 0)
            end
        end
    end
    if revision >= 1e12 then
        return nil, "Revision limit reached. History and current work are unchanged."
    end
    local restored = Project.clone(source)
    restored.revision = revision + 1
    restored.nextId = math.max(current.nextId, source.nextId)
    for _, key in { "sequences", "drafts", "tracks", "programs" } do
        for id, object in restored[key] do
            object.revision = restored.revision
            if key == "sequences" or key == "drafts" then
                local previous = current[key][id]
                object.savedRevision = previous and previous.savedRevision or 0
            end
        end
    end
    valid, problem = Project.validate(restored)
    return if valid then restored else nil, problem
end

return State
