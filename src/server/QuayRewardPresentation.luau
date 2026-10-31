local Rewards = require(game.ReplicatedStorage.Shared.QuayRewards)
local P = {}
function P.player(player, profile)
    local equipped = Rewards.sanitize(profile.rewards, profile.quay)
    player:SetAttribute("QuayTitle", equipped.title)
    player:SetAttribute("QuayBadge", equipped.badge)
end
function P.roamer(van, profile)
    local id = Rewards.sanitize(profile.rewards, profile.quay).roamer
    if van.rewardLook == id then
        return
    end
    van.rewardLook = id
    local old = van.model:FindFirstChild("RewardLights")
    if old then
        old:Destroy()
    end
    local item = Rewards.find("roamer", id)
    if not item then
        return
    end
    local group = Instance.new("Model")
    group.Name = "RewardLights"
    for _, side in { -1, 1 } do
        local strip = Instance.new("Part")
        strip.Name = "RunningLight"
        strip.Anchored = true
        strip.CanCollide, strip.CanTouch, strip.CanQuery = false, false, false
        strip.CastShadow = false
        strip.Size = Vector3.new(14, 0.16, 0.16)
        strip.Material = Enum.Material.Neon
        strip.Color = item.color
        strip.CFrame = van.model:GetPivot() * CFrame.new(0, -3.35, side * 4.62)
        strip.Parent = group
    end
    group.Parent = van.model
end
return P
