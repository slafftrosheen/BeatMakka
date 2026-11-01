-- Server-owned starter transaction. Uses the existing project and save schemas.
local Http = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Project = require(Shared.MusicProject)
local Groove = require(Shared.FirstGroove)
local Profiles = require(script.Parent.ProfileStore)
local WorkspaceState = require(script.Parent.WorkspaceState)
local Session = {}

function Session.start(profile, request)
    if profile.saving then
        return false, "Wait for the current save before starting another loop."
    end
    if type(request) ~= "table" or request.schema ~= 1 then
        return false, "Refresh First Groove before starting."
    end
    local current = profile.music.project
    if
        request.projectId ~= current.id
        or request.projectRevision ~= current.revision
        or request.editVersion ~= profile.editVersion
        or request.workspaceGeneration ~= (profile.workspaceGeneration or 0)
        or request.station ~= profile.station
    then
        return false, "Your workspace changed. Review it before starting another loop."
    end
    if request.mode ~= "example" and request.mode ~= "blank" then
        return false, "Choose Example loop or Start blank."
    end

    local candidate = Project.new("groove_" .. Http:GenerateGUID(false))
    local populated, problem = Groove.populate(candidate, request.mode, profile.unlocked)
    if not populated then
        return false, problem
    end
    local proposed = Project.clone(profile.music)
    -- The untouched factory workspace contains no personal work. Everything
    -- else, including a renamed empty project, gets an exact archived version.
    if not WorkspaceState.same(current, Project.new()) then
        local preserved, preservationProblem = WorkspaceState.preserve(proposed, current)
        if not preserved then
            return false, preservationProblem
        end
    end
    proposed.project = candidate
    local snapshot, captureProblem = Profiles.capture(profile, proposed, {})
    if not snapshot then
        return false, captureProblem
    end
    -- All readiness, version, archive and byte-budget gates precede this point.
    WorkspaceState.activate(profile, proposed)
    profile.bank = 1
    return true,
        if request.mode == "example"
            then "Example loop opened, not a finished Song. Tap a pad, change a note, then save your version. Previous work is in CRATES / Archives."
            else "Blank loop opened. Choose a sound and place its notes. Previous work is in CRATES / Archives."
end

return Session
