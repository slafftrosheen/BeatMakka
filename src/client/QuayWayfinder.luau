-- Local navigable breadcrumbs. If a route fails, retain only the destination beacon.
local Paths = game:GetService("PathfindingService")
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Wayfinder = {}
Wayfinder.__index = Wayfinder
function Wayfinder.new()
    local self = setmetatable({ dots = {}, generation = 0, nextRoute = 0 }, Wayfinder)
    self.folder = Instance.new("Folder")
    self.folder.Name = "LocalQuayRoute"
    self.folder.Parent = workspace
    for i = 1, 16 do
        local dot = Instance.new("Part")
        dot.Name = "RouteDot" .. i
        dot.Shape = Enum.PartType.Ball
        dot.Size = Vector3.new(0.38, 0.38, 0.38)
        dot.Anchored = true
        dot.CanCollide = false
        dot.CanQuery = false
        dot.CanTouch = false
        dot.CastShadow = false
        dot.Material = Enum.Material.Neon
        dot.Color = Theme.Amber
        dot.Transparency = 1
        dot.Parent = self.folder
        self.dots[i] = dot
    end
    self.highlight = Instance.new("Highlight")
    self.highlight.FillTransparency = 0.88
    self.highlight.OutlineColor = Theme.Amber
    self.highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    self.highlight.Enabled = false
    self.highlight.Parent = self.folder
    return self
end
function Wayfinder:update(origin, destination, enabled)
    for _, dot in self.dots do
        dot.Transparency = 1
    end
    self.highlight.Enabled = false
    if not enabled or not origin then
        if self.destination then
            self.generation += 1
            self.destination = nil
            self.points = nil
        end
        return
    end
    local changed = not self.destination or (self.destination - destination).Magnitude > 2
    if changed then
        self.generation += 1
        self.destination = destination
        self.points = nil
        self.nextRoute = 0
    end
    local district = workspace:FindFirstChild("NeedleQuay")
    if changed and district then
        local nearest, dist = nil, 8
        for _, part in district:GetDescendants() do
            if
                part:IsA("BasePart")
                and (
                    part:GetAttribute("QuayPersonalTarget") or part:GetAttribute("QuayInteraction")
                )
            then
                local d = (part.Position - destination).Magnitude
                if d < dist then
                    nearest, dist = part, d
                end
            end
        end
        self.highlight.Adornee = nearest
    end
    self.highlight.Enabled = self.highlight.Adornee ~= nil
    if not self.pending and os.clock() >= self.nextRoute then
        self.pending = true
        self.nextRoute = os.clock() + 4
        local generation = self.generation
        task.spawn(function()
            local path = Paths:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true,
                WaypointSpacing = 5,
            })
            local ok = pcall(function()
                path:ComputeAsync(origin, destination)
            end)
            if not self.dead and generation == self.generation then
                self.points = if ok and path.Status == Enum.PathStatus.Success
                    then path:GetWaypoints()
                    else nil
            end
            path:Destroy()
            self.pending = false
        end)
    end
    if not self.points then
        return
    end
    local index, closest = 1, math.huge
    for i, point in self.points do
        local d = (point.Position - origin).Magnitude
        if d < closest then
            index, closest = i, d
        end
    end
    local out = 1
    for i = index + 1, #self.points do
        if out > #self.dots then
            break
        end
        local point = self.points[i]
        self.dots[out].Position = point.Position + Vector3.new(0, 0.32, 0)
        self.dots[out].Transparency = 0.18
        out += 1
    end
end
function Wayfinder:destroy()
    self.dead = true
    self.generation += 1
    self.folder:Destroy()
end
return Wayfinder
