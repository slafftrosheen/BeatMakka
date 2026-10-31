local Input = game:GetService("UserInputService")
local Shared = game.ReplicatedStorage.Shared
local Theme = require(Shared.Theme)
local Sound = require(Shared.PadSound)
local Waves = require(Shared.SampleWaveforms)
local Catalog = require(Shared.SampleCatalog)
local Gui = require(script.Parent.GuiFactory)
local Recipes = require(Shared.QuayFxRecipes)
local Icons = require(script.Parent.GameIcons)
local Voice = require(script.Parent.CompanionVoice)
local Mix = require(script.Parent.AudioMix)
local Editor = {}
Editor.__index = Editor
local sections = {
    Tone = { "gain", "pitch", "start", "finish" },
    ADSR = { "attack", "decay", "sustain", "release", "gate" },
    FX = { "echo", "delay", "reverb", "tone", "drive" },
}
local labels = {
    gain = "LEVEL",
    pitch = "PITCH",
    start = "TRIM IN",
    finish = "TRIM OUT",
    attack = "ATTACK",
    decay = "DECAY",
    sustain = "SUSTAIN",
    release = "RELEASE",
    gate = "GATE",
    echo = "ECHO SEND",
    delay = "ECHO TIME",
    reverb = "ROOM SEND",
    tone = "WARM / BRIGHT",
    drive = "DRIVE",
}
function Editor.new(parent, change, audition, selectPad, preset)
    local self = setmetatable(
        { values = Sound.sanitize(nil), mode = "Tone", rows = {}, bars = {}, change = change },
        Editor
    )
    self.root = Gui.round(
        Gui.make("Frame", parent, {
            Name = "SampleSculptor",
            LayoutOrder = 0,
            Size = UDim2.new(1, -10, 0, 620),
            BackgroundColor3 = Theme.Ink,
            BorderSizePixel = 0,
        }),
        12
    )
    Gui.make("UIStroke", self.root, { Color = Theme.Amber, Thickness = 2 })
    self.title = Gui.label(self.root, "PAD 01 / SAMPLE STUDIO", 15, Theme.Cream)
    self.title.Position, self.title.Size = UDim2.fromOffset(12, 8), UDim2.new(1, -216, 0, 40)
    local preview = Gui.button(self.root, "Audition", function()
        Voice.Cue:Fire("silence")
        if self.pad and audition(self.pad, self.values) then
            self.auditionStarted = os.clock()
            self.auditionSettings = Sound.sanitize(self.values)
            local wave = Waves[self.sample]
            local duration = if wave
                then wave.duration
                    * (self.values.finish - self.values.start)
                    / 2 ^ (self.values.pitch / 12)
                else 4
            local _, finish = Sound.timing(self.values, duration)
            Mix.sampleAuditionUntil = os.clock() + finish + 1.2
            if self.lesson and self.lesson.phase == "audition" and self.lesson.pad == self.pad then
                self.lesson.phase = "listen"
                self.lesson.finishAt = Mix.sampleAuditionUntil
                self:drawLesson()
            end
        end
    end)
    self.usePad = Gui.button(self.root, "USE THIS PAD →", function()
        self:confirmLessonPad()
    end)
    self.usePad.Position, self.usePad.Size = UDim2.new(1, -156, 0, 86), UDim2.fromOffset(144, 44)
    self.usePad.Visible = false
    self.usePad.ZIndex = 6
    self.preview = preview
    self.previewGlow = Gui.make("UIStroke", preview, {
        Color = Theme.Amber,
        Thickness = 3,
        Enabled = false,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    preview.Name, preview.Position, preview.Size =
        "AuditionSample", UDim2.new(1, -104, 0, 4), UDim2.fromOffset(92, 44)
    for i, delta in { -1, 1 } do
        local nav = Gui.button(self.root, if delta < 0 then "‹" else "›", function()
            self.drag = nil
            selectPad(((self.pad or 1) - 1 + delta) % 64 + 1)
        end)
        nav.Name = if delta < 0 then "PreviousPad" else "NextPad"
        nav.Position, nav.Size = UDim2.new(1, -204 + (i - 1) * 48, 0, 4), UDim2.fromOffset(44, 44)
    end
    self.wave = Gui.round(
        Gui.make("Frame", self.root, {
            Name = "Waveform",
            Position = UDim2.fromOffset(12, 50),
            Size = UDim2.new(1, -24, 0, 82),
            BackgroundColor3 = Color3.fromRGB(19, 38, 38),
            ClipsDescendants = true,
        }),
        6
    )
    for i = 1, 64 do
        self.bars[i] = Gui.make("Frame", self.wave, {
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale((i - 1) / 64, 0.5),
            Size = UDim2.new(1 / 64, -1, 0, 2),
            BackgroundColor3 = Theme.FadedTeal,
        })
    end
    self.envelope = {}
    for i = 1, 64 do
        self.envelope[i] = Gui.make("Frame", self.wave, {
            Name = "Envelope",
            BorderSizePixel = 0,
            ZIndex = 3,
            Size = UDim2.new(1 / 64, 1, 0, 3),
            BackgroundColor3 = Theme.Coral,
        })
    end
    self.trimIn = Gui.make("Frame", self.wave, {
        Name = "TrimIn",
        Size = UDim2.new(0, 2, 1, 0),
        BackgroundColor3 = Theme.Amber,
        BorderSizePixel = 0,
    })
    self.trimOut = self.trimIn:Clone()
    self.trimOut.Name = "TrimOut"
    self.trimOut.Parent = self.wave
    self.playhead = Gui.make("Frame", self.wave, {
        Name = "PlaybackCursor",
        Size = UDim2.new(0, 2, 1, 0),
        BackgroundColor3 = Theme.Cream,
        BorderSizePixel = 0,
        ZIndex = 4,
        Visible = false,
    })
    self.playback = game:GetService("RunService").Heartbeat:Connect(function()
        if self.lesson then
            if not self.root.Parent.Visible then
                self.lesson = nil
                Voice.Cue:Fire("tutorial_cancel")
                self:drawLesson()
            elseif self.lesson.phase == "listen" and os.clock() >= self.lesson.finishAt then
                self.taught[self.lesson.id] = true
                self.lesson.phase = "done"
                Voice.Cue:Fire("fx_done")
                self:drawLesson()
            end
        end
        local at, wave = self.auditionStarted, self.sample and Waves[self.sample]
        if not at or not wave then
            if self.playhead.Visible then
                self.playhead.Visible = false
                preview.Text = "Audition"
            end
            return
        end
        local t, settings = os.clock() - at, self.auditionSettings
        local duration = wave.duration
            * (settings.finish - settings.start)
            / 2 ^ (settings.pitch / 12)
        local _, stop = Sound.timing(settings, duration)
        if t >= stop or not self.root.Parent.Visible then
            self.auditionStarted = nil
            self.playhead.Visible = false
            preview.Text = "Audition"
            return
        end
        preview.Text = "Playing"
        self.playhead.Visible = true
        self.playhead.Position =
            UDim2.fromScale(settings.start + t * 2 ^ (settings.pitch / 12) / wave.duration, 0)
    end)
    self.summary =
        Gui.label(self.root, "Original sample / non-destructive editing", 12, Theme.Cream)
    self.summary.Position, self.summary.Size = UDim2.fromOffset(12, 137), UDim2.new(1, -24, 0, 24)
    self.tabs = {}
    for i, mode in { "Tone", "ADSR", "FX" } do
        local button = Gui.button(self.root, mode, function()
            self.drag = nil
            self.mode = mode
            self:draw()
        end)
        button.Position, button.Size =
            UDim2.new((i - 1) / 3, 12, 0, 168), UDim2.new(1 / 3, -16, 0, 36)
        self.tabs[mode] = button
    end
    for key, spec in Sound.Spec do
        local row = Gui.make(
            "Frame",
            self.root,
            { Name = key, Size = UDim2.new(1, -24, 0, 42), BackgroundTransparency = 1 }
        )
        local name = Gui.label(row, labels[key], 12, Theme.Cream)
        name.Size = UDim2.fromScale(0.28, 1)
        local minus = Gui.button(row, "−", function()
            self:set(key, self.values[key] - spec[4], true)
        end)
        minus.Position, minus.Size = UDim2.new(0.28, 0, 0, 2), UDim2.fromOffset(36, 38)
        local plus = Gui.button(row, "+", function()
            self:set(key, self.values[key] + spec[4], true)
        end)
        plus.Position, plus.Size = UDim2.new(1, -36, 0, 2), UDim2.fromOffset(36, 38)
        local rail = Gui.make("TextButton", row, {
            Name = "Slider",
            Position = UDim2.new(0.28, 40, 0, 4),
            Size = UDim2.new(0.72, -80, 0, 34),
            Text = "",
            BackgroundColor3 = Theme.Teal,
            BorderSizePixel = 0,
            AutoButtonColor = false,
        })
        Gui.round(rail, 6)
        local fill = Gui.make("Frame", rail, {
            Size = UDim2.fromScale(0.5, 1),
            BackgroundColor3 = Theme.Amber,
            BorderSizePixel = 0,
            BackgroundTransparency = 0.15,
        })
        Gui.round(fill, 6)
        local value = Gui.label(rail, "", 13, Theme.Cream)
        value.BackgroundTransparency = 0.15
        value.BackgroundColor3 = Theme.Ink
        Gui.round(value, 5)
        value.AnchorPoint, value.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
        value.Size = UDim2.fromOffset(66, 26)
        value.TextXAlignment = Enum.TextXAlignment.Center
        rail.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                self.drag = { key = key, rail = rail, input = input }
                self:dragTo(input.Position.X)
            end
        end)
        self.rows[key] = { row = row, fill = fill, value = value }
    end
    self.presets = {}
    for i, entry in { { "dry", "Dry" }, { "dub", "Dotted echo" }, { "room", "Small room" } } do
        local b = Gui.button(self.root, entry[2], function()
            preset(entry[1])
        end)
        b.Name = "Preset_" .. entry[1]
        b.Position, b.Size = UDim2.new((i - 1) / 3, 12, 0, 442), UDim2.new(1 / 3, -16, 0, 44)
        self.presets[i] = b
    end
    self.dryAudition = Gui.button(self.root, "A / DRY", function()
        local dry = Sound.preset(self.values, "dry", self.bpm or 96)
        if self.pad and audition(self.pad, dry) then
            self.auditionStarted, self.auditionSettings = os.clock(), dry
        end
    end)
    self.dryAudition.Name = "AuditionDry"
    self.dryAudition.Position, self.dryAudition.Size =
        UDim2.fromOffset(12, 494), UDim2.new(0.5, -18, 0, 44)
    self.syncEcho = Gui.button(self.root, "SYNC / 1/2 BEAT", function()
        local values = { 0.25, 0.5, 0.75, 1 }
        self.syncIndex = (self.syncIndex or 1) % #values + 1
        local beats = values[self.syncIndex]
        self:set("delay", math.clamp(60 / (self.bpm or 96) * beats, 0.05, 1), true)
        self.syncEcho.Text = "SYNC / " .. ({ "1/4", "1/2", "3/4", "1" })[self.syncIndex] .. " BEAT"
    end)
    self.syncEcho.Name = "SyncEcho"
    self.syncEcho.Position, self.syncEcho.Size =
        UDim2.new(0.5, 6, 0, 494), UDim2.new(0.5, -18, 0, 44)
    local reset = Gui.button(self.root, "Reset sound edits", function()
        preset("reset")
    end)
    reset.Name = "ResetSoundEdits"
    reset.Position, reset.Size = UDim2.new(0, 12, 1, -50), UDim2.new(1, -24, 0, 40)
    self.moved = Input.InputChanged:Connect(function(input)
        if
            self.drag
            and (
                input == self.drag.input
                or input.UserInputType == Enum.UserInputType.MouseMovement
            )
        then
            self:dragTo(input.Position.X)
        end
    end)
    self.ended = Input.InputEnded:Connect(function(input)
        if
            self.drag
            and (input == self.drag.input or input.UserInputType == Enum.UserInputType.MouseButton1)
        then
            local key = self.drag.key
            self.drag = nil
            self.change(key, self.values[key])
        end
    end)
    self.recipePanel = Gui.round(
        Gui.make("Frame", parent, {
            Name = "DiscoveredFX",
            LayoutOrder = 1,
            Size = UDim2.new(1, -10, 0, 358),
            BackgroundColor3 = Theme.Ink,
            BorderSizePixel = 0,
        }),
        12
    )
    local heading = Gui.label(
        self.recipePanel,
        "DISCOVERED FX / SELECT PAD → APPLY → AUDITION",
        12,
        Theme.Amber
    )
    heading.Position, heading.Size = UDim2.fromOffset(12, 4), UDim2.new(1, -24, 0, 34)
    self.taught = {}
    self.lessonButton = Gui.button(self.recipePanel, "SHOW ME / LEARN AN EARNED FX", function()
        if not self.lesson or self.lesson.phase == "done" then
            local chosen
            for _, item in Recipes.List do
                if Recipes.earned(self.progress, item) then
                    chosen = chosen or item
                    if not self.taught[item.id] then
                        chosen = item
                        break
                    end
                end
            end
            if not chosen then
                return
            end
            self.lesson = { id = chosen.id, phase = "select", pad = self.pad }
            self.mode = "FX"
            self:draw()
            Voice.Cue:Fire("fx_select")
            parent.CanvasPosition = Vector2.zero
        elseif self.lesson.phase == "select" then
            self.lesson.pad = self.pad
            self.lesson.phase = "apply"
            Voice.Cue:Fire("fx_apply")
        elseif self.lesson.phase == "apply" then
            Voice.Cue:Fire("fx_apply")
        elseif self.lesson.phase == "audition" then
            parent.CanvasPosition = Vector2.zero
            Voice.Cue:Fire("fx_audition")
        end
        self:drawLesson()
    end)
    self.lessonButton.Position, self.lessonButton.Size =
        UDim2.fromOffset(12, 42), UDim2.new(1, -64, 0, 58)
    local cancelLesson = Gui.button(self.recipePanel, "×", function()
        self.lesson = nil
        Voice.Cue:Fire("tutorial_cancel")
        self:drawLesson()
    end)
    cancelLesson.Position, cancelLesson.Size = UDim2.new(1, -48, 0, 48), UDim2.fromOffset(36, 44)
    self.recipeRows = {}
    for i, item in Recipes.List do
        local row = Gui.make("Frame", self.recipePanel, {
            Position = UDim2.fromOffset(10, 112 + (i - 1) * 60),
            Size = UDim2.new(1, -20, 0, 54),
            BackgroundColor3 = Theme.Graphite,
            BorderSizePixel = 0,
        })
        Icons.make(row, item.icon, Theme.Amber, 26).Position = UDim2.fromOffset(6, 13)
        local label = Gui.label(row, item.label, 12, Theme.Cream)
        label.Position, label.Size = UDim2.fromOffset(40, 3), UDim2.new(1, -142, 0, 23)
        local hint = Gui.label(row, item.hint, 11, Theme.FadedTeal)
        hint.Position, hint.Size = UDim2.fromOffset(40, 27), UDim2.new(1, -142, 0, 24)
        local button = Gui.button(row, "LOCKED", function()
            if Recipes.earned(self.progress, item) then
                if self.lesson and self.lesson.id == item.id and self.lesson.phase == "apply" then
                    self.lesson.phase = "confirm"
                    self:drawLesson()
                end
                preset(item.id)
            end
        end)
        button.Position, button.Size = UDim2.new(1, -90, 0, 5), UDim2.fromOffset(84, 44)
        local glow = Gui.make("UIStroke", button, {
            Color = Theme.Amber,
            Thickness = 3,
            Enabled = false,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
        self.recipeRows[item.id] = { button = button, hint = hint, glow = glow }
    end
    self:draw()
    return self
end
function Editor:confirmLessonPad()
    if not self.lesson or self.lesson.phase ~= "select" then
        return
    end
    self.lesson.pad = self.pad
    self.lesson.phase = "apply"
    Voice.Cue:Fire("fx_apply")
    local parent = self.root.Parent
    parent.CanvasPosition = Vector2.new(
        0,
        math.max(
            0,
            self.recipePanel.AbsolutePosition.Y
                - parent.AbsolutePosition.Y
                + parent.CanvasPosition.Y
                - 8
        )
    )
    self:drawLesson()
end
function Editor:drawLesson()
    self.usePad.Visible = self.lesson ~= nil and self.lesson.phase == "select"
    for id, row in self.recipeRows or {} do
        row.glow.Enabled = self.lesson ~= nil
            and self.lesson.id == id
            and self.lesson.phase == "apply"
    end
    self.previewGlow.Enabled = self.lesson ~= nil and self.lesson.phase == "audition"
    if not self.lessonButton then
        return
    end
    local lesson = self.lesson
    self.lessonButton.Text = if not lesson
        then "SHOW ME / LEARN AN EARNED FX"
        elseif lesson.phase == "select" then string.format(
            "1  SELECT PAD / USE PAD %02d →",
            self.pad
        )
        elseif lesson.phase == "apply" then "2  APPLY " .. Recipes.find(lesson.id).label
        elseif lesson.phase == "confirm" then "WAITING FOR PAD SETTINGS"
        elseif lesson.phase == "audition" then "3  AUDITION ↑ / HEAR YOUR FX"
        elseif lesson.phase == "listen" then "LISTENING…"
        else "✓ FX LEARNED / SAVE YOUR BEAT"
end
function Editor:dragTo(x)
    local d = self.drag
    local spec = Sound.Spec[d.key]
    local fraction =
        math.clamp((x - d.rail.AbsolutePosition.X) / math.max(1, d.rail.AbsoluteSize.X), 0, 1)
    self:set(
        d.key,
        math.round((spec[1] + fraction * (spec[2] - spec[1])) / spec[4]) * spec[4],
        false
    )
end
function Editor:set(key, value, commit)
    self.values[key] = value
    self.values = Sound.sanitize(self.values)
    self:draw()
    if commit then
        self.change(key, self.values[key])
    end
end
function Editor:draw()
    self.dryAudition.Visible, self.syncEcho.Visible = self.mode == "FX", self.mode == "FX"
    for _, b in self.presets do
        b.Visible = self.mode == "FX"
    end
    for mode, tab in self.tabs do
        tab.BackgroundColor3 = if mode == self.mode then Theme.Coral else Theme.Teal
    end
    for _, row in self.rows do
        row.row.Visible = false
    end
    for i, key in sections[self.mode] do
        local row, spec = self.rows[key], Sound.Spec[key]
        row.row.Visible = true
        row.row.Position = UDim2.fromOffset(12, 212 + (i - 1) * 44)
        row.fill.Size = UDim2.fromScale((self.values[key] - spec[1]) / (spec[2] - spec[1]), 1)
        row.value.Text = if key == "pitch"
            then string.format("%+d st", self.values[key])
            elseif
                key == "attack"
                or key == "decay"
                or key == "release"
                or key == "delay"
            then string.format("%.2f s", self.values[key])
            else string.format("%.0f%%", self.values[key] * 100)
    end
    self.trimIn.Position = UDim2.fromScale(self.values.start, 0)
    self.trimOut.Position = UDim2.new(self.values.finish, -2, 0, 0)
    local wave = self.sample and Waves[self.sample]
    local duration = if wave
        then wave.duration * (self.values.finish - self.values.start) / 2 ^ (self.values.pitch / 12)
        else 1
    for i, dot in self.envelope do
        dot.Visible = self.mode == "ADSR"
        dot.Size = UDim2.new((self.values.finish - self.values.start) / 64, 1, 0, 3)
        dot.Position = UDim2.fromScale(
            self.values.start + (i - 1) / 64 * (self.values.finish - self.values.start),
            0.95 - 0.9 * Sound.envelope(self.values, duration, duration * (i - 1) / 63)
        )
    end
    for i, bar in self.bars do
        bar.Size =
            UDim2.new(1 / 64, -1, math.max(0.02, if wave then wave.peaks[i] * 0.9 else 0.02), 0)
        bar.BackgroundColor3 = if i / 64 >= self.values.start
                and (i - 1) / 64 <= self.values.finish
            then Theme.Amber
            else Theme.Teal
    end
    self.summary.Text = if wave
        then string.format(
            "%.2fs source  /  %.2fs slice  /  %.2fx speed",
            wave.duration,
            (self.values.finish - self.values.start) * wave.duration,
            2 ^ (self.values.pitch / 12)
        )
        else "Waveform unavailable for this source"
end
function Editor:update(state, pad)
    if not state or not state.pattern then
        self.lesson = nil
        self.drag = nil
        return
    end
    self.bpm = state.pattern and state.pattern.bpm or 96
    if self.lesson then
        if not state.station then
            self.lesson = nil
            Voice.Cue:Fire("tutorial_cancel")
        elseif self.lesson.pad ~= pad and self.lesson.phase ~= "select" then
            self.lesson = { id = self.lesson.id, phase = "select", pad = pad }
            Voice.Cue:Fire("tutorial_cancel")
        elseif self.lesson.phase == "confirm" then
            local expected = Recipes.apply(
                state.quay and state.quay.progress,
                state.pattern.sounds[pad],
                self.lesson.id,
                state.pattern.bpm
            )
            local raw = state.pattern.sounds[pad]
            if
                expected
                and math.abs(raw.echo - expected.echo) < 0.001
                and math.abs(raw.reverb - expected.reverb) < 0.001
                and math.abs(raw.delay - expected.delay) < 0.001
            then
                self.lesson.phase = "audition"
                Voice.Cue:Fire("fx_audition")
                self.root.Parent.CanvasPosition = Vector2.zero
            end
        end
    end
    self.progress = state.quay and state.quay.progress
    for _, item in Recipes.List do
        local row = self.recipeRows[item.id]
        local earned = Recipes.earned(self.progress, item)
        row.button.Text = if earned then "APPLY" else "LOCKED"
        row.button.Active, row.button.Selectable, row.button.AutoButtonColor =
            earned, earned, earned
        row.button.BackgroundColor3 = if earned then Theme.Teal else Theme.Graphite
        row.hint.Text = if earned then "READY / PAD " .. string.format("%02d", pad) else item.hint
    end
    if self.pad ~= pad or not state.station then
        self.auditionStarted = nil
        self.drag = nil
    end
    self.pad = pad
    self:drawLesson()
    if not state.pattern then
        return
    end
    local sample = state.pattern.assignments[pad]
    local raw = state.pattern.sounds and state.pattern.sounds[pad]
    if
        self.sample == sample
        and self.lastPad == pad
        and Sound.same(self.values, raw)
        and not self.drag
    then
        return
    end
    self.lastPad = pad
    self.sample = sample
    if not self.drag then
        self.values = Sound.sanitize(state.pattern.sounds and state.pattern.sounds[pad])
    end
    local definition = Catalog.ById[self.sample] or Catalog.RetiredById[self.sample]
    self.title.Text = string.format(
        "%s%02d / %s",
        string.char(65 + math.floor((pad - 1) / 16)),
        (pad - 1) % 16 + 1,
        if definition then definition.label else "Unavailable source"
    )
    self:draw()
end
function Editor:destroy()
    self.playback:Disconnect()
    self.moved:Disconnect()
    self.ended:Disconnect()
    self.recipePanel:Destroy()
    self.root:Destroy()
end
return Editor
