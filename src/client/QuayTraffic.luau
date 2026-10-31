-- Cosmetic, bounded traffic. Server gameplay and player movement never depend on it.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Traffic = {}
Traffic.__index = Traffic

function Traffic.new()
    local self = setmetatable({ entries = {}, enabled = true, elapsed = 0 }, Traffic)
    local folder = workspace
        :WaitForChild("NeedleQuay")
        :WaitForChild("DemoDistrict")
        :WaitForChild("StreetLiftup")
        :WaitForChild("Traffic")
    for _, model in folder:GetChildren() do
        local entry = {
            model = model,
            base = model:GetPivot(),
            parts = {},
            x = model:GetAttribute("TrafficStartX"),
            lane = model:GetAttribute("TrafficLane"),
            direction = model:GetAttribute("TrafficDirection"),
            speed = model:GetAttribute("TrafficSpeed"),
            wait = 0,
            stopped = false,
        }
        for _, part in model:GetDescendants() do
            if part:IsA("BasePart") then
                table.insert(entry.parts, part)
            end
        end
        table.insert(self.entries, entry)
    end
    self.connection = RunService.Heartbeat:Connect(function(dt)
        self.elapsed += dt
        if self.elapsed < 1 / 30 then
            return
        end
        local step = math.min(self.elapsed, 0.1)
        self.elapsed = 0
        local character = Players.LocalPlayer.Character
        local player = character and character:FindFirstChild("HumanoidRootPart")
        local camera = workspace.CurrentCamera
        for _, entry in self.entries do
            if not entry.model.Parent then
                continue
            end
            local ahead = player and (player.Position.X - 450 - entry.x) * entry.direction
            local yielding = ahead
                and ahead > -4
                and ahead < 22
                and math.abs(player.Position.Z - entry.lane) < 6
            local before = entry.x
            if self.enabled and not yielding then
                if entry.wait > 0 then
                    entry.wait = math.max(0, entry.wait - step)
                else
                    entry.x += entry.direction * entry.speed * step
                end
                -- One short pause at the central crossing per traversal.
                if
                    not entry.stopped
                    and (before + 14 * entry.direction) * entry.direction < 0
                    and (entry.x + 14 * entry.direction) * entry.direction >= 0
                then
                    entry.wait, entry.stopped = 2.2, true
                end
                if math.abs(entry.x) > 205 then
                    entry.x, entry.stopped = -entry.direction * 205, false
                end
            end
            local at = Vector3.new(450 + entry.x, 0.12, entry.lane)
            local near = camera and (camera.CFrame.Position - at).Magnitude < 240
            local fade = if self.enabled and near
                then math.clamp((math.abs(entry.x) - 185) / 18, 0, 1)
                else 1
            if entry.fade ~= fade then
                entry.fade = fade
                for _, part in entry.parts do
                    part.LocalTransparencyModifier = fade
                end
            end
            if near and self.enabled then
                entry.model:PivotTo(
                    CFrame.new(at) * CFrame.Angles(0, -entry.direction * math.pi / 2, 0)
                )
            end
        end
    end)
    return self
end

function Traffic:destroy()
    self.connection:Disconnect()
    for _, entry in self.entries do
        if entry.model.Parent then
            entry.model:PivotTo(entry.base)
            for _, part in entry.parts do
                part.LocalTransparencyModifier = 0
            end
        end
    end
end
return Traffic
