-- One bounded session-local take. Keep/discard is called only after stage ownership/range checks.
local Http = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Project = require(Shared.MusicProject)
local Take = require(Shared.PerformanceTake)
local Catalog = require(Shared.SampleCatalog)
local Profiles = require(script.Parent.ProfileStore)
local WorkspaceState = require(script.Parent.WorkspaceState)
local Session = {}

local function context(profile)
    return {
        projectId = profile.music.project.id, projectRevision = profile.music.project.revision,
        workspaceGeneration = profile.workspaceGeneration or 0, editVersion = profile.editVersion,
    }
end

function Session.arm(profile, performance, sourceProject, draftId)
    if profile.performanceTake then
        return false, "Keep or discard your retained take before recording another. Capture OFF can still perform."
    end
    local valid, problem = Project.validate(sourceProject)
    if not valid then return false, problem end
    performance.captureProject = Project.clone(sourceProject)
    performance.captureDraftId = draftId
    performance.captureId = "take_" .. Http:GenerateGUID(false)
    -- Bound the pinned preparation snapshot. Retain separately checks the
    -- completed-bar capture; no unbounded performance history is accumulated.
    local bytes, message = Project.serializedBytes(performance, Project.Limits.MusicBytes)
    if not bytes then return false, message end
    return true
end

function Session.retain(profile, performance, now)
    if not performance.captureProject then return nil end
    if profile.performanceTake then
        return "The earlier temporary take was retained; it was not overwritten."
    end
    local ok, take, problem = pcall(Take.capture, performance, now, performance.captureId)
    if not ok then
        return "Take capture could not complete. Source music is unchanged; no draft was created."
    end
    if not take then return problem end
    profile.performanceTake = take
    return "Temporary take retained: " .. take.bars .. " completed bars. Keep as Draft, then Save at your instrument. It is not saved yet."
end

function Session.summary(profile)
    if not profile or not profile.music then return nil end
    local take = profile.performanceTake
    if not take then
        local receipt = profile.performanceTakeReceipt
        if not receipt then return nil end
        local here = profile.music.project.id == receipt.projectId
        local draft = if here then profile.music.project.drafts[receipt.draftId] else nil
        return {
            id = receipt.id, imported = true, draftId = receipt.draftId,
            title = draft and draft.name or "Street take", inWorkspace = draft ~= nil,
            saved = draft ~= nil and draft.savedRevision == draft.revision,
            saveMode = profile.saveMode,
        }
    end
    return {
        id = take.id, title = take.title, bars = take.bars, plannedBars = take.plannedBars,
        duration = take.schedule.duration, partial = take.partial, localOnly = take.localOnly,
        context = context(profile), saving = profile.saving == true, imported = false,
    }
end

function Session.command(profile, action, packet)
    if type(packet) ~= "table" or packet.schema ~= 1 or type(packet.id) ~= "string" then
        return false, "Review the retained take before choosing Keep or Discard."
    end
    local take = profile.performanceTake
    if not take or take.id ~= packet.id then
        local receipt = profile.performanceTakeReceipt
        return false, if receipt and receipt.id == packet.id
            then "This take was already imported. Use Song Mode or Undo/Redo; no duplicate was created."
            else "That temporary take is no longer available."
    end
    local current = context(profile)
    for key, value in current do
        if type(packet.context) ~= "table" or packet.context[key] ~= value then
            return false, "Your workspace changed. Review the take and confirm again."
        end
    end
    if action == "StageTakeDiscard" then
        profile.performanceTake = nil
        return true, "Temporary take discarded. Source music, drafts and saves are unchanged."
    elseif action ~= "StageTakeKeep" then
        return false, "Unsupported take action."
    end
    if profile.saving then
        return false, "A save is pending. Your temporary take remains available."
    end
    local ok, candidate, problem, selected = pcall(Take.materialize, take, profile.music.project, function(id)
        return Catalog.isPlaybackReady(id, profile.unlocked)
    end)
    if not ok then
        return false, "The draft could not be constructed safely. Music and the temporary take are unchanged."
    end
    if not candidate then return false, problem end
    local proposed = Project.clone(profile.music)
    proposed.project = candidate
    local snapshot, budgetProblem = Profiles.capture(profile, proposed, selected)
    if not snapshot then return false, budgetProblem end
    local before = profile.music.project
    local history = table.clone(profile.musicUndo or {})
    table.insert(history, before)
    if #history > Project.Limits.History then table.remove(history, 1) end
    -- All conversion, resolver equivalence and whole-profile gates precede mutation.
    WorkspaceState.activate(profile, proposed, selected)
    profile.musicUndo = history
    profile.performanceTake = nil
    profile.performanceTakeReceipt = { id = take.id, projectId = candidate.id, draftId = selected.draftId }
    return true, "Editable Draft created, NOT saved or finished. Leave to your instrument, open SONG, review and Save. Undo removes this import; Redo restores it."
end

return Session
