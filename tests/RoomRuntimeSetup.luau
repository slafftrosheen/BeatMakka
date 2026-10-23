-- Explicit Server-only Studio MCP fixture. Never included in the game build.
assert(game:GetService("RunService"):IsStudio(), "QA fixture requires Studio")
assert(
    not game.ReplicatedStorage:FindFirstChild("RoomRuntimeMove"),
    "QA movement fixture already exists"
)
local move = Instance.new("RemoteFunction")
move.Name = "RoomRuntimeMove"
move:SetAttribute("AcceptanceSuite", "RoomRuntime")
move.OnServerInvoke = function(player, role)
    local bay
    for _, model in workspace.NeedleQuay:GetChildren() do
        if
            model:GetAttribute("PersonalWorkshop")
            and model:GetAttribute("OwnerUserId") == player.UserId
        then
            bay = model
        end
    end
    assert(bay and player.Character, "Owned bay/character required")
    local target
    if role == "bay" then
        target = bay.SignMount.Position + Vector3.new(0, -3, -9)
    elseif role == "metal" or role == "station" then
        for _, model in workspace.NeedleQuay:GetChildren() do
            if role == "metal" and model:GetAttribute("DiscoveryId") == "I01" then
                target = model.DiscoveryTarget.Position + Vector3.new(0, 0, -6)
            elseif
                role == "station"
                and model:GetAttribute("StationId") == bay:GetAttribute("RoomStationId")
            then
                target = model.Interaction.Position + Vector3.new(0, 0, -6)
            end
        end
    end
    assert(target, "Unknown QA movement role")
    player.Character:PivotTo(CFrame.new(target))
    return true
end
move.Parent = game.ReplicatedStorage
return "Installed explicit server-authoritative QA movement fixture"
