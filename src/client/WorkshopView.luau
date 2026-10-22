local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Theme = require(Shared.Theme)
local Catalog = require(Shared.SampleCatalog)
local Cosmetics = require(Shared.CosmeticCatalog)
local Atlas = require(Shared.UiAtlas)
local Gui = require(script.Parent.GuiFactory)
local WorkshopView = {}
WorkshopView.__index = WorkshopView

function WorkshopView.new(callbacks)
    local self = setmetatable({
        selectedPad = 1,
        callbacks = callbacks,
        pads = {},
        steps = {},
        samples = {},
        effects = true,
        muted = false,
    }, WorkshopView)
    local screen = Gui.make("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {
        Name = "FrequencyZero",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
    })
    self.screen = screen
    local hud = Gui.round(Gui.make("Frame", screen, {
        Position = UDim2.new(0, 12, 1, -112),
        Size = UDim2.new(1, -24, 0, 100),
        BackgroundColor3 = Theme.Ink,
        BorderSizePixel = 0,
    }))
    hud.Name = "HubHud"
    Gui.make("UISizeConstraint", hud, { MaxSize = Vector2.new(670, 144) })
    self.hudLabel = Gui.label(
        hud,
        "NEEDLE QUAY\nVisit a workshop sampler. Discover three neighborhood sounds.",
        15,
        Theme.Cream
    )
    self.hudLabel.Position = UDim2.fromOffset(14, 10)
    self.hudLabel.Size = UDim2.new(1, -210, 1, -20)
    local function toggleSound()
        self.muted = not self.muted
        self.sound.Text = if self.muted then "Sound MUTED" else "Sound ON"
        if self.panelSound then
            self.panelSound.Text = self.sound.Text
        end
        callbacks.mute(self.muted)
    end
    self.sound = Gui.button(hud, "Sound ON", toggleSound)
    self.sound.Name = "Sound"
    self.sound.Position = UDim2.new(1, -192, 0.5, -22)
    self.sound.Size = UDim2.fromOffset(84, 44)
    local function toggleEffects()
        self.effects = not self.effects
        self.effectsButton.Text = if self.effects then "Effects ON" else "Effects OFF"
        if self.panelEffects then
            self.panelEffects.Text = self.effectsButton.Text
        end
        callbacks.effects(self.effects)
    end
    self.effectsButton = Gui.button(hud, "Effects ON", toggleEffects)
    self.effectsButton.Name = "Effects"
    self.effectsButton.Position = UDim2.new(1, -100, 0.5, -22)
    self.effectsButton.Size = UDim2.fromOffset(88, 44)
    self.hud = hud
    local function resizeHud()
        local narrow = hud.AbsoluteSize.X < 480
        hud.Size = UDim2.new(1, -24, 0, if narrow then 144 else 100)
        hud.Position = UDim2.new(0, 12, 1, if narrow then -156 else -112)
        if UserInputService.TouchEnabled then
            hud.Position =
                UDim2.fromOffset(12, if self.state and self.state.listening then 178 else 12)
        end
        self.hudLabel.Size = if narrow then UDim2.new(1, -28, 0, 76) else UDim2.new(1, -210, 1, -20)
        self.sound.Position = if narrow
            then UDim2.new(0, 14, 1, -54)
            else UDim2.new(1, -192, 0.5, -22)
        self.effectsButton.Position = if narrow
            then UDim2.new(0, 106, 1, -54)
            else UDim2.new(1, -100, 0.5, -22)
    end
    hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeHud)
    resizeHud()
    local panel = Gui.round(
        Gui.make("Frame", screen, {
            Name = "Workstation",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, -24, 1, -24),
            BackgroundColor3 = Theme.Cream,
            Visible = false,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }),
        16
    )
    Gui.make("UISizeConstraint", panel, { MaxSize = Vector2.new(1040, 850) })
    self.panel = panel
    self.resizeHud = resizeHud
    Gui.panelMask(panel)
    local scroll = Gui.make("ScrollingFrame", panel, {
        Position = UDim2.fromOffset(16, 12),
        Size = UDim2.new(1, -32, 1, -24),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    })
    Gui.make(
        "UIListLayout",
        scroll,
        { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    scroll.Name = "Content"
    local header = Gui.make(
        "Frame",
        scroll,
        { Size = UDim2.new(1, -6, 0, 58), BackgroundTransparency = 1, LayoutOrder = 1 }
    )
    local title = Gui.label(header, "MK-I  /  MAKE SOMETHING YOURS", 21)
    header.Name = "Header"
    title.Font = Theme.Bold
    title.Size = UDim2.new(1, -90, 1, 0)
    local close = Gui.button(header, "Leave", function()
        callbacks.command("Release")
    end)
    close.Modal = true
    close.Name = "Leave"
    close.Size = UDim2.fromOffset(78, 44)
    close.Position = UDim2.new(1, -78, 0, 5)
    local toolbar = Gui.make(
        "Frame",
        scroll,
        { Size = UDim2.new(1, -6, 0, 152), BackgroundTransparency = 1, LayoutOrder = 2 }
    )
    Gui.make("UIGridLayout", toolbar, {
        CellSize = UDim2.new(0.25, -6, 0, 44),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    toolbar.Name = "Transport"
    local transportIndex = 0
    local function control(text, action, a)
        local button = Gui.button(toolbar, text, function()
            callbacks.command(action, if type(a) == "function" then a() else a)
        end)
        transportIndex += 1
        button.Name = action
        button.LayoutOrder = transportIndex
        return button
    end
    self.play = control("Play [SPACE]", "Play")
    self.record = control("Record OFF", "Record")
    self.playIcon = Gui.icon(self.play, "play")
    Gui.icon(self.record, "record")
    self.bpmDown = control("Tempo -", "Bpm", function()
        return math.max(60, self.state.pattern.bpm - 1)
    end)
    self.bpmUp = control("Tempo +", "Bpm", function()
        return math.min(180, self.state.pattern.bpm + 1)
    end)
    self.bpmDown.Name = "TempoDown"
    self.bpmUp.Name = "TempoUp"
    self.save = control("Save", "Save")
    self.restore = control("Restore", "Restore")
    self.padMute = control("Mute pad", "MutePad", function()
        return self.selectedPad
    end)
    control("Clear pad", "ClearPad", function()
        return self.selectedPad
    end)
    self.panelSound = Gui.button(toolbar, "Sound ON", toggleSound)
    self.panelEffects = Gui.button(toolbar, "Effects ON", toggleEffects)
    self.panelSound.Name = "Sound"
    self.panelSound.LayoutOrder = 9
    self.panelEffects.Name = "Effects"
    self.panelEffects.LayoutOrder = 10
    self.finish = Gui.button(toolbar, "Finish: Workshop teal", function()
        if not self.state then
            return
        end
        local current = table.find(Cosmetics.Order, self.state.finish) or 1
        callbacks.command("Finish", Cosmetics.Order[current % #Cosmetics.Order + 1])
    end)
    self.finish.Name = "Finish"
    self.finish.LayoutOrder = 11
    self.status = Gui.label(scroll, "Loading session...", 14)
    self.status.Name = "Status"
    self.status.Size = UDim2.new(1, -6, 0, 52)
    self.status.AutomaticSize = Enum.AutomaticSize.Y
    self.status.LayoutOrder = 3
    local workspace = Gui.make(
        "Frame",
        scroll,
        { Size = UDim2.new(1, -6, 0, 300), BackgroundTransparency = 1, LayoutOrder = 4 }
    )
    local pads = Gui.make(
        "Frame",
        workspace,
        { Size = UDim2.fromScale(0.49, 1), BackgroundTransparency = 1 }
    )
    workspace.Name = "Instrument"
    pads.Name = "Pads"
    Gui.make("UIGridLayout", pads, {
        CellSize = UDim2.new(0.25, -6, 0.25, -6),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    local details = Gui.make("Frame", workspace, {
        Position = UDim2.fromScale(0.52, 0),
        Size = UDim2.fromScale(0.48, 1),
        BackgroundTransparency = 1,
    })
    self.rowTitle = Gui.label(details, "PAD 01 / 16 STEPS", 16)
    details.Name = "Sequencer"
    self.rowTitle.Font = Theme.Bold
    self.rowTitle.Size = UDim2.new(1, 0, 0, 38)
    local steps = Gui.make("Frame", details, {
        Position = UDim2.fromOffset(0, 44),
        Size = UDim2.new(1, 0, 1, -44),
        BackgroundTransparency = 1,
    })
    Gui.make("UIGridLayout", steps, {
        CellSize = UDim2.new(0.25, -6, 0.25, -6),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    steps.Name = "Steps"
    for pad = 1, 16 do
        self.pads[pad] = Gui.button(pads, tostring(pad), function()
            self:selectPad(pad)
            callbacks.tap(pad)
        end)
        self.pads[pad].LayoutOrder = pad
        self.pads[pad].Name = string.format("Pad_%02d", pad)
    end
    for step = 1, 16 do
        self.steps[step] = Gui.button(steps, tostring(step), function()
            callbacks.command("Step", self.selectedPad, step)
        end)
        self.steps[step].LayoutOrder = step
        self.steps[step].Name = string.format("Step_%02d", step)
    end
    for index, button in self.pads do
        button.NextSelectionLeft = self.pads[index - 1]
        button.NextSelectionRight = self.pads[index + 1]
        button.NextSelectionUp = self.pads[index - 4]
        button.NextSelectionDown = self.pads[index + 4]
    end
    local libraryTitle =
        Gui.label(scroll, "SOUND COLLECTION  /  Choose a sound to assign to the selected pad", 15)
    libraryTitle.Size = UDim2.new(1, -6, 0, 42)
    libraryTitle.LayoutOrder = 5
    local library = Gui.make(
        "Frame",
        scroll,
        { Size = UDim2.new(1, -6, 0, 356), BackgroundTransparency = 1, LayoutOrder = 6 }
    )
    Gui.make("UIGridLayout", library, {
        CellSize = UDim2.new(1 / 3, -6, 0, 44),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    library.Name = "Collection"
    for index, sample in Catalog.List do
        local button = Gui.button(library, sample.label, function()
            if self.state and Catalog.isUnlocked(sample.id, self.state.unlocked) then
                callbacks.command("Assign", self.selectedPad, sample.id)
            else
                self:notice("Explore the alley to collect this sound.")
            end
        end)
        button.LayoutOrder = index
        button.Name = sample.id
        self.samples[sample.id] = button
    end
    self.audioStatus = Gui.label(scroll, "Audio loading...", 13)
    self.audioStatus.Name = "AudioStatus"
    self.audioStatus.Size = UDim2.new(1, -6, 0, 52)
    self.audioStatus.LayoutOrder = 7
    self.audioStatus.AutomaticSize = Enum.AutomaticSize.Y
    self.appearanceStatus = Gui.label(scroll, "", 13)
    self.appearanceStatus.Name = "AppearanceStatus"
    self.appearanceStatus.Size = UDim2.new(1, -6, 0, 52)
    self.appearanceStatus.AutomaticSize = Enum.AutomaticSize.Y
    self.appearanceStatus.LayoutOrder = 8
    local function resize()
        local narrow = panel.AbsoluteSize.X < 680
        workspace.Size = UDim2.new(1, -6, 0, if narrow then 568 else 300)
        pads.Size = if narrow then UDim2.new(1, 0, 0, 272) else UDim2.fromScale(0.49, 1)
        details.Position = if narrow then UDim2.fromOffset(0, 284) else UDim2.fromScale(0.52, 0)
        details.Size = if narrow then UDim2.new(1, 0, 0, 284) else UDim2.fromScale(0.48, 1)
    end
    panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    resize()
    return self
end

function WorkshopView:notice(text)
    self.noticeText = text
    self.noticeUntil = os.clock() + 8
    self.status.Text = text
    if not self.panel.Visible then
        self.hudLabel.Text = text
    end
end

function WorkshopView:selectPad(pad)
    self.selectedPad = pad
    if self.state then
        self:update(self.state)
    end
end

function WorkshopView:update(state)
    local wasOpen = self.panel.Visible
    self.state = state
    self.panel.Visible = state.station ~= nil
    self.hud.Visible = state.station == nil
    self.resizeHud()
    if UserInputService.GamepadEnabled and wasOpen ~= self.panel.Visible then
        GuiService.SelectedObject = if self.panel.Visible then self.play else self.sound
    end
    local p = state.pattern
    self.play.Text = if state.playing then "Stop [SPACE]" else "Play [SPACE]"
    if self.playIcon then
        self.playIcon.ImageRectOffset = Atlas[if state.playing then "stop" else "play"]
    end
    self.record.Text = if state.recording then "RECORDING [T]" else "Record OFF [T]"
    self.finish.Text = "Finish: " .. Cosmetics.Sets[state.finish].label
    self.padMute.Text = if p.muted[self.selectedPad] then "Unmute pad" else "Mute pad"
    self.save.Text = if state.saving then "Saving..." elseif state.dirty then "Save *" else "Save"
    self.restore.Text = if state.hasSave then "Restore" else "No saved pattern"
    self.rowTitle.Text = string.format("PAD %02d / %d BPM / 16 STEPS", self.selectedPad, p.bpm)
    for pad, button in self.pads do
        local sample = Catalog.ById[p.assignments[pad]]
        local key = Catalog.List[pad].key
        key = ({ One = "1", Two = "2", Three = "3", Four = "4" })[key] or key
        button.Text = string.format(
            "%02d [%s]\n%s\n%s",
            pad,
            key,
            sample.label,
            if p.muted[pad]
                then "MUTED"
                elseif pad == self.selectedPad then "SELECTED"
                else "Tap to play"
        )
        button.BackgroundColor3 = if pad == self.selectedPad then Theme.Amber else Theme.Teal
        button.TextColor3 = if pad == self.selectedPad then Theme.Ink else Theme.Cream
    end
    for step, button in self.steps do
        local on = p.rows[self.selectedPad][step]
        button.Text = string.format("%02d\n%s", step, if on then "ON" else "OFF")
        button.BackgroundColor3 = if on then Theme.Teal else Theme.Stone
        button.TextColor3 = if on then Theme.Cream else Theme.Ink
    end
    for _, sample in Catalog.List do
        local unlocked = Catalog.isUnlocked(sample.id, state.unlocked)
        self.samples[sample.id].Text = (
            if not unlocked then "LOCKED / " elseif sample.discovery then "COLLECTED / " else ""
        ) .. sample.label
        self.samples[sample.id].BackgroundColor3 = if unlocked then Theme.Teal else Theme.Graphite
    end
    if not self.noticeUntil or os.clock() >= self.noticeUntil then
        if not state.station then
            local collected = 0
            for _, id in { "I01", "I02", "I03" } do
                if state.unlocked[id] then
                    collected += 1
                end
            end
            self.hudLabel.Text = string.format(
                "NEEDLE QUAY / %d of 3 sounds collected\nVisit a sampler to make your loop. Save before leaving.",
                collected
            )
        end
        self.status.Text = string.format(
            "%s  /  %s. Save before leaving. %d / 4 workshop states.",
            if state.recording then "RECORDING" elseif state.playing then "PLAYING" else "READY",
            if state.saveMode == "session"
                then "Studio session save"
                elseif state.saveMode == "cloud" then "Cloud save"
                else "Saving unavailable",
            state.restoration
        )
    end
    if state.notice then
        self:notice(state.notice)
        state.notice = nil
    end
end

function WorkshopView:playhead(step)
    if not self.state then
        return
    end
    for index, button in self.steps do
        local on = self.state.pattern.rows[self.selectedPad][index]
        button.BackgroundColor3 = if index == step
            then Theme.Amber
            elseif on then Theme.Teal
            else Theme.Stone
        button.TextColor3 = if index == step or not on then Theme.Ink else Theme.Cream
        button.Text = string.format(
            "%s%02d\n%s",
            if index == step then "> " else "",
            index,
            if on then "ON" else "OFF"
        )
    end
end

function WorkshopView:tick()
    if self.state and self.noticeUntil and os.clock() >= self.noticeUntil then
        self.noticeUntil = nil
        self:update(self.state)
    end
end
return WorkshopView
