-- One-way, server-authorized finish events. Local bounded effects; never awards progress.
local Players = game:GetService("Players")
local Tween = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local Voice = require(script.Parent.CompanionVoice)
local Celebrations = {}
Celebrations.__index = Celebrations
function Celebrations.new(follower, neighbors)
    local self = setmetatable(
        { effects = true, follower = follower, neighbors = neighbors, last = 0, lastFx = -10 },
        Celebrations
    )
    self.root = Instance.new("Folder")
    self.root.Name = "LocalQuayCelebrations"
    self.root.Parent = workspace
    local remote = game.ReplicatedStorage.MusicNetwork:WaitForChild("QuayCelebration", 10)
    if not remote then
        return self
    end
    local commissionRemote =
        game.ReplicatedStorage.MusicNetwork:WaitForChild("QuayCommissionPlayback", 10)
    if commissionRemote then
        self.commissionConnection = commissionRemote.OnClientEvent:Connect(function(pattern)
            local player = Players.LocalPlayer
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not root then
                return
            end
            for _, actor in self.neighbors.actors do
                local at = actor.current or actor.origin
                if at and (at.Position - root.Position).Magnitude <= 24 then
                    actor.noticeKind = "badge"
                    actor.noticeUntil = os.clock() + 8 + 240 / pattern.bpm
                    actor.noticeTarget = root.Position
                end
            end
        end)
    end
    self.connection = remote.OnClientEvent:Connect(function(event)
        self:show(event)
    end)
    return self
end
function Celebrations:show(event)
    if event.serial <= self.last then
        return
    end
    self.last = event.serial
    local player = Players.LocalPlayer
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or (root.Position - event.position).Magnitude > 90 then
        return
    end
    self.neighbors:celebrate(event.position, event.serial)
    if event.userId == player.UserId then
        self.follower:celebrate(event.serial)
        Voice.Cue:Fire("success")
        if not event.first then
            Gui.Cue:Fire("ui_collect")
        end
    end
    if not self.effects or os.clock() - self.lastFx < 1.2 then
        return
    end
    self.lastFx = os.clock()
    -- Small neighborhood favors get a short, warm acknowledgement. The large
    -- finish burst is reserved for performances and quest milestones.
    local everyday = event.id == "neighborhood_life"
    local at = event.position - Vector3.new(0, 2.8, 0)
    local ring = Instance.new("Part")
    ring.Name, ring.Shape = "FinishHalo", Enum.PartType.Cylinder
    ring.Size, ring.CFrame =
        Vector3.new(0.06, 3, 3), CFrame.new(at) * CFrame.Angles(0, 0, math.pi / 2)
    ring.Anchored, ring.CanCollide, ring.CanTouch, ring.CanQuery = true, false, false, false
    ring.Material, ring.Color, ring.Transparency =
        Enum.Material.Neon, Theme.Amber, if everyday then 0.82 else 0.4
    ring.Parent = self.root
    local diameter = if everyday then 5 else 13
    Tween:Create(
        ring,
        TweenInfo.new(1.1),
        { Size = Vector3.new(0.06, diameter, diameter), Transparency = 1 }
    ):Play()
    Debris:AddItem(ring, 1.2)
    local anchor = Instance.new("Part")
    anchor.Anchored, anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = true, false, false, false
    anchor.Transparency, anchor.Position, anchor.Size =
        1, event.position + Vector3.new(0, 3, 0), Vector3.one
    anchor.Parent = self.root
    local board = Gui.make("BillboardGui", anchor, {
        Adornee = anchor,
        Size = UDim2.fromOffset(210, 42),
        AlwaysOnTop = false,
        MaxDistance = 65,
    })
    local text = Gui.label(
        board,
        if everyday then "A LITTLE CLOSER" elseif event.first then "NICE ONE!" else "ENCORE!",
        if everyday then 15 else 21,
        Theme.Amber
    )
    text.Size, text.TextXAlignment = UDim2.fromScale(1, 1), Enum.TextXAlignment.Center
    Tween:Create(anchor, TweenInfo.new(2), { Position = anchor.Position + Vector3.new(0, 2, 0) })
        :Play()
    Tween:Create(
        text,
        TweenInfo.new(0.6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 1.4),
        { TextTransparency = 1 }
    ):Play()
    Debris:AddItem(anchor, 2.1)
    for i = 1, if everyday then 4 else 10 do
        local chip = Instance.new("Part")
        chip.Size = Vector3.new(0.13, 0.28, 0.07)
        chip.Anchored, chip.CanCollide, chip.CanTouch, chip.CanQuery = true, false, false, false
        chip.Color = if i % 2 == 0 then Theme.Coral else Theme.Amber
        chip.Material = if everyday then Enum.Material.SmoothPlastic else Enum.Material.Neon
        chip.Position = event.position
        chip.Parent = self.root
        local angle = i * math.pi / 5
        Tween:Create(chip, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = event.position
                + Vector3.new(math.cos(angle) * 3, 2 + i % 3, math.sin(angle) * 3),
            Transparency = 1,
            Orientation = Vector3.new(i * 23, i * 41, i * 17),
        }):Play()
        Debris:AddItem(chip, 1.4)
    end
end
function Celebrations:destroy()
    if self.commissionConnection then
        self.commissionConnection:Disconnect()
    end
    if self.connection then
        self.connection:Disconnect()
    end
    self.root:Destroy()
end
function Celebrations:setEffects(enabled)
    self.effects = enabled
    if not enabled then
        self.root:ClearAllChildren()
    end
end
return Celebrations
