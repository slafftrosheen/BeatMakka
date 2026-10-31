-- Fixed LCD sound editor. All graphs and controls are allocated once; pad hits
-- change their values without rebuilding the screen or its event connections.
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Actions = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Theme = require(Shared.Theme)
local Sound = require(Shared.PadSound)
local Waves = require(Shared.SampleWaveforms)
local Catalog = require(Shared.SampleCatalog)
local Recipes = require(Shared.QuayFxRecipes)
local Gui = require(script.Parent.GuiFactory)
local Skin = require(script.Parent.DeviceSkin)
local Icons = require(script.Parent.GameIcons)
local Mix = require(script.Parent.AudioMix)

local Editor = {}
Editor.__index = Editor
local nextId = 0
local modes = { "TRIM", "ENV", "FX" }
local envelopeKeys = { "attack", "decay", "sustain", "release", "gate" }
local compactRecipeNames =
    { quay_echo = "DOCK", quay_vent = "VENT", quay_lantern = "LANTERN", quay_signal = "SIGNAL" }
local names = {
    start = "IN",
    finish = "OUT",
    attack = "ATTACK",
    decay = "DECAY",
    sustain = "SUSTAIN",
    release = "RELEASE",
    gate = "GATE",
    delay = "ECHO TIME",
}
local directions = {
    [Enum.KeyCode.Left] = -1,
    [Enum.KeyCode.Down] = -1,
    [Enum.KeyCode.DPadLeft] = -1,
    [Enum.KeyCode.DPadDown] = -1,
    [Enum.KeyCode.Right] = 1,
    [Enum.KeyCode.Up] = 1,
    [Enum.KeyCode.DPadRight] = 1,
    [Enum.KeyCode.DPadUp] = 1,
}

local function set(object, property, value)
    if object[property] ~= value then
        object[property] = value
    end
end

local function attribute(object, key, value)
    if object:GetAttribute(key) ~= value then
        object:SetAttribute(key, value)
    end
end

local function label(parent, text, size, color)
    local object = Gui.label(parent, text, size or 11, color or Theme.Cream)
    object.Font, object.TextWrapped = Enum.Font.Code, false
    object.TextTruncate = Enum.TextTruncate.AtEnd
    return object
end

local function frame(parent, name, color)
    return Gui.make("Frame", parent, {
        Name = name,
        BorderSizePixel = 0,
        BackgroundColor3 = color or Theme.Screen,
    })
end

local function route(state, pad)
    local music = state and state.music or {}
    return table.concat({
        tostring(state and state.station or ""),
        tostring(music.projectId or ""),
        tostring(music.trackId or ""),
        tostring(music.program and music.program.id or ""),
        tostring(music.bank or ""),
        tostring(pad or ""),
        tostring(
            state and state.pattern and state.pattern.assignments and state.pattern.assignments[pad]
                or ""
        ),
    }, ":")
end

local function quantize(key, value)
    local spec = Sound.Spec[key]
    return math.clamp(math.round(value / spec[4]) * spec[4], spec[1], spec[2])
end

local function earned(progress, item)
    return progress ~= nil
        and type(if item.side then progress.side else progress.completed) == "table"
        and Recipes.earned(progress, item) == true
end

function Editor:connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self.connections, connection)
    return connection
end

function Editor:button(parent, name, text, callback)
    local button = Gui.make("TextButton", parent, {
        Name = name,
        Text = text,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextColor3 = Theme.Cream,
        BackgroundColor3 = Theme.Ink,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Selectable = true,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    attribute(button, "AccessibleLabel", text)
    local focus = Gui.make("UIStroke", button, {
        Name = "FocusRing",
        Color = Theme.Amber,
        Thickness = 2,
        Enabled = false,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    self:connect(button.SelectionGained, function()
        focus.Enabled = true
    end)
    self:connect(button.SelectionLost, function()
        focus.Enabled = false
    end)
    self:connect(button.Activated, callback)
    return button
end

function Editor:isVisible(target)
    local object = target or self.root
    while object do
        if object:IsA("GuiObject") and not object.Visible then
            return false
        elseif object:IsA("ScreenGui") and not object.Enabled then
            return false
        end
        object = object.Parent
    end
    return self.root.Parent ~= nil
end

function Editor:editable()
    return not self.destroyed
        and self.state ~= nil
        and self.state.ready == true
        and self.state.station ~= nil
        and self.pad ~= nil
        and self:isVisible()
end

function Editor:valid(edit)
    return self:editable()
        and edit.route == self.route
        and edit.route == route(self.state, self.pad)
        and edit.pad == self.pad
end

function Editor:newFader(parent, key, vertical)
    local root = frame(parent, "Fader_" .. key, Theme.Screen)
    root.BackgroundTransparency = 1
    local title = label(root, names[key])
    title.TextXAlignment = Enum.TextXAlignment.Center
    local value = label(root, "", 12, Theme.Amber)
    value.TextXAlignment = Enum.TextXAlignment.Center
    local rail = self:button(root, "Control_" .. key, "", function() end)
    rail.BackgroundTransparency = 1
    attribute(rail, "PadSoundKey", key)
    attribute(rail, "AccessibleLabel", names[key])
    local track = frame(rail, "Track", Theme.Teal)
    local fill = frame(track, "Fill", Theme.FadedTeal)
    local thumb = frame(rail, "Thumb", Theme.Cream)
    local ridge = frame(thumb, "Ridge", Theme.Ink)
    ridge.AnchorPoint = Vector2.new(0.5, 0.5)
    ridge.Position = UDim2.fromScale(0.5, 0.5)
    ridge.Size = if vertical then UDim2.new(1, -8, 0, 2) else UDim2.new(0, 2, 1, -8)
    if vertical then
        track.AnchorPoint, track.Position = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0)
        track.Size = UDim2.new(0, 4, 1, 0)
        fill.AnchorPoint, fill.Position = Vector2.new(0, 1), UDim2.fromScale(0, 1)
        thumb.AnchorPoint, thumb.Size = Vector2.new(0.5, 0.5), UDim2.fromOffset(28, 12)
    else
        track.AnchorPoint, track.Position = Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5)
        track.Size = UDim2.new(1, 0, 0, 4)
        thumb.AnchorPoint, thumb.Size = Vector2.new(0.5, 0.5), UDim2.fromOffset(12, 24)
    end
    local fader = {
        root = root,
        title = title,
        value = value,
        rail = rail,
        fill = fill,
        track = track,
        thumb = thumb,
        vertical = vertical,
    }
    self.faders[key] = fader
    self.controls[rail] = key
    self:connect(rail.InputBegan, function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            self:begin(key, input, fader)
        end
    end)
    self:connect(rail.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            self:adjust(key, input.Position.Z)
        end
    end)
    return fader
end

function Editor.new(parent, change, audition, selectPad, preset)
    nextId += 1
    local self = setmetatable({
        change = change,
        audition = audition,
        selectPad = selectPad,
        preset = preset,
        connections = {},
        faders = {},
        controls = {},
        values = Sound.sanitize(nil),
        pending = {},
        mode = "TRIM",
        recipePage = 1,
        nextSend = 0,
        action = "DeviceSoundScreen" .. nextId,
    }, Editor)
    self.root = frame(parent, "DeviceSoundScreen", Theme.Screen)
    self.root.Size, self.root.ClipsDescendants = UDim2.fromScale(1, 1), true
    attribute(self.root, "PersistentControls", true)
    attribute(self.root, "WaveformBins", 64)
    self.header = frame(self.root, "SourceHeader")
    self.title = label(self.header, "SELECT A PAD", 13, Theme.Amber)
    self.sourceInfo = label(self.header, "REAL SAMPLE / NON-DESTRUCTIVE EDITS", 10, Theme.FadedTeal)
    self.previous = self:button(self.header, "PreviousPad", "<", function()
        self:cancel()
        selectPad(((self.pad or 1) - 2) % 64 + 1)
    end)
    self.next = self:button(self.header, "NextPad", ">", function()
        self:cancel()
        selectPad((self.pad or 1) % 64 + 1)
    end)
    self.tabs = {}
    self.tabRow = frame(self.root, "SoundPages")
    for _, mode in modes do
        self.tabs[mode] = self:button(self.tabRow, mode, mode, function()
            self:cancel()
            self.mode = mode
            self:resize(self.width, self.height)
        end)
    end
    self.graph = frame(self.root, "Waveform", Theme.Ink)
    self.graph.ClipsDescendants = true
    self.graph.Active = true
    self.axis = frame(self.graph, "ZeroLine", Theme.Teal)
    self.axis.Position, self.axis.Size = UDim2.fromScale(0, 0.5), UDim2.new(1, 0, 0, 1)
    self.bars, self.envelope = {}, {}
    for index = 1, 64 do
        local bar = frame(self.graph, string.format("WaveBin_%02d", index), Theme.FadedTeal)
        bar.AnchorPoint = Vector2.new(0.5, 0.5)
        bar.Position, bar.Size =
            UDim2.fromScale((index - 0.5) / 64, 0.5), UDim2.new(1 / 64, -1, 0, 1)
        self.bars[index] = bar
        local segment = frame(self.graph, "EnvelopeSegment_" .. index, Theme.Amber)
        segment.AnchorPoint, segment.ZIndex = Vector2.new(0, 0.5), 4
        self.envelope[index] = segment
    end
    self.trimHandles = {}
    for _, key in { "start", "finish" } do
        local handle = self:button(
            self.graph,
            if key == "start" then "TrimIn" else "TrimOut",
            "",
            function() end
        )
        handle.Size, handle.AnchorPoint = UDim2.new(0, 28, 1, 0), Vector2.new(0.5, 0)
        handle.BackgroundTransparency, handle.ZIndex = 1, 6
        attribute(handle, "AccessibleLabel", "TRIM " .. names[key])
        attribute(handle, "PadSoundKey", key)
        local line = frame(handle, "Marker", Theme.Amber)
        line.Position, line.Size, line.ZIndex = UDim2.new(0.5, -1, 0, 0), UDim2.new(0, 2, 1, 0), 6
        local flag = label(handle, names[key], 10, Theme.Ink)
        flag.BackgroundTransparency, flag.BackgroundColor3 = 0, Theme.Amber
        flag.Size, flag.TextXAlignment, flag.ZIndex =
            UDim2.fromOffset(28, 16), Enum.TextXAlignment.Center, 7
        self.trimHandles[key], self.controls[handle] = handle, key
        self:connect(handle.InputBegan, function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                self:begin(key, input, { rail = self.graph, vertical = false, trim = true })
            end
        end)
    end
    self.playhead = frame(self.graph, "AuditionCursor", Theme.Cream)
    self.playhead.Size, self.playhead.Visible, self.playhead.ZIndex =
        UDim2.new(0, 2, 1, 0), false, 8
    self.graphCaption = label(self.graph, "PCM WAVEFORM", 10, Theme.Cream)
    self.graphCaption.Position, self.graphCaption.Size, self.graphCaption.ZIndex =
        UDim2.fromOffset(6, 4), UDim2.new(1, -12, 0, 14), 5
    self.pages = {}
    for _, mode in modes do
        self.pages[mode] = frame(self.root, mode .. "Page")
    end
    self:newFader(self.pages.TRIM, "start", false)
    self:newFader(self.pages.TRIM, "finish", false)
    self.trimSummary = label(self.pages.TRIM, "", 11, Theme.FadedTeal)
    for _, key in envelopeKeys do
        self:newFader(self.pages.ENV, key, true)
    end
    self.fxTop = frame(self.pages.FX, "SignalRoute")
    self.delay = self:newFader(self.fxTop, "delay", false)
    self.delayKnob = Skin.image(
        self.fxTop,
        "knob",
        { Name = "EchoTimeDial", Size = UDim2.fromOffset(42, 42), ZIndex = 2 }
    )
    self.routing = label(self.fxTop, "PAD > TONE / DRIVE", 10, Theme.FadedTeal)
    self.fxReadout = label(self.fxTop, "", 11, Theme.Cream)
    self.recipeHeader = label(self.pages.FX, "EARNED FX", 10, Theme.Amber)
    self.recipePager = label(self.pages.FX, "1 / 1", 10, Theme.FadedTeal)
    self.recipePager.TextXAlignment = Enum.TextXAlignment.Right
    self.recipePrevious = self:button(self.pages.FX, "PreviousFXPage", "<", function()
        self.recipePage = math.max(1, self.recipePage - 1)
        self:drawRecipes()
    end)
    self.recipeNext = self:button(self.pages.FX, "NextFXPage", ">", function()
        self.recipePage = math.min(math.max(1, math.ceil(#Recipes.List / 4)), self.recipePage + 1)
        self:drawRecipes()
    end)
    self.recipeTiles = {}
    for index = 1, 4 do
        local tile = self:button(self.pages.FX, "RecipeTile_" .. index, "", function()
            local item = Recipes.List[(self.recipePage - 1) * 4 + index]
            if item and self:editable() and earned(self.progress, item) then
                self:cancel()
                table.clear(self.pending)
                preset(item.id)
            end
        end)
        local icon = Icons.make(tile, "coil", Theme.FadedTeal, 18)
        icon.Position = UDim2.fromOffset(6, 8)
        local lockedIcon = Icons.make(tile, "lock", Theme.FadedTeal, 18)
        lockedIcon.Position = UDim2.fromOffset(6, 8)
        local title = label(tile, "", 10, Theme.Cream)
        title.Position, title.Size = UDim2.fromOffset(30, 3), UDim2.new(1, -34, 0, 15)
        local hint = label(tile, "", 10, Theme.FadedTeal)
        hint.Position, hint.Size = UDim2.fromOffset(30, 18), UDim2.new(1, -34, 0, 15)
        self.recipeTiles[index] =
            { button = tile, title = title, hint = hint, icon = icon, lockedIcon = lockedIcon }
    end
    self.footer = frame(self.root, "AuditionControls")
    self.dry = self:button(self.footer, "AuditionDry", "A / DRY", function()
        self:auditionPad(Sound.preset(self.values, "dry", self.bpm or 96))
    end)
    self.sync = self:button(self.footer, "SyncEcho", "SYNC 1/2", function()
        self:adjustTo("delay", math.clamp(60 / (self.bpm or 96) * 0.5, 0.05, 1))
    end)
    self.reset = self:button(self.footer, "ResetSoundEdits", "RESET", function()
        if self:editable() then
            self:cancel()
            table.clear(self.pending)
            preset("reset")
        end
    end)
    self.preview = self:button(self.footer, "AuditionSample", "AUDITION", function()
        self:auditionPad(self.values)
    end)
    self.previewArt = Skin.image(self.preview, "pad", {
        Name = "AuditionPadSurface",
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(0, 4, 0.5, -12),
        ZIndex = 1,
    })
    self.previewIcon = Icons.make(self.preview, "play", Theme.Amber, 14)
    self.previewIcon.Position, self.previewIcon.ZIndex = UDim2.new(0, 9, 0.5, -7), 2
    self:connect(Input.InputChanged, function(input)
        local edit = self.edit
        if edit and edit.kind == "pointer" then
            local mouse = edit.input.UserInputType == Enum.UserInputType.MouseButton1
            if
                (mouse and input.UserInputType == Enum.UserInputType.MouseMovement)
                or (not mouse and input == edit.input)
            then
                self:dragTo(input.Position)
            end
        end
    end)
    self:connect(Input.InputEnded, function(input)
        local edit = self.edit
        if
            edit
            and edit.kind == "pointer"
            and (
                input == edit.input
                or (
                    edit.input.UserInputType == Enum.UserInputType.MouseButton1
                    and input.UserInputType == Enum.UserInputType.MouseButton1
                )
            )
        then
            self:flush(true)
            self.edit = nil
            attribute(self.root, "Dragging", false)
        end
    end)
    self:connect(Input.WindowFocusReleased, function()
        self:cancel()
    end)
    self:connect(Input.TextBoxFocused, function()
        self:cancel()
    end)
    self:connect(self.root:GetPropertyChangedSignal("Visible"), function()
        if not self.root.Visible then
            self:cancel()
        end
    end)
    self:connect(RunService.Heartbeat, function()
        if self.edit then
            self:flush(false)
            if self.edit and self.edit.kind == "step" and os.clock() >= self.edit.expires then
                self:flush(true)
                self.edit = nil
            end
        end
        if self.auditionStarted then
            self:stepAudition()
        end
    end)
    Actions:BindActionAtPriority(
        self.action,
        function(_, inputState, input)
            local selected = GuiService.SelectedObject
            local key = self.controls[selected]
            if
                key
                and self:editable()
                and self:isVisible(selected)
                and not Input:GetFocusedTextBox()
            then
                if inputState == Enum.UserInputState.Begin then
                    self:adjust(key, directions[input.KeyCode])
                end
                return Enum.ContextActionResult.Sink
            end
            return Enum.ContextActionResult.Pass
        end,
        false,
        Enum.ContextActionPriority.High.Value + 1,
        Enum.KeyCode.Left,
        Enum.KeyCode.Right,
        Enum.KeyCode.Up,
        Enum.KeyCode.Down,
        Enum.KeyCode.DPadLeft,
        Enum.KeyCode.DPadRight,
        Enum.KeyCode.DPadUp,
        Enum.KeyCode.DPadDown
    )
    self:connect(self.root.Destroying, function()
        self:destroy(true)
    end)
    self:resize(480, 360)
    self:draw()
    return self
end

function Editor:begin(key, input, fader)
    if not self:editable() or (self.edit and self.edit.kind == "pointer") then
        return
    end
    self:flush(true)
    self.edit = {
        key = key,
        input = input,
        fader = fader,
        route = self.route,
        pad = self.pad,
        initialY = input.Position.Y,
        initial = self.values[key],
        kind = "pointer",
        sent = self.values[key],
    }
    attribute(self.root, "Dragging", true)
    self:dragTo(input.Position)
end

function Editor:dragTo(position)
    local edit = self.edit
    if not edit or not self:valid(edit) then
        self:cancel()
        return
    end
    local rail = if edit.fader.vertical and edit.fader.track
        then edit.fader.track
        else edit.fader.rail
    local fraction = if edit.fader.vertical
        then 1 - (position.Y - rail.AbsolutePosition.Y) / math.max(1, rail.AbsoluteSize.Y)
        else (position.X - rail.AbsolutePosition.X) / math.max(1, rail.AbsoluteSize.X)
    local spec = Sound.Spec[edit.key]
    local value = if edit.fader.trim then fraction else spec[1] + fraction * (spec[2] - spec[1])
    self:setValue(edit.key, value)
    self:flush(false)
end

function Editor:setValue(key, value)
    value = quantize(key, value)
    if key == "start" then
        value = math.min(value, self.values.finish - 0.02)
    elseif key == "finish" then
        value = math.max(value, self.values.start + 0.02)
    end
    if self.values[key] == value then
        return
    end
    self.values[key] = value
    self:draw()
end

function Editor:flush(force)
    local edit = self.edit
    if not edit then
        return
    end
    if not self:valid(edit) then
        self:cancel()
        return
    end
    local value = self.values[edit.key]
    if value == edit.sent or (not force and os.clock() < self.nextSend) then
        return
    end
    edit.sent, self.nextSend = value, os.clock() + 0.08
    self.pending[edit.key] = { value = value, at = os.clock(), route = edit.route }
    self.change(edit.key, value)
end

function Editor:adjustTo(key, value)
    if not self:editable() or (self.edit and self.edit.kind == "pointer") then
        return
    end
    if not self.edit or self.edit.key ~= key then
        self:flush(true)
        self.edit = {
            key = key,
            route = self.route,
            pad = self.pad,
            kind = "step",
            sent = self.values[key],
        }
    end
    self.edit.expires = os.clock() + 0.16
    self:setValue(key, value)
    self:flush(false)
end

function Editor:adjust(key, amount)
    if not amount or amount == 0 then
        return
    end
    self:adjustTo(key, self.values[key] + amount * Sound.Spec[key][4])
end

function Editor:cancel()
    self.edit = nil
    attribute(self.root, "Dragging", false)
end

function Editor:auditionPad(settings)
    if not self:editable() then
        return
    end
    if self.audition(self.pad, settings) then
        self.auditionUnavailable = false
        self.auditionStarted = os.clock()
        self.auditionSettings = Sound.sanitize(settings)
        local wave = Waves[self.sample]
        local duration = (if wave then wave.duration else 0)
            * (settings.finish - settings.start)
            / 2 ^ (settings.pitch / 12)
        local _, finish = Sound.timing(settings, duration)
        Mix.sampleAuditionUntil = os.clock() + finish + 1.2
        set(self.preview, "Text", "PLAYING")
    else
        self.auditionUnavailable = true
        set(self.sourceInfo, "Text", "AUDITION UNAVAILABLE / CHECK SOUND")
    end
    self:draw()
end

function Editor:stepAudition()
    local wave = Waves[self.sample]
    local settings = self.auditionSettings
    local elapsed = os.clock() - self.auditionStarted
    local duration = (if wave then wave.duration else 0)
        * (settings.finish - settings.start)
        / 2 ^ (settings.pitch / 12)
    local _, finish = Sound.timing(settings, duration)
    if not wave or elapsed >= finish or not self:isVisible() then
        self.auditionStarted = nil
        self.playhead.Visible = false
        set(self.preview, "Text", "AUDITION")
        return
    end
    self.playhead.Visible = true
    self.playhead.Position =
        UDim2.fromScale(settings.start + elapsed * 2 ^ (settings.pitch / 12) / wave.duration, 0)
end

function Editor:drawRecipes()
    local count = math.max(1, math.ceil(#Recipes.List / 4))
    self.recipePage = math.clamp(self.recipePage, 1, count)
    set(self.recipePager, "Text", string.format("%d / %d", self.recipePage, count))
    set(self.recipePrevious, "Active", self.recipePage > 1)
    set(self.recipePrevious, "Selectable", self.recipePage > 1)
    set(self.recipeNext, "Active", self.recipePage < count)
    set(self.recipeNext, "Selectable", self.recipePage < count)
    for index, tile in self.recipeTiles do
        local item = Recipes.List[(self.recipePage - 1) * 4 + index]
        set(tile.button, "Visible", item ~= nil)
        if item then
            local isEarned = earned(self.progress, item)
            set(
                tile.title,
                "Text",
                if self.dense then compactRecipeNames[item.id] or item.label else item.label
            )
            set(
                tile.hint,
                "Text",
                if self.dense
                    then (if isEarned then "APPLY" else "LOCKED")
                    elseif isEarned then "APPLY TO " .. (self.address or "PAD")
                    else item.hint
            )
            set(tile.icon, "Visible", isEarned)
            set(tile.lockedIcon, "Visible", not isEarned)
            set(tile.button, "BackgroundColor3", if isEarned then Theme.Teal else Theme.Ink)
            set(tile.button, "Active", isEarned)
            set(tile.button, "Selectable", isEarned)
            attribute(tile.button, "RecipeId", item.id)
            attribute(tile.button, "Earned", isEarned)
            attribute(
                tile.button,
                "AccessibleLabel",
                item.label .. (if isEarned then " / Apply" else " / Locked: " .. item.hint)
            )
        end
    end
end

function Editor:draw()
    local values, wave = self.values, self.sample and Waves[self.sample]
    local duration = if wave then wave.duration else 0
    for _, mode in modes do
        set(self.pages[mode], "Visible", self.mode == mode)
        set(
            self.tabs[mode],
            "BackgroundColor3",
            if self.mode == mode then Theme.Amber else Theme.Ink
        )
        set(self.tabs[mode], "TextColor3", if self.mode == mode then Theme.Screen else Theme.Cream)
        attribute(self.tabs[mode], "Selected", self.mode == mode)
    end
    attribute(self.root, "SoundPage", self.mode)
    for key, fader in self.faders do
        local spec = Sound.Spec[key]
        local fraction = math.clamp((values[key] - spec[1]) / (spec[2] - spec[1]), 0, 1)
        local text = if key == "start" or key == "finish"
            then string.format("%.0f ms", values[key] * duration * 1000)
            elseif key == "sustain" or key == "gate" then string.format(
                "%d%%",
                math.round(values[key] * 100)
            )
            else string.format("%.0f ms", values[key] * 1000)
        set(fader.value, "Text", text)
        set(
            fader.fill,
            "Size",
            if fader.vertical then UDim2.fromScale(1, fraction) else UDim2.fromScale(fraction, 1)
        )
        set(
            fader.thumb,
            "Position",
            if fader.vertical
                then UDim2.new(0.5, 0, 1 - fraction, (2 * fraction - 1) * (fader.thumbInset or 0))
                else UDim2.fromScale(fraction, 0.5)
        )
        attribute(fader.rail, "ControlValue", values[key])
        attribute(fader.rail, "AbsolutePad", self.pad)
        attribute(fader.rail, "AccessibleLabel", names[key] .. " / " .. text)
    end
    local peak = 0.001
    for _, value in if wave then wave.peaks else {} do
        peak = math.max(peak, value)
    end
    for index, bar in self.bars do
        local value = if wave then wave.peaks[index] or 0 else 0
        local inside = (index - 0.5) / 64 >= values.start and (index - 0.5) / 64 <= values.finish
        set(bar, "Size", UDim2.new(1 / 64, -1, math.max(0.01, value / peak * 0.8), 0))
        set(bar, "BackgroundColor3", if inside then Theme.FadedTeal else Theme.Teal)
        set(bar, "BackgroundTransparency", if self.mode == "ENV" then 0.7 else 0)
        attribute(bar, "PCMNormalizedPeak", value)
    end
    for key, handle in self.trimHandles do
        set(handle, "Visible", self.mode == "TRIM")
        set(handle, "Position", UDim2.fromScale(values[key], 0))
        attribute(handle, "ControlValue", values[key])
        attribute(handle, "AbsolutePad", self.pad)
    end
    local slice = duration * (values.finish - values.start) / 2 ^ (values.pitch / 12)
    local graphWidth, graphHeight = self.graphWidth or 1, self.graphHeight or 1
    for index, segment in self.envelope do
        set(segment, "Visible", self.mode == "ENV")
        if self.mode == "ENV" then
            local x1, x2 = (index - 1) / 64, index / 64
            local y1 = 1 - Sound.envelope(values, math.max(0.001, slice), x1 * slice) * 0.78
            local y2 = 1 - Sound.envelope(values, math.max(0.001, slice), x2 * slice) * 0.78
            local dx, dy = (x2 - x1) * graphWidth, (y2 - y1) * (graphHeight - 8)
            set(segment, "Position", UDim2.fromOffset(x1 * graphWidth, 4 + y1 * (graphHeight - 8)))
            set(segment, "Size", UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1, 2))
            set(segment, "Rotation", math.deg(math.atan2(dy, dx)))
        end
    end
    set(
        self.graphCaption,
        "Text",
        if self.auditionUnavailable
            then "AUDITION UNAVAILABLE / CHECK SOUND"
            elseif not wave then "SOURCE WAVEFORM UNAVAILABLE"
            elseif self.mode == "ENV" then string.format("ENVELOPE / %.0f ms", slice * 1000)
            else string.format("PCM WAVEFORM / %.0f ms", duration * 1000)
    )
    set(self.graphCaption, "Visible", not self.dense or self.auditionUnavailable == true)
    set(
        self.trimSummary,
        "Text",
        string.format("SLICE %.0f ms  /  %.2fx SPEED", slice * 1000, 2 ^ (values.pitch / 12))
    )
    set(
        self.fxReadout,
        "Text",
        string.format(
            "ECHO %02d%% / SPACE %02d%%",
            math.round(values.echo * 100),
            math.round(values.reverb * 100)
        )
    )
    set(self.delayKnob, "Rotation", -135 + (values.delay - 0.05) / 0.95 * 270)
    set(self.sync, "Visible", self.mode == "FX")
    set(self.dry, "Visible", self.mode == "FX")
    self:drawRecipes()
end

function Editor:update(state, absolutePad)
    if self.destroyed then
        return
    end
    local nextRoute = route(state, absolutePad)
    local changedRoute = self.route ~= nextRoute
    if changedRoute then
        self:cancel()
        table.clear(self.pending)
        self.auditionStarted, self.playhead.Visible = nil, false
        self.auditionUnavailable = false
        set(self.preview, "Text", "AUDITION")
    end
    self.state, self.pad, self.route = state, absolutePad, nextRoute
    local pattern = state and state.pattern
    local sample = pattern and pattern.assignments and pattern.assignments[absolutePad]
    local values = Sound.sanitize(pattern and pattern.sounds and pattern.sounds[absolutePad])
    for key, pending in self.pending do
        if
            pending.route ~= nextRoute
            or values[key] == pending.value
            or os.clock() - pending.at > 1.2
        then
            self.pending[key] = nil
        else
            values[key] = pending.value
        end
    end
    if self.edit and self:valid(self.edit) then
        values[self.edit.key] = self.values[self.edit.key]
    end
    local changed = changedRoute or sample ~= self.sample or not Sound.same(self.values, values)
    self.sample, self.values = sample, values
    self.bpm = pattern and pattern.bpm or 96
    self.progress = state and state.quay and state.quay.progress
    self.address = if type(absolutePad) == "number"
        then string.char(65 + math.floor((absolutePad - 1) / 16)) .. string.format(
            "%02d",
            (absolutePad - 1) % 16 + 1
        )
        else "PAD"
    set(
        self.title,
        "Text",
        self.address .. " / " .. (if sample then Catalog.label(sample) else "SELECT A SOURCE")
    )
    attribute(self.root, "AbsolutePad", absolutePad)
    attribute(self.root, "SampleId", sample)
    attribute(self.root, "Ready", state and state.ready == true or false)
    local wave = sample and Waves[sample]
    set(
        self.sourceInfo,
        "Text",
        if wave
            then string.format("%.3fs SOURCE  /  TRIM + ADSR + FX", wave.duration)
            else "SOURCE WAVEFORM UNAVAILABLE"
    )
    if changed then
        self:draw()
    else
        self:drawRecipes()
    end
end

function Editor:resizeCompact(width, height)
    local contentWidth = math.max(1, width - 8)
    local graphHeight = math.max(22, math.min(38, math.floor(height * 0.17), height - 123))
    local graphY, footerHeight = 48, 22
    local pageY = graphY + graphHeight + 2
    local footerY = height - footerHeight - 2
    local pageHeight = math.max(47, footerY - pageY - 2)
    self.header.Position, self.header.Size =
        UDim2.fromOffset(4, 0), UDim2.fromOffset(contentWidth, 22)
    self.title.Position, self.title.Size = UDim2.fromOffset(0, 0), UDim2.new(1, -52, 1, 0)
    self.title.TextSize = 11
    self.sourceInfo.Visible = false
    self.previous.Position, self.previous.Size = UDim2.new(1, -48, 0, 0), UDim2.fromOffset(22, 22)
    self.next.Position, self.next.Size = UDim2.new(1, -22, 0, 0), UDim2.fromOffset(22, 22)
    self.tabRow.Position, self.tabRow.Size =
        UDim2.fromOffset(4, 24), UDim2.fromOffset(contentWidth, 22)
    for index, mode in modes do
        self.tabs[mode].Position, self.tabs[mode].Size =
            UDim2.fromScale((index - 1) / 3, 0), UDim2.new(1 / 3, -2, 1, 0)
    end
    self.graph.Position, self.graph.Size =
        UDim2.fromOffset(4, graphY), UDim2.fromOffset(contentWidth, graphHeight)
    self.graphWidth, self.graphHeight = contentWidth, graphHeight
    for _, page in self.pages do
        page.Position, page.Size =
            UDim2.fromOffset(4, pageY), UDim2.fromOffset(contentWidth, pageHeight)
    end
    for index, key in { "start", "finish" } do
        local fader = self.faders[key]
        fader.root.Position, fader.root.Size =
            UDim2.fromScale((index - 1) / 2, 0), UDim2.new(0.5, -3, 1, 0)
        fader.title.Position, fader.title.Size = UDim2.fromOffset(0, 0), UDim2.new(0.25, 0, 0, 14)
        fader.value.Position, fader.value.Size = UDim2.fromScale(0.25, 0), UDim2.new(0.75, 0, 0, 14)
        fader.title.TextSize, fader.value.TextSize = 10, 11
        fader.rail.Position, fader.rail.Size = UDim2.fromOffset(8, 19), UDim2.new(1, -16, 1, -21)
    end
    self.trimSummary.Visible = false
    for index, key in envelopeKeys do
        local fader = self.faders[key]
        fader.root.Position, fader.root.Size =
            UDim2.fromScale((index - 1) / 5, 0), UDim2.new(0.2, -3, 1, 0)
        fader.value.Position, fader.value.Size = UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 11)
        fader.title.Position, fader.title.Size = UDim2.new(0, 0, 1, -12), UDim2.new(1, 0, 0, 12)
        fader.title.TextSize, fader.value.TextSize = 10, 10
        fader.rail.Position, fader.rail.Size = UDim2.fromOffset(2, 12), UDim2.new(1, -4, 1, -25)
        fader.track.Position, fader.track.Size = UDim2.new(0.5, 0, 0, 5), UDim2.new(0, 4, 1, -10)
        fader.thumb.Size, fader.thumbInset = UDim2.fromOffset(24, 8), 5
    end
    local topHeight = math.max(22, math.min(44, math.floor(pageHeight * 0.45)))
    self.fxTop.Size = UDim2.new(1, 0, 0, topHeight)
    self.delayKnob.Visible, self.routing.Visible, self.fxReadout.Visible = false, false, false
    self.delay.root.Position, self.delay.root.Size = UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1)
    self.delay.title.Position, self.delay.title.Size =
        UDim2.fromOffset(0, 0), UDim2.fromOffset(52, topHeight)
    self.delay.title.Text, self.delay.title.TextSize = "DELAY", 10
    self.delay.value.Position, self.delay.value.Size =
        UDim2.fromOffset(52, 0), UDim2.fromOffset(56, topHeight)
    self.delay.value.TextSize = 11
    self.delay.rail.Position, self.delay.rail.Size =
        UDim2.fromOffset(116, 0), UDim2.new(1, -124, 1, 0)
    self.recipeHeader.Visible, self.recipePager.Visible = false, false
    self.recipePrevious.Visible, self.recipeNext.Visible = false, false
    local tileHeight = math.max(22, pageHeight - topHeight - 3)
    for index, tile in self.recipeTiles do
        tile.button.Position, tile.button.Size =
            UDim2.new((index - 1) / 4, 0, 0, topHeight + 3), UDim2.new(0.25, -3, 0, tileHeight)
        tile.button.ClipsDescendants = true
        for _, icon in { tile.icon, tile.lockedIcon } do
            icon.Size, icon.Position =
                UDim2.fromOffset(12, 12),
                UDim2.fromOffset(3, if tileHeight >= 34 then 5 else (tileHeight - 12) / 2)
        end
        tile.title.Position, tile.title.Size =
            UDim2.fromOffset(18, if tileHeight >= 34 then 3 else (tileHeight - 14) / 2),
            UDim2.new(1, -20, 0, 14)
        tile.hint.Position, tile.hint.Size = UDim2.fromOffset(3, 21), UDim2.new(1, -6, 0, 12)
        tile.hint.Visible = tileHeight >= 34
    end
    self.footer.Position, self.footer.Size =
        UDim2.fromOffset(4, footerY), UDim2.fromOffset(contentWidth, footerHeight)
    if self.mode == "FX" then
        self.dry.Position, self.dry.Size = UDim2.fromScale(0, 0), UDim2.new(0.21, -2, 1, 0)
        self.sync.Position, self.sync.Size = UDim2.fromScale(0.21, 0), UDim2.new(0.23, -2, 1, 0)
        self.reset.Position, self.reset.Size = UDim2.fromScale(0.44, 0), UDim2.new(0.19, -2, 1, 0)
        self.preview.Position, self.preview.Size =
            UDim2.fromScale(0.63, 0), UDim2.fromScale(0.37, 1)
    else
        self.reset.Position, self.reset.Size = UDim2.fromScale(0, 0), UDim2.new(0.3, -3, 1, 0)
        self.preview.Position, self.preview.Size =
            UDim2.fromScale(0.32, 0), UDim2.fromScale(0.68, 1)
    end
    self.previewArt.Size, self.previewArt.Position =
        UDim2.fromOffset(20, 20), UDim2.new(0, 3, 0.5, -10)
    self:draw()
end

function Editor:resize(width, height)
    if self.destroyed then
        return
    end
    width, height = math.max(1, width), math.max(1, height)
    self.width, self.height = width, height
    self.dense = height < 240
    if self.dense then
        self:resizeCompact(width, height)
        return
    end
    self.sourceInfo.Visible, self.trimSummary.Visible = true, true
    self.title.TextSize = 13
    self.delayKnob.Visible, self.routing.Visible, self.fxReadout.Visible = true, true, true
    self.delay.title.Text = names.delay
    self.recipeHeader.Visible, self.recipePager.Visible = true, true
    self.recipePrevious.Visible, self.recipeNext.Visible = true, true
    for _, fader in self.faders do
        fader.title.TextSize, fader.value.TextSize = 11, 12
    end
    for _, key in envelopeKeys do
        local fader = self.faders[key]
        fader.track.Position, fader.track.Size = UDim2.fromScale(0.5, 0), UDim2.new(0, 4, 1, 0)
        fader.thumb.Size, fader.thumbInset = UDim2.fromOffset(28, 12), nil
    end
    for _, tile in self.recipeTiles do
        for _, icon in { tile.icon, tile.lockedIcon } do
            icon.Size, icon.Position = UDim2.fromOffset(18, 18), UDim2.fromOffset(6, 8)
        end
        tile.title.Size = UDim2.new(1, -34, 0, 15)
        tile.hint.Position, tile.hint.Size = UDim2.fromOffset(30, 18), UDim2.new(1, -34, 0, 15)
    end
    self.previewArt.Size, self.previewArt.Position =
        UDim2.fromOffset(24, 24), UDim2.new(0, 4, 0.5, -12)
    local gap, contentWidth = 6, math.max(1, width - 12)
    local headerHeight = if height < 290 then 28 else 36
    local tabsHeight, footerHeight =
        if height < 290 then 24 else 28, if height < 290 then 26 else 32
    self.header.Position, self.header.Size =
        UDim2.fromOffset(gap, 0), UDim2.fromOffset(contentWidth, headerHeight)
    self.title.Position, self.title.Size =
        UDim2.fromOffset(0, 0), UDim2.new(1, -68, 0, headerHeight - 13)
    self.sourceInfo.Position, self.sourceInfo.Size =
        UDim2.fromOffset(0, headerHeight - 13), UDim2.new(1, -68, 0, 13)
    self.previous.Position, self.previous.Size =
        UDim2.new(1, -64, 0, 0), UDim2.fromOffset(28, headerHeight)
    self.next.Position, self.next.Size = UDim2.new(1, -28, 0, 0), UDim2.fromOffset(28, headerHeight)
    self.tabRow.Position, self.tabRow.Size =
        UDim2.fromOffset(gap, headerHeight + 4), UDim2.fromOffset(contentWidth, tabsHeight)
    for index, mode in modes do
        self.tabs[mode].Position, self.tabs[mode].Size =
            UDim2.fromScale((index - 1) / 3, 0), UDim2.new(1 / 3, -4, 1, 0)
    end
    local graphY = headerHeight + tabsHeight + 8
    local graphHeight =
        math.max(36, math.min(140, math.floor((height - graphY - footerHeight - 18) * 0.42)))
    if self.mode == "FX" then
        graphHeight = math.max(28, math.min(graphHeight, height - graphY - footerHeight - 118))
    end
    self.graph.Position, self.graph.Size =
        UDim2.fromOffset(gap, graphY), UDim2.fromOffset(contentWidth, graphHeight)
    self.graphWidth, self.graphHeight = contentWidth, graphHeight
    local pageY, pageHeight =
        graphY + graphHeight + 6, math.max(1, height - graphY - graphHeight - footerHeight - 18)
    for _, page in self.pages do
        page.Position, page.Size =
            UDim2.fromOffset(gap, pageY), UDim2.fromOffset(contentWidth, pageHeight)
    end
    for index, key in { "start", "finish" } do
        local fader = self.faders[key]
        fader.root.Position, fader.root.Size =
            UDim2.fromScale((index - 1) * 0.5, 0), UDim2.new(0.5, -6, 1, -22)
        fader.title.Position, fader.title.Size = UDim2.fromOffset(0, 0), UDim2.new(0.35, 0, 0, 20)
        fader.value.Position, fader.value.Size = UDim2.fromScale(0.35, 0), UDim2.new(0.65, 0, 0, 20)
        fader.rail.Position, fader.rail.Size = UDim2.fromOffset(10, 24), UDim2.new(1, -20, 1, -28)
    end
    self.trimSummary.Position, self.trimSummary.Size =
        UDim2.new(0, 0, 1, -18), UDim2.new(1, 0, 0, 18)
    for index, key in envelopeKeys do
        local fader = self.faders[key]
        fader.root.Position, fader.root.Size =
            UDim2.fromScale((index - 1) / 5, 0), UDim2.new(0.2, -4, 1, 0)
        fader.value.Position, fader.value.Size = UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 18)
        fader.title.Position, fader.title.Size = UDim2.new(0, 0, 1, -16), UDim2.new(1, 0, 0, 16)
        fader.rail.Position, fader.rail.Size = UDim2.fromOffset(2, 24), UDim2.new(1, -4, 1, -46)
    end
    local topHeight = if pageHeight < 150 then 34 else 52
    self.fxTop.Size = UDim2.new(1, 0, 0, topHeight)
    self.delayKnob.Position, self.delayKnob.Size = UDim2.fromOffset(2, 2), UDim2.fromOffset(28, 28)
    self.delay.root.Position, self.delay.root.Size =
        UDim2.fromOffset(36, 0), UDim2.new(0.52, -42, 1, 0)
    self.delay.title.Position, self.delay.title.Size =
        UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 14)
    self.delay.value.Position, self.delay.value.Size =
        UDim2.new(1, -58, 0, 0), UDim2.fromOffset(58, 14)
    self.delay.title.TextXAlignment = Enum.TextXAlignment.Left
    self.delay.rail.Position, self.delay.rail.Size =
        UDim2.fromOffset(8, 18), UDim2.new(1, -16, 1, -20)
    self.routing.Position, self.routing.Size = UDim2.fromScale(0.54, 0), UDim2.new(0.46, 0, 0, 14)
    self.fxReadout.Position, self.fxReadout.Size =
        UDim2.new(0.54, 0, 0, 16), UDim2.new(0.46, 0, 0, 16)
    self.recipeHeader.Position, self.recipeHeader.Size =
        UDim2.fromOffset(0, topHeight), UDim2.new(1, -128, 0, 18)
    self.recipePager.Position, self.recipePager.Size =
        UDim2.new(1, -128, 0, topHeight), UDim2.fromOffset(64, 18)
    self.recipePrevious.Position, self.recipePrevious.Size =
        UDim2.new(1, -58, 0, topHeight), UDim2.fromOffset(24, 18)
    self.recipeNext.Position, self.recipeNext.Size =
        UDim2.new(1, -26, 0, topHeight), UDim2.fromOffset(24, 18)
    local tileHeight = math.max(1, (pageHeight - topHeight - 24) / 2)
    for index, tile in self.recipeTiles do
        tile.button.Position = UDim2.new(
            (index - 1) % 2 * 0.5,
            0,
            0,
            topHeight + 22 + math.floor((index - 1) / 2) * (tileHeight + 3)
        )
        tile.button.Size = UDim2.new(0.5, -4, 0, tileHeight - 1)
        tile.button.ClipsDescendants = true
        tile.hint.Visible = tileHeight >= 34
        tile.title.Position =
            UDim2.fromOffset(30, if tileHeight >= 34 then 3 else math.max(0, (tileHeight - 16) / 2))
    end
    self.footer.Position, self.footer.Size =
        UDim2.fromOffset(gap, height - footerHeight - 4),
        UDim2.fromOffset(contentWidth, footerHeight)
    self.dry.Position, self.dry.Size = UDim2.fromScale(0, 0), UDim2.new(0.21, -4, 1, 0)
    self.sync.Position, self.sync.Size = UDim2.fromScale(0.21, 0), UDim2.new(0.23, -4, 1, 0)
    self.reset.Position, self.reset.Size = UDim2.fromScale(0.44, 0), UDim2.new(0.19, -4, 1, 0)
    self.preview.Position, self.preview.Size = UDim2.fromScale(0.63, 0), UDim2.fromScale(0.37, 1)
    self:draw()
end

function Editor:destroy(fromRoot)
    if self.destroyed then
        return
    end
    self.destroyed = true
    self.edit = nil
    Actions:UnbindAction(self.action)
    for _, connection in self.connections do
        connection:Disconnect()
    end
    table.clear(self.connections)
    if not fromRoot then
        self.root:Destroy()
    end
end

return Editor
