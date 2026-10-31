local Gui = require(script.Parent.GuiFactory)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Digital = require(script.Parent.DigitalDisplay)
local Face = {}
Face.__index = Face
function Face.new(panel, command, state)
    local self = setmetatable({}, Face)
    panel.BackgroundColor3 = Theme.Teal
    local texture = require(script.Parent.GrooveboxSkin).image(panel, "enamel", {
        Name = "EnamelFaceplate",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ImageTransparency = 0.35,
        ScaleType = Enum.ScaleType.Stretch,
        ZIndex = 0,
    })
    texture.Name = "EnamelFaceplate"
    for _, side in { 0, 1 } do
        local cheek = Gui.make("Frame", panel, {
            Name = "WalnutCheek",
            AnchorPoint = Vector2.new(side, 0),
            Position = UDim2.fromScale(side, 0),
            Size = UDim2.new(0, 8, 1, 0),
            BackgroundColor3 = Theme.Walnut,
            BorderSizePixel = 0,
        })
        Gui.round(cheek, 4)
        for _, y in { 0, 1 } do
            local screw = Gui.round(
                Gui.make("Frame", panel, {
                    Name = "CaseScrew",
                    AnchorPoint = Vector2.new(side, y),
                    Position = UDim2.new(
                        side,
                        if side == 0 then 10 else -10,
                        y,
                        if y == 0 then 4 else -4
                    ),
                    Size = UDim2.fromOffset(6, 6),
                    BackgroundColor3 = Theme.Stone,
                    BorderSizePixel = 0,
                }),
                4
            )
            Gui.make("Frame", screw, {
                Position = UDim2.fromOffset(1, 2),
                Size = UDim2.fromOffset(4, 1),
                BackgroundColor3 = Theme.Graphite,
                BorderSizePixel = 0,
            })
        end
    end
    self.display = Gui.round(
        Gui.make("Frame", panel, {
            Name = "HardwareDisplay",
            Position = UDim2.fromOffset(16, 12),
            Size = UDim2.new(1, -32, 0, 68),
            BackgroundColor3 = Theme.Screen,
            BorderSizePixel = 0,
        }),
        8
    )
    self.brand = Gui.label(self.display, "BEATMAKKA / MK-I", 16, Theme.Amber)
    self.brand.Font = Enum.Font.Code
    self.brand.Position = UDim2.fromOffset(14, 8)
    self.brand.Size = UDim2.new(0.25, -20, 0, 22)
    self.track = Gui.label(self.display, "PAD 01 / READY", 11, Theme.Cream)
    self.track.Font = Enum.Font.Code
    self.track.Position = UDim2.fromOffset(14, 34)
    self.track.Size = UDim2.new(0.25, -20, 0, 20)
    self.signalRoot = Gui.make("Frame", self.display, {
        Name = "LiveSignal",
        Position = UDim2.new(0.30, 0, 0, 10),
        Size = UDim2.new(0.46, -32, 1, -20),
        BackgroundTransparency = 1,
    })
    self.signalBars, self.signalHistory = {}, {}
    for index = 1, 36 do
        self.signalHistory[index] = 0
        self.signalBars[index] = Gui.make("Frame", self.signalRoot, {
            Name = "Signal_" .. index,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale((index - 1) / 36, 0.5),
            Size = UDim2.new(1 / 36, -3, 0, 2),
            BackgroundColor3 = Theme.FadedTeal,
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
        })
    end
    self.tempo = Digital.new(self.display)
    self.tempo.root.Position = UDim2.new(1, -158, 0, 10)
    Gui.make("UIScale", self.tempo.root, { Scale = 0.75 })
    local bpm = Gui.label(self.display, "TAP BPM", 10, Theme.Amber)
    self.bpmLabel = bpm
    bpm.Font = Enum.Font.Code
    bpm.Position = UDim2.new(1, -155, 0, 46)
    bpm.Size = UDim2.fromOffset(80, 16)
    local taps = {}
    self.tapTempo = Gui.button(self.display, "", function()
        local current = state()
        if not current or not current.ready then
            return
        end
        local now = os.clock()
        if #taps > 0 and now - taps[#taps] > 2 then
            table.clear(taps)
        end
        if #taps > 0 and now - taps[#taps] < 0.15 then
            return
        end
        table.insert(taps, now)
        if #taps > 5 then
            table.remove(taps, 1)
        end
        if #taps >= 2 then
            local interval = (taps[#taps] - taps[1]) / (#taps - 1)
            command("Bpm", math.clamp(math.floor(60 / interval + 0.5), 60, 180))
        end
    end, { silent = true })
    self.tapTempo.Name = "TapTempo"
    self.tapTempo.BackgroundTransparency = 1
    self.tapTempo.Position, self.tapTempo.Size = UDim2.new(1, -184, 0, 10), UDim2.fromOffset(80, 44)
    bpm.Position = UDim2.new(1, -184, 0, 46)
    self.tempoButtons = {}
    for _, direction in { -1, 1 } do
        local b = Gui.button(self.display, if direction < 0 then "−" else "+", function()
            local s = state()
            if s and s.ready then
                command("Bpm", math.clamp(s.pattern.bpm + direction, 60, 180))
            end
        end, { silent = true })
        b.Name = if direction < 0 then "TempoMinus" else "TempoPlus"
        b.Position = UDim2.new(1, if direction < 0 then -68 else -34, 0, 10)
        b.Size = UDim2.fromOffset(30, 44)
        b.BackgroundColor3 = Theme.Graphite
        self.tempoButtons[direction] = b
    end
    panel.Destroying:Connect(function()
        self.dead = true
        if self.image then
            self.image:Destroy()
        end
    end)
    return self
end
function Face:resize(narrow, compact, minimal)
    self.display.Position = UDim2.fromOffset(16, if compact then 8 else 12)
    self.display.Size = UDim2.new(1, -32, 0, if compact then 54 else 68)
    self.brand.Position = UDim2.fromOffset(14, if compact then 4 else 8)
    self.track.Position = UDim2.fromOffset(14, if compact then 28 else 34)
    self.bpmLabel.Visible = not compact
    self.brand.TextSize = if narrow then 13 else 16
    self.signalRoot.Visible = not narrow and not minimal
    self.brand.Visible, self.track.Visible = not minimal, not minimal
    self.brand.Text = if narrow then "MK-I / QUAY" else "BEATMAKKA / MK-I"
    self.brand.Size = if narrow then UDim2.new(1, -204, 0, 22) else UDim2.new(0.27, -20, 0, 22)
    self.track.Size = if narrow then UDim2.new(1, -204, 0, 20) else UDim2.new(0.27, -20, 0, 20)
    local y = if compact then 4 else 10
    self.tempo.root.Position = UDim2.new(1, -184, 0, y)
    self.tapTempo.Position = UDim2.new(1, -184, 0, y)
    self.tempoButtons[-1].Position = UDim2.new(1, -94, 0, y)
    self.tempoButtons[1].Position = UDim2.new(1, -46, 0, y)
    for _, button in self.tempoButtons do
        button.Size = UDim2.fromOffset(44, 44)
    end
    if minimal then
        self.display.Position = UDim2.new(0.5, 5, 0, 0)
        self.display.Size = UDim2.new(0.5, -64, 0, 44)
        if narrow then
            self.display.Position, self.display.Size =
                UDim2.fromOffset(16, 0), UDim2.new(1, -76, 0, 44)
        end
        self.tempo.root.Position, self.tapTempo.Position =
            UDim2.fromOffset(4, 4), UDim2.fromOffset(4, 0)
        self.tempoButtons[-1].Position, self.tempoButtons[1].Position =
            UDim2.new(1, -94, 0, 0), UDim2.new(1, -46, 0, 0)
    end
end
function Face:signal(level)
    if not self.signalRoot.Visible or not self.display.Parent.Visible then
        return
    end
    if os.clock() < (self.nextSignalAt or 0) then
        return
    end
    self.nextSignalAt = os.clock() + 0.05
    table.remove(self.signalHistory, 1)
    table.insert(self.signalHistory, math.clamp(level, 0, 1))
    self.signalRoot:SetAttribute("SignalLevel", level)
    for index, bar in self.signalBars do
        local value = self.signalHistory[index]
        bar.Size = UDim2.new(1 / 36, -3, math.max(0.035, value), 0)
        bar.BackgroundColor3 = if value > 0.85
            then Theme.Coral
            elseif value > 0.02 then Theme.Amber
            else Theme.FadedTeal
        bar.BackgroundTransparency = if value > 0.02 then 0 else 0.6
    end
end
function Face:update(state, pad)
    self.tempo:set(state.pattern.bpm)
    local address = if state.music
        then string.format(
            "%s%02d",
            string.char(65 + math.floor((pad - 1) / 16)),
            (pad - 1) % 16 + 1
        )
        else string.format("PAD %02d", pad)
    self.track.Text = address
        .. " / "
        .. (if state.recording then "REC" elseif state.playing then "PLAY" else "STOPPED")
end
return Face
