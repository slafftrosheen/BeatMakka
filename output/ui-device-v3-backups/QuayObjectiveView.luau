-- Optional personal guidance. Reads server progress/waypoints; never awards or teleports.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Objectives = require(game.ReplicatedStorage.Shared.QuayObjectives)
local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Games = require(game.ReplicatedStorage.Shared.QuayStreetGames)
local Steps = require(game.ReplicatedStorage.Shared.QuayMissionSteps)
local Recipes = require(game.ReplicatedStorage.Shared.QuayFxRecipes)
local View = {}
View.__index = View
local function busy(state)
    return not state
        or not state.ready
        or not state.quay
        or state.station
        or state.playing
        or state.recording
        or state.listening
        or (state.stage and state.stage.open)
        or (state.concert and state.concert.open)
        or (state.jam and (state.jam.active or state.jam.open))
        or state.quay.canReturn
        or state.quay.open ~= nil
        or state.quay.sideActivity ~= nil
end
function View.new(screen)
    local self = setmetatable({ guide = true, elapsed = 0, expanded = false }, View)
    self.wayfinder = require(script.Parent.QuayWayfinder).new()
    self.root = Gui.round(
        Gui.make("Frame", screen, {
            Name = "TrackedObjective",
            Position = UDim2.fromOffset(12, 62),
            Size = UDim2.fromOffset(310, 118),
            BackgroundColor3 = Theme.Ink,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            Visible = false,
        }),
        10
    )
    self.title = Gui.label(self.root, "", 15, Theme.Amber)
    self.title.Font = Theme.Bold
    self.title.Position, self.title.Size = UDim2.fromOffset(48, 8), UDim2.new(1, -148, 0, 32)
    self.arrow = Icons.make(self.root, "arrow", Theme.Amber, 26)
    self.arrow.Position = UDim2.fromOffset(12, 12)
    self.toggle = Gui.button(self.root, "Guide OFF", function()
        self.guide = not self.guide
        self:render()
    end)
    self.toggle.Name, self.toggle.Position, self.toggle.Size =
        "ToggleGuide", UDim2.new(1, -92, 0, 6), UDim2.fromOffset(84, 44)
    self.detail = Gui.label(self.root, "", 14, Theme.Cream)
    self.detail.Position, self.detail.Size = UDim2.fromOffset(12, 48), UDim2.new(1, -24, 0, 42)
    self.distance = Gui.label(self.root, "", 12, Theme.FadedTeal)
    self.distance.Position, self.distance.Size = UDim2.fromOffset(12, 94), UDim2.new(1, -24, 0, 18)
    self.more = Gui.button(self.root, "?", function()
        self.expanded = not self.expanded
        if self.expanded then
            require(script.Parent.CompanionVoice).Cue:Fire("mission")
        end
        self.resizeLayout()
    end)
    self.stepLabels = {}
    for i = 1, 3 do
        local label = Gui.label(self.root, "", 10, Theme.Cream)
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.BackgroundTransparency = 0
        label.Size = UDim2.new(1 / 3, -12, 0, 22)
        self.stepLabels[i] = label
    end
    self.fxTrail = Gui.button(self.root, "FX TRAIL", function()
        if not self.state or not self.state.quay then
            return
        end
        if self.fxTracking then
            self.fxTracking = false
            self.activity, self.preferred = nil, nil
            self:render()
            return
        end
        for _, item in Recipes.List do
            if not Recipes.earned(self.state.quay.progress, item) then
                self.fxTracking = true
                if item.side then
                    self:trackActivity(item.target)
                else
                    self:track(
                        if item.quest == "NQ-Q10"
                                and not self.state.quay.progress.completed["NQ-Q09"]
                            then "NQ-Q09"
                            else item.quest
                    )
                end
                return
            end
        end
    end)
    self.fxTrail.Size = UDim2.new(1, -24, 0, 36)
    self.more.Position, self.more.Size = UDim2.new(1, -44, 0, 43), UDim2.fromOffset(32, 30)
    self.marker = Gui.make("Part", workspace, {
        Name = "LocalQuayDestination",
        Size = Vector3.one,
        Anchored = true,
        Transparency = 1,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
    })
    self.beacon = Gui.make("BillboardGui", screen.Parent, {
        Name = "QuayDestination",
        ResetOnSpawn = false,
        Adornee = self.marker,
        Size = UDim2.fromOffset(180, 50),
        StudsOffsetWorldSpace = Vector3.new(0, 5, 0),
        AlwaysOnTop = false,
        MaxDistance = 650,
        Enabled = false,
    })
    local backing = Gui.round(
        Gui.make(
            "Frame",
            self.beacon,
            { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Teal, BorderSizePixel = 0 }
        ),
        8
    )
    self.markerLabel = Gui.label(backing, "", 14, Theme.Cream)
    self.markerLabel.Size, self.markerLabel.TextXAlignment =
        UDim2.fromScale(1, 1), Enum.TextXAlignment.Center
    self.connection = RunService.Heartbeat:Connect(function(dt)
        self.elapsed += dt
        if self.elapsed < 0.2 then
            return
        end
        self.elapsed = 0
        self:render()
    end)
    local function resize()
        local touch = Input.TouchEnabled
        local width = math.min(310, math.max(250, screen.AbsoluteSize.X - 24))
        self.root.Size = UDim2.fromOffset(width, if self.expanded then 190 else 148)
        self.root.Position = UDim2.fromOffset(
            12,
            if touch then (if screen.AbsoluteSize.X - 24 < 480 then 168 else 124) else 62
        )
        self.detail.Visible = self.expanded
        self.distance.Position = UDim2.fromOffset(12, if self.expanded then 98 else 52)
        for i, label in self.stepLabels do
            label.Position = UDim2.new((i - 1) / 3, 8, 0, if self.expanded then 120 else 78)
        end
        self.fxTrail.Position = UDim2.fromOffset(12, if self.expanded then 146 else 104)
    end
    self.resize = screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    self.resizeLayout = resize
    resize()
    return self
end
function View:track(id)
    self.lifeTarget = nil
    self.activity = nil
    self.preferred = id
    self.guide = true
    self:render()
    require(script.Parent.CompanionVoice).Cue:Fire("route")
end
function View:trackActivity(id)
    self.lifeTarget = nil
    if not Games.ById[id] then
        return
    end
    self.activity = id
    self.guide = true
    self:render()
    require(script.Parent.CompanionVoice).Cue:Fire("route")
end
function View:accept(state)
    local active = state.quay and state.quay.commission and state.quay.commission.active
    if active ~= self.commissionId then
        self.commissionId = active
        if active then
            self.lifeTarget = nil
            self.preferred = nil
            self.activity = nil
            self.fxTracking = false
            self.guide = true
        end
    end
    self.state = state
    local life = state.quay and state.quay.life and state.quay.life.progress
    if self.lifeTarget and life then
        local key = self.lifeTarget.key
        local done = (key:sub(1, 7) == "listen_" and life.stamps[key:sub(8)])
            or (key:sub(1, 7) == "garden_" and life.gardens[key:sub(8)])
            or (key == "parcel_pickup" and life.parcel >= 1)
            or (key == "parcel_drop" and life.parcel == 2)
        if done then
            self.lifeTarget = nil
        end
    end
    if self.activity and state.quay and state.quay.progress.side[self.activity] then
        self.activity = nil
        self.fxTracking = false
    end
    if
        self.fxTracking
        and self.preferred
        and state.quay
        and state.quay.progress.completed[self.preferred]
    then
        self.preferred = nil
        self.fxTracking = false
    end
    if self.activity and state.quay and state.quay.sideActivity then
        self.activity = nil
    end
    self:render()
end
function View:trackLife(key, title, detail)
    self.lifeTarget =
        { key = key, target = "life_" .. key, title = string.upper(title), text = detail }
    self.activity, self.preferred, self.fxTracking = nil, nil, false
    self.guide = true
    self:render()
end
function View:render()
    local state = self.state
    local visible = not busy(state)
    local objective = state and Objectives.select(state.quay, self.preferred)
    if self.lifeTarget then
        objective = self.lifeTarget
    end
    if self.activity then
        objective = {
            target = "activity_" .. self.activity,
            text = Games.ById[self.activity].hint,
        }
    end
    if not objective and state and state.quay then
        for _, item in Recipes.List do
            if item.side and not Recipes.earned(state.quay.progress, item) then
                objective = {
                    target = "activity_" .. item.target,
                    text = item.hint .. " to discover " .. item.label .. ".",
                }
                break
            end
        end
    end
    self.root.Visible = visible and objective ~= nil
    local destination = objective
        and state.quay.waypoints
        and state.quay.waypoints[objective.target]
    local valid = typeof(destination) == "Vector3"
    local character = Players.LocalPlayer.Character
    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
    self.wayfinder:update(
        playerRoot and playerRoot.Position,
        destination,
        visible and self.guide and valid
    )
    self.beacon.Enabled = visible and self.guide and objective ~= nil and valid
    if not objective then
        return
    end
    local action = if objective.title
        then objective.title
        elseif objective.target == "enter" then "MAKE A BEAT"
        elseif objective.target == "activity_echo" then "ECHO PADS"
        elseif objective.target == "activity_pulse" then "PULSE CLUB"
        elseif objective.target == "activity_chase" then "LIGHT CHASE"
        elseif objective.target == "activity_lantern" then "LANTERN LOCK"
        elseif objective.target == "activity_busk" then "STREET SET"
        elseif
            objective.target:sub(1, 4) == "dock" or objective.target:sub(1, 6) == "market"
        then "STOW CASE"
        elseif objective.target:sub(1, 6) == "repair" then "FIX THE VENT"
        elseif objective.target == "radio" then "LIGHT IT UP"
        else "MEET " .. (({
            P1 = "TORI",
            P2 = "IVO",
            P3 = "NAYA",
            P4 = "MICA",
            finale = "RONAN",
        })[objective.target] or "THE QUAY")
    local steps = Steps.project(state.quay, objective)
    if self.lifeTarget then
        steps = {
            key = objective.target,
            done = 0,
            labels = { "FIND", "INTERACT", "REMEMBER" },
            hint = objective.text,
        }
    end
    if steps.key ~= self.progressKey then
        self.progressKey = steps.key
        self.idleTime = 0
        self.hintOffered = false
    end
    if visible and self.guide then
        self.idleTime = (self.idleTime or 0) + 0.2
    end
    if visible and self.guide and not self.hintOffered and (self.idleTime or 0) > 35 then
        self.hintOffered = true
        self.expanded = true
        self.resizeLayout()
    end
    for i, label in self.stepLabels do
        label.Text = (if i <= steps.done then "✓ " else "") .. steps.labels[i]
        label.BackgroundColor3 = if i <= steps.done
            then Theme.Teal
            elseif i == steps.done + 1 then Theme.Amber
            else Theme.Graphite
        label.TextColor3 = if i == steps.done + 1 then Theme.Ink else Theme.Cream
    end
    local unlocked = 0
    for _, item in Recipes.List do
        if Recipes.earned(state.quay.progress, item) then
            unlocked += 1
        end
    end
    self.fxTrail.Text = if self.fxTracking
        then "← MAIN MISSION"
        elseif unlocked == #Recipes.List then "ALL FX FOUND / ROAMER → SOUNDS"
        else string.format("DISCOVER FX  /  %d OF %d", unlocked, #Recipes.List)
    self.title.Text, self.detail.Text = action, steps.hint
    self.toggle.Text = if self.guide then "ROUTE ON" else "ROUTE OFF"
    self.toggle.BackgroundColor3 = if self.guide then Theme.Amber else Theme.Teal
    self.toggle.TextColor3 = if self.guide then Theme.Ink else Theme.Cream
    self.markerLabel.Text = action
    if valid then
        self.marker.Position = destination
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local distance = root and (destination - root.Position).Magnitude or 0
        self.distance.Text = if distance < 12
            then "YOU'RE HERE  /  INTERACT"
            else string.format("%03d  /  FOLLOW THE MARKERS", distance)
        if root and workspace.CurrentCamera then
            local localDirection =
                workspace.CurrentCamera.CFrame:VectorToObjectSpace(destination - root.Position)
            self.arrow.Rotation = math.deg(math.atan2(localDirection.X, -localDirection.Z))
        end
    else
        self.distance.Text = "Explore the quay at your own pace"
    end
end
function View:destroy()
    self.wayfinder:destroy()
    self.connection:Disconnect()
    self.resize:Disconnect()
    self.marker:Destroy()
    self.beacon:Destroy()
    self.root:Destroy()
end
return View
