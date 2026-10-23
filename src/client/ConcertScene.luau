-- Personal temporary crowd stand-ins reuse H04; no imported NPC art claim.
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Scene = {}
Scene.__index = Scene

function Scene.new()
    return setmetatable({ actors = {}, lights = {}, reaction = 0 }, Scene)
end

function Scene:update(state)
    self.playback = state and state.playback
    self.reaction = if state then state.reaction else 0
    if not state or (not state.open and state.checkpoint == 0) then
        self:destroy()
        return
    end
    local root = workspace:FindFirstChild("NeedleQuay")
    if not root or self.folder then
        return
    end
    local source
    for _, model in root:GetChildren() do
        if model:GetAttribute("DiscoveryId") == "I03" then
            source = model
        end
    end
    if not source then
        return
    end
    local folder = Instance.new("Folder")
    folder.Name = "PersonalChapterCrowd"
    local roles = { "Quay crew", "Vent keeper", "Mica" }
    for index, role in roles do
        local actor = source:Clone()
        actor.Name = role
        actor:SetAttribute("DiscoveryId", nil)
        actor:SetAttribute("ChapterStandIn", true)
        for _, object in actor:GetDescendants() do
            if object:IsA("ProximityPrompt") or object:IsA("BillboardGui") then
                object:Destroy()
            else
                object:SetAttribute("MotionRole", nil)
                if object:IsA("BasePart") then
                    object.Anchored = true
                    object.CanCollide = false
                    object.CanQuery = false
                    object.CanTouch = false
                end
            end
        end
        local base = CFrame.new(37.5 + (index - 1) * 4.5, 0, 21)
        actor:PivotTo(base)
        actor.Parent = folder
        self.actors[index] = { model = actor, base = base }
        local anchor = actor:FindFirstChildWhichIsA("BasePart", true)
        if anchor then
            local gui = Instance.new("BillboardGui")
            gui.Name = "ResidentRole"
            gui.Size = UDim2.fromOffset(130, 28)
            gui.StudsOffset = Vector3.new(0, 4.5, 0)
            gui.MaxDistance = 32
            gui.Parent = anchor
            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundColor3 = Theme.Ink
            label.TextColor3 = Theme.Cream
            label.Font = Theme.Bold
            label.TextSize = 14
            label.Text = role
            label.Parent = gui
        end
    end
    folder.Parent = root
    self.folder = folder
    for _, object in root:GetDescendants() do
        if
            object:IsA("BasePart")
            and (object:GetAttribute("ChapterLight") or object.Name == "ListeningCourt")
        then
            table.insert(self.lights, {
                object = object,
                color = object.Color,
                material = object.Material,
                floor = object.Name == "ListeningCourt",
            })
        end
    end
end

function Scene:step(effects)
    local t = if self.playback
        then (workspace:GetServerTimeNow() - self.playback.startedAt)
            * self.playback.pattern.bpm
            / 60
            * math.pi
            * 2
        else os.clock() * 3
    for index, actor in self.actors do
        if actor.model.Parent then
            local move = CFrame.identity
            if effects and self.reaction >= 1 then
                move = CFrame.Angles(math.sin(t + index) * 0.035, 0, 0)
                if self.reaction >= 2 then
                    move *= CFrame.new(0, math.abs(math.sin(t + index)) * 0.12, 0)
                end
            end
            actor.model:PivotTo(actor.base * move)
        end
    end
    local key = tostring(self.reaction) .. tostring(effects)
    if key ~= self.lightState then
        self.lightState = key
        for _, record in self.lights do
            local object = record.object
            if object.Parent then
                object.Color = if record.floor
                    then (if self.reaction >= 4 then Theme.FadedTeal else record.color)
                    elseif self.reaction >= 3 then Theme.Amber
                    else Theme.Graphite
                object.Material = if not record.floor
                        and effects
                        and self.reaction >= 3
                    then Enum.Material.Neon
                    else Enum.Material.SmoothPlastic
            end
        end
    end
end

function Scene:destroy()
    if self.folder then
        self.folder:Destroy()
        self.folder = nil
    end
    table.clear(self.actors)
    for _, record in self.lights do
        if record.object.Parent then
            record.object.Color = record.color
            record.object.Material = record.material
        end
    end
    table.clear(self.lights)
    self.lightState = nil
end

return Scene
