local Workspace = game:GetService("Workspace")
local Theme = require(game:GetService("ReplicatedStorage").Shared.Theme)
local Restoration = {}

function Restoration.update(stage, effects, neighborhood)
    local root = Workspace:FindFirstChild("NeedleQuay")
    if not root then
        return
    end
    for _, object in root:GetDescendants() do
        local index = object:GetAttribute("RestorationIndicator")
        local job = object:GetAttribute("NeighborhoodMissionId")
        if object:IsA("BasePart") and type(job) == "string" then
            local earned = neighborhood and neighborhood.earned and neighborhood.earned[job] == true
            object.Color = if earned then Theme.Amber else Theme.Graphite
            object.Material = if earned and effects
                then Enum.Material.Neon
                else Enum.Material.SmoothPlastic
        elseif object:IsA("BasePart") and type(index) == "number" then
            object.Color = if index <= stage then Theme.Amber else Theme.Graphite
            object.Material = if effects and index <= stage
                then Enum.Material.Neon
                else Enum.Material.SmoothPlastic
        elseif object:IsA("BasePart") and object:GetAttribute("PersonalLamp") then
            local light = object:FindFirstChildOfClass("PointLight")
            if light then
                light.Enabled = effects
                light.Brightness = if stage == 4 then 1.8 else 1
            end
        end
    end
end
return Restoration
