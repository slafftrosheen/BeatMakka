local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Theme = require(Shared.Theme)
local Catalog = require(Shared.SampleCatalog)
local Cosmetics = require(Shared.CosmeticCatalog)
local Pattern = require(Shared.Pattern)
local Gui = require(script.Parent.GuiFactory)
local BeatBookView = require(script.Parent.BeatBookView)
local PadInput = require(script.Parent.PadInput)
local RoomSettings = require(script.Parent.RoomSettings)
local RecorderGuide = require(script.Parent.RecorderGuide)
local SampleEditor = require(script.Parent.SampleEditor)
local Icons = require(script.Parent.GameIcons)
local WorkshopView = {}
WorkshopView.__index = WorkshopView
local compactSampleNames = {
    kick = "KICK",
    snare = "SNARE",
    closed_hat = "HAT C",
    open_hat = "HAT O",
    clap = "CLAP",
    rim = "RIM",
    low_tom = "L TOM",
    high_tom = "H TOM",
    shaker = "SHAKE",
    tambourine = "TAMB",
    bell = "BELL",
    pluck = "PLUCK",
    bass_c = "C",
    bass_eb = "E♭",
    bass_g = "G",
    chord = "CHORD",
}

function WorkshopView.new(callbacks)
    local self = setmetatable({
        selectedPad = 1,
        callbacks = callbacks,
        pads = {},
        steps = {},
        samples = {},
        effects = true,
        muted = false,
        packIndex = 1,
    }, WorkshopView)
    local screen = Gui.make("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {
        Name = "FrequencyZero",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
    })
    self.screen = screen
    self.inputConnections = {}
    self.padInput = PadInput.new(function(pad)
        self:selectPad(pad)
        if self.padSelectOnly then
            return false
        end
        self.playedPad = true
        return callbacks.tap(pad)
    end, function(pad, held)
        if held and self.motion then
            self.motion:hit(pad)
        end
        local button = self.pads[pad]
        if button then
            button:SetAttribute("Held", held)
            button.TextColor3 = Theme.Ink
            button.BackgroundColor3 = if held
                then Theme.Coral
                elseif pad == self.selectedPad then Theme.Amber
                elseif button:GetAttribute("PadMuted") then Theme.Stone
                else Theme.Cream
        end
    end)
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
        self:setMuted(not self.muted)
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
            Size = UDim2.new(1, -8, 1, -8),
            BackgroundColor3 = Theme.Cream,
            Visible = false,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }),
        16
    )
    Gui.make("UISizeConstraint", panel, { MaxSize = Vector2.new(1920, 1200) })
    self.panel = panel
    self.resizeHud = resizeHud
    self.hardware = require(script.Parent.HardwareFaceplate).new(
        panel,
        callbacks.command,
        function()
            return self.state
        end
    )
    self.pages = {}
    self.tabs = {}
    self.page = "Play"
    local header = Gui.label(panel, "MK-I / NEEDLE QUAY", 18)
    header.Name = "Header"
    header.Font = Theme.Bold
    local navigation = Gui.make("Frame", panel, {
        Name = "Navigation",
        BackgroundTransparency = 1,
    })
    local tabNames = { "Play", "Sounds", "Beats", "Settings" }
    for index, name in tabNames do
        local button = Gui.button(navigation, name, function()
            self:showPage(name)
        end)
        button.Name = name
        button.Size = UDim2.new(1 / 6, -4, 1, 0)
        button.Position = UDim2.fromScale((index - 1) / 6, 0)
        self.tabs[name] = button
        button.Text = ""
        local icon = Icons.make(
            button,
            ({
                Play = "pads",
                Steps = "steps",
                Sounds = "sound",
                Beats = "disc",
                Settings = "knob",
            })[name],
            Theme.Cream,
            20
        )
        icon.Position = UDim2.new(0.5, -10, 0, 3)
        local caption = Gui.label(button, string.upper(name), 10, Theme.Cream)
        caption.Name = "Caption"
        caption.Font = Enum.Font.Code
        caption.Position, caption.Size = UDim2.new(0, 0, 1, -19), UDim2.new(1, 0, 0, 18)
        caption.TextXAlignment = Enum.TextXAlignment.Center
    end
    self.tabs.Steps = self.tabs.Play
    local close = Gui.button(panel, "EXIT", function()
        callbacks.command("Release")
    end)
    close.Modal = true
    close.Name = "Leave"
    close.Size = UDim2.new(1 / 6, -4, 1, 0)
    close.Position = UDim2.fromScale(5 / 6, 0)
    local toolbar = Gui.make("Frame", panel, {
        Name = "Transport",
        BackgroundTransparency = 1,
    })
    local transportGrid = Gui.make("UIGridLayout", toolbar, {
        CellSize = UDim2.new(1 / 3, -4, 1, 0),
        CellPadding = UDim2.fromOffset(6, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    local function control(parent, text, action, a)
        local button = Gui.button(parent, text, function()
            if self.state and self.state.ready then
                if action == "Save" then
                    self.restoreConfirmation = nil
                    self.packConfirmation = nil
                    self:update(self.state)
                end
                callbacks.command(action, if type(a) == "function" then a() else a)
            end
        end)
        button.Name = action
        return button
    end
    self.play = control(toolbar, "Play", "Play")
    self.play.LayoutOrder = 1
    self.record = control(toolbar, "Record", "Record")
    self.record.LayoutOrder = 2
    self.stop = control(toolbar, "Stop", "Stop")
    self.stop.LayoutOrder = 3
    for _, entry in { { self.play, "play" }, { self.record, "record" }, { self.stop, "stop" } } do
        local icon = Icons.make(
            entry[1],
            entry[2],
            if entry[2] == "record" then Theme.Coral else Theme.Cream,
            22
        )
        icon.Position = UDim2.new(0, 8, 0.5, -11)
        entry[1].Font = Enum.Font.Code
        Gui.make(
            "UIPadding",
            entry[1],
            { PaddingLeft = UDim.new(0, 30), PaddingRight = UDim.new(0, 4) }
        )
    end
    local body = Gui.make("ScrollingFrame", panel, {
        Name = "Pages",
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(),
    })
    local function page(name, scrolling)
        local frame =
            Gui.make(if scrolling or name == "Play" then "ScrollingFrame" else "Frame", body, {
                Name = name,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Visible = name == "Play",
            })
        if scrolling then
            frame.CanvasSize = UDim2.new()
            frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
            frame.ScrollingDirection = Enum.ScrollingDirection.Y
            frame.ScrollBarThickness = 4
            Gui.make("UIListLayout", frame, {
                Padding = UDim.new(0, 12),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
        end
        self.pages[name] = frame
        return frame
    end
    local performance = page("Play", false)
    performance.CanvasSize = UDim2.new()
    performance.ScrollBarThickness = 3
    performance.ScrollingDirection = Enum.ScrollingDirection.Y
    -- The pad bank is independent of the right-hand page navigation.
    local padBank = Gui.make("Frame", body, {
        Name = "PersistentPadBank",
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -8, 1, 0),
    })
    local bankIcon = Icons.make(padBank, "pads", Theme.Amber, 24)
    self.mobileEdit = false
    local mobileEdit = Gui.button(body, "EDIT STEPS & SOUND", function()
        self.mobileEdit = not self.mobileEdit
        self.resizeLayout()
    end)
    mobileEdit.Name, mobileEdit.Size, mobileEdit.Visible =
        "MobileWorkspace", UDim2.new(1, -6, 0, 44), false
    local bankLabel = Gui.label(padBank, "16 PADS / LIVE", 13, Theme.Cream)
    bankLabel.Font = Enum.Font.Code
    bankLabel.Position, bankLabel.Size = UDim2.fromOffset(32, 0), UDim2.new(1, -32, 0, 24)
    bankIcon.Position = UDim2.fromOffset(0, 0)
    local selectMode = Gui.button(padBank, "PLAY PADS", function()
        self.padSelectOnly = not self.padSelectOnly
        self.padMode.Text = if self.padSelectOnly then "SELECT PADS" else "PLAY PADS"
        self.padMode.BackgroundColor3 = if self.padSelectOnly then Theme.Walnut else Theme.Teal
    end)
    selectMode.Name, selectMode.Position, selectMode.Size =
        "PadMode", UDim2.new(1, -116, 0, 0), UDim2.fromOffset(116, 44)
    selectMode.TextSize = 11
    self.padMode = selectMode
    bankLabel.Size = UDim2.new(1, -154, 0, 44)
    self.hardwareKnobs =
        require(script.Parent.HardwarePadControls).new(performance, self, callbacks.command)
    local sequencer = performance
    local sounds = page("Sounds", true)
    self.sampleEditor = SampleEditor.new(sounds, function(key, value)
        callbacks.command("PadSound", self.selectedPad, { key = key, value = value })
    end, function(pad, settings)
        if callbacks.preview then
            return callbacks.preview(pad, settings)
        end
    end, function(pad)
        self:selectPad(pad)
    end, function(name)
        callbacks.command("PadPreset", self.selectedPad, name)
    end)
    local broadcast = Gui.button(panel, "STREET SPEAKER / OFF", function()
        if self.state and self.state.ready then
            callbacks.command("Broadcast", not self.state.broadcast)
        end
    end)
    broadcast.Name = "StreetSpeaker"
    self.broadcast = broadcast
    local footer = Gui.make("Frame", padBank, {
        Name = "PatternControls",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -44),
        Size = UDim2.new(1, 0, 0, 44),
    })
    Gui.make("UIGridLayout", footer, {
        CellSize = UDim2.new(1 / 6, -5, 1, 0),
        CellPadding = UDim2.fromOffset(5, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    self.slotButtons = {}
    for slot = 1, 4 do
        local b = Gui.button(footer, string.char(64 + slot), function()
            callbacks.command("SelectSlot", slot)
        end)
        b.Name = "Slot" .. slot
        b.LayoutOrder = slot
        b.Font = Enum.Font.Code
        self.slotButtons[slot] = b
    end
    self.quickMute = Gui.button(footer, "MUTE", function()
        callbacks.command("MutePad", self.selectedPad)
    end)
    self.quickMute.Name = "MutePad"
    self.quickMute.LayoutOrder = 5
    self.quickSave = Gui.button(footer, "SAVE", function()
        callbacks.command("Save")
    end)
    self.quickSave.Name = "Save"
    self.quickSave.LayoutOrder = 6
    local beats = page("Beats", true)
    local settings = page("Settings", true)
    local pads = Gui.make("Frame", padBank, {
        Name = "Pads",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
    })
    local padGrid = Gui.make("UIGridLayout", pads, {
        CellSize = UDim2.new(0.25, -4.5, 0.25, -4.5),
        CellPadding = UDim2.fromOffset(6, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    self.rowTitle = Gui.label(sequencer, "PAD 01 / 16 STEPS", 15, Theme.Cream)
    self.rowTitle.Name = "SelectedPad"
    self.rowTitle.Font = Theme.Bold
    self.rowTitle.Size = UDim2.new(1, 0, 0, 26)
    local steps = Gui.make("Frame", sequencer, {
        Name = "Steps",
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, 0, 1, -30),
        BackgroundTransparency = 1,
    })
    local stepGrid = Gui.make("UIGridLayout", steps, {
        CellSize = UDim2.new(0.25, -4.5, 0.25, -4.5),
        CellPadding = UDim2.fromOffset(6, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    for pad = 1, 16 do
        local button = Gui.button(pads, tostring(pad), function(input)
            -- Mouse/touch already fired on begin. Activated preserves gamepad and
            -- accessibility activation without a second hit on finger release.
            if
                input
                and (
                    input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1
                )
            then
                return
            end
            local token = {}
            self:beginPad(pad, token)
            self.padInput:finish(token)
        end, { silent = true })
        button.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1
            then
                if self:beginPad(pad, input) then
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        self.mouseToken = input
                    end
                    local connection
                    connection = input.Changed:Connect(function()
                        if
                            input.UserInputState == Enum.UserInputState.End
                            or input.UserInputState == Enum.UserInputState.Cancel
                        then
                            self.padInput:finish(input)
                            connection:Disconnect()
                            self.inputConnections[input] = nil
                        end
                    end)
                    self.inputConnections[input] = connection
                end
            end
        end)
        Gui.make("UIGradient", button, {
            Rotation = 90,
            Color = ColorSequence.new(Color3.fromRGB(210, 216, 211), Color3.new(1, 1, 1)),
        })
        Gui.make("UIStroke", button, {
            Color = Theme.Walnut,
            Thickness = 3,
            Transparency = 0.15,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
        Gui.round(
            Gui.make("Frame", button, {
                Name = "PadLed",
                Position = UDim2.new(1, -14, 0, 8),
                Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = Theme.Amber,
                BorderSizePixel = 0,
            }),
            3
        )
        button.LayoutOrder = pad
        button.Name = string.format("Pad_%02d", pad)
        self.pads[pad] = button
        local mini = Gui.make("Frame", button, {
            Name = "NotePreview",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 6, 1, -10),
            Size = UDim2.new(1, -12, 0, 4),
        })
        for step = 1, 16 do
            Gui.make("Frame", mini, {
                Name = tostring(step),
                BorderSizePixel = 0,
                BackgroundColor3 = Theme.Teal,
                BackgroundTransparency = 0.8,
                Position = UDim2.fromScale((step - 1) / 16, 0),
                Size = UDim2.new(1 / 16, -1, 1, 0),
            })
        end
    end
    for step = 1, 16 do
        local button = Gui.button(steps, tostring(step), function()
            if self.state and self.state.ready then
                callbacks.command("Step", self.selectedPad, step)
            end
        end)
        button.LayoutOrder = step
        button.Name = string.format("Step_%02d", step)
        self.steps[step] = button
    end
    self.beatGuide = require(script.Parent.QuayBeatGuide).new(sequencer, self)
    self.beatTools = require(script.Parent.GrooveboxTools).new(sequencer, self, callbacks.command)
    for index, button in self.pads do
        button.NextSelectionLeft = self.pads[index - 1]
        button.NextSelectionRight = self.pads[index + 1]
        button.NextSelectionUp = self.pads[index - 4]
        button.NextSelectionDown = self.pads[index + 4]
    end
    local libraryTitle = Gui.label(sounds, "Choose a sound for the selected pad", 15)
    libraryTitle.Name = "CollectionTitle"
    libraryTitle.Size = UDim2.new(1, -8, 0, 40)
    libraryTitle.LayoutOrder = 1
    self.libraryTitle = libraryTitle
    self.recorderGuide = RecorderGuide.new(sounds)
    local packControls = Gui.make("Frame", sounds, {
        Name = "PackControls",
        Size = UDim2.new(1, -8, 0, 96),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
    })
    local previous = Gui.button(packControls, "<", function()
        self:browsePack(-1)
    end)
    previous.Name = "PreviousKit"
    previous.Size = UDim2.fromOffset(44, 44)
    local nextPack = Gui.button(packControls, ">", function()
        self:browsePack(1)
    end)
    nextPack.Name = "NextKit"
    nextPack.Position = UDim2.new(1, -44, 0, 0)
    nextPack.Size = UDim2.fromOffset(44, 44)
    self.packLabel = Gui.label(packControls, "Needle Quay", 13)
    self.packLabel.Position = UDim2.fromOffset(52, 0)
    self.packLabel.Size = UDim2.new(1, -104, 0, 44)
    self.packApply = Gui.button(packControls, "Use kit on 16 pads", function()
        self:applyPack()
    end)
    self.packApply.Name = "UseKit"
    self.packApply.Position = UDim2.fromOffset(0, 48)
    self.packApply.Size = UDim2.new(1, 0, 0, 44)
    local library = Gui.make("Frame", sounds, {
        Name = "Collection",
        Size = UDim2.new(1, -8, 0, 512),
        BackgroundTransparency = 1,
        LayoutOrder = 4,
    })
    local libraryGrid = Gui.make("UIGridLayout", library, {
        CellSize = UDim2.new(0.5, -4, 0, 48),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    self.library = library
    self.libraryColumns = 2
    for index, sample in Catalog.List do
        local button = Gui.button(library, sample.label, function()
            if
                self.state
                and self.state.ready
                and Catalog.isUnlocked(sample.id, self.state.unlocked)
            then
                callbacks.command("Assign", self.selectedPad, sample.id)
            else
                self:notice("Explore the alley to collect this sound.")
            end
        end)
        button.LayoutOrder = index
        button.Name = sample.id
        self.samples[sample.id] = button
    end
    self.bookView = BeatBookView.new(beats, {
        command = callbacks.command,
        notice = function(text)
            self:notice(text)
        end,
    })
    local settingsTitle = Gui.label(settings, "TEMPO / PAD / APPEARANCE", 15)
    settingsTitle.Size = UDim2.new(1, -8, 0, 32)
    settingsTitle.LayoutOrder = 1
    local controls = Gui.make("Frame", settings, {
        Name = "Controls",
        Size = UDim2.new(1, -8, 0, 272),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
    })
    Gui.make("UIGridLayout", controls, {
        CellSize = UDim2.new(0.5, -4, 0, 48),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    self.bpmDown = control(controls, "Tempo -", "Bpm", function()
        return math.max(60, self.state.pattern.bpm - 1)
    end)
    self.bpmDown.Name = "TempoDown"
    self.bpmDown.LayoutOrder = 1
    self.bpmUp = control(controls, "Tempo +", "Bpm", function()
        return math.min(180, self.state.pattern.bpm + 1)
    end)
    self.bpmUp.Name = "TempoUp"
    self.bpmUp.LayoutOrder = 2
    self.padMute = control(controls, "Mute pad", "MutePad", function()
        return self.selectedPad
    end)
    self.padMute.LayoutOrder = 3
    local clear = control(controls, "Clear pad", "ClearPad", function()
        return self.selectedPad
    end)
    clear.LayoutOrder = 4
    self.save = control(controls, "Save profile", "Save")
    self.save.LayoutOrder = 5
    self.restore = Gui.button(controls, "Restore slots", function()
        self:restoreSlots()
    end)
    self.restore.LayoutOrder = 6
    self.panelSound = Gui.button(controls, "Sound ON", toggleSound)
    self.panelSound.Name = "Sound"
    self.panelSound.LayoutOrder = 7
    self.panelEffects = Gui.button(controls, "Effects ON", toggleEffects)
    self.panelEffects.Name = "Effects"
    self.panelEffects.LayoutOrder = 8
    self.finish = Gui.button(controls, "Finish: Workshop teal", function()
        if not self.state or not self.state.ready then
            return
        end
        local current = table.find(Cosmetics.Order, self.state.finish) or 1
        callbacks.command("Finish", Cosmetics.Order[current % #Cosmetics.Order + 1])
    end)
    self.finish.Name = "Finish"
    self.finish.LayoutOrder = 9
    local jam = control(controls, "Two-player jam", "JamOpen")
    jam.Name = "Jam"
    jam.LayoutOrder = 10
    self.audioStatus = Gui.label(settings, "Audio loading...", 13)
    self.audioStatus.Name = "AudioStatus"
    self.audioStatus.Size = UDim2.new(1, -8, 0, 52)
    self.audioStatus.AutomaticSize = Enum.AutomaticSize.Y
    self.audioStatus.LayoutOrder = 3
    self.appearanceStatus = Gui.label(settings, "", 13)
    self.appearanceStatus.Name = "AppearanceStatus"
    self.appearanceStatus.Size = UDim2.new(1, -8, 0, 52)
    self.appearanceStatus.AutomaticSize = Enum.AutomaticSize.Y
    self.appearanceStatus.LayoutOrder = 4
    self.inputStatus = Gui.label(settings, "Input measurements: no hits yet.", 13)
    self.inputStatus.Name = "InputStatus"
    self.inputStatus.Size = UDim2.new(1, -8, 0, 72)
    self.inputStatus.AutomaticSize = Enum.AutomaticSize.Y
    self.inputStatus.LayoutOrder = 5
    self.audioStatus.Visible, self.appearanceStatus.Visible, self.inputStatus.Visible =
        false, false, false
    local diagnostics = Gui.button(settings, "Diagnostics", function()
        local visible = not self.inputStatus.Visible
        self.audioStatus.Visible, self.appearanceStatus.Visible, self.inputStatus.Visible =
            visible, visible, visible
    end)
    diagnostics.Size = UDim2.new(1, -8, 0, 44)
    diagnostics.LayoutOrder = 20
    self.roomSettings = RoomSettings.new(settings, callbacks.command)
    require(script.Parent.AudioMixView).new(settings)
    self.status = Gui.label(panel, "Loading session...", 13)
    self.status.Name = "Status"
    self.noticeLabel = header
    local function resize()
        local size = panel.AbsoluteSize
        local narrow = size.X < 600
        local portrait = narrow
        local shortPortrait = portrait and size.Y < 700
        local shortLandscape = not portrait and size.Y < 470
        self.hardware:resize(narrow, shortPortrait or shortLandscape)
        self.hardware.display.Visible = true
        self.hardware.brand.Visible, self.hardware.track.Visible =
            not shortLandscape, not shortLandscape
        toolbar.Position = if narrow then UDim2.fromOffset(18, 88) else UDim2.new(0.29, 0, 0, 24)
        toolbar.Size = if narrow then UDim2.new(1, -36, 0, 44) else UDim2.new(0.39, -20, 0, 44)
        transportGrid.CellSize = UDim2.new(1 / 3, -4, 1, 0)
        local navY = if narrow then 142 else 90
        navigation.Position = if narrow
            then UDim2.fromOffset(18, navY + 50)
            else UDim2.new(0.5, 8, 0, navY)
        navigation.Size = if narrow then UDim2.new(1, -36, 0, 44) else UDim2.new(0.5, -26, 0, 44)
        for index, name in tabNames do
            local button = self.tabs[name]
            button.Position = UDim2.fromScale((index - 1) / 4, 0)
            button.Size = UDim2.new(0.25, -4, 1, 0)
            button.Caption.Text = ({
                Play = "PERFORM",
                Sounds = "SOUNDS",
                Beats = "BEATS",
                Settings = "SETUP",
            })[name]
        end
        broadcast.Position = UDim2.fromOffset(18, navY)
        broadcast.Size = if narrow then UDim2.new(1, -132, 0, 44) else UDim2.new(0.5, -124, 0, 44)
        close.Position = if narrow
            then UDim2.new(1, -106, 0, navY)
            else UDim2.new(0.5, -98, 0, navY)
        close.Size = UDim2.fromOffset(88, 44)
        -- On a short phone, sharing lives in Setup so the performance pads keep
        -- their space. Exit stays beside the transport and remains reachable.
        broadcast.Parent = if shortPortrait or shortLandscape then settings else panel
        broadcast.LayoutOrder = -1
        if shortPortrait then
            toolbar.Position = UDim2.fromOffset(18, 70)
            toolbar.Size = UDim2.new(1, -90, 0, 44)
            close.Position, close.Size = UDim2.new(1, -62, 0, 70), UDim2.fromOffset(44, 44)
            navigation.Position = UDim2.fromOffset(18, 120)
            broadcast.Size = UDim2.new(1, -8, 0, 44)
        end
        if shortLandscape then
            toolbar.Position, toolbar.Size = UDim2.fromOffset(18, 12), UDim2.new(1, -272, 0, 44)
            close.Position, close.Size = UDim2.new(1, -248, 0, 12), UDim2.fromOffset(44, 44)
            navigation.Position = UDim2.new(0.5, 12, 0, 68)
            broadcast.Size = UDim2.new(1, -8, 0, 44)
        end
        footer.Parent = if shortLandscape then beats else padBank
        footer.LayoutOrder = -2
        footer.Position = if shortLandscape then UDim2.new() else UDim2.new(0, 0, 1, -44)
        selectMode.Parent = if shortLandscape then settings else padBank
        selectMode.LayoutOrder = -2
        selectMode.Position = if shortLandscape then UDim2.new() else UDim2.new(1, -116, 0, 0)
        selectMode.Size = if shortLandscape
            then UDim2.new(1, -8, 0, 44)
            else UDim2.fromOffset(116, 44)
        bankIcon.Visible, bankLabel.Visible = not shortLandscape, not shortLandscape
        local bodyY = if shortLandscape
            then 68
            elseif shortPortrait then 176
            elseif narrow then 248
            else 148
        body.Position = UDim2.fromOffset(18, bodyY)
        body.Size = UDim2.new(1, -36, 1, -bodyY - (if shortLandscape then 32 else 40))
        header.Position, header.Size = UDim2.new(0, 18, 1, -32), UDim2.new(0.36, -18, 0, 24)
        header.Font, header.TextColor3, header.TextSize = Enum.Font.Code, Theme.Cream, 11
        header.TextYAlignment = Enum.TextYAlignment.Center
        self.status.Position, self.status.Size =
            UDim2.new(0.36, 0, 1, -32), UDim2.new(0.64, -18, 0, 24)
        self.status.TextSize = 11
        self.status.TextColor3 = Theme.Cream
        local available = body.AbsoluteSize
        local mobileHeader = if portrait and self.page == "Play" then 50 else 0
        local bankHeight = if shortLandscape
            then available.Y
            elseif portrait then available.Y - mobileHeader
            else math.max(330, available.Y)
        local paneWidth = if portrait then available.X - 6 else available.X / 2 - 12
        local paneHeight = bankHeight - (if shortLandscape then 50 else 0)
        body.CanvasSize = if portrait then UDim2.new() else UDim2.fromOffset(0, bankHeight)
        body.ScrollingEnabled = not portrait and available.Y < bankHeight
        mobileEdit.Visible = portrait and self.page == "Play"
        mobileEdit.Text = if self.mobileEdit then "BACK TO 16 PADS" else "EDIT STEPS & SOUND"
        padBank.Visible = not portrait or (self.page == "Play" and not self.mobileEdit)
        padBank.Position = UDim2.fromOffset(0, mobileHeader)
        padBank.Size = if portrait
            then UDim2.new(1, -6, 0, bankHeight)
            else UDim2.new(0.5, -12, 0, bankHeight)
        for _, frame in self.pages do
            frame.Position = if portrait
                then UDim2.fromOffset(0, mobileHeader)
                else UDim2.new(0.5, 12, 0, if shortLandscape then 50 else 0)
            frame.Size = if portrait
                then UDim2.new(1, -6, 0, paneHeight)
                else UDim2.new(0.5, -12, 0, paneHeight)
            frame.Visible = frame.Name == self.page
                and (not portrait or self.page ~= "Play" or self.mobileEdit)
        end
        -- Fixed minimum interaction sizes; the work area scrolls on small screens.
        local recipeHeight = if self.beatGuide.root.Visible then 62 else 0
        local columns = if paneWidth < 380 then 4 else 8
        local stepHeight = (16 / columns) * 48 - 4
        steps.Position = UDim2.fromOffset(0, 34 + recipeHeight)
        steps.Size = UDim2.new(1, -6, 0, stepHeight)
        -- Integer cell widths prevent subpixel rounding from silently wrapping
        -- an eight-step row into seven columns and covering steps 15/16.
        stepGrid.CellSize =
            UDim2.fromOffset(math.floor((paneWidth - 6 - 6 * (columns - 1)) / columns), 44)
        stepGrid.CellPadding = UDim2.fromOffset(6, 4)
        local toolsY = 44 + recipeHeight + stepHeight
        self.beatTools.rhythm.Position = UDim2.fromOffset(0, toolsY)
        self.beatTools.root.Position = UDim2.fromOffset(0, toolsY + 56)
        self.hardwareKnobs.root.Position = UDim2.fromOffset(0, toolsY + 208)
        local knobHeight = self.hardwareKnobs:resize(paneWidth - 6)
        self.hardwareKnobs.root.AnchorPoint = Vector2.zero
        self.hardwareKnobs.root.Visible = true
        performance.CanvasSize = UDim2.fromOffset(0, toolsY + 220 + knobHeight)
        performance.ClipsDescendants = true
        local side =
            math.max(0, math.min(paneWidth - 8, bankHeight - (if shortLandscape then 8 else 92)))
        pads.Position = UDim2.new(0.5, 0, 0.5, 2)
        pads.Size = UDim2.fromOffset(side, side)
        local cell = math.max(0, math.floor((side - 18) / 4))
        padGrid.CellSize = UDim2.fromOffset(cell, cell)
        local smallPads = side < 300
        self.microPads = side < 230
        for _, button in self.pads do
            button.TextSize = if smallPads then 11 else 14
        end
        self.compactPads = smallPads
        local libraryColumns = if paneWidth < 480 then 2 else 3
        libraryGrid.CellSize = UDim2.new(1 / libraryColumns, -6, 0, 48)
        self.libraryColumns = libraryColumns
        self:filterSamples()
        if self.state then
            self:updatePadLabels()
        end
    end
    panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    body:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    self.endedConnection = UserInputService.InputEnded:Connect(function(input)
        self.padInput:finish(input)
        local connection = self.inputConnections[input]
        if connection then
            connection:Disconnect()
            self.inputConnections[input] = nil
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 and self.mouseToken then
            self.padInput:finish(self.mouseToken)
            local mouseConnection = self.inputConnections[self.mouseToken]
            if mouseConnection then
                mouseConnection:Disconnect()
                self.inputConnections[self.mouseToken] = nil
            end
            self.mouseToken = nil
        end
    end)
    self.viewportConnection = screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:cancelInput(true)
    end)
    screen.Destroying:Connect(function()
        self.padInput:destroy()
        self:cancelInput(true)
        if self.state and self.state.station then
            self.callbacks.command("Release")
        end
        self.endedConnection:Disconnect()
        self.viewportConnection:Disconnect()
    end)
    self.resizeLayout = resize
    local skin = require(script.Parent.GrooveboxSkin)
    for _, button in self.pads do
        skin.pad(button)
        button.PadLed.ZIndex = 4
        button.NotePreview.ZIndex = 4
    end
    for _, frame in
        { padBank, self.pages.Play, self.pages.Sounds, self.pages.Beats, self.pages.Settings }
    do
        local performanceSurface = frame == padBank or frame == self.pages.Play
        frame.BackgroundColor3 = if performanceSurface
            then Color3.fromRGB(30, 51, 48)
            else Theme.Paper
        frame.BackgroundTransparency = 0
        if frame:IsA("ScrollingFrame") then
            frame.ScrollBarImageColor3 = Theme.FadedTeal
        end
        Gui.round(frame, 8)
    end
    self.motion = require(script.Parent.GrooveboxMotion).new(self, self.hardware.display)
    self:showPage("Play")
    resize()
    return self
end

function WorkshopView:beginPad(pad, token)
    if
        not self.state
        or not self.state.ready
        or not self.state.station
        or not self.panel.Visible
    then
        return false
    end
    return self.padInput:begin(pad, token)
end

function WorkshopView:cancelInput(interrupted)
    self.padInput:cancel()
    self.mouseToken = nil
    for _, connection in self.inputConnections do
        connection:Disconnect()
    end
    table.clear(self.inputConnections)
    if interrupted and self.callbacks.interrupt then
        self.callbacks.interrupt()
    end
end

function WorkshopView:showPage(name)
    if name == "Steps" then
        name = "Play"
    end
    if not self.pages[name] then
        return
    end
    if self.bookView and self.page ~= name then
        self.bookView.confirmation = nil
        if self.state then
            self.bookView:update(self.state)
        end
    end
    if self.page ~= name then
        self.restoreConfirmation = nil
        self.packConfirmation = nil
        if self.packApply then
            self:filterSamples()
        end
    end
    if self.sampleEditor then
        self.sampleEditor.drag = nil
    end
    self.page = name
    if self.state then
        self.noticeLabel.Text = if self.noticeUntil and os.clock() < self.noticeUntil
            then self.noticeText
            else self:guideText()
        self.restore.Text = if self.state.hasSave then "Restore slots" else "No saved slots"
    end
    if name ~= "Play" then
        self:cancelInput(false)
    end
    for pageName, frame in self.pages do
        frame.Visible = pageName == name
        local tab = self.tabs[pageName]
        tab.BackgroundColor3 = if pageName == name then Theme.Amber else Theme.Teal
        tab.TextColor3 = if pageName == name then Theme.Ink else Theme.Cream
        if tab:FindFirstChild("Caption") then
            tab.Caption.TextColor3 = tab.TextColor3
        end
    end
    if self.resizeLayout then
        self.resizeLayout()
    end
    if
        UserInputService.GamepadEnabled
        and GuiService.SelectedObject
        and GuiService.SelectedObject:IsDescendantOf(self.panel)
    then
        GuiService.SelectedObject = self.tabs[name]
    end
end

function WorkshopView:guideText()
    local state = self.state
    if not state then
        return "MK-I / MAKE SOMETHING YOURS"
    end
    if self.restoreConfirmation then
        return "Restore replaces working slots A-D. Press again to confirm."
    end
    if self.page == "Settings" then
        return "SAVE / SOUND / FX"
    elseif self.page == "Sounds" then
        return "SELECT / SHAPE / AUDITION"
    elseif self.page == "Beats" then
        return "YOUR BEAT SHELF"
    elseif state.recording then
        return "REC / TAP THE PADS"
    elseif self.page == "Steps" then
        return "LIGHT A STEP / PRESS PLAY"
    elseif Pattern.hasNotes(state.pattern) then
        return "PLAY / TURN FX / SHARE TO STREET"
    elseif self.playedPad then
        return "LIGHT STEPS / RECORD PADS"
    end
    return "TAP A PAD"
end

function WorkshopView:filterSamples()
    local pack = Catalog.Packs[self.packIndex]
    self.packLabel.Text = pack.label
        .. (if pack.key then " / " .. pack.key else " / Original collection")
    self.packApply.Text = if self.packConfirmation
        then "Replace 16 pad sounds?"
        else "Use kit on 16 pads"
    for id, button in self.samples do
        local sample = Catalog.ById[id]
        button.Visible = if pack.id == "quay" then sample.pack == nil else sample.pack == pack.id
    end
    self.library.Size = UDim2.new(1, -8, 0, math.ceil(#pack.samples / self.libraryColumns) * 56)
end

function WorkshopView:browsePack(delta)
    self.packIndex = (self.packIndex - 1 + delta) % #Catalog.Packs + 1
    self.packConfirmation = nil
    self:filterSamples()
end

function WorkshopView:applyPack()
    local state = self.state
    if not state or not state.ready or not state.station or state.saving then
        return
    end
    local pack = Catalog.Packs[self.packIndex]
    local confirmation = self.packConfirmation
    if
        confirmation
        and confirmation.id == pack.id
        and confirmation.editVersion == state.editVersion
        and confirmation.station == state.station
        and os.clock() < confirmation.expires
    then
        self.packConfirmation = nil
        self.callbacks.command("Pack", pack.id, state.editVersion)
    else
        self.packConfirmation = {
            id = pack.id,
            editVersion = state.editVersion,
            station = state.station,
            expires = os.clock() + 5,
        }
        task.delay(5, function()
            if self.screen.Parent and self.state then
                self:update(self.state)
            end
        end)
    end
    self:filterSamples()
end

function WorkshopView:restoreSlots()
    local state = self.state
    if not state or not state.ready or not state.station or not state.hasSave or state.saving then
        return
    end
    local confirmation = self.restoreConfirmation
    if
        confirmation
        and confirmation.editVersion == state.editVersion
        and confirmation.station == state.station
        and os.clock() < confirmation.expires
    then
        self.restoreConfirmation = nil
        self.callbacks.command("Restore", state.editVersion)
    else
        self.restoreConfirmation = {
            editVersion = state.editVersion,
            station = state.station,
            expires = os.clock() + 5,
        }
        task.delay(5, function()
            if self.screen.Parent and self.state then
                self:update(self.state)
            end
        end)
    end
    self:update(state)
end

function WorkshopView:updatePadLabels()
    if not self.state then
        return
    end
    local p = self.state.pattern
    for pad, button in self.pads do
        local sample = Catalog.ById[p.assignments[pad]]
        local key = Catalog.List[pad].key
        key = ({ One = "1", Two = "2", Three = "3", Four = "4" })[key] or key
        local compactName = compactSampleNames[sample.id]
            or string.upper((sample.label:match("^%S+") or sample.label):sub(1, 5))
        button:SetAttribute("SampleName", sample.label)
        button:SetAttribute("ShortName", compactName)
        button:SetAttribute("PadKey", key)
        button:SetAttribute("PadMuted", p.muted[pad] == true)
        button:SetAttribute("PadSelected", pad == self.selectedPad)
        button.Text = if self.compactPads
            then string.format(
                "%02d%s\n%s",
                pad,
                if p.muted[pad] then " M" else "",
                if self.microPads then compactName else sample.label
            )
            else string.format(
                "%02d [%s]\n%s%s",
                pad,
                key,
                sample.label,
                if p.muted[pad] then " / M" else ""
            )
        button.BackgroundColor3 = if self.padInput.held[pad]
            then Theme.Coral
            elseif pad == self.selectedPad then Theme.Amber
            elseif p.muted[pad] then Theme.Stone
            else Theme.Cream
        button.TextColor3 = Theme.Ink
        button.Font = Enum.Font.Code
        button.PadLed.BackgroundColor3 = if p.muted[pad]
            then Theme.FadedTeal
            elseif pad == self.selectedPad then Theme.Coral
            else Theme.Amber
        button.PadLed.BackgroundTransparency = if pad == self.selectedPad then 0 else 0.5
        for step = 1, 16 do
            button.NotePreview[tostring(step)].BackgroundTransparency = if p.rows[pad][step]
                then 0
                else 0.85
        end
    end
    self.libraryTitle.Text = string.format("PAD %02d / Choose a sound to assign", self.selectedPad)
end

function WorkshopView:notice(text)
    self.noticeText = text
    self.noticeUntil = os.clock() + 8
    self.noticeLabel.Text = text
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

function WorkshopView:setMuted(value)
    self.muted = value == true
    self.sound.Text = if self.muted then "Sound MUTED" else "Sound ON"
    if self.panelSound then
        self.panelSound.Text = self.sound.Text
    end
    self.callbacks.mute(self.muted)
end

function WorkshopView:update(state)
    local wasOpen = self.panel.Visible
    self.state = state
    self.panel.Visible = state.station ~= nil
    if not self.panel.Visible then
        self:cancelInput(false)
    end
    self.hud.Visible = state.station == nil
        and not (state.quay and state.quay.open)
        and not state.listening
        and not (state.concert and state.concert.open)
        and not (state.stage and state.stage.open)
    self.resizeHud()
    if not wasOpen and self.panel.Visible then
        self:showPage("Play")
    end
    self.bookView:update(state)
    self.roomSettings:update(state)
    self.recorderGuide:update(state)
    self.sampleEditor:update(state, self.selectedPad)
    self.beatTools:update(state)
    if UserInputService.GamepadEnabled and wasOpen ~= self.panel.Visible then
        GuiService.SelectedObject = if self.panel.Visible then self.play else self.sound
    end
    local p = state.pattern
    local wasRecipeVisible = self.beatGuide.root.Visible
    self.beatGuide:update(state, self.selectedPad)
    if wasRecipeVisible ~= self.beatGuide.root.Visible then
        self.resizeLayout()
    end
    self.play.Text = if state.playing then "PAUSE" else "PLAY"
    self.record.Text = if state.recording then "RECORDING" else "REC"
    self.stop.Text = "STOP"
    self.record.BackgroundColor3 = if state.recording then Theme.Coral else Theme.Graphite
    self.play.BackgroundColor3 = if state.playing then Theme.Teal else Theme.Graphite
    self.broadcast.Text = if state.broadcast
        then "STREET SPEAKER / LIVE"
        else "STREET SPEAKER / OFF"
    self.broadcast.BackgroundColor3 = if state.broadcast then Theme.Coral else Theme.Teal
    self.quickMute.Text = if p.muted[self.selectedPad] then "UNMUTE" else "MUTE"
    self.quickSave.Text = if state.saving then "..." elseif state.dirty then "SAVE *" else "SAVE"
    for slot, button in self.slotButtons do
        button.BackgroundColor3 = if state.book and state.book.activeSlot == slot
            then Theme.Amber
            else Theme.Graphite
        button.TextColor3 = if state.book and state.book.activeSlot == slot
            then Theme.Ink
            else Theme.Cream
    end
    self.finish.Text = "Finish: " .. Cosmetics.Sets[state.finish].label
    self.padMute.Text = if p.muted[self.selectedPad] then "Unmute pad" else "Mute pad"
    self.save.Text = if state.saving
        then "Saving..."
        elseif state.dirty then "Save profile *"
        else "Save profile"
    local confirmation = self.restoreConfirmation
    if
        confirmation
        and (
            os.clock() >= confirmation.expires
            or confirmation.editVersion ~= state.editVersion
            or confirmation.station ~= state.station
            or state.saving
            or not state.hasSave
            or not state.station
        )
    then
        self.restoreConfirmation = nil
    end
    self.restore.Text = if self.restoreConfirmation
        then "Replace slots A-D?"
        elseif state.hasSave then "Restore slots"
        else "No saved slots"
    local packConfirmation = self.packConfirmation
    if
        packConfirmation
        and (
            os.clock() >= packConfirmation.expires
            or state.editVersion ~= packConfirmation.editVersion
            or state.station ~= packConfirmation.station
            or state.saving
            or not state.station
        )
    then
        self.packConfirmation = nil
    end
    self:filterSamples()
    self.rowTitle.Text = string.format(
        "%02d / %s · 16 STEPS",
        self.selectedPad,
        Catalog.ById[p.assignments[self.selectedPad]].label
    )
    self:updatePadLabels()
    for step, button in self.steps do
        local on = p.rows[self.selectedPad][step]
        button.Text = string.format("%02d", step)
        button.BackgroundColor3 = if on then Theme.Amber else Theme.Graphite
        button.TextColor3 = if on then Theme.Ink else Theme.Cream
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
            self.hudLabel.Text = if state.quest
                then (if state.quest.completed
                    then "FIRST COURTYARD SET / COMPLETE\n"
                    else "MICA'S REQUEST / " .. tostring(collected) .. "/3 sounds\n") .. state.quest.objective
                else string.format(
                    "NEEDLE QUAY / %d of 3 sounds collected\nVisit a sampler to make your loop. Save before leaving.",
                    collected
                )
            if state.quay then
                local completed = 0
                for id, done in state.quay.progress.completed do
                    if done and id ~= "NQ-Q03" then
                        completed += 1
                    end
                end
                self.hudLabel.Text = "NEEDLE QUAY / "
                    .. completed
                    .. "/12   /   "
                    .. collected
                    .. "/3 SOUNDS"
            elseif state.quest and state.quest.completed and state.neighborhood then
                self.hudLabel.Text = if state.neighborhood.courtReady
                    then (if state.concert and state.concert.completed
                        then "NEIGHBORHOOD SECTION COMPLETE\nKeep creating. Other chapters are still ahead."
                        else "COURTYARD PREPARED\nVisit the Chapter concert prompt beside the listening podium.")
                    else string.format(
                        "NEIGHBORHOOD JOBS / %d of 3 complete\nOpen Virtual recorder in Sounds for your next job.",
                        state.neighborhood.completed
                    )
            end
        end
    end
    self.status.Text = string.format(
        "%s / %d BPM / %s / %s",
        if state.book then state.book.slots[state.book.activeSlot].label else "A",
        p.bpm,
        if not state.ready
            then "LOADING"
            elseif state.recording then "REC"
            elseif state.playing then "PLAYING"
            else "READY",
        if state.saving
            then "SAVING..."
            elseif state.saveMode == "unavailable" then "TEMPORARY"
            elseif state.dirty then "UNSAVED"
            elseif not state.hasSave then "NEW"
            elseif state.saveMode == "session" then "SESSION SAVED"
            else "SAVED"
    )
    self.hardware:update(state, self.selectedPad)
    self.hardwareKnobs:update(state, self.selectedPad)
    self.status.Font = Enum.Font.Code
    self.noticeLabel.Text = if self.noticeUntil and os.clock() < self.noticeUntil
        then self.noticeText
        else self:guideText()

    if state.notice then
        self:notice(state.notice)
        state.notice = nil
    end
end

function WorkshopView:playhead(step)
    if not self.state then
        return
    end
    for pad, button in self.pads do
        local hit = self.state.pattern.rows[pad][step] and not self.state.pattern.muted[pad]
        if hit and self.motion then
            self.motion:hit(pad)
        end
        button.PadLed.BackgroundColor3 = if hit then Theme.Amber else Theme.FadedTeal
        button.PadLed.BackgroundTransparency = if hit then 0 else 0.65
        button.BackgroundColor3 = if hit and self.effects
            then Theme.Coral
            elseif self.padInput.held[pad] then Theme.Coral
            elseif pad == self.selectedPad then Theme.Amber
            elseif self.state.pattern.muted[pad] then Theme.Stone
            else Theme.Cream
        button.TextColor3 = Theme.Ink
    end
    for index, button in self.steps do
        local on = self.state.pattern.rows[self.selectedPad][index]
        button.BackgroundColor3 = if index == step
            then Theme.Coral
            elseif on then Theme.Amber
            else Theme.Graphite
        button.TextColor3 = if index == step or on then Theme.Ink else Theme.Cream
        button.Text = string.format("%02d", index)
    end
end

function WorkshopView:tick()
    self.bookView:tick()
    local metrics = self.padInput:diagnostics()
    self.inputStatus.Text = string.format(
        "Input: %d hits; %d local playback submissions; %d unavailable/muted. %s",
        metrics.hits,
        metrics.submitted,
        metrics.unavailable,
        if metrics.p95Ms
            then string.format(
                "Handler → Play submission p95 %.2f ms (last %d). Not audible latency.",
                metrics.p95Ms,
                metrics.measured
            )
            else "No audible latency measurement. Bind and verify the sound bank first."
    )
    if self.state and self.noticeUntil and os.clock() >= self.noticeUntil then
        self.noticeUntil = nil
        self:update(self.state)
    end
end
return WorkshopView
