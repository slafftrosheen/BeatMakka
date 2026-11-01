-- Bounded native presentation owned by WorldFeedback/ConcertScene.
-- It reads an accepted schedule; it owns no audio, game progress or musical clock.
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Signatures = require(Shared.HarbourSignatures)
local Theme = require(Shared.Theme)
local Feedback = {}
Feedback.__index = Feedback

local function category(object)
    if object:IsA("Model") then
        if object:GetAttribute("DiscoveryId") == "I03"
            or (object:GetAttribute("ChapterStandIn") and object.Name == "Mica") then
            return "helper"
        elseif object:GetAttribute("DiscoveryId") == "I01" then
            return "dock"
        end
    elseif object:IsA("BasePart") then
        if object.Name == "ListeningCourt" or object.Name == "QuayStreetBusking" then
            return "venue"
        elseif object:GetAttribute("ChapterLight") then
            return "dock"
        end
    end
    return nil
end

local function packetKey(packet)
    local source = packet.schedule.source or {}
    return table.concat({ tostring(packet.epoch), tostring(packet.startedAt),
        tostring(packet.scheduleRevision), tostring(source.projectId),
        tostring(source.id), tostring(source.revision) }, ":")
end

function Feedback.new(name)
    return setmetatable({ name = name, candidates = {}, marks = {}, connections = {} }, Feedback)
end

function Feedback:clear()
    for _, connection in self.connections do
        connection:Disconnect()
    end
    table.clear(self.connections)
    if self.folder then
        self.folder:Destroy()
    end
    self.folder, self.label, self.caption = nil, nil, nil
    self.marks, self.candidates = {}, {}
    self.selectedOrigin, self.rawExpression = nil, nil
end

function Feedback:accept(packet, origin)
    if self.dead then
        return
    end
    if not packet or not packet.schedule or packet.playing == false then
        self.packet, self.index, self.key, self.origin = nil, nil, nil, nil
        self:clear()
        return
    end
    local key = packetKey(packet)
    if key ~= self.key then
        self.index = Signatures.compile(packet.schedule)
        self.key = key
    end
    self.packet = packet
    self.explicitOrigin = origin
    if origin then
        self.origin = origin
    else
        -- Public scene coordinates already belong to this accepted listening epoch.
        -- Never attach a stale set's visuals to a new performer's venue.
        self.origin = nil
        self.rawExpression = nil
    end
end

function Feedback:ensure()
    if self.folder or self.dead then
        return
    end
    local player = Players.LocalPlayer
    local gui = player and player:FindFirstChildOfClass("PlayerGui")
    local screen = gui and gui:FindFirstChild("NeedleQuayInstrument")
    if not screen then
        return
    end
    self.screen = screen
    self.folder = Instance.new("Folder")
    self.folder.Name = self.name
    self.folder.Parent = workspace
    local function watch(object)
        if self.dead or not self.folder then
            return
        end
        local kind = category(object)
        if kind and object:IsDescendantOf(workspace) then
            self.candidates[object] = kind
            self.selectionDirty = true
        end
    end
    for _, object in workspace:GetDescendants() do
        watch(object)
    end
    table.insert(self.connections, workspace.DescendantAdded:Connect(function(object)
        -- Streaming/tag assignment may complete after the parent event.
        task.defer(watch, object)
    end))
    table.insert(self.connections, workspace.DescendantRemoving:Connect(function(object)
        if self.candidates[object] then
            self.candidates[object] = nil
            self.selectionDirty = true
        end
    end))
    table.insert(self.connections, screen.Destroying:Connect(function()
        self:destroy()
    end))
    for _, kind in { "dock", "helper", "venue" } do
        local highlight = Instance.new("Highlight")
        highlight.Name = kind
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.FillColor, highlight.OutlineColor = Theme.Amber, Theme.Amber
        highlight.FillTransparency, highlight.OutlineTransparency = 0.97, 0.7
        highlight.Enabled = false
        highlight.Parent = self.folder
        self.marks[kind] = highlight
    end
    self.caption = Instance.new("BillboardGui")
    self.caption.Name = "MusicCause"
    self.caption.Size = UDim2.fromOffset(250, 62)
    self.caption.StudsOffset = Vector3.new(0, 6, 0)
    self.caption.MaxDistance = 48
    self.caption.AlwaysOnTop = false
    self.caption.Enabled = false
    self.caption.Parent = self.folder
    self.label = Instance.new("TextLabel")
    self.label.Size = UDim2.fromScale(1, 1)
    self.label.Font, self.label.TextSize = Enum.Font.Code, 13
    self.label.TextWrapped = true
    self.label.BackgroundColor3, self.label.TextColor3 = Theme.Ink, Theme.Cream
    self.label.BackgroundTransparency = 0.15
    self.label.BorderSizePixel = 0
    self.label.Parent = self.caption
end

function Feedback:resolveOrigin()
    if self.explicitOrigin then
        return
    end
    local raw = workspace:GetAttribute("QuayPublicBeat")
    if self.rawExpression == raw then
        return
    end
    self.rawExpression, self.origin = raw, nil
    if type(raw) ~= "string" then
        return
    end
    local ok, value = pcall(Http.JSONDecode, Http, raw)
    local p = self.packet
    if ok and type(value) == "table" and value.epoch == p.epoch
        and type(value.startedAt) == "number" and math.abs(value.startedAt - p.startedAt) < 0.001
        and type(value.x) == "number" and type(value.y) == "number" and type(value.z) == "number" then
        self.origin = Vector3.new(value.x, value.y, value.z)
    end
end

function Feedback:selectTargets()
    local selected, distances = {}, {}
    for object, kind in self.candidates do
        if not object:IsDescendantOf(workspace) then
            self.candidates[object] = nil
        else
            local distance = (object:GetPivot().Position - self.origin).Magnitude
            if distance <= 48 and (not distances[kind] or distance < distances[kind]) then
                selected[kind], distances[kind] = object, distance
            end
        end
    end
    for kind, mark in self.marks do
        -- A missing final lamp/helper uses the existing podium as a cue target,
        -- not a fabricated character or a substitute musical sound.
        mark.Adornee = selected[kind] or selected.venue
    end
    local anchor = selected.venue or selected.dock or selected.helper
    self.caption.Adornee = if anchor and anchor:IsA("Model")
        then anchor:FindFirstChildWhichIsA("BasePart", true) else anchor
    self.selectedOrigin, self.selectionDirty = self.origin, false
end

function Feedback:step(effects)
    if self.dead or not self.packet then
        return nil
    end
    local packet = self.packet
    local value = Signatures.sample(self.index,
        workspace:GetServerTimeNow() - packet.startedAt + (packet.offset or 0), packet.loop)
    self:resolveOrigin()
    self:ensure()
    if not self.folder then
        return value
    end
    if self.origin and (self.selectionDirty or self.selectedOrigin ~= self.origin) then
        self:selectTargets()
    end
    local available = self.origin ~= nil and self.screen.Enabled
    local levels = { dock = value.drums, helper = value.helper, venue = if value.climax then 0.5 else 0 }
    local strongest, painted = {}, {}
    for kind, mark in self.marks do
        if mark.Adornee then
            strongest[mark.Adornee] = math.max(strongest[mark.Adornee] or 0, levels[kind] or 0)
        end
    end
    for _, kind in { "dock", "helper", "venue" } do
        local mark = self.marks[kind]
        local target = mark.Adornee
        local level = target and strongest[target] or 0
        mark.Enabled = available and effects == true and value.active and level > 0
            and target ~= nil and not painted[target]
        if target then
            painted[target] = true
        end
        mark.OutlineTransparency = 0.85 - level * 0.25
        mark.FillTransparency = 0.98 - level * 0.03
    end
    self.caption.Enabled = available and self.caption.Adornee ~= nil
    local text = value.caption .. (if effects then "" else "\nReduced effects / musical cue shown as text")
    if self.label.Text ~= text then
        self.label.Text = text
        self.label:SetAttribute("AccessibleLabel", text)
    end
    return value
end

function Feedback:destroy()
    self.dead, self.packet, self.index = true, nil, nil
    self:clear()
end

return Feedback
