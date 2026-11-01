-- Personal temporary crowd stand-ins reuse H04; no imported NPC art claim.
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local HarbourFeedback = require(script.Parent.HarbourFeedback)
local Scene = {}
Scene.__index = Scene

function Scene.new()
    return setmetatable({ actors = {} }, Scene)
end

function Scene:update(state)
    self.state = state
    if not state or not state.open then
        self:destroy()
        return
    end
    if not self.harbour then
        self.harbour = HarbourFeedback.new("PersonalChapterSignatures")
    end
    self.harbour:accept(state.playback, state.sceneOrigin)
    local root = workspace:FindFirstChild("NeedleQuay")
    if not root or (self.folder and self.folder.Parent) then
        return
    end
    self.folder, self.actors = nil, {}
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
        actor:SetAttribute("MotionRole", nil)
        actor:SetAttribute("ChapterStandIn", true)
        for _, object in actor:GetDescendants() do
            if object:IsA("ProximityPrompt") or object:IsA("BillboardGui") or object:IsA("Highlight") then
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
            label.Text = "NPC / " .. role
            label.Parent = gui
        end
    end
    folder.Parent = root
    self.folder = folder
end

function Scene:step(effects)
    local cue = self.harbour and self.harbour:step(effects)
    for index, actor in self.actors do
        if actor.model.Parent then
            local move = CFrame.identity
            if effects and cue and cue.active then
                local amount = if index == 3 then cue.helper else cue.drums
                move = CFrame.Angles(-amount * 0.035, 0, 0)
                if cue.climax then
                    move *= CFrame.new(0, amount * 0.05, 0)
                end
            end
            -- Pause, silence, end and reduced effects all settle to the base pose.
            -- There is no independent wall-clock dance or delayed applause callback.
            actor.model:PivotTo(actor.base * move)
        end
    end
end

function Scene:destroy()
    if self.harbour then
        self.harbour:destroy()
        self.harbour = nil
    end
    if self.folder then
        self.folder:Destroy()
        self.folder = nil
    end
    table.clear(self.actors)
    self.state = nil
end

return Scene
