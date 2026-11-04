-- Non-blocking, fixed-location Roamer identity. Uses the existing RoomCatalog
-- save fields; it is not a separate shop/decor inventory or imported asset.
local Shared = game:GetService("ReplicatedStorage").Shared
local Rooms = require(Shared.RoomCatalog)
local Cosmetics = require(Shared.CosmeticCatalog)
local Theme = require(Shared.Theme)
local Identity = {}

local function part(parent, name, size, localTransform, pivot, color)
    local item = Instance.new("Part")
    item.Name, item.Size = name, size
    item.CFrame = pivot * localTransform
    item.Anchored = true
    item.CanCollide, item.CanTouch, item.CanQuery = false, false, false
    item.CastShadow = false
    item.Material = Enum.Material.SmoothPlastic
    item.Color = color
    item.Parent = parent
    return item
end

function Identity.reset(van)
    local old = van.model:FindFirstChild("RoamerIdentityDisplay")
    if old then old:Destroy() end
    van.identitySignature = nil
    van.model:SetAttribute("RoomSign", nil)
    van.model:SetAttribute("RoomDecor", nil)
    van.model:SetAttribute("RoomFinish", nil)
    van.model:SetAttribute("StudioOwnerUserId", nil)
end

function Identity.update(van, player, profile)
    local choices = Rooms.sanitize(profile.room, profile)
    local signature = table.concat({
        tostring(player.UserId), player.DisplayName,
        choices.finish, choices.sign, choices.decor,
    }, ":")
    if signature == van.identitySignature
        and van.model:FindFirstChild("RoamerIdentityDisplay") then
        return
    end
    Identity.reset(van)
    local pivot = van.model:GetPivot()
    local root = Instance.new("Model")
    root.Name = "RoamerIdentityDisplay"
    root:SetAttribute("OwnedCosmetic", true)
    root.Parent = van.model

    -- Outer, off-door side of the parked van. Nothing here collides, queries,
    -- occludes a prompt or creates a new functional workstation target.
    local sign = part(root, "PersonalSign", Vector3.new(5.1, 1.5, 0.08),
        CFrame.new(-3.0, 0.45, -4.86), pivot, Theme.Ink)
    local gui = Instance.new("SurfaceGui")
    gui.Name, gui.Face = "PersonalSignText", Enum.NormalId.Front
    gui.CanvasSize = Vector2.new(520, 150)
    gui.LightInfluence = 0
    gui.Parent = sign
    local text = Instance.new("TextLabel")
    text.Name, text.Size = "OwnerAndStudio", UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.TextWrapped = true
    text.Font = Enum.Font.Code
    text.TextSize = 32
    text.TextColor3 = Theme.Cream
    text.Text = Rooms.Signs[choices.sign] .. "\n" .. player.DisplayName
    text.Parent = gui

    if choices.decor == "vinyl" then
        local disc = part(root, "VinylEmblem", Vector3.new(0.1, 1.25, 1.25),
            CFrame.new(2.6, 0.4, -4.9) * CFrame.Angles(0, math.pi / 2, 0),
            pivot, Theme.Graphite)
        disc.Shape = Enum.PartType.Cylinder
        local marker = Instance.new("SurfaceGui")
        marker.Name, marker.Face = "VinylLabel", Enum.NormalId.Right
        marker.CanvasSize = Vector2.new(100, 100)
        marker.LightInfluence = 0
        marker.Parent = disc
        local circle = Instance.new("TextLabel")
        circle.Size, circle.Text = UDim2.fromScale(1, 1), "●"
        circle.TextSize, circle.Font = 45, Enum.Font.Code
        circle.BackgroundTransparency, circle.TextColor3 = 1, Theme.Amber
        circle.Parent = marker
    end

    van.identitySignature = signature
    van.model:SetAttribute("RoomFinish", choices.finish)
    van.model:SetAttribute("RoomSign", choices.sign)
    van.model:SetAttribute("RoomDecor", choices.decor)
    van.model:SetAttribute("StudioOwnerUserId", player.UserId)
end

return Identity
