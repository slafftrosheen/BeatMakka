-- CLIENT-ONLY art stand-in: local, noncolliding, noninteractive, no Roblox upload.
-- Production 15-bone DCC candidate will replace the shapes after acceptance.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Theme = require(game:GetService("ReplicatedStorage").Shared.Theme)
local Catalog = require(game:GetService("ReplicatedStorage").Shared.CompanionCatalog)
local Follower = {}
Follower.__index = Follower

local function piece(parent, name, size, point, color, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = CFrame.new(point)
    p.Color = color
    p.Material = Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    if shape then
        p.Shape = shape
    end
    p.Parent = parent
    return p
end

local function blockout(id)
    local alissia = id == "alissia"
    local outfit = if alissia then Theme.FadedTeal else Theme.Teal
    local accent = if alissia then Theme.Coral else Theme.Amber
    local model = Instance.new("Model")
    model.Name = "Companion_" .. id .. "_LOCAL_CANDIDATE"
    local root = piece(model, "Root", Vector3.new(0.1, 0.1, 0.1), Vector3.zero, Theme.White)
    root.Transparency = 1
    model.PrimaryPart = root
    piece(model, "Torso", Vector3.new(1.18, 1.34, 0.67), Vector3.new(0, 1.79, 0), outfit)
    piece(model, "Head", Vector3.new(1.05, 1.05, 1.0), Vector3.new(0, 2.94, 0), Theme.Cream, Enum.PartType.Ball)
    piece(model, "Hair", Vector3.new(1.1, 0.32, 1.02), Vector3.new(0, 3.42, 0), if alissia then Theme.Walnut else Theme.Stone)
    for _, side in { -1, 1 } do
        piece(model, "Arm", Vector3.new(0.39, 1.0, 0.4), Vector3.new(side * 0.86, 1.80, 0), outfit)
        piece(model, "Hand", Vector3.new(0.37, 0.38, 0.34), Vector3.new(side * 0.86, 1.16, -0.02), Theme.Cream)
        piece(model, "Leg", Vector3.new(0.47, 0.92, 0.48), Vector3.new(side * 0.32, 0.73, 0), if alissia then Theme.Teal else Theme.Walnut)
        piece(model, "Shoe", Vector3.new(0.52, 0.29, 0.72), Vector3.new(side * 0.32, 0.18, -0.15), accent)
        piece(model, "Eye", Vector3.new(0.13, 0.13, 0.12), Vector3.new(side * 0.23, 3.03, -0.48), Theme.Ink, Enum.PartType.Ball)
    end
    piece(model, "Pack", Vector3.new(0.95, 0.99, 0.29), Vector3.new(0, 1.8, 0.5), accent)
    if alissia then
        piece(model, "GoggleBand", Vector3.new(1.11, 0.14, 1.1), Vector3.new(0, 3.29, 0), accent)
    else
        piece(model, "UtilityBeatBadge", Vector3.new(0.55, 0.22, 0.08), Vector3.new(0, 1.95, -0.38), accent)
    end
    return model
end

function Follower.new()
    return setmetatable({ model = nil, selected = "none", pivot = nil, clock = 0 }, Follower)
end

function Follower:setSelected(id)
    id = Catalog.normalize(id)
    if id == self.selected then
        return
    end
    self:destroy()
    self.selected = id
    if id ~= "none" then
        self.model = blockout(id)
    end
end

function Follower:step(dt, state)
    if self.model == nil then
        return
    end
    local player = Players.LocalPlayer
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local hide = root == nil or humanoid == nil or humanoid.Health <= 0
        or state == nil or not state.ready
        or state.station ~= nil or state.listening ~= nil
        or (state.stage and state.stage.open)
        or (state.concert and state.concert.open)
    if hide then
        self.model.Parent = nil
        self.pivot = nil
        return
    end
    if self.model.Parent ~= Workspace then
        self.model.Parent = Workspace
    end
    -- Character root is above floor; the blockout pivot is at ground level.
    local x = if self.selected == "alissia" then -2.9 else 2.9
    local offset = (root.CFrame * CFrame.new(x, 0, 3.1)).Position
    local ground = Vector3.new(offset.X, root.Position.Y - 2.8, offset.Z)
    local facing = Vector3.new(root.Position.X, ground.Y, root.Position.Z)
    local target = CFrame.lookAt(ground, facing)
    if self.pivot == nil or (self.pivot.Position - target.Position).Magnitude > 16 then
        self.pivot = target
    else
        self.pivot = self.pivot:Lerp(target, math.clamp(dt * 8, 0, 1))
    end
    self.clock += dt
    self.model:PivotTo(self.pivot * CFrame.new(0, math.sin(self.clock * 4) * 0.025, 0))
end

function Follower:destroy()
    if self.model then
        self.model:Destroy()
        self.model = nil
    end
    self.pivot = nil
    self.selected = "none"
end

return Follower
