local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Games = require(game.ReplicatedStorage.Shared.QuayStreetGames)
local Input = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local DeviceSkin = require(script.Parent.DeviceSkin)
local View = {}
View.__index = View
local colors = { Theme.Coral, Theme.Amber, Theme.FadedTeal, Theme.Cream }
local Catalog = require(game.ReplicatedStorage.Shared.SampleCatalog)
local sounds = { "tutorial_kick", "tutorial_closed_hat", "tutorial_pluck", "tutorial_kick" }
local function cue(role)
    local id = Catalog.sampleForRole(role)
    if id then
        Gui.Cue:Fire(id)
    end
end
function View.new(screen, send)
    local self = setmetatable({ send = send, pads = {}, dots = {}, effects = true }, View)
    self.root = Gui.round(
        Gui.make("Frame", screen, {
            Name = "StreetGame",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, -32, 0, 310),
            BackgroundColor3 = Theme.Ink,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 20,
        }),
        16
    )
    DeviceSkin.panel(self.root, "faceplate")
    Gui.round(
        Gui.make("Frame", self.root, {
            Name = "GameDisplay",
            Position = UDim2.fromOffset(7, 7),
            Size = UDim2.new(1, -14, 1, -14),
            BackgroundColor3 = Theme.Ink,
            BorderSizePixel = 0,
            ZIndex = 1,
        }),
        12
    )
    Gui.make("UISizeConstraint", self.root, { MaxSize = Vector2.new(460, 310) })
    self.title = Gui.label(self.root, "", 19, Theme.Amber)
    self.title.Font = Enum.Font.Code
    self.title.Position, self.title.Size = UDim2.fromOffset(52, 12), UDim2.new(1, -116, 0, 36)
    self.title.TextScaled = true
    Gui.make("UITextSizeConstraint", self.title, { MinTextSize = 14, MaxTextSize = 19 })
    local close = Gui.button(self.root, "", function()
        send("QuaySideClose")
    end)
    close.Position, close.Size = UDim2.new(1, -54, 0, 10), UDim2.fromOffset(44, 44)
    close:SetAttribute("NoActionIcon", true)
    Icons.make(close, "close", Theme.Cream, 26).Position = UDim2.fromOffset(8, 8)
    self.cue = Gui.label(self.root, "", 17, Theme.Cream)
    self.cue.Position, self.cue.Size = UDim2.fromOffset(20, 54), UDim2.new(1, -40, 0, 30)
    self.cue.TextXAlignment = Enum.TextXAlignment.Center
    self.cue.Font = Enum.Font.Code
    self.rail = Gui.make("Frame", self.root, {
        Position = UDim2.new(0.1, 0, 0, 86),
        Size = UDim2.new(0.8, 0, 0, 10),
        BackgroundColor3 = Theme.Graphite,
        BorderSizePixel = 0,
        Visible = false,
    })
    Gui.make("Frame", self.rail, {
        Position = UDim2.fromScale(0.38, 0),
        Size = UDim2.fromScale(0.24, 1),
        BackgroundColor3 = Theme.Amber,
        BorderSizePixel = 0,
    })
    self.cursor = Gui.make("Frame", self.rail, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(6, 20),
        BackgroundColor3 = Theme.Cream,
        BorderSizePixel = 0,
    })
    for i = 1, 4 do
        local button = Gui.button(self.root, tostring(i), function()
            self:tap(i)
        end, { silent = true })
        button.Position, button.Size =
            UDim2.new((i - 1) * 0.25, 10, 0, 108), UDim2.new(0.25, -20, 0, 100)
        button.BackgroundColor3, button.TextColor3, button.Font, button.TextSize =
            Theme.Graphite, colors[i], Enum.Font.Code, 18
        button:SetAttribute("NoActionIcon", true)
        button.TextYAlignment = Enum.TextYAlignment.Bottom
        Gui.make("UIPadding", button, { PaddingBottom = UDim.new(0, 10) })
        self.pads[i] = button
        self.dots[i] = Gui.round(
            Gui.make("Frame", self.root, {
                Position = UDim2.new(0.5, (i - 2.5) * 28 - 6, 0, 228),
                Size = UDim2.fromOffset(12, 12),
                BackgroundColor3 = Theme.Graphite,
                BorderSizePixel = 0,
            }),
            12
        )
    end
    self.retry = Gui.button(self.root, "PLAY AGAIN", function()
        send("QuaySideRetry")
    end)
    self.retry.Position, self.retry.Size = UDim2.new(0.5, -90, 1, -54), UDim2.fromOffset(180, 42)
    self.retry.Size = UDim2.fromOffset(180, 44)
    self.retry:SetAttribute("UiIcon", "play")
    self.connection = Run.Heartbeat:Connect(function()
        self:render()
    end)
    self.input = Input.InputBegan:Connect(function(key, processed)
        if processed or not self.root.Visible or Input:GetFocusedTextBox() then
            return
        end
        local pad = ({
            [Enum.KeyCode.One] = 1,
            [Enum.KeyCode.Two] = 2,
            [Enum.KeyCode.Three] = 3,
            [Enum.KeyCode.Four] = 4,
            [Enum.KeyCode.ButtonX] = 1,
            [Enum.KeyCode.ButtonY] = 2,
            [Enum.KeyCode.ButtonB] = 3,
            [Enum.KeyCode.ButtonA] = 4,
        })[key.KeyCode]
        if pad then
            if self.round and (self.round.id == "lantern" or self.round.id == "pulse") then
                pad = 1
            end
            self:tap(pad)
        end
    end)
    return self
end
function View:tap(pad)
    local r = self.round
    if not r or r.status ~= "playing" then
        return
    end
    local now = workspace:GetServerTimeNow()
    if r.id == "echo" and now < r.response then
        return
    end
    self.hit, self.hitUntil = pad, now + 0.16
    cue(sounds[pad])
    self.send("QuaySideTap", { serial = r.serial, pad = pad })
end
function View:accept(state)
    self.round = state.quay and state.quay.sideActivity
    self.root.Visible = self.round ~= nil
    self:render()
end
function View:render()
    local r = self.round
    if not r then
        return
    end
    local now = workspace:GetServerTimeNow()
    local character = game:GetService("Players").LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local at = Games.ById[r.id].position
    if now > r.expires or not root or (root.Position - at).Magnitude > 15 then
        self.round = nil
        self.root.Visible = false
        self.send("QuaySideClose")
        return
    end
    self.retry.Visible = r.status ~= "playing"
    self.title.Text = Games.ById[r.id].title
    if self.visualGame ~= r.id then
        self.visualGame = r.id
        local previous = self.root:FindFirstChild("GameIcon")
        if previous then
            previous:Destroy()
        end
        local icon = Icons.make(self.root, Games.ById[r.id].icon, Theme.Amber, 28)
        icon.Name, icon.Position = "GameIcon", UDim2.fromOffset(16, 16)
    end
    self.rail.Visible = r.id == "lantern"
    local active, beat
    if r.status == "complete" then
        self.cue.Text = "NICE!  4 / 4"
    elseif r.status == "retry" then
        self.cue.Text = "SO CLOSE. TRY AGAIN?"
    elseif r.id == "echo" then
        if now >= r.response and self.voiceRound ~= r.serial then
            self.voiceRound = r.serial
            require(script.Parent.CompanionVoice).Cue:Fire("turn")
        end
        self.cue.Text = if now < r.response then "WATCH + LISTEN" else "YOUR TURN"
        local t = now - r.start
        local step = math.floor(t / 0.6) + 1
        if t >= 0 and step <= 4 and t % 0.6 < 0.4 then
            active = r.sequence[step]
            beat = step
        end
    elseif r.id == "chase" then
        active = if now >= r.targetAt and now <= r.targetAt + 2.2 then r.sequence[r.index] else nil
        self.cue.Text = if now < r.targetAt
            then "READY…"
            elseif active then "CATCH THE LIGHT"
            else "MISSED IT — TRY AGAIN"
        self.retry.Visible = now > r.targetAt + 2.2
    elseif r.id == "lantern" then
        local phase = if now >= r.targetAt then ((now - r.targetAt) % 1.8) / 1.8 else 0
        self.cursor.Position = UDim2.fromScale(phase, 0.5)
        self.cue.Text = if now < r.targetAt then "READY…" else "LOCK INSIDE AMBER"
        active = if phase >= 0.38 and phase <= 0.62 then 1 else nil
    else
        local t = now - r.start
        beat = if t >= 0 and t < 3.7 then math.floor(t / 0.6) else nil
        active = if t >= 0 and t % 0.6 < 0.24 then 1 else nil
        self.cue.Text = if now < r.start + 1.2 then "GET READY" else "TAP ON THE PULSE"
        if r.status == "playing" and now > r.start + (r.index + 1) * 0.6 + 0.28 then
            self.cue.Text = "MISSED IT — TRY AGAIN"
            self.retry.Visible = true
        end
    end
    local cueKey = tostring(r.serial) .. ":" .. tostring(beat)
    if beat and cueKey ~= self.lastCue and r.status == "playing" and now < r.expires then
        self.lastCue = cueKey
        cue(if r.id == "echo" then sounds[active or 1] else "tutorial_closed_hat")
    end
    for i, button in self.pads do
        button.Visible = r.id == "echo" or r.id == "chase" or i == 1
        if (r.id == "pulse" or r.id == "lantern") and i == 1 then
            button.Position, button.Size = UDim2.new(0.5, -72, 0, 100), UDim2.fromOffset(144, 112)
            button.Text = if r.id == "lantern" then "LOCK" else "TAP"
        else
            button.Position, button.Size =
                UDim2.new((i - 1) * 0.25, 10, 0, 108), UDim2.new(0.25, -20, 0, 100)
            button.Text = tostring(i)
        end
        local lit = active == i or (self.hit == i and now < (self.hitUntil or 0))
        button.BackgroundColor3 = if lit then colors[i] else Theme.Graphite
        button.TextColor3 = if lit then Theme.Ink else colors[i]
        local iconName = if r.id == "lantern"
            then "lamp"
            elseif r.id == "chase" then "bolt"
            else ({ "drum", "steps", "sound", "drum" })[i]
        local iconKey = iconName .. ":" .. tostring(lit)
        if button:GetAttribute("MiniPadGraphic") ~= iconKey then
            button:SetAttribute("MiniPadGraphic", iconKey)
            local previous = button:FindFirstChild("PadGraphic")
            if previous then
                previous:Destroy()
            end
            local icon = Icons.make(button, iconName, if lit then Theme.Ink else colors[i], 32)
            icon.Name, icon.Position, icon.ZIndex =
                "PadGraphic", UDim2.new(0.5, -16, 0, 14), button.ZIndex + 3
            for _, shape in icon:GetDescendants() do
                if shape:IsA("GuiObject") then
                    shape.ZIndex = icon.ZIndex
                end
            end
        end
        self.dots[i].BackgroundColor3 = if i <= r.score then Theme.Amber else Theme.Graphite
    end
end
function View:destroy()
    self.connection:Disconnect()
    self.input:Disconnect()
    self.root:Destroy()
end
return View
