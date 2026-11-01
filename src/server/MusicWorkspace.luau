-- Public workstation boundary. Existing callers retain the same API.
-- Core is the unchanged original editor/transport implementation; focused
-- command extensions still run behind MusicService's ownership/rate checks.
local Core = require(script.Parent.MusicWorkspaceCore)
local Discoveries = require(script.Parent.DiscoverySession)
local Workspace = table.clone(Core)

function Workspace.handles(action)
    return Discoveries.handles(action) or Core.handles(action)
end

function Workspace.command(player, profile, action, a, b, persist, send)
    if Discoveries.handles(action) then
        Core.sync(profile)
        return Discoveries.command(player, profile, action, a, Core, persist, send)
    end
    return Core.command(player, profile, action, a, b, persist, send)
end

return Workspace
