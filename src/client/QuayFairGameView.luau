-- Picture-first fair rounds. All scores, clocks, coins and ownership come from the server.
local Shared = game.ReplicatedStorage.Shared
local Fair = require(Shared.QuayFair)
local Games = require(Shared.QuayStreetGames)
local Theme = require(Shared.Theme)
local Catalog = require(Shared.SampleCatalog)
local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Steps = require(script.Parent.VisualSteps)
local Input = game:GetService("UserInputService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local View = {}
View.__index = View
local colors = { Theme.Coral, Theme.Amber, Theme.FadedTeal, Theme.Cream }
local function glyph(parent, name, color, size)
    local icon = Icons.make(parent, name, color, size)
    icon.ZIndex = 4
    for _, child in icon:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 4 end end
    return icon
end
local function enable(button, value)
    button.Active, button.Interactable, button.Selectable = value, value, value
end
function View.new(screen, send, showPrizes)
    local self = setmetatable({ send = send, showPrizes = showPrizes, pads = {}, marks = {}, stamps = {}, targets = {}, effects = true }, View)
    self.root = Gui.round(Gui.make("Frame", screen, { Name = "FairGame", Visible = false,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(480, 450), BackgroundColor3 = Theme.Ink, BorderSizePixel = 0, ZIndex = 22 }), 14)
    self.title = Gui.label(self.root, "", 18, Theme.Cream)
    self.title.Position, self.title.Size = UDim2.fromOffset(54, 8), UDim2.new(1, -120, 0, 36)
    self.title.TextScaled = true
    Gui.make("UITextSizeConstraint", self.title, { MinTextSize = 12, MaxTextSize = 18 })
    self.close = Gui.button(self.root, "", function() send("QuaySideClose") end)
    self.close.Position, self.close.Size = UDim2.new(1, -54, 0, 6), UDim2.fromOffset(44, 44)
    self.close:SetAttribute("NoActionIcon", true)
    glyph(self.close, "close", Theme.Cream, 26).Position = UDim2.fromOffset(9, 9)
    self.flow = Steps.new(self.root, { { "SEE", "eye" }, { "PLAY", "hand" }, { "PRIZE", "badge" } }, 2)
    self.flow.root.Position, self.flow.root.Size = UDim2.fromOffset(12, 52), UDim2.new(1, -24, 0, 48)
    for _, item in self.flow.items do item.caption.Position = UDim2.fromOffset(2, 27); item.caption.Size = UDim2.new(1, -4, 0, 18) end
    self.cue = Gui.label(self.root, "", 14, Theme.Amber)
    self.cue.TextXAlignment, self.cue.Font = Enum.TextXAlignment.Center, Enum.Font.Code
    self.cue.Position, self.cue.Size = UDim2.fromOffset(42, 102), UDim2.new(1, -84, 0, 26)
    self.wait = glyph(self.root, "eye", Theme.Amber, 24)
    self.wait.Position = UDim2.fromOffset(14, 102)
    self.padArea = Gui.make("Frame", self.root, { Name = "TapTargets", BackgroundTransparency = 1 })
    for i = 1, 4 do
        local button = Gui.button(self.padArea, tostring(i), function() self:tap(i) end, { silent = true })
        button:SetAttribute("NoActionIcon", true)
        button:SetAttribute("AccessibleLabel", "Target " .. i)
        button.TextYAlignment = Enum.TextYAlignment.Bottom
        button.BackgroundColor3 = Theme.Graphite
        local icon = glyph(button, "target", colors[i], 34)
        icon.Name, icon.Position = "TargetPicture", UDim2.new(0.5, -17, 0, 8)
        local outline = Gui.make("UIStroke", button, { Color = Theme.Amber, Thickness = 3, Enabled = false })
        local finger = glyph(button, "hand", Theme.Ink, 24)
        finger.Position, finger.Visible = UDim2.new(1, -28, 0, 4), false
        self.pads[i] = { button = button, icon = icon, finger = finger, outline = outline }
    end
    self.rail = Gui.make("Frame", self.padArea, { Name = "RingTravel", BackgroundColor3 = Theme.Graphite,
        BorderSizePixel = 0, Position = UDim2.new(0.05, 0, 0, 4), Size = UDim2.new(0.9, 0, 0, 14) })
    self.window = Gui.make("Frame", self.rail, { Position = UDim2.fromScale(Fair.RingLow, 0),
        Size = UDim2.fromScale(Fair.RingHigh - Fair.RingLow, 1), BackgroundColor3 = Theme.Amber, BorderSizePixel = 0 })
    self.peg = glyph(self.window, "target", Theme.Ink, 22)
    self.peg.Position = UDim2.new(0.5, -11, 0.5, -11)
    self.ring = glyph(self.rail, "disc", Theme.Cream, 26)
    self.ring.AnchorPoint = Vector2.new(0.5, 0.5)
    self.progress = Gui.make("Frame", self.root, { BackgroundTransparency = 1 })
    for i = 1, 4 do
        local mark = Gui.round(Gui.make("Frame", self.progress, { Position = UDim2.new(0.5, (i - 2.5) * 30 - 12, 0, 0),
            Size = UDim2.fromOffset(24, 24), BackgroundColor3 = Theme.Graphite, BorderSizePixel = 0 }), 12)
        local check = glyph(mark, "check", Theme.Cream, 18)
        check.Position, check.Visible = UDim2.fromOffset(3, 3), false
        self.marks[i] = { root = mark, check = check }
    end
    self.coins = Gui.make("Frame", self.root, { BackgroundTransparency = 1 })
    for i = 1, Fair.Heats do
        local coin = glyph(self.coins, "coin", Theme.Graphite, 22)
        coin.Position = UDim2.new(0.5, (i - 2) * 28 - 11, 0, 0)
        self.stamps[i] = coin
    end
    self.wallet = Gui.label(self.coins, "", 12, Theme.Amber)
    self.wallet.Position, self.wallet.Size = UDim2.new(0.5, 48, 0, 0), UDim2.fromOffset(86, 24)
    self.primary = Gui.button(self.root, "PLAY", function() self:primaryAction() end)
    self.primary.Position, self.primary.Size = UDim2.new(0.5, -80, 1, -54), UDim2.fromOffset(160, 44)
    self.primary:SetAttribute("UiIcon", "play")
    self.again = Gui.button(self.root, "", function() send("QuaySideRetry") end)
    self.again.Position, self.again.Size = UDim2.new(1, -54, 1, -54), UDim2.fromOffset(44, 44)
    self.again:SetAttribute("NoActionIcon", true)
    glyph(self.again, "redo", Theme.Cream, 24).Position = UDim2.fromOffset(10, 10)
    self.again:SetAttribute("AccessibleLabel", "Watch and play again")
    self.learn = Gui.button(self.root, "?", function()
        self.lesson.Visible = not self.lesson.Visible
        if self.lesson.Visible and Input.GamepadEnabled then GuiService.SelectedObject = self.lessonClose end
    end)
    self.learn.Position, self.learn.Size = UDim2.new(0, 10, 1, -54), UDim2.fromOffset(44, 44)
    self.learn:SetAttribute("UiIcon", "hint")
    self.lesson = Gui.round(Gui.make("Frame", self.root, { Name = "OptionalMusicLesson", Visible = false,
        Position = UDim2.fromOffset(12, 102), Size = UDim2.new(1, -24, 1, -164),
        BackgroundColor3 = Theme.Teal, BorderSizePixel = 0, ZIndex = 8 }), 10)
    self.lessonText = Gui.label(self.lesson, "", 16, Theme.Cream)
    self.lessonText.Position, self.lessonText.Size = UDim2.fromOffset(18, 12), UDim2.new(1, -36, 1, -72)
    self.lessonText.ZIndex = 9
    self.lessonClose = Gui.button(self.lesson, "OK", function()
        self.lesson.Visible = false
        if Input.GamepadEnabled then GuiService.SelectedObject = self.primary end
    end)
    self.lessonClose.Position, self.lessonClose.Size, self.lessonClose.ZIndex = UDim2.new(0.5, -44, 1, -54), UDim2.fromOffset(88, 44), 9
    local function resize()
        local height = math.min(450, math.max(280, screen.AbsoluteSize.Y - 24))
        self.compact = height < 410
        local width = math.min(if self.compact then 640 else 500, screen.AbsoluteSize.X - 24)
        self.root.Size = UDim2.fromOffset(width, height)
        self.padArea.Position, self.padArea.Size = UDim2.fromOffset(12, 134), UDim2.new(1, -24, 0, if self.compact then math.max(44, height - 248) else 164)
        self.progress.Position, self.progress.Size = UDim2.new(0, 12, 1, -106), UDim2.new(1, -24, 0, 24)
        self.coins.Position, self.coins.Size = UDim2.new(0, 12, 1, -78), UDim2.new(1, -24, 0, 24)
        self:render()
    end
    self.resize = screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    self.heartbeat = game:GetService("RunService").Heartbeat:Connect(function() if self.root.Visible then self:render() end end)
    self.input = Input.InputBegan:Connect(function(key, processed)
        if processed or not self.root.Visible or self.lesson.Visible or Input:GetFocusedTextBox() then return end
        local pad = ({ [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4 })[key.KeyCode]
        if pad then self:tap(if self.round and self.round.id == "rings" then 1 else pad) end
    end)
    resize()
    return self
end
function View:primaryAction()
    local r = self.round
    if not r then return end
    if r.status == "ready" then
        self.pending = os.clock() + 2
        self.send("QuaySideBegin", r.serial)
    elseif r.status == "complete" then
        if self.showPrizes then self.showPrizes() end
        self.send("QuaySideClose")
    elseif r.status == "retry" or self.missed then self.send("QuaySideRetry") end
end
function View:tap(pad)
    local r = self.round
    if not r or r.status ~= "playing" or self.missed or self.lesson.Visible then return end
    if workspace:GetServerTimeNow() < r.targetAt then return end
    local sample = Catalog.sampleForRole("tutorial_closed_hat")
    if sample then Gui.Cue:Fire(sample) end
    self.send("QuaySideTap", { serial = r.serial, pad = pad })
end
function View:restoreTargets()
    for part, base in self.targets do
        if part.Parent then part.Color, part.Material, part.CFrame = base.color, base.material, base.cf end
    end
    table.clear(self.targets)
end
function View:accept(state)
    local r = state.quay and state.quay.sideActivity
    if r and not Fair.isGame(r.id) then r = nil end
    local previous = self.round
    local newRound = r and (not previous or r.serial ~= previous.serial)
    if not r or newRound then
        self:restoreTargets()
        if r then
            local world = workspace:FindFirstChild("NeedleQuay")
            local district = world and world:FindFirstChild("DemoDistrict")
            local fair = district and district:FindFirstChild("NeedleQuayFair")
            for _, part in fair and fair:GetDescendants() or {} do
                if part:IsA("BasePart") and part:GetAttribute("FairGame") == r.id then
                    self.targets[part] = { color = part.Color, material = part.Material, cf = part.CFrame }
                end
            end
        end
    end
    self.round, self.fair, self.saveMode = r, state.quay and state.quay.fair, state.saveMode
    self.root.Visible = r ~= nil
    if not r then self.lesson.Visible = false; return end
    if newRound then
        self.demoAt, self.pending, self.focusStatus, self.lesson.Visible = os.clock(), nil, nil, false
        local old = self.root:FindFirstChild("GamePicture")
        if old then old:Destroy() end
        local picture = glyph(self.root, Games.ById[r.id].icon, Theme.Amber, 30)
        picture.Name, picture.Position = "GamePicture", UDim2.fromOffset(14, 11)
        self.title.Text, self.lessonText.Text = Games.ById[r.id].title, Games.ById[r.id].lesson
        for _, item in self.pads do
            item.icon:Destroy()
            item.icon = glyph(item.button, Games.ById[r.id].icon, Theme.Cream, 32)
            item.icon.Position = UDim2.new(0.5, -16, 0, 6)
        end
    end
    if r.status ~= "ready" then self.pending = nil end
    if r.status == "playing" then self.lesson.Visible = false end
    self:render()
end
function View:render()
    local r = self.round
    if not r then return end
    local character = Players.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local now = workspace:GetServerTimeNow()
    if now > r.expires or not root or (root.Position - Games.ById[r.id].position).Magnitude > 13 then
        self.round, self.root.Visible, self.lesson.Visible = nil, false, false
        self:restoreTargets()
        self.send("QuaySideClose")
        return
    end
    local demo, won = r.status == "ready", r.status == "complete"
    local elapsed = os.clock() - (self.demoAt or os.clock())
    local phase = if demo then (elapsed % Fair.RingPeriod) / Fair.RingPeriod else math.max(0, (now - r.targetAt) % Fair.RingPeriod) / Fair.RingPeriod
    local waiting = not demo and now < r.targetAt
    local active
    self.missed = r.status == "playing" and Fair.Windows[r.id] ~= nil and now > r.targetAt + Fair.Windows[r.id]
    if demo then
        active = if r.id == "rings" then (if phase >= Fair.RingLow and phase <= Fair.RingHigh then 1 else nil)
            else (if elapsed % 2.4 >= 0.9 and elapsed % 2.4 <= 1.9 then math.floor(elapsed / 2.4) % 4 + 1 else nil)
    elseif r.status == "playing" and not waiting and not self.missed then
        active = if r.id == "rings" then (if phase >= Fair.RingLow and phase <= Fair.RingHigh then 1 else nil) else r.sequence[r.index]
    end
    local failed = r.status == "retry" or self.missed
    self.cue.Text = if won then (if (r.coins or 0) > 0 then "+10" else "3 / 3")
        elseif failed then "AGAIN" elseif demo then "WATCH" elseif waiting or (r.id == "rings" and not active) then "WAIT" else "TAP"
    local cuePicture = if won then "coin" elseif failed then "redo" elseif demo or waiting or not active then "eye" else "hand"
    if self.cuePicture ~= cuePicture then
        self.wait:Destroy()
        self.wait = glyph(self.root, cuePicture, Theme.Amber, 24)
        self.wait.Position, self.cuePicture = UDim2.fromOffset(14, 102), cuePicture
    end
    self.flow:update(if won then 3 elseif demo then 1 else 2, { demo == false, won, false })
    self.rail.Visible = r.id == "rings"
    self.ring.Position = UDim2.fromScale(if waiting then 0 else phase, 0.5)
    self.rail.Position, self.rail.Size = if self.compact then UDim2.new(0.02, 0, 0.5, -7) else UDim2.new(0.05, 0, 0, 4),
        if self.compact then UDim2.new(0.50, 0, 0, 14) else UDim2.new(0.9, 0, 0, 14)
    for i, item in self.pads do
        local single = r.id == "rings"
        item.button.Visible = not single or i == 1
        if single and self.compact then
            item.button.Position, item.button.Size = UDim2.fromScale(0.58, 0), UDim2.fromScale(0.42, 1)
        elseif single then
            item.button.Position, item.button.Size = UDim2.new(0.5, -70, 0, 26), UDim2.new(0, 140, 1, -26)
        elseif self.compact then
            item.button.Position, item.button.Size = UDim2.new((i - 1) / 4, 2, 0, 0), UDim2.new(0.25, -4, 1, 0)
        else
            item.button.Position, item.button.Size = UDim2.new((i - 1) % 2 / 2, 2, math.floor((i - 1) / 2) / 2, 2), UDim2.new(0.5, -4, 0.5, -4)
        end
        local lit = active == i
        item.button.BackgroundColor3 = if lit then Theme.Amber else Theme.Graphite
        item.button.Text = if single then "" else tostring(i)
        item.finger.Visible, item.outline.Enabled = lit, lit
        item.finger.Position = UDim2.new(1, -28, 0, if self.effects then 6 + math.sin(elapsed * 4) * 2 else 6)
        Icons.tint(item.icon, if lit then Theme.Ink else colors[i])
        enable(item.button, r.status == "playing" and not waiting and not self.missed and not self.lesson.Visible)
    end
    for i, mark in self.marks do
        mark.check.Visible = i <= r.score
        mark.root.BackgroundColor3 = if i <= r.score then Theme.Teal else Theme.Graphite
    end
    local clears = self.fair and self.fair.clears[r.id] or 0
    for i, stamp in self.stamps do Icons.tint(stamp, if i <= clears then Theme.Amber else Theme.Graphite) end
    self.wallet.Text = tostring(self.fair and self.fair.balance or 0)
        .. (if self.saveMode == "session" then " / SESSION" elseif self.saveMode == "unavailable" then " / TEMP" else "")
    self.wallet:SetAttribute("AccessibleLabel", "Fair coins: " .. self.wallet.Text)
    local primary = demo or failed or won
    self.primary.Visible, self.again.Visible, self.learn.Visible = primary, won, r.status ~= "playing"
    self.primary.Text = if demo then "PLAY" elseif won then "PRIZE" else "AGAIN"
    self.primary:SetAttribute("UiIcon", if won then "badge" elseif failed then "redo" else "play")
    enable(self.primary, primary and not (demo and self.pending and os.clock() < self.pending))
    self.primary.BackgroundColor3 = if won then Theme.Amber else Theme.Teal
    self.primary.TextColor3 = if won then Theme.Ink else Theme.Cream
    local focusStatus = r.status .. tostring(self.missed) .. tostring(waiting)
    if self.focusStatus ~= focusStatus then
        self.focusStatus = focusStatus
        if Input.GamepadEnabled then
            GuiService.SelectedObject = if primary then self.primary elseif waiting then self.close else self.pads[1].button
        end
    end
    for part, base in self.targets do
        if part.Parent then
            local lit = active == part:GetAttribute("FairPad")
            part.Color, part.Material = if lit then Theme.Cream else base.color, if lit and self.effects then Enum.Material.Neon else base.material
            if part:GetAttribute("FairRing") and not won and not failed then
                part.CFrame = base.cf + Vector3.new(((if waiting then 0 else phase) - 0.5) * 6, 0, 0)
            else part.CFrame = base.cf + Vector3.new(0, if lit then 0.45 else 0, 0) end
        end
    end
    self.root:SetAttribute("AccessibleLabel", self.title.Text .. " / " .. self.cue.Text .. " / " .. r.score .. " of 4 hits")
end
function View:destroy()
    self:restoreTargets()
    self.resize:Disconnect(); self.heartbeat:Disconnect(); self.input:Disconnect()
    self.root:Destroy()
end
return View
