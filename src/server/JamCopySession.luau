-- Private, session-local consented jam copy. No storage write occurs here.
local Shared = game:GetService("ReplicatedStorage").Shared
local Project = require(Shared.MusicProject)
local JamCopy = require(Shared.JamCollaboration)
local Catalog = require(Shared.SampleCatalog)
local Profiles = require(script.Parent.ProfileStore)
local WorkspaceState = require(script.Parent.WorkspaceState)
local Session = {}

local function context(profile)
    return {
        projectId = profile.music.project.id, projectRevision = profile.music.project.revision,
        workspaceGeneration = profile.workspaceGeneration or 0,
        editVersion = profile.editVersion,
    }
end

function Session.summary(profile)
    local copy = profile.jamCopyTake
    if not copy then
        local receipt = profile.jamCopyReceipt
        if not receipt then return nil end
        local project = profile.music.project
        local draft = project.id == receipt.projectId and project.drafts[receipt.draftId]
        return {
            id = receipt.id, imported = true, inWorkspace = draft ~= nil,
            draftId = receipt.draftId, title = draft and draft.name or "Joint Draft",
            saved = draft ~= nil and draft.savedRevision == draft.revision,
            saveMode = profile.saveMode,
        }
    end
    return {
        id = copy.id, imported = false, title = copy.title,
        bpm = copy.bpm, bars = copy.bars, duration = copy.bars * 240 / copy.bpm,
        contributors = Project.clone(copy.contributors),
        context = context(profile), saveMode = profile.saveMode,
        saving = profile.saving == true,
    }
end

function Session.manage(profile, action, request)
    if type(request) ~= "table" or type(request.id) ~= "string" then
        return false, "Review your private joint copy before choosing Keep or Discard."
    end
    local copy = profile.jamCopyTake
    if not copy or copy.id ~= request.id then
        return false, if profile.jamCopyReceipt and profile.jamCopyReceipt.id == request.id
            then "That joint copy was already imported. Open SONG or use Undo/Redo."
            else "This joint copy is unavailable or expired with the session."
    end
    local live = context(profile)
    for key, value in live do
        if type(request.context) ~= "table" or request.context[key] ~= value then
            return false, "The project changed. Review the joint copy before confirming again."
        end
    end
    if action == "JamCopyDiscard" then
        profile.jamCopyTake = nil
        return true, "Temporary joint copy discarded. Both source projects are unchanged."
    end
    if action ~= "JamCopyKeep" then
        return false, "Unsupported joint-copy command."
    end
    if profile.saving then
        return false, "A save is in progress. Your joint copy remains available."
    end
    local ok, candidate, problem, selection = pcall(
        JamCopy.materialize, copy, profile.music.project,
        function(id)
            return Catalog.isPlaybackReady(id, profile.unlocked)
        end
    )
    if not ok then
        return false, "The joint draft could not be validated. No project changed."
    end
    if not candidate then return false, problem end
    local proposed = Project.clone(profile.music)
    proposed.project = candidate
    local captured, budgetProblem = Profiles.capture(profile, proposed, selection)
    if not captured then return false, budgetProblem end
    local history = table.clone(profile.musicUndo or {})
    table.insert(history, profile.music.project)
    if #history > Project.Limits.History then table.remove(history, 1) end
    -- Pure materialization, exact source-event check and full save budget have
    -- succeeded before any live mutation or consumption of the private copy.
    WorkspaceState.activate(profile, proposed, selection)
    profile.musicUndo = history
    profile.jamCopyTake = nil
    profile.jamCopyReceipt = {
        id = copy.id, projectId = candidate.id, draftId = selection.draftId,
    }
    return true,
        "Joint Draft created with both credits, but NOT SAVED. Open SONG, edit or Undo, then Save explicitly. Nothing was finished or published."
end

return Session
