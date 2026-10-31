local Rewards = require(game.ReplicatedStorage.Shared.QuayRewards)
local Icons = require(script.Parent.GameIcons)
local C = {}
function C.update(follower)
    local q = follower.state and follower.state.quay
    local id = q and q.rewards and q.rewards.companion or "none"
    if follower.charmId ~= id then
        C.clear(follower)
        follower.charmId = id
        local item = Rewards.find("companion", id)
        if item then
            local part = Instance.new("Part")
            part.Name = "EarnedCompanionCharm"
            part.Shape = Enum.PartType.Ball
            part.Size = Vector3.new(0.38, 0.38, 0.38)
            part.Anchored = true
            part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
            part.CastShadow = false
            part.Material = Enum.Material.Neon
            part.Color = item.color
            local icon = Instance.new("BillboardGui")
            icon.Size = UDim2.fromOffset(24, 24)
            icon.MaxDistance = 40
            icon.Parent = part
            Icons.make(icon, item.icon, item.color, 24)
            part.Parent = follower.model
            follower.charm = part
        end
    end
    if follower.charm then
        follower.charm.CFrame = follower.facing
            * CFrame.new(1.15, 3.6 + math.sin(os.clock() * 2) * 0.08, 0)
        follower.charm.Transparency = if follower.shown then 0 else 1
        follower.charm.BillboardGui.Enabled = follower.shown == true
    end
end
function C.clear(follower)
    if follower.charm then
        follower.charm:Destroy()
        follower.charm = nil
    end
    follower.charmId = nil
end
return C
