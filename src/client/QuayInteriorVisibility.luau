-- The legacy workshop is an interior instance, never a second island on the horizon.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Visibility = {}
function Visibility.new()
    local world = workspace:WaitForChild("NeedleQuay")
    local entries = {}
    local hidden
    local function apply(object, record)
        if object:IsA("BasePart") then
            object:SetAttribute("InteriorHidden", hidden == true)
            object.LocalTransparencyModifier = if hidden then 1 else record.value
        else
            object.Enabled = if hidden then false else record.value
        end
    end
    local function register(object)
        local ancestor = object
        while ancestor.Parent and ancestor.Parent ~= world do
            ancestor = ancestor.Parent
        end
        if
            ancestor.Parent ~= world
            or ancestor.Name == "DemoDistrict"
            or ancestor.Name == "Arrival"
        then
            return
        end
        local value
        if object:IsA("BasePart") then
            value = object.LocalTransparencyModifier
        elseif object:IsA("BillboardGui") or object:IsA("SurfaceGui") or object:IsA("Light") then
            value = object.Enabled
        else
            return
        end
        entries[object] = { value = value }
        if hidden ~= nil then
            apply(object, entries[object])
        end
    end
    for _, object in world:GetDescendants() do
        register(object)
    end
    local added = world.DescendantAdded:Connect(register)
    local heartbeat = RunService.Heartbeat:Connect(function()
        local character = Players.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end
        local outside = root.Position.X > 200
        if outside == hidden then
            return
        end
        hidden = outside
        for object, record in entries do
            if object.Parent then
                apply(object, record)
            else
                entries[object] = nil
            end
        end
    end)
    return {
        destroy = function()
            added:Disconnect()
            heartbeat:Disconnect()
            hidden = false
            for object, record in entries do
                if object.Parent then
                    apply(object, record)
                end
            end
        end,
    }
end
return Visibility
