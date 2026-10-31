-- Bounded local life: small seabirds, breeze on flags, personally tended gardens.
local Run = game:GetService("RunService")
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Life = require(game.ReplicatedStorage.Shared.QuayLifeCatalog)
local Tween = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Motion = {}
Motion.__index = Motion
function Motion.new()
    local self =
        setmetatable({ enabled = true, breeze = {}, birds = {}, gardens = {}, elapsed = 0 }, Motion)
    local root = workspace:WaitForChild("NeedleQuay"):WaitForChild("DemoDistrict")
    self.root = Instance.new("Folder")
    self.root.Name = "LocalHarborLife"
    self.root.Parent = workspace
    local function register(p)
        if p:IsA("BasePart") and p:GetAttribute("QuayBreeze") then
            self.breeze[p] = {
                base = p.CFrame,
                phase = p:GetAttribute("QuayBreeze"),
                pivot = p:GetAttribute("BreezePivot") or Vector3.zero,
            }
        end
    end
    for _, p in root:GetDescendants() do
        register(p)
    end
    self.added = root.DescendantAdded:Connect(register)
    for i = 1, 7 do
        local bird = { parts = {}, phase = i * 1.9 }
        for side = -1, 1, 2 do
            local p = Instance.new("WedgePart")
            p.Name = "GullWing"
            p.Size = Vector3.new(0.13, 0.6, 1.7)
            p.Color = Theme.Paper
            p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
            p.Parent = self.root
            bird.parts[side] = p
        end
        table.insert(self.birds, bird)
    end
    self.connection = Run.Heartbeat:Connect(function(dt)
        self.elapsed += dt
        if self.elapsed < 1 / 24 then
            return
        end
        self.elapsed = 0
        local now = os.clock()
        local camera = workspace.CurrentCamera
        for p, row in self.breeze do
            if p.Parent then
                p.CFrame = row.base
                    * CFrame.new(row.pivot)
                    * CFrame.Angles(
                        if self.enabled then math.sin(now * 1.5 + row.phase) * 0.075 else 0,
                        0,
                        0
                    )
                    * CFrame.new(-row.pivot)
            else
                self.breeze[p] = nil
            end
        end
        for i, bird in self.birds do
            local t = now * 0.075 + bird.phase
            local at = Vector3.new(
                450 + math.cos(t) * 145,
                20 + i * 1.7 + math.sin(t * 2) * 2,
                185 + math.sin(t) * 43
            )
            local facing = CFrame.lookAt(at, at + Vector3.new(-math.sin(t), 0, math.cos(t) * 0.3))
            local visible = self.enabled
                and camera
                and (camera.CFrame.Position - at).Magnitude < 270
            for side, p in bird.parts do
                p.Transparency = if visible then 0 else 1
                if visible then
                    p.CFrame = facing
                        * CFrame.new(side * 0.65, 0, 0)
                        * CFrame.Angles(
                            0,
                            math.pi / 2,
                            side * (0.15 + math.sin(now * 3.6 + bird.phase) * 0.25)
                        )
                end
            end
        end
    end)
    return self
end
function Motion:accept(state)
    local saved = state.quay and state.quay.life and state.quay.life.progress
    if not saved then
        return
    end
    for _, row in Life.Gardens do
        if not saved.gardens[row.id] or self.gardens[row.id] then
            continue
        end
        self.gardens[row.id] = true
        local function petal(name, at, size, color)
            local p = Instance.new("Part")
            p.Name, p.Shape, p.Size, p.Position = name, Enum.PartType.Ball, size, at
            p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
            p.Color, p.Material, p.CastShadow = color, Enum.Material.SmoothPlastic, false
            p.Parent = self.root
            return p
        end
        for i = 1, 3 do
            local at = row.at + Vector3.new((i - 2) * 0.55, 2.5 + (i % 2) * 0.25, (i % 2) * 0.35)
            petal(
                "GardenStem",
                at - Vector3.new(0, 0.45, 0),
                Vector3.new(0.09, 0.9, 0.09),
                Theme.Teal
            )
            for j = 1, 5 do
                local a = j * math.pi * 0.4
                petal(
                    "GardenBloom",
                    at + Vector3.new(math.cos(a) * 0.19, 0, math.sin(a) * 0.19),
                    Vector3.new(0.3, 0.14, 0.3),
                    if i % 2 == 0 then Theme.Coral else Theme.Cream
                )
            end
            petal(
                "GardenHeart",
                at + Vector3.new(0, 0.07, 0),
                Vector3.new(0.19, 0.12, 0.19),
                Theme.Amber
            )
        end
        if self.seenState and self.enabled then
            for i = 1, 12 do
                local a = i * math.pi / 6
                local at = row.at
                    + Vector3.new(math.cos(a) * 0.8, 3.8 + (i % 3) * 0.2, math.sin(a) * 0.8)
                local drop = petal("WateringDrop", at, Vector3.new(0.1, 0.22, 0.1), Theme.FadedTeal)
                Tween:Create(
                    drop,
                    TweenInfo.new(0.7 + i * 0.02),
                    { Position = at - Vector3.new(0, 2, 0), Transparency = 1 }
                ):Play()
                Debris:AddItem(drop, 1.1)
            end
        end
    end
    self.seenState = true
end
function Motion:destroy()
    self.connection:Disconnect()
    self.added:Disconnect()
    for p, row in self.breeze do
        if p.Parent then
            p.CFrame = row.base
        end
    end
    self.root:Destroy()
end
return Motion
