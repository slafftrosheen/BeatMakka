local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage").Shared
local Theme = require(Shared.Theme)
local Poses = require(Shared.MotionPoses)
local Feedback = {}
Feedback.__index = Feedback

function Feedback.new()
    local self = setmetatable(
        { targets = {}, pulses = {}, enabled = true, stage = 0, pose = "idle", poseUntil = 0 },
        Feedback
    )
    local function watch(object)
        if not object:IsDescendantOf(Workspace) then
            return
        end
        local root = Workspace:FindFirstChild("NeedleQuay")
        if not root or not object:IsDescendantOf(root) then
            return
        end
        if object:GetAttribute("MotionRole") and object:IsA("PVInstance") then
            self.targets[object] =
                { base = object:GetPivot(), role = object:GetAttribute("MotionRole") }
        end
        if object:IsA("BasePart") and object:GetAttribute("PadId") then
            self.targets[object] = { base = object.CFrame, role = "Pad", color = object.Color }
        end
        if object:IsA("BasePart") and object:GetAttribute("RestorationSign") then
            self.targets[object] = { base = object.CFrame, role = "Sign", color = object.Color }
        end
    end
    for _, object in Workspace:GetDescendants() do
        watch(object)
    end
    Workspace.DescendantAdded:Connect(function(object)
        task.defer(watch, object)
    end)
    Workspace.DescendantRemoving:Connect(function(object)
        self.targets[object] = nil
    end)
    return self
end

function Feedback:setEnabled(value)
    self.enabled = value
    if not value then
        table.clear(self.pulses)
        for object, record in self.targets do
            if object.Parent then
                object:PivotTo(record.base)
                if record.color then
                    object.Color = record.color
                end
            end
        end
    end
end

function Feedback:pulse(pad, station)
    if not self.enabled then
        return
    end
    local now = os.clock()
    self.beatUntil = now + 0.1
    self.pulses[tostring(station) .. ":" .. tostring(pad)] = now + 0.12
end

function Feedback:discovery(id)
    if not self.enabled then
        return
    end
    self.pose = if id == "I03" then "carry" else "chirp"
    self.poseUntil = os.clock() + 0.8
    local root = Workspace:FindFirstChild("NeedleQuay")
    if root then
        for _, model in root:GetChildren() do
            if model:GetAttribute("DiscoveryId") == id then
                local highlight = Instance.new("Highlight")
                highlight.Name = "PersonalDiscoveryFeedback"
                highlight.Adornee = model
                highlight.FillTransparency = 0.85
                highlight.OutlineColor = Theme.Amber
                highlight.Parent = model
                game:GetService("Debris"):AddItem(highlight, 0.7)
            end
        end
    end
end

function Feedback:update(state)
    self.state = state
    if self.stage ~= state.restoration then
        if self.enabled and state.restoration > self.stage then
            self.pose = "celebrate"
            self.poseUntil = os.clock() + 1.2
        end
        self.stage = state.restoration
    end
    self.station = state.station
    self.listening = state.listening ~= nil
end

function Feedback:step()
    local now = os.clock()
    local pose = Poses[if now < self.poseUntil
        then self.pose
        elseif self.listening then "listen"
        else "idle"]
    for object, record in self.targets do
        if object.Parent == nil then
            self.targets[object] = nil
            continue
        end
        if not self.enabled then
            continue
        end
        local transform = CFrame.identity
        if record.role == "Pad" then
            local model = object.Parent and object.Parent.Parent
            local station = model and model:GetAttribute("StationId")
            local key = tostring(station) .. ":" .. tostring(object:GetAttribute("PadId"))
            local active = (self.pulses[key] or 0) > now
            transform = CFrame.new(0, if active then -0.035 else 0, 0)
            object.Color = if active then Theme.Amber else record.color
        elseif record.role == "SpeakerCone" then
            transform = CFrame.new(0, 0, if (self.beatUntil or 0) > now then -0.035 else 0)
        elseif record.role == "RobotHead" then
            transform =
                CFrame.Angles(pose.head.X, pose.head.Y + math.sin(now * 0.7) * 0.025, pose.head.Z)
        elseif record.role == "LeftArm" then
            transform = CFrame.Angles(pose.left, 0, 0)
        elseif record.role == "RightArm" then
            transform = CFrame.Angles(pose.right, 0, 0)
        elseif record.role == "Sign" then
            object.Color = if self.stage == 4 then Theme.Amber else record.color
        end
        object:PivotTo(record.base * transform)
    end
    if now < (self.nextSceneUpdate or 0) then
        return
    end
    self.nextSceneUpdate = now + 0.1
    -- Hide overhead roof geometry locally while the camera is inside the workshop.
    local root = Workspace:FindFirstChild("NeedleQuay")
    local camera = Workspace.CurrentCamera
    if root and camera then
        if self.state then
            for _, model in root:GetChildren() do
                local id = model:GetAttribute("DiscoveryId")
                local anchor = model:FindFirstChild("DiscoveryTarget")
                if id and anchor then
                    local prompt = anchor:FindFirstChildOfClass("ProximityPrompt")
                    local billboard = anchor:FindFirstChild("StatusLabel")
                    local text = billboard and billboard:FindFirstChildOfClass("TextLabel")
                    local collected = self.state.unlocked[id] == true
                    if prompt then
                        prompt.ActionText = if collected
                            then "Preview collected sound"
                            else "Preview / collect"
                        if text then
                            text.Text = prompt.ObjectText
                                .. (if collected then " / COLLECTED" else " / DISCOVER")
                        end
                    end
                end
            end
        end
        local p = camera.CFrame.Position
        local inside = math.abs(p.X) < 18 and math.abs(p.Z) < 14 and p.Y < 18
        local kit = root:FindFirstChild("ExactModules")
        if kit then
            for _, model in kit:GetChildren() do
                if model:GetAttribute("CameraRoof") then
                    for _, part in model:GetDescendants() do
                        if part:IsA("BasePart") then
                            part.LocalTransparencyModifier = if inside then 1 else 0
                        end
                    end
                end
            end
        end
        local lowQuality = false
        local quality = UserSettings():GetService("UserGameSettings").SavedQualityLevel
        if quality ~= Enum.SavedQualitySetting.Automatic then
            lowQuality = quality.Value <= 3
        end
        local backdrop = root:FindFirstChild("Backdrop")
        if backdrop then
            for _, part in backdrop:GetDescendants() do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = if lowQuality then 1 else 0
                end
            end
        end
        for _, emitter in root:GetDescendants() do
            if emitter:IsA("ParticleEmitter") and emitter:GetAttribute("AmbientAccent") then
                emitter.Enabled = self.enabled and not lowQuality
            end
        end
    end
end

return Feedback
