local Workspace = game:GetService("Workspace")
local Theme = require(game:GetService("ReplicatedStorage").Shared.Theme)
local Restoration = {}

function Restoration.update(stage, effects)
    local root = Workspace:FindFirstChild("NeedleQuay")
    if not root then
        return
    end
    for _, object in root:GetDescendants() do
        local index = object:GetAttribute("RestorationIndicator")
        if object:IsA("BasePart") and type(index) == "number" then
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
