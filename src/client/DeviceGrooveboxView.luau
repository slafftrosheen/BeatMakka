-- Fixed instrument surfaces. State changes rebind values, never rebuild controls.
local W = require(script.Parent.DeviceWidgets)
local Skin = require(script.Parent.DeviceSkin)
local Pads = require(script.Parent.PadInput)
local PadControls = require(script.Parent.DevicePadControls)
local Shared = game.ReplicatedStorage.Shared
local Catalog = require(Shared.SampleCatalog)
local Transport = require(Shared.MusicTransport)
local Input = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local View = {}
View.__index = View
local keys = require(Shared.SamplerPadLayout).KeyboardKeys
local names =
    { Sequence = "SEQ", Song = "SONG", Sounds = "SOUND", Library = "CRATES", Settings = "SETUP" }
local icons =
    { Sequence = "steps", Song = "disc", Sounds = "sound", Library = "library", Settings = "knob" }
local legends = {
    A = {
        "MAIN KICK",
        "DROP KICK",
        "FAST KICK",
        "GHOST KICK",
        "MAIN SNARE",
        "SNARE ROLL",
        "RIMSHOT",
        "CRACK SNARE",
        "HAT 1",
        "HAT 2",
        "OPEN HAT",
        "SHAKER",
        "DOCK 1",
        "DOCK 2",
        "CLANK",
        "BREAK FILL",
    },
    B = {
        "DROP SUB",
        "808 PULSE",
        "WARM SUB",
        "DEEP SUB",
        "GROWL",
        "REESE BITE",
        "PITCH DIVE",
        "REESE BARK",
        "FOGHORN",
        "STUTTER",
        "REESE HIT",
        "WOBBLE",
        "STAB 1",
        "STAB 2",
        "GLIDE",
        "BASS TAIL",
    },
    D = {
        "BELL D5",
        "BELL F5",
        "BELL A5",
        "BELL D6",
        "Dm CHORD",
        "PAD SWELL",
        "SYNTH LICK",
        "BELL MELODY",
        "CABLE ZING",
        "STEAM",
        "FOGHORN",
        "VINYL",
        "RISER",
        "METAL PIPE",
        "TAPE ECHO",
        "DROP BOOM",
    },
}
local function attr(object, name, value)
    if object:GetAttribute(name) ~= value then
        object:SetAttribute(name, value)
    end
end
local function routeChanged(a, b)
    local x, y = a and a.music, b and b.music
    return a
        and (
            a.station ~= b.station
            or not x
            or not y
            or x.projectId ~= y.projectId
            or x.trackId ~= y.trackId
            or x.sequenceId ~= y.sequenceId
            or x.bank ~= y.bank
            or x.program.id ~= y.program.id
        )
end
function View.new(callbacks)
    local self = setmetatable({
        callbacks = callbacks,
        selectedPad = 1,
        page = "Sequence",
        pads = {},
        bankButtons = {},
        transportButtons = {},
        heldContexts = {},
        effects = true,
        connections = {},
        menuIndex = 1,
    }, View)
    self.screen = W.make("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"), {
        Name = "NeedleQuayInstrument",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        DisplayOrder = 10,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    self.panel = W.frame(self.screen, "Workstation")
    self.panel.Visible = false
    Skin.panel(self.panel, "device")
    self.panel:SetAttribute("DeviceUiRevision", 4)
    self.hardware = require(script.Parent.HardwareFaceplate).new(self.panel, function(...)
        self:command(...)
    end, function()
        return self.state
    end)
    for _, v in self.panel:GetChildren() do
        if v.Name == "EnamelFaceplate" or v.Name == "WalnutCheek" or v.Name == "CaseScrew" then
            v:Destroy()
        end
    end
    self.body = W.frame(self.panel, "DeviceBody")
    self.performanceDeck = W.frame(self.body, "PerformanceDeck")
    attr(self.performanceDeck, "PersistentDeck", true)
    self.editorDeck = W.frame(self.body, "EditorDeck")
    Skin.image(self.editorDeck, "bezel-v4", {
        Name = "DisplayBezel",
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(80, 80, 944, 602),
        SliceScale = 0.28,
        ZIndex = 0,
    })
    self.bankRow = W.frame(self.performanceDeck, "SoundBanks")
    for i = 1, 4 do
        local b = W.key(
            self.bankRow,
            "Bank" .. string.char(64 + i),
            ({ "drum", "bass", "mic", "waves" })[i],
            ({ "DRUMS", "BASS", "VOX", "QUAY" })[i],
            function()
                self:command("Bank", i)
            end
        )
        attr(b, "Bank", i)
        self.bankButtons[i] = b
    end
    self.padGrid = W.frame(self.performanceDeck, "PhysicalPads")
    attr(self.padGrid, "PadCount", 16)
    attr(self.padGrid, "GridOrder", "row-major-top-left")
    self.padInput = Pads.new(function(pad)
        local context = callbacks.noteContext and callbacks.noteContext(pad)
        self.heldContexts[pad] = { context = context, nextAt = os.clock() }
        return callbacks.tap(pad, context)
    end, function(pad, held)
        if math.floor((pad - 1) / 16) + 1 == self:bank() then
            Skin.setPadDown(self.pads[(pad - 1) % 16 + 1], held)
        end
        if not held then
            self.heldContexts[pad] = nil
        end
    end)
    for i = 1, 16 do
        local button = W.make("TextButton", self.padGrid, {
            Name = string.format("Pad%02d", i),
            Text = "",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Selectable = true,
            AutoButtonColor = false,
        })
        attr(button, "PhysicalPad", i)
        attr(button, "Address", string.format("A%02d", i))
        attr(button, "PadKey", keys[i])
        Skin.pad(button)
        self.pads[i] = button
        button.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                self:beginPad(i, input)
            end
        end)
        button.InputEnded:Connect(function(input)
            self.padInput:finish(input)
        end)
    end
    self.padControls = PadControls.new(self.performanceDeck, {
        state = function()
            return self.state
        end,
        absolutePad = function()
            return self:absolutePad()
        end,
        command = function(...)
            self:command(...)
        end,
        visible = function()
            return self.panel.Visible and not self:hasModal()
        end,
    })
    self.transportRow = W.frame(self.performanceDeck, "PerformanceTransport")
    for _, item in
        {
            { "Play", "play", "PLAY" },
            { "Stop", "stop", "STOP" },
            { "Record", "record", "REC" },
            { "Overdub", "record", "DUB" },
        }
    do
        local action = item[1]
        self.transportButtons[action] = W.key(
            self.transportRow,
            "Transport_" .. action,
            item[2],
            item[3],
            function()
                self:command(action)
            end
        )
    end
    self.navigation = W.frame(self.editorDeck, "Navigation")
    self.tabs = {}
    for _, name in { "Sequence", "Song", "Sounds", "Library", "Settings" } do
        self.tabs[name] = W.key(self.navigation, name, icons[name], names[name], function()
            self:showPage(name)
        end)
    end
    self.viewport = W.frame(self.editorDeck, "DeviceScreen")
    self.pages = {}
    for _, name in { "Sequence", "Song", "Sounds", "Library", "Settings" } do
        local page = W.frame(self.viewport, name)
        page.Size = UDim2.fromScale(1, 1)
        page.Visible = name == self.page
        self.pages[name] = page
    end
    self.sequenceScreen = require(script.Parent.DeviceSequencerScreen).new(self.pages.Sequence, {
        command = function(...)
            self:command(...)
        end,
        selectPad = function(pad)
            self:selectPad(pad)
        end,
    })
    self.songScreen = require(script.Parent.DeviceSongScreen).new(self.pages.Song, {
        command = function(...)
            self:command(...)
        end,
        page = function(name)
            self:showPage(name)
        end,
        namePrompt = function(...)
            self:namePrompt(...)
        end,
    })
    self.libraryScreen = require(script.Parent.DeviceLibraryScreen).new(self.pages.Library, {
        command = function(...)
            self:command(...)
        end,
        page = function(name)
            self:showPage(name)
        end,
    })
    self.sampleEditor = require(script.Parent.DeviceSoundScreen).new(
        self.pages.Sounds,
        function(key, value)
            self:command("PadSound", self:absolutePad(), { key = key, value = value })
        end,
        function(pad, settings)
            return callbacks.preview(pad, settings)
        end,
        function(pad)
            self:command("Bank", math.floor((pad - 1) / 16) + 1)
            self:selectPad((pad - 1) % 16 + 1)
        end,
        function(name)
            self:command("PadPreset", self:absolutePad(), name)
        end
    )
    self.footer = W.frame(self.editorDeck, "SoftKeys")
    self.softKeys = {}
    for i = 1, 6 do
        self.softKeys[i] = W.key(self.footer, "SoftKey" .. i, "plus", "", function()
            local item = self.actions and self.actions[i]
            if item then
                item.run()
            end
        end)
    end
    self.settingsKeys = {}
    for i = 1, 6 do
        self.settingsKeys[i] = W.key(
            self.pages.Settings,
            "Option" .. i,
            ({ "sound", "waves", "record", "pads", "steps", "lamp" })[i],
            "",
            function()
                self:setting(i)
            end
        )
    end
    self.settingsTitle = W.label(self.pages.Settings, "SettingsTitle", "MAKE IT YOURS", 17, W.amber)
    self.audioStatus = W.label(self.pages.Settings, "AudioStatus", "LOADING SOUNDS", 12)
    self.appearanceStatus = W.label(self.pages.Settings, "AppearanceStatus", "", 11)
    self.settingHint =
        W.label(self.pages.Settings, "InputHint", "PADS = SOUND / SPACE = PLAY / T = RECORD", 11)
    self.noticeLabel = W.label(
        self.panel,
        "Notice",
        "TAP A PAD. MAKE A RHYTHM.",
        12,
        Color3.fromRGB(239, 223, 184)
    )
    self.exit = W.key(self.panel, "BackToQuay", "city", "QUAY", function()
        self:cancelInput(true)
        self:command("Release")
    end)
    self.menu = W.frame(self.editorDeck, "ToolsOverlay", Color3.fromRGB(17, 38, 32))
    self.menu.ZIndex = 20
    self.menu.Visible = false
    self.menuTitle = W.label(self.menu, "Title", "TOOLS", 17, W.amber)
    self.menuButtons = {}
    for i = 1, 6 do
        self.menuButtons[i] = W.key(self.menu, "Tool" .. i, "plus", "", function()
            local item = self.menuItems and self.menuItems[(self.menuIndex - 1) * 6 + i]
            if item then
                item.run()
            end
        end)
    end
    self.menuPrev = W.key(self.menu, "PreviousTools", "undo", "BACK", function()
        self.menuIndex = math.max(1, self.menuIndex - 1)
        self:paintMenu()
    end)
    self.menuNext = W.key(self.menu, "NextTools", "redo", "MORE", function()
        self.menuIndex = math.min(math.ceil(#self.menuItems / 6), self.menuIndex + 1)
        self:paintMenu()
    end)
    self.menuClose = W.key(self.menu, "CloseTools", "close", "CLOSE", function()
        self:closeModal()
    end)
    self.prompt = W.frame(self.editorDeck, "NameOverlay", Color3.fromRGB(17, 38, 32))
    self.prompt.ZIndex = 22
    self.prompt.Visible = false
    self.promptTitle = W.label(self.prompt, "Title", "NAME", 17, W.amber)
    self.nameBox = W.make("TextBox", self.prompt, {
        Name = "NameField",
        Text = "",
        Font = Enum.Font.Code,
        TextSize = 18,
        TextColor3 = W.text,
        PlaceholderColor3 = Color3.fromRGB(95, 126, 102),
        BackgroundColor3 = Color3.fromRGB(25, 48, 39),
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
    })
    self.promptSave = W.key(self.prompt, "ConfirmName", "check", "KEEP", function()
        self:submitName()
    end)
    self.promptCancel = W.key(self.prompt, "CancelName", "close", "BACK", function()
        self.prompt.Visible = false
    end)
    self.nameBox.FocusLost:Connect(function(enter)
        if enter and self.prompt.Visible then
            self:submitName()
        end
    end)
    table.insert(
        self.connections,
        Input.InputEnded:Connect(function(input)
            self.padInput:finish(input)
        end)
    )
    table.insert(
        self.connections,
        self.panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            self:resizeDevice()
        end)
    )
    table.insert(
        self.connections,
        self.screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            self:resizeDevice()
        end)
    )
    for _, component in { self.songScreen, self.libraryScreen } do
        if component.popup then
            component.popup.Active = true
            table.insert(
                self.connections,
                component.popup:GetPropertyChangedSignal("Visible"):Connect(function()
                    if component.popup.Visible then
                        self:cancelInput(false)
                    end
                end)
            )
        end
    end
    self.menu.Active, self.prompt.Active = true, true
    table.insert(
        self.connections,
        self.panel:GetPropertyChangedSignal("Visible"):Connect(function()
            if not self.panel.Visible then
                self:cancelInput(false)
            end
        end)
    )
    table.insert(
        self.connections,
        Run.Heartbeat:Connect(function()
            if self.dead or not self.panel.Visible then
                return
            end
            local m = self.state and self.state.music
            if m and m.noteRepeat then
                local interval = (if m.timingCorrect > 0 then m.timingCorrect else 240)
                    / 960
                    * 60
                    / m.sequence.bpm
                for pad, held in self.heldContexts do
                    if os.clock() - held.nextAt >= interval then
                        held.nextAt = os.clock()
                        -- Keep a held repeat on its captured route while allowing
                        -- acknowledged live instrument edits on subsequent hits.
                        local current = callbacks.noteContext and callbacks.noteContext(pad)
                        callbacks.tap(
                            pad,
                            if current
                                    and held.context
                                    and current.route == held.context.route
                                then current
                                else held.context
                        )
                        self:pulsePad(pad)
                    end
                end
            end
            self:tick()
        end)
    )
    self.panel.Destroying:Connect(function()
        self.dead = true
        for _, c in self.connections do
            c:Disconnect()
        end
        self.padInput:destroy()
        self.padControls:destroy()
    end)
    self:resizeDevice()
    self:showPage("Sequence")
    task.defer(function()
        if self.screen.Parent then
            self:resizeDevice()
        end
    end)
    return self
end
function View:bank()
    return self.requestedBank or self.state and self.state.music and self.state.music.bank or 1
end
function View:absolutePad()
    return (self:bank() - 1) * 16 + self.selectedPad
end
function View:hasModal()
    return self.menu.Visible
        or self.prompt.Visible
        or (self.songScreen.popup and self.songScreen.popup.Visible)
        or (self.libraryScreen.popup and self.libraryScreen.popup.Visible)
end
function View:closeModal()
    self.menu.Visible, self.prompt.Visible = false, false
    if self.songScreen.popup then
        self.songScreen.popup.Visible = false
    end
    if self.libraryScreen.popup then
        self.libraryScreen.popup.Visible = false
    end
end
function View:command(action, a, b)
    if not self.state or not self.state.ready then
        return
    end
    if action == "Bank" then
        self:cancelInput(false)
        self.requestedBank = a
        self:paintPads()
        self:updateSelection()
    elseif
        action == "Stop"
        or action == "ClearPad"
        or action == "SequenceClear"
        or action == "SequenceDelete"
        or action == "SongDelete"
    then
        self:cancelInput(false)
        self:clearFlashes()
        if action == "SequenceDelete" then
            -- Even a protected last/used section must not keep sounding after
            -- the player presses Delete. The server still validates deletion.
            self.callbacks.command("Stop")
        end
    end
    self.callbacks.command(action, a, b)
end
function View:beginPad(pad, token)
    if
        not self.panel.Visible
        or self:hasModal()
        or not self.state
        or not self.state.ready
        or not self.state.music
    then
        return false
    end
    if pad ~= self.selectedPad then
        self.padControls:cancel()
    end
    self.selectedPad = pad
    -- Submit sound before any visual binding work.
    local submitted = self.padInput:begin(self:absolutePad(), token)
    self:paintPads()
    self:updateSelection()
    if Run:IsStudio() then
        local diagnostic = self.padInput:diagnostics()
        attr(self.panel, "InputHits", diagnostic.hits)
        attr(self.panel, "InputSubmitted", diagnostic.submitted)
        attr(self.panel, "InputP95Ms", diagnostic.p95Ms)
        attr(self.panel, "InputMaxMs", diagnostic.maxMs)
        attr(self.panel, "LastInputPad", self:absolutePad())
    end
    return submitted
end
function View:selectPad(pad)
    if type(pad) ~= "number" or pad < 1 or pad > 16 then
        return
    end
    if self.selectedPad ~= pad then
        self.padControls:cancel()
        self.selectedPad = pad
        self:paintPads()
        self:updateSelection()
    end
end
function View:cancelInput(interrupted)
    self.padInput:cancel()
    self.padControls:cancel()
    if self.sampleEditor then
        self.sampleEditor:cancel()
    end
    table.clear(self.heldContexts)
    if interrupted and self.callbacks.interrupt then
        self.callbacks.interrupt()
    end
end
function View:clearFlashes()
    for _, pad in self.pads do
        attr(pad, "PadFlash", false)
        attr(pad, "PulseEpoch", (pad:GetAttribute("PulseEpoch") or 0) + 1)
    end
end
function View:pulsePad(pad, route)
    local m = self.state and self.state.music
    if
        not m
        or not self.panel.Visible
        or not pad
        or math.floor((pad - 1) / 16) + 1 ~= self:bank()
    then
        return
    end
    if
        route
        and (
            route.projectId ~= m.projectId
            or route.trackId ~= m.trackId
            or route.programId ~= m.program.id
        )
    then
        return
    end
    Skin.pulse(self.pads[(pad - 1) % 16 + 1])
end
function View:paintPads()
    local s = self.state
    if not s or not s.pattern then
        return
    end
    local bank = self:bank()
    for i, b in self.pads do
        local absolute = (bank - 1) * 16 + i
        local id = s.pattern.assignments[absolute]
        local sample = Catalog.ById[id] or Catalog.RetiredById[id]
        attr(b, "AbsolutePad", absolute)
        attr(b, "Address", string.format("%s%02d", string.char(64 + bank), i))
        attr(b, "PadSelected", i == self.selectedPad)
        attr(b, "SampleName", sample and sample.label or "NO SOUND")
        attr(
            b,
            "ShortName",
            sample and (legends[sample.bank] and legends[sample.bank][sample.pad] or sample.label)
                or "NO SOUND"
        )
        attr(b, "SoundFamily", sample and sample.bank)
        attr(
            b,
            "AudioReady",
            Catalog.isPlaybackReady(id, s.unlocked)
                and (not self.callbacks.sampleReady or self.callbacks.sampleReady(id))
        )
        attr(b, "AudioApproved", Catalog.isReady(id, s.unlocked))
        attr(b, "PreviewAvailable", Catalog.isPreviewAvailable(id, s.unlocked))
        attr(b, "PadMuted", s.pattern.muted[absolute] == true)
    end
    for i, b in self.bankButtons do
        attr(b, "Selected", i == bank)
    end
end
function View:updateSelection()
    if not self.state or not self.state.music then
        return
    end
    self.padControls:update(self.state, self:absolutePad())
    if self.page == "Sequence" then
        self.sequenceScreen:update(self.state, self:absolutePad())
    elseif self.page == "Sounds" then
        self.sampleEditor:update(self.state, self:absolutePad())
    end
end
function View:notice(text)
    if text and text ~= "" then
        W.set(
            self.noticeLabel,
            "Text",
            Catalog.localDiscoveryText and Catalog.localDiscoveryText(text) or text
        )
    end
end
function View:setMuted(value)
    self.muted = value == true
    self.callbacks.mute(self.muted)
    self:paintSettings()
end
function View:update(state)
    local old = self.state
    if routeChanged(old, state) then
        self:cancelInput(false)
    end
    local oldt = old and old.music and old.music.transport
    local newt = state.music and state.music.transport
    if oldt and (not newt or oldt.epoch ~= newt.epoch) then
        self.padInput:cancel()
        table.clear(self.heldContexts)
        self:clearFlashes()
    end
    if old and old.playing and not state.playing then
        self:cancelInput(false)
        self:clearFlashes()
    end
    self.state = state
    if self.requestedBank and state.music and state.music.bank == self.requestedBank then
        self.requestedBank = nil
    end
    self.panel.Visible = state.ready and state.station ~= nil and state.music ~= nil
    if not self.panel.Visible then
        self:cancelInput(false)
        return
    end
    self:paintPads()
    self:updateSelection()
    if self.page == "Song" then
        self.songScreen:update(state)
    elseif self.page == "Library" then
        self.libraryScreen:update(state)
    elseif self.page == "Settings" then
        self:paintSettings()
    end
    attr(self.transportButtons.Play, "Selected", state.playing == true)
    W.legend(self.transportButtons.Play, if state.playing then "PAUSE" else "PLAY")
    attr(self.transportButtons.Record, "Selected", state.recording == true)
    self.hardware:update(state, self:absolutePad())
    if state.notice then
        self:notice(state.notice)
    end
    self:bindSoftKeys()
end
function View:showPage(name)
    if not self.pages[name] then
        return
    end
    self.page = name
    self:closeModal()
    for page, frame in self.pages do
        frame.Visible = page == name
        attr(self.tabs[page], "Selected", page == name)
    end
    attr(self.editorDeck, "ActivePage", name)
    if self.state then
        self:updateSelection()
        if name == "Song" then
            self.songScreen:update(self.state)
        elseif name == "Library" then
            self.libraryScreen:update(self.state)
        elseif name == "Settings" then
            self:paintSettings()
        end
    end
    self:bindSoftKeys()
    self:resizeDevice()
end
function View:bindSoftKeys()
    local actions = {}
    if self.page == "Sequence" then
        actions = {
            {
                label = "NEW",
                run = function()
                    self:namePrompt("NAME YOUR SECTION", "New section", function(name)
                        self:command("SequenceNew", { name = name })
                    end)
                end,
            },
            {
                label = "CRATES",
                run = function()
                    self:showPage("Library")
                end,
            },
            {
                label = "COPY",
                run = function()
                    self:command("SequenceDuplicate")
                end,
            },
            {
                label = "ERASE",
                run = function()
                    self:eraseTools()
                end,
            },
            {
                label = "SAVE",
                run = function()
                    self:command("SaveSequence")
                end,
            },
            {
                label = "TOOLS",
                run = function()
                    self:sequenceTools()
                end,
            },
        }
    elseif self.page == "Sounds" then
        actions = {
            {
                label = "SOURCE",
                run = function()
                    self:sourceTools()
                end,
            },
            {
                label = "KIT",
                run = function()
                    self:command("Kit", Catalog.PlannedPack.id)
                end,
            },
            {
                label = "AUDITION",
                run = function()
                    self.callbacks.preview(
                        self:absolutePad(),
                        self.state.pattern.sounds[self:absolutePad()]
                    )
                end,
            },
            {
                label = "MUTE",
                run = function()
                    self:command("MutePad", self:absolutePad())
                end,
            },
            {
                label = "UNDO",
                run = function()
                    self:command("Undo")
                end,
            },
            {
                label = "SETUP",
                run = function()
                    self:showPage("Settings")
                end,
            },
        }
    elseif self.page == "Settings" then
        actions = {
            {
                label = "TIMING",
                run = function()
                    self:timingTools()
                end,
            },
            {
                label = "TRACKS",
                run = function()
                    self:trackTools()
                end,
            },
            {
                label = "KIT",
                run = function()
                    self:command("Kit", Catalog.PlannedPack.id)
                end,
            },
            {
                label = "JAM",
                run = function()
                    self:command("JamOpen")
                end,
            },
            {
                label = "SAVE",
                run = function()
                    self:command("SaveProject")
                end,
            },
            {
                label = "UNDO",
                run = function()
                    self:command("Undo")
                end,
            },
        }
    end
    self.actions = actions
    for i, b in self.softKeys do
        b.Visible = actions[i] ~= nil
        if actions[i] then
            W.legend(b, actions[i].label)
        end
    end
    self.footer.Visible = #actions > 0
end
function View:namePrompt(title, current, submit)
    self.menu.Visible = false
    self.prompt.Visible = true
    self:cancelInput(false)
    self.promptTitle.Text = title
    self.nameBox.Text = tostring(current or "")
    self.nameSubmit = submit
    task.defer(function()
        if self.prompt.Visible then
            self.nameBox:CaptureFocus()
        end
    end)
end
function View:submitName()
    local text = self.nameBox.Text
    if #text < 1 or #text > 64 then
        self.promptTitle.Text = "USE 1–64 CHARACTERS"
        return
    end
    self.prompt.Visible = false
    if self.nameSubmit then
        self.nameSubmit(text)
    end
end
function View:showMenu(title, items)
    self:cancelInput(false)
    self.prompt.Visible = false
    self.menu.Visible = true
    self.menuTitle.Text = title
    self.menuItems = items
    self.menuIndex = 1
    self:paintMenu()
end
function View:paintMenu()
    for i, b in self.menuButtons do
        local item = self.menuItems[(self.menuIndex - 1) * 6 + i]
        b.Visible = item ~= nil
        if item then
            W.legend(b, item.label)
        end
    end
    self.menuPrev.Visible = self.menuIndex > 1
    self.menuNext.Visible = self.menuIndex * 6 < #self.menuItems
end
function View:sequenceTools()
    local m = self.state.music
    self:showMenu("SECTION TOOLS", {
        {
            label = "RENAME",
            run = function()
                self:namePrompt("NAME YOUR SECTION", m.sequence.name, function(name)
                    self:command("SequenceRename", { name = name })
                end)
            end,
        },
        {
            label = "LENGTH",
            run = function()
                self:namePrompt("BARS / 1–64", m.sequence.bars, function(value)
                    self:command("SequenceLength", { bars = tonumber(value) })
                end)
            end,
        },
        {
            label = "DOUBLE",
            run = function()
                self:command("SequenceDouble")
                self:closeModal()
            end,
        },
        {
            label = "CLEAR ALL",
            run = function()
                self:command("SequenceClear", { scope = "sequence" })
                self:closeModal()
            end,
        },
        {
            label = "DELETE",
            run = function()
                self:command("SequenceDelete")
                self:closeModal()
            end,
        },
        {
            label = "UNDO",
            run = function()
                self:command("Undo")
                self:closeModal()
            end,
        },
        {
            label = "REDO",
            run = function()
                self:command("Redo")
                self:closeModal()
            end,
        },
        {
            label = "TRACKS",
            run = function()
                self:trackTools()
            end,
        },
        {
            label = "TIMING",
            run = function()
                self:timingTools()
            end,
        },
        {
            label = "QUEUE NEXT",
            run = function()
                local entries = {}
                for _, seq in self.state.music.library.sequences do
                    local id = seq.id
                    table.insert(entries, {
                        label = seq.name,
                        run = function()
                            self:command("NextSequence", id)
                            self:closeModal()
                        end,
                    })
                end
                self:showMenu("PLAY NEXT SECTION", entries)
            end,
        },
        {
            label = "CANCEL NEXT",
            run = function()
                self:command("NextCancel")
                self:closeModal()
            end,
        },
        {
            label = "TEACH BAR",
            run = function()
                self:command("QuayTeachingBar", self.state.music.bar)
                self:closeModal()
            end,
        },
        {
            label = "NOTE MUTE",
            run = function()
                self:command("MutePad", self:absolutePad())
                self:closeModal()
            end,
        },
        {
            label = "QUANTIZE",
            run = function()
                local state = self.state.music
                self:command("Quantize", {
                    pad = self:absolutePad(),
                    quantizeTicks = state.timingCorrect,
                    swing = (state.swing - 50) / 50,
                })
                self:closeModal()
            end,
        },
        {
            label = "HIT EDIT",
            run = function()
                self:eventTools()
            end,
        },
    })
end
function View:eraseTools()
    self:showMenu("ERASE / UNDO IS AVAILABLE", {
        {
            label = "THIS PAD",
            run = function()
                self:command("ClearPad", self:absolutePad())
                self:closeModal()
            end,
        },
        {
            label = "THIS PART",
            run = function()
                self:command("SequenceClear")
                self:closeModal()
            end,
        },
        {
            label = "ALL NOTES",
            run = function()
                self:command("SequenceClear", { scope = "sequence" })
                self:closeModal()
            end,
        },
        {
            label = "DELETE SECTION",
            run = function()
                self:command("SequenceDelete")
                self:closeModal()
            end,
        },
        {
            label = "UNDO",
            run = function()
                self:command("Undo")
                self:closeModal()
            end,
        },
        {
            label = "KEEP PLAYING",
            run = function()
                self:closeModal()
            end,
        },
    })
end
function View:sourceTools()
    local entries = {}
    for _, sample in Catalog.List do
        local id = sample.id
        table.insert(entries, {
            label = sample.address .. " " .. sample.label,
            run = function()
                self:command("Assign", self:absolutePad(), id)
                self:closeModal()
            end,
        })
    end
    self:showMenu("CHOOSE A SOUND / 64 LOCAL SOURCES", entries)
end
function View:eventTools()
    local m = self.state.music
    local entries = {}
    for _, event in m.sequence.trackEvents[m.trackId] or {} do
        if
            event.pad == self:absolutePad()
            and event.tick >= (m.bar - 1) * 3840
            and event.tick < m.bar * 3840
        then
            local id, tick, velocity = event.eventId, event.tick, event.velocity
            table.insert(entries, {
                label = string.format("T%04d / V%03d", tick % 3840, velocity),
                run = function()
                    self:showMenu("EDIT HIT", {
                        {
                            label = "SOFTER",
                            run = function()
                                self:command(
                                    "EventVelocity",
                                    { eventId = id, velocity = math.max(1, velocity - 8) }
                                )
                                self:closeModal()
                            end,
                        },
                        {
                            label = "HARDER",
                            run = function()
                                self:command(
                                    "EventVelocity",
                                    { eventId = id, velocity = math.min(127, velocity + 8) }
                                )
                                self:closeModal()
                            end,
                        },
                        {
                            label = "EARLIER",
                            run = function()
                                self:command("EventPut", {
                                    eventId = id,
                                    pad = self:absolutePad(),
                                    tick = math.max(0, tick - 60),
                                    velocity = velocity,
                                })
                                self:closeModal()
                            end,
                        },
                        {
                            label = "LATER",
                            run = function()
                                self:command("EventPut", {
                                    eventId = id,
                                    pad = self:absolutePad(),
                                    tick = math.min(m.sequence.bars * 3840 - 1, tick + 60),
                                    velocity = velocity,
                                })
                                self:closeModal()
                            end,
                        },
                        {
                            label = "REMOVE",
                            run = function()
                                self:command("EventRemove", { eventId = id })
                                self:closeModal()
                            end,
                        },
                        {
                            label = "BACK",
                            run = function()
                                self:eventTools()
                            end,
                        },
                    })
                end,
            })
        end
    end
    if #entries == 0 then
        table.insert(entries, {
            label = "NO HITS ON THIS PAD",
            run = function()
                self:closeModal()
            end,
        })
    end
    self:showMenu("HIT EDIT / EXACT RECORDED TIMING", entries)
end
function View:trackTools()
    local m = self.state.music
    local entries = {}
    for _, track in m.library.tracks do
        local id = track.id
        table.insert(entries, {
            label = track.name,
            run = function()
                self:command("TrackSelect", id)
                self:closeModal()
            end,
        })
    end
    table.insert(entries, {
        label = "ADD PART",
        run = function()
            self:namePrompt("NEW PART", "New part", function(name)
                self:command("TrackNew", { name = name })
            end)
        end,
    })
    table.insert(entries, {
        label = "RENAME PART",
        run = function()
            self:namePrompt("PART NAME", self.state.music.track.name, function(name)
                self:command("TrackRename", { name = name })
            end)
        end,
    })
    table.insert(entries, {
        label = "COPY KIT",
        run = function()
            self:command("ProgramDuplicate")
            self:closeModal()
        end,
    })
    table.insert(entries, {
        label = "SELECT KIT",
        run = function()
            local kits = {}
            for _, program in self.state.music.library.programs do
                local id = program.id
                table.insert(kits, {
                    label = program.name,
                    run = function()
                        self:command("TrackProgram", { programId = id })
                        self:closeModal()
                    end,
                })
            end
            self:showMenu("YOUR KITS", kits)
        end,
    })
    table.insert(entries, {
        label = "MUTE PART",
        run = function()
            self:command("TrackMute", { muted = not self.state.music.track.mix.muted })
            self:closeModal()
        end,
    })
    table.insert(entries, {
        label = "SOLO PART",
        run = function()
            self:command("TrackSolo", { solo = not self.state.music.track.mix.solo })
            self:closeModal()
        end,
    })
    table.insert(entries, {
        label = "PART LEVEL",
        run = function()
            self:namePrompt(
                "PART LEVEL / 0–200%",
                math.floor(self.state.music.track.mix.gain * 100),
                function(v)
                    self:command("TrackMix", { mix = { gain = (tonumber(v) or 100) / 100 } })
                end
            )
        end,
    })
    table.insert(entries, {
        label = "PART PAN",
        run = function()
            self:namePrompt(
                "PAN / -100 LEFT, +100 RIGHT",
                math.floor(self.state.music.track.mix.pan * 100),
                function(v)
                    self:command("TrackMix", { mix = { pan = (tonumber(v) or 0) / 100 } })
                end
            )
        end,
    })
    self:showMenu("PARTS + KITS", entries)
end
function View:timingTools()
    local m = self.state.music
    self:showMenu("FEEL + TIMING", {
        {
            label = "GRID OFF",
            run = function()
                self:command("TimingCorrect", 0)
                self:closeModal()
            end,
        },
        {
            label = "1/16",
            run = function()
                self:command("TimingCorrect", 240)
                self:closeModal()
            end,
        },
        {
            label = "1/8",
            run = function()
                self:command("TimingCorrect", 480)
                self:closeModal()
            end,
        },
        {
            label = "1/32",
            run = function()
                self:command("TimingCorrect", 120)
                self:closeModal()
            end,
        },
        {
            label = "1/16 TRIPLET",
            run = function()
                self:command("TimingCorrect", 160)
                self:closeModal()
            end,
        },
        {
            label = "1/8 TRIPLET",
            run = function()
                self:command("TimingCorrect", 320)
                self:closeModal()
            end,
        },
        {
            label = "SWING",
            run = function()
                self:namePrompt("SWING / 50–75%", m.swing, function(v)
                    self:command("Swing", tonumber(v))
                end)
            end,
        },
        {
            label = "VELOCITY",
            run = function()
                self:namePrompt("HIT STRENGTH / 1–127", m.velocity, function(v)
                    self:command("Velocity", tonumber(v))
                end)
            end,
        },
        {
            label = "CLEAR PART",
            run = function()
                self:command("SequenceClear")
                self:closeModal()
            end,
        },
    })
end
function View:setting(index)
    local m = self.state.music
    if index == 1 then
        self:setMuted(not self.muted)
    elseif index == 2 then
        self.effects = not self.effects
        self.callbacks.effects(self.effects)
        self:paintSettings()
    elseif index == 3 then
        self:command("CountIn", not m.countIn)
    elseif index == 4 then
        self:command("FullLevel", not m.fullLevel)
    elseif index == 5 then
        self:command("NoteRepeat", not m.noteRepeat)
    elseif index == 6 then
        self:command(
            "Metronome",
            if m.metronome == "off" then "record" elseif m.metronome == "record" then "on" else "off"
        )
    end
end
function View:paintSettings()
    local m = self.state and self.state.music
    if not m then
        return
    end
    local labels = {
        if self.muted then "SOUND OFF" else "SOUND ON",
        if self.effects then "WORLD FX ON" else "WORLD FX OFF",
        if m.countIn then "COUNT IN ON" else "COUNT IN OFF",
        if m.fullLevel then "FULL LEVEL ON" else "FULL LEVEL OFF",
        if m.noteRepeat then "REPEAT ON" else "REPEAT OFF",
        "CLICK / " .. string.upper(m.metronome),
    }
    for i, b in self.settingsKeys do
        W.legend(b, labels[i])
    end
end
function View:playhead(step)
    self.sequenceScreen:setPlayhead(step)
end
function View:tick()
    if not self.panel.Visible or os.clock() < (self.nextTick or 0) then
        return
    end
    self.nextTick = os.clock() + 0.025
    self.hardware:signal(if self.callbacks.signal then self.callbacks.signal() else 0)
    local m = self.state and self.state.music
    local t = m and m.transport
    if t and t.playing then
        local seconds = workspace:GetServerTimeNow() - t.startedAt + (t.offset or 0)
        if t.loop and t.schedule.duration > 0 then
            seconds %= t.schedule.duration
        end
        local cursor = Transport.cursor(t.schedule, math.max(0, seconds))
        self:playhead(math.floor((cursor.sequenceTick or 0) % 3840 / 240) + 1)
    else
        self:playhead(nil)
    end
    if self.page == "Song" then
        self.songScreen:tick()
    end
end
function View:resizeDevice()
    local screen = self.screen.AbsoluteSize
    W.place(self.panel, 10, 8, screen.X - 20, screen.Y - 16)
    local width, height = self.panel.AbsoluteSize.X, self.panel.AbsoluteSize.Y
    if width < 100 or height < 100 then
        return
    end
    local portrait = width < height
    local tight = height < 450 or (portrait and width < 460)
    self.hardware:resize(width < 640, height < 580, tight)
    local top = if tight then 48 else 86
    local bottom = if tight then 4 else 42
    W.place(self.body, 16, top, width - 32, height - top - bottom)
    local bw, bh = width - 32, height - top - bottom
    local dw = if portrait then bw else (bw - 10) / 2
    local dh = if portrait then (bh - 10) / 2 else bh
    W.place(self.performanceDeck, 0, 0, dw, dh)
    W.place(
        self.editorDeck,
        if portrait then 0 else dw + 10,
        if portrait then dh + 10 else 0,
        dw,
        dh
    )
    attr(self.panel, "DeviceLayout", if portrait then "portrait" else "landscape")
    attr(self.body, "SplitAxis", if portrait then "vertical" else "horizontal")
    local short = height < 450 and not portrait
    self.bankRow.Parent = if short then self.panel else self.performanceDeck
    W.place(self.bankRow, if short then 16 else 4, if short then 0 else 0, dw - 8, 44)
    self.transportRow.Parent = self.performanceDeck
    W.place(self.transportRow, 4, dh - 44, dw - 8, 44)
    for i, b in self.bankButtons do
        W.place(b, (i - 1) * (dw - 4) / 4, 0, (dw - 4) / 4 - 6, 44)
    end
    for i, key in { "Play", "Stop", "Record", "Overdub" } do
        W.place(self.transportButtons[key], (i - 1) * (dw - 4) / 4, 0, (dw - 4) / 4 - 6, 44)
    end
    local usable = dh - (if short then 52 else 100)
    local knob = math.clamp(dw * 0.29, 92, 196)
    local side = math.floor(math.min(usable, dw - knob - 12))
    local gap = if side < 210 then 4 else 8
    local padSide = math.floor((side - gap * 3) / 4)
    local total = side + knob + 8
    local x = math.max(4, (dw - total) / 2)
    local y = if short then 4 else 50 + math.max(0, (usable - side) / 2)
    W.place(self.padGrid, x, y, side, side)
    for i, b in self.pads do
        W.place(
            b,
            (i - 1) % 4 * (padSide + gap),
            math.floor((i - 1) / 4) * (padSide + gap),
            padSide,
            padSide
        )
    end
    self.padControls.root.Position = UDim2.fromOffset(x + side + 8, y)
    self.padControls:resize(knob, side)
    attr(self.performanceDeck, "PadTargetPixels", padSide)
    attr(self.performanceDeck, "AllPadsFixed", true)
    W.place(self.navigation, 10, 4, dw - 20, 44)
    for i, name in { "Sequence", "Song", "Sounds", "Library", "Settings" } do
        W.place(self.tabs[name], (i - 1) * (dw - 16) / 5, 0, (dw - 16) / 5 - 4, 44)
    end
    local ownFooter = self.page == "Sequence" or self.page == "Settings" or self.page == "Sounds"
    local editorBottom = if ownFooter then 48 else 8
    W.place(self.viewport, 14, 54, dw - 28, dh - 54 - editorBottom)
    local vw, vh = dw - 28, dh - 54 - editorBottom
    self.sequenceScreen:resize(vw, vh)
    self.songScreen:resize(vw, vh)
    self.sampleEditor:resize(vw, vh)
    self.libraryScreen:resize(vw, vh)
    W.place(self.footer, 10, dh - 46, dw - 20, 44)
    for i, b in self.softKeys do
        W.place(b, (i - 1) * (dw - 16) / 6, 0, (dw - 16) / 6 - 4, 44)
    end
    self.footer.Visible = ownFooter
    self.transportRow.Visible = true
    W.place(self.settingsTitle, 0, 0, vw, 28)
    local compactSettings = vh < 220
    local columns = if compactSettings then 3 else 2
    local rows = if compactSettings then 2 else 3
    local statusHeight = if compactSettings then 22 else 40
    local cardH = math.min(76, (vh - 32 - statusHeight - (rows - 1) * 5) / rows)
    for i, b in self.settingsKeys do
        W.place(
            b,
            (i - 1) % columns * (vw + 6) / columns,
            32 + math.floor((i - 1) / columns) * (cardH + 5),
            (vw - (columns - 1) * 6) / columns,
            cardH
        )
    end
    W.place(self.audioStatus, 0, vh - (if compactSettings then 20 else 34), vw, 18)
    self.appearanceStatus.Visible = not compactSettings
    W.place(self.appearanceStatus, 0, vh - 17, vw, 16)
    W.place(self.settingHint, 0, vh - 56, vw, 20)
    self.settingHint.Visible = vh >= 290
    W.place(self.noticeLabel, 22, height - 38, width - 174, 28)
    self.noticeLabel.Visible = not tight
    W.place(
        self.exit,
        width - (if tight then 48 else 126),
        if tight then 0 else height - 40,
        if tight then 44 else 112,
        36
    )
    W.place(self.menu, 10, 8, dw - 20, dh - 16)
    W.place(self.prompt, 10, 8, dw - 20, dh - 16)
    local mw, mh = dw - 20, dh - 16
    W.place(self.menuTitle, 10, 4, mw - 20, 28)
    local ch = (mh - 88) / 2
    for i, b in self.menuButtons do
        W.place(
            b,
            8 + (i - 1) % 3 * (mw - 12) / 3,
            36 + math.floor((i - 1) / 3) * ch,
            (mw - 12) / 3 - 6,
            ch - 6
        )
    end
    W.place(self.menuPrev, 8, mh - 46, (mw - 20) / 3, 40)
    W.place(self.menuNext, 12 + (mw - 20) / 3, mh - 46, (mw - 20) / 3, 40)
    W.place(self.menuClose, mw - (mw - 20) / 3 - 8, mh - 46, (mw - 20) / 3, 40)
    W.place(self.promptTitle, 14, 12, mw - 28, 36)
    W.place(self.nameBox, 14, 60, mw - 28, 48)
    W.place(self.promptSave, 14, mh - 58, (mw - 36) / 2, 44)
    W.place(self.promptCancel, mw / 2 + 4, mh - 58, (mw - 36) / 2, 44)
end
return View
