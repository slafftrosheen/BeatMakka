local Gui = require(script.Parent.GuiFactory)
local Shared = game.ReplicatedStorage.Shared
local Theme = require(Shared.Theme)
local Catalog = require(Shared.SampleCatalog)
local Transport = require(Shared.MusicTransport)
local PadInput = require(script.Parent.PadInput)
local Skin = require(script.Parent.DeviceSkin)
local PadControls = require(script.Parent.DevicePadControls)
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Http = game:GetService("HttpService")
local View = {}
View.__index = View
local lcdText = Color3.fromRGB(179, 215, 153)
local padKeys = require(Shared.SamplerPadLayout).KeyboardKeys
local keyLabels = { One = "1", Two = "2", Three = "3", Four = "4" }
-- Short faceplate legends; the LCD retains each complete source label.
local padLegends = {
    A = {
        "MAIN KICK",
        "DROP KICK",
        "FAST KICK",
        "GHOST KICK",
        "MAIN SNARE",
        "SNARE ROLL",
        "RIMSHOT",
        "CRACK SNARE",
        "CLOSED HAT 1",
        "CLOSED HAT 2",
        "OPEN HAT",
        "SHAKER",
        "DOCK PERC 1",
        "DOCK PERC 2",
        "METAL CLANK",
        "BREAK FILL",
    },
    B = {
        "DROP SUB",
        "808 PULSE",
        "WARM SUB",
        "DEEP SUB",
        "REESE GROWL",
        "REESE BITE",
        "PITCH DIVE",
        "REESE BARK",
        "LOW FOGHORN",
        "FOGHORN STUTTER",
        "DISTORTED REESE",
        "WOBBLE SUB",
        "REESE STAB 1",
        "REESE STAB 2",
        "SUB GLIDE",
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
        "FOGHORN ECHO",
        "VINYL DROP",
        "RISER",
        "METAL PIPE",
        "TAPE ECHO",
        "DROP BOOM",
    },
}
local actionIcons = {
    Play = "play",
    PlayStart = "play",
    Stop = "stop",
    Record = "record",
    Overdub = "record",
    SaveProject = "save",
    SaveSequence = "save",
    SaveDraft = "save",
    SongFinish = "save",
    Undo = "undo",
    Redo = "redo",
}
local function label(parent, text, height)
    local item = Gui.label(parent, text, 13, lcdText)
    item.Font = Enum.Font.Code
    item.Size = UDim2.new(1, -12, 0, height or 44)
    item.LayoutOrder = #parent:GetChildren()
    return item
end
local function orderedButton(parent, text, callback, options)
    local item = Gui.button(parent, text, callback, options)
    item.LayoutOrder = #parent:GetChildren()
    return item
end
local function flow(parent, maximumColumns, height, minimumWidth)
    local f = Gui.make("Frame", parent, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #parent:GetChildren() + 1,
    })
    maximumColumns, height, minimumWidth = maximumColumns or 4, height or 44, minimumWidth or 104
    local grid = Gui.make("UIGridLayout", f, {
        CellSize = UDim2.new(1, -8, 0, height),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    local function resize()
        local columns =
            math.clamp(math.floor((f.AbsoluteSize.X + 8) / (minimumWidth + 8)), 1, maximumColumns)
        if maximumColumns == 8 then
            columns = if columns >= 8 then 8 elseif columns >= 4 then 4 else 2
        end
        grid.CellSize = UDim2.new(1 / columns, -8, 0, height)
    end
    f:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    task.defer(resize)
    return f
end

local function box(parent, placeholder, text)
    return Gui.round(Gui.make("TextBox", parent, {
        PlaceholderText = placeholder,
        Text = text or "",
        ClearTextOnFocus = false,
        BackgroundColor3 = Theme.Screen,
        TextColor3 = lcdText,
        PlaceholderColor3 = Theme.FadedTeal,
        Font = Enum.Font.Code,
        TextSize = 14,
        TextWrapped = true,
        Size = UDim2.fromOffset(160, 48),
    }))
end
local function clear(parent)
    for _, child in parent:GetChildren() do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
end
local function address(pad)
    return string.format("%s%02d", string.char(65 + math.floor((pad - 1) / 16)), (pad - 1) % 16 + 1)
end
function View.new(callbacks)
    local self = setmetatable({
        callbacks = callbacks,
        selectedPad = 2,
        page = "Sequence",
        muted = false,
        pads = {},
        steps = {},
        heldContexts = {},
    }, View)
    self.screen = Gui.make("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"), {
        Name = "NeedleQuayInstrument",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        DisplayOrder = 10,
    })
    self.panel = Gui.round(Gui.make("Frame", self.screen, {
        Name = "Workstation",
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(1, -24, 1, -24),
        BackgroundColor3 = Theme.Teal,
        Visible = false,
    }))
    self.hardware = require(script.Parent.HardwareFaceplate).new(
        self.panel,
        callbacks.command,
        function()
            return self.state
        end
    )
    for _, child in self.panel:GetChildren() do
        if
            child.Name == "EnamelFaceplate"
            or child.Name == "WalnutCheek"
            or child.Name == "CaseScrew"
        then
            child:Destroy()
        end
    end
    Skin.panel(self.panel, "device")
    self.body = Gui.make("Frame", self.panel, {
        Name = "DeviceBody",
        BackgroundTransparency = 1,
    })
    self.performanceDeck = Gui.make("Frame", self.body, {
        Name = "PerformanceDeck",
        BackgroundTransparency = 1,
    })
    self.performanceDeck:SetAttribute("PersistentDeck", true)
    self.performanceDeck:SetAttribute("ScreenShare", 0.5)
    self.editorDeck = Gui.make("Frame", self.body, {
        Name = "EditorDeck",
        BackgroundColor3 = Theme.Screen,
        BorderSizePixel = 0,
    })
    self.editorDeck:SetAttribute("ScreenShare", 0.5)
    Skin.panel(self.editorDeck, "lcd")
    self.bankRow = Gui.make("Frame", self.performanceDeck, {
        Name = "SoundBanks",
        BackgroundTransparency = 1,
    })
    self.transportRow = Gui.make("Frame", self.performanceDeck, {
        Name = "PerformanceTransport",
        BackgroundTransparency = 1,
    })
    self.padGrid = Gui.make("Frame", self.performanceDeck, {
        Name = "PhysicalPads",
        BackgroundTransparency = 1,
    })
    self.padGrid:SetAttribute("PadCount", 16)
    self.padGrid:SetAttribute("GridOrder", "row-major-top-left")
    self.padLayout = Gui.make("UIGridLayout", self.padGrid, {
        FillDirectionMaxCells = 4,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    self.padControls = PadControls.new(self.performanceDeck, {
        state = function()
            return self.state
        end,
        absolutePad = function()
            return self:absolutePad()
        end,
        command = callbacks.command,
        visible = function()
            return self.panel.Visible
        end,
    })
    local nav = Gui.make("Frame", self.editorDeck, {
        Name = "Navigation",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.new(1, -12, 0, 44),
        BackgroundTransparency = 1,
    })
    self.tabs = {}
    for index, name in { "Sequence", "Song", "Library", "Sounds", "Settings" } do
        local b = orderedButton(nav, name, function()
            self:showPage(name)
        end)
        b.Name = name
        b:SetAttribute("AccessibleLabel", name)
        b:SetAttribute(
            "UiIcon",
            ({
                Sequence = "steps",
                Song = "disc",
                Library = "library",
                Sounds = "sound",
                Settings = "knob",
            })[name]
        )
        b.Position = UDim2.fromScale((index - 1) / 5, 0)
        b.Size = UDim2.new(0.2, -5, 1, 0)
        self.tabs[name] = b
    end
    self.context = Gui.label(self.editorDeck, "Open the Roamer to make music", 12, lcdText)
    self.context.Font = Enum.Font.Code
    self.context.Position = UDim2.fromOffset(10, 54)
    self.context.Size = UDim2.new(1, -20, 0, 34)
    self.pages = {}
    for _, name in { "Sequence", "Song", "Library", "Sounds", "Settings" } do
        local page = Gui.make("ScrollingFrame", self.editorDeck, {
            Name = name,
            Position = UDim2.fromOffset(6, 92),
            Size = UDim2.new(1, -12, 1, -98),
            BackgroundColor3 = Theme.Screen,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 6,
            ScrollBarImageColor3 = Theme.FadedTeal,
            Visible = name == self.page,
        })
        Gui.make("UIPadding", page, {
            PaddingLeft = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 14),
        })
        Gui.make(
            "UIListLayout",
            page,
            { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }
        )
        self.pages[name] = page
    end
    self.noticeLabel = Gui.label(
        self.panel,
        "PADS / PLAY ANY TAB     SEQUENCE / REPEAT A SECTION     SONG / ARRANGE SECTIONS",
        11,
        Theme.Cream
    )
    self.noticeLabel.Font = Enum.Font.Code
    self.noticeLabel.Position = UDim2.new(0, 24, 1, -76)
    self.noticeLabel.Size = UDim2.new(1, -184, 0, 20)
    self.audioStatus =
        Gui.label(self.panel, "6 local preview sounds / listening review pending", 11, Theme.Cream)
    self.audioStatus.Font = Enum.Font.Code
    self.audioStatus.Position = UDim2.new(0, 24, 1, -56)
    self.audioStatus.Size = UDim2.new(1, -184, 0, 20)
    self.appearanceStatus = Gui.label(self.pages.Settings, "", 12, Theme.Cream)
    self.appearanceStatus.Size = UDim2.new(1, -12, 0, 40)
    self.settingsAudioStatus = label(self.pages.Settings, "", 44)
    self.audioStatus:GetPropertyChangedSignal("Text"):Connect(function()
        self.settingsAudioStatus.Text = self.audioStatus.Text
    end)
    local leave = orderedButton(self.panel, "Back to Quay", function()
        self:cancelInput(true)
        callbacks.command("Release")
    end)
    leave.Position = UDim2.new(1, -140, 1, -48)
    leave.Size = UDim2.fromOffset(124, 44)
    self.leaveButton = leave
    self.toast = Gui.round(
        Gui.make("Frame", self.panel, {
            Name = "DeviceToast",
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -12),
            Size = UDim2.new(0.9, 0, 0, 54),
            BackgroundColor3 = Theme.Screen,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 30,
        }),
        8
    )
    self.toastText = Gui.label(self.toast, "", 12, Theme.Cream)
    self.toastText.Font, self.toastText.Position, self.toastText.Size, self.toastText.ZIndex =
        Enum.Font.Code, UDim2.fromOffset(10, 4), UDim2.new(1, -20, 1, -8), 31
    local function command(action, value, extra)
        if self.state and self.state.ready and self.state.music then
            callbacks.command(action, value, extra)
        end
    end
    local function button(parent, text, action, value, extra)
        local item = orderedButton(parent, text, function()
            command(
                action,
                if type(value) == "function" then value() else value,
                if type(extra) == "function" then extra() else extra
            )
        end)
        item:SetAttribute("MusicAction", action)
        if actionIcons[action] then
            item:SetAttribute("UiIcon", actionIcons[action])
        end
        return item
    end
    local seqPage = self.pages.Sequence
    local pageControls = flow(seqPage, 4, 44, 58)
    pageControls.Name = "BarPager"
    button(pageControls, "Previous bar", "Bar", function()
        return math.max(1, self.state.music.bar - 1)
    end)
    self.barLabel = Gui.label(pageControls, "Bar 1", 12, lcdText)
    self.barLabel.Font = Enum.Font.Code
    self.barLabel.TextXAlignment = Enum.TextXAlignment.Center
    self.barLabel.LayoutOrder = 2
    button(pageControls, "Next bar", "Bar", function()
        return math.min(self.state.music.sequence.bars, self.state.music.bar + 1)
    end)
    button(pageControls, "Teach this bar", "QuayTeachingBar", function()
        return self.state.music.bar
    end)
    self.padLabel = label(seqPage, "A02 / Select a pad", 32)
    self.padLabel.Name = "SelectedPad"
    self.stepGrid = flow(seqPage, 8, 44, 44)
    self.stepGrid.Name = "StepGrid"
    for step = 1, 16 do
        self.steps[step] = orderedButton(self.stepGrid, tostring(step), function()
            command("Step", self:absolutePad(), step)
        end)
        self.steps[step]:SetAttribute("Step", step)
        self.steps[step]:SetAttribute("MusicAction", "Step")
        Skin.step(self.steps[step])
    end
    label(seqPage, "SEQUENCE / saved sections and variations", 26)
    self.sequenceList = flow(seqPage)
    local names = flow(seqPage)
    self.sequenceName = box(names, "Sequence name")
    button(names, "New sequence", "SequenceNew", function()
        return { name = if self.sequenceName.Text ~= "" then self.sequenceName.Text else "New idea" }
    end)
    button(names, "Rename", "SequenceRename", function()
        return { name = self.sequenceName.Text }
    end)
    button(names, "Make variation", "SequenceDuplicate")
    local length = flow(seqPage)
    self.bars = box(length, "Bars (1–64)", "4")
    button(length, "Set length", "SequenceLength", function()
        return { bars = tonumber(self.bars.Text) }
    end)
    button(length, "Double length", "SequenceDouble")
    button(length, "Save Sequence", "SaveSequence")
    local sequenceEdits = flow(seqPage)
    button(sequenceEdits, "Delete sequence (Undo available)", "SequenceDelete")
    label(seqPage, "TRACKS / parts share kits across sequences", 30)
    self.trackList = flow(seqPage)
    local tracks = flow(seqPage)
    self.trackName = box(tracks, "Track name")
    button(tracks, "Add track", "TrackNew", function()
        return { name = if self.trackName.Text ~= "" then self.trackName.Text else "New part" }
    end)
    button(tracks, "Rename track", "TrackRename", function()
        return { name = self.trackName.Text }
    end)
    button(tracks, "Duplicate kit", "ProgramDuplicate")
    self.kitList = flow(seqPage)
    local mix = flow(seqPage)
    self.trackMute = button(mix, "Mute track", "TrackMute", function()
        return { muted = not self.state.music.track.mix.muted }
    end)
    self.trackSolo = button(mix, "Solo track", "TrackSolo", function()
        return { solo = not self.state.music.track.mix.solo }
    end)
    button(mix, "Track level −", "TrackMix", function()
        return { mix = { gain = math.max(0, self.state.music.track.mix.gain - 0.1) } }
    end)
    button(mix, "Track level +", "TrackMix", function()
        return { mix = { gain = math.min(1.5, self.state.music.track.mix.gain + 0.1) } }
    end)
    local transport = flow(seqPage)
    transport.Name = "ProjectTransport"
    self.transportButtons = {}
    for index, item in
        {
            { "PLAY", "Play" },
            { "STOP", "Stop" },
            { "RECORD", "Record" },
            { "OVERDUB", "Overdub" },
        }
    do
        local transportButton = button(self.transportRow, item[1], item[2])
        transportButton.Name = "Transport_" .. item[2]
        transportButton.LayoutOrder = index
        self.transportButtons[item[2]] = transportButton
    end
    for _, item in
        {
            { "Play Start", "PlayStart" },
            { "Undo", "Undo" },
            { "Redo", "Redo" },
            { "Save Project", "SaveProject" },
        }
    do
        button(transport, item[1], item[2])
    end
    self.transportLabel = label(seqPage, "Stopped", 44)
    local timing = flow(seqPage)
    self.velocity = box(timing, "Velocity 1–127", "100")
    button(timing, "Set velocity", "Velocity", function()
        return tonumber(self.velocity.Text)
    end)
    self.fullLevel = button(timing, "Full Level OFF", "FullLevel", function()
        return not self.state.music.fullLevel
    end)
    self.repeatButton = button(timing, "Note Repeat OFF", "NoteRepeat", function()
        return not self.state.music.noteRepeat
    end)
    local corrections = flow(seqPage)
    for _, division in
        {
            { "Timing Off", 0 },
            { "1/16", 240 },
            { "1/16 triplet", 160 },
            { "1/8", 480 },
            { "1/8 triplet", 320 },
            { "1/32", 120 },
        }
    do
        button(corrections, division[1], "TimingCorrect", division[2])
    end
    local timingOptions = flow(seqPage)
    self.swing = box(timingOptions, "Swing 50–75%", "50")
    button(timingOptions, "Set swing", "Swing", function()
        return tonumber(self.swing.Text)
    end)
    button(timingOptions, "Quantize selected pad", "Quantize", function()
        return {
            pad = self:absolutePad(),
            quantizeTicks = self.state.music.timingCorrect,
            swing = (self.state.music.swing - 50) / 50,
        }
    end)
    self.countIn = button(timingOptions, "Count-in OFF", "CountIn", function()
        return not self.state.music.countIn
    end)
    local clicks = flow(seqPage)
    for _, mode in { "off", "record", "on" } do
        button(clicks, "Metronome " .. mode, "Metronome", mode)
    end
    self.bankButtons = {}
    for i = 1, 4 do
        local bankButton =
            button(self.bankRow, ({ "A / DRUMS", "B / BASS", "C / VOX", "D / FX" })[i], "Bank", i)
        bankButton.Name = "Bank" .. string.char(64 + i)
        bankButton:SetAttribute("UiIcon", ({ "drum", "bass", "mic", "waves" })[i])
        bankButton:SetAttribute("Bank", i)
        self.bankButtons[i] = bankButton
    end
    self.padInput = PadInput.new(function(pad)
        local ctx = callbacks.noteContext and callbacks.noteContext(pad)
        self.heldContexts[pad] = { context = ctx, nextAt = os.clock() }
        return callbacks.tap(pad, ctx)
    end, function(pad, held)
        local physical = (pad - 1) % 16 + 1
        if self.pads[physical] then
            Skin.setPadDown(self.pads[physical], held)
        end
        if not held then
            self.heldContexts[pad] = nil
        end
    end)
    for physical = 1, 16 do
        local b = orderedButton(self.padGrid, string.format("A%02d", physical), function()
            self:selectPad(physical)
        end, { silent = true })
        b.Name = string.format("Pad%02d", physical)
        b.LayoutOrder = physical
        b:SetAttribute("PhysicalPad", physical)
        b:SetAttribute("Row", math.floor((physical - 1) / 4) + 1)
        b:SetAttribute("Column", (physical - 1) % 4 + 1)
        b:SetAttribute("Address", address(physical))
        b:SetAttribute("PadKey", keyLabels[padKeys[physical]] or padKeys[physical])
        Skin.pad(b)
        self.pads[physical] = b
        b.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                self:beginPad(physical, input)
            end
        end)
        b.InputEnded:Connect(function(input)
            self.padInput:finish(input)
        end)
    end
    local edits = flow(seqPage)
    self.padMute = button(edits, "Mute pad", "MutePad", function()
        return self:absolutePad()
    end)
    button(edits, "Clear pad notes", "ClearPad", function()
        return self:absolutePad()
    end)
    button(edits, "Clear track notes", "SequenceClear")
    button(edits, "Cancel queued next", "NextCancel")
    label(seqPage, "EVENTS / recorded timing is retained until explicitly quantized", 36)
    self.eventList = Gui.make("Frame", seqPage, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #seqPage:GetChildren(),
    })
    Gui.make(
        "UIListLayout",
        self.eventList,
        { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    label(seqPage, "NEXT SEQUENCE / queues a live transition at the section end", 36)
    self.nextList = flow(seqPage)
    local song = self.pages.Song
    label(song, "SONG / BUILD YOUR JOURNEY", 32).LayoutOrder = -60
    self.songPosition = label(song, "Stopped / add a sequence to start your song.", 44)
    self.songPosition.Name = "SongPosition"
    self.songPosition.LayoutOrder = -50
    self.draftList = flow(song)
    self.draftList.LayoutOrder = -40
    local songNames = flow(song)
    self.songName = box(songNames, "Song draft title")
    button(songNames, "New draft", "SongNew", function()
        return { name = if self.songName.Text ~= "" then self.songName.Text else "My song" }
    end)
    button(songNames, "Rename draft", "SongRename", function()
        return { name = self.songName.Text }
    end)
    button(songNames, "Duplicate draft", "SongDuplicate")
    local songActions = flow(song)
    songActions.LayoutOrder = -10
    button(songActions, "Add selected sequence", "SongStepInsert", function()
        return { sequenceId = self.state.music.sequenceId, repeats = 1 }
    end)
    button(songActions, "Play song from start", "SongPlay")
    button(songActions, "Play / pause", "Play")
    button(songActions, "Stop", "Stop")
    button(songActions, "Save Draft", "SaveDraft")
    local songActions2 = flow(song)
    button(songActions2, "Finish & Save Song", "SongFinish", function()
        local m = self.state.music
        self.finishKey = self.finishKey or {}
        local key = tostring(m.projectId)
            .. ":"
            .. tostring(m.draftId)
            .. ":"
            .. tostring(m.projectRevision)
            .. ":"
            .. tostring(m.draft and m.draft.revision)
        self.finishKey[key] = self.finishKey[key] or Http:GenerateGUID(false)
        return {
            requestId = self.finishKey[key],
            projectRevision = m.projectRevision,
            draftRevision = m.draft and m.draft.revision,
        }
    end)
    button(songActions2, "Convert to Sequence", "SongConvert")
    self.tempoMode = button(songActions2, "Use Song tempo", "SongTempo", function()
        local d = self.state.music.draft
        return {
            tempoMode = if d and d.tempoMode == "song" then "sequence" else "song",
            bpm = tonumber(self.songBpm.Text) or 96,
        }
    end)
    self.songBpm = box(songActions2, "Song BPM", "96")
    local draftEdits = flow(song)
    button(draftEdits, "Delete draft (Undo available)", "SongDelete")
    local cover = flow(song)
    button(cover, "Copy my sleeve to draft", "LifeCopySleeveToDraft", function()
        return self.state.music.draftId
    end)
    button(cover, "Undo arrangement edit", "Undo")
    button(cover, "Redo arrangement edit", "Redo")
    self.songSummary = label(song, "Add a sequence to start your song.", 64)
    self.songSummary.LayoutOrder, self.songSummary.Size = -20, UDim2.new(1, -12, 0, 32)
    self.songSteps = Gui.make("Frame", song, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = -30,
    })
    Gui.make(
        "UIListLayout",
        self.songSteps,
        { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    label(
        song,
        "END / Song preview stops here. Finish saves arrangement data for in-game playback.",
        48
    )
    label(
        self.pages.Library,
        "LIBRARY / saved sequences, drafts, Finished Songs and legacy imports",
        44
    )
    self.libraryList = Gui.make("Frame", self.pages.Library, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
    })
    Gui.make(
        "UIListLayout",
        self.libraryList,
        { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    self.sampleEditor = require(script.Parent.SampleEditor).new(
        self.pages.Sounds,
        function(key, value)
            command("PadSound", self:absolutePad(), { key = key, value = value })
        end,
        function(pad, settings)
            return callbacks.preview(pad, settings)
        end,
        function(pad)
            command("Bank", math.floor((pad - 1) / 16) + 1)
            self:selectPad((pad - 1) % 16 + 1)
        end,
        function(name)
            command("PadPreset", self:absolutePad(), name)
        end
    )
    self.sampleEditor.root.LayoutOrder = -30
    self.sampleEditor.recipePanel.LayoutOrder = 10
    label(
        self.pages.Sounds,
        "Kit edits are shared by every editable sequence using this kit. Duplicate the kit for independent edits. Finished Songs retain their saved settings.",
        64
    )
    self.assignmentList = flow(self.pages.Sounds)
    self.assignmentList.LayoutOrder = 30
    local kits = flow(self.pages.Sounds, 1)
    kits.LayoutOrder = -40
    button(kits, "Load Harbour Pulse / 64 sounds", "Kit", Catalog.PlannedPack.id):SetAttribute(
        "UiIcon",
        "pads"
    )
    local options = flow(self.pages.Settings)
    self.soundButton = orderedButton(options, "Sound ON", function()
        self:setMuted(not self.muted)
    end)
    self.effectsButton = orderedButton(options, "World effects ON", function()
        self.effects = not self.effects
        callbacks.effects(self.effects)
        self.effectsButton.Text = if self.effects then "World effects ON" else "World effects OFF"
    end)
    self.effects = true
    button(options, "Two-player jam", "JamOpen")
    button(options, "Save Project", "SaveProject")
    local broadcast = orderedButton(options, "Street broadcast OFF", function()
        command("Broadcast", not (self.state and self.state.broadcast))
    end)
    self.broadcastButton = broadcast
    self.saveStatus = label(self.pages.Settings, "", 44)
    label(
        self.pages.Settings,
        "Mouse and touch use the explicit velocity level. Full Level sets 127. No microphone capture or pressure sensing is required. Off-grid events remain intact when viewing a 16-step bar.",
        80
    )
    self.guide = require(script.Parent.RecorderGuide).new(self.pages.Settings)
    self.repeatConnection = RunService.Heartbeat:Connect(function()
        if
            not self.panel.Visible
            or not self.state
            or not self.state.music
            or not self.state.music.noteRepeat
        then
            return
        end
        local m = self.state.music
        local interval = (if m.timingCorrect > 0 then m.timingCorrect else 240)
            / 960
            * 60
            / m.sequence.bpm
        for pad, held in self.heldContexts do
            if os.clock() >= held.nextAt + interval then
                held.nextAt = os.clock()
                callbacks.tap(pad, held.context)
                Skin.pulse(self.pads[(pad - 1) % 16 + 1])
            end
        end
    end)
    self.inputEnded = Input.InputEnded:Connect(function(input)
        self.padInput:finish(input)
    end)
    self.layoutConnection = self.panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:resizeDevice()
    end)
    self.visibilityConnection = self.panel:GetPropertyChangedSignal("Visible"):Connect(function()
        if not self.panel.Visible then
            self:cancelInput(false)
        end
    end)
    self.screen.Destroying:Connect(function()
        self.repeatConnection:Disconnect()
        self.inputEnded:Disconnect()
        self.layoutConnection:Disconnect()
        self.visibilityConnection:Disconnect()
        self.padInput:destroy()
        self.padControls:destroy()
    end)
    self:showPage(self.page)
    self:resizeDevice()
    task.defer(function()
        if self.screen.Parent then
            self:resizeDevice()
        end
    end)
    return self
end

function View:resizeDevice()
    local width, height = self.panel.AbsoluteSize.X, self.panel.AbsoluteSize.Y
    local compact = height < 580
    local portrait = width < height
    local short = height < 430 and not portrait
    local phonePortrait = portrait and width < 460
    local tight = short or phonePortrait
    self.hardware:resize(width < 640, compact or phonePortrait, tight)
    local top = if tight then 48 elseif compact then 70 else 88
    local bodyWidth, bodyHeight =
        math.max(0, width - 32), math.max(0, height - top - (if tight then 8 else 76))
    local gutter = 10
    self.body.Position, self.body.Size =
        UDim2.fromOffset(16, top), UDim2.fromOffset(bodyWidth, bodyHeight)
    local deckWidth = if portrait then bodyWidth else math.max(0, (bodyWidth - gutter) / 2)
    local deckHeight = if portrait then math.max(0, (bodyHeight - gutter) / 2) else bodyHeight
    self.performanceDeck.Position, self.performanceDeck.Size =
        UDim2.fromOffset(0, 0), UDim2.fromOffset(deckWidth, deckHeight)
    self.editorDeck.Position = if portrait
        then UDim2.fromOffset(0, deckHeight + gutter)
        else UDim2.fromOffset(deckWidth + gutter, 0)
    self.editorDeck.Size = UDim2.fromOffset(deckWidth, deckHeight)
    self.panel:SetAttribute("DeviceLayout", if portrait then "portrait" else "landscape")
    self.panel:SetAttribute("ShortScreen", short)
    self.panel:SetAttribute("TightLayout", tight)
    self.body:SetAttribute("SplitAxis", if portrait then "vertical" else "horizontal")
    for name, tab in self.tabs do
        tab.Text = if deckWidth < 500
            then ({
                Sequence = "SEQ",
                Song = "SONG",
                Library = "LIB",
                Sounds = "SOUND",
                Settings = "SET",
            })[name]
            else name
    end

    local inner = math.max(0, deckWidth - 16)
    self.bankRow.Parent = if short then self.panel else self.performanceDeck
    self.bankRow.Position, self.bankRow.Size =
        if short then UDim2.fromOffset(16, 0) else UDim2.fromOffset(8, 4),
        UDim2.fromOffset(inner, 44)
    self.transportRow.Parent = if short then self.editorDeck else self.performanceDeck
    self.transportRow.Position, self.transportRow.Size =
        UDim2.fromOffset(8, math.max(0, deckHeight - 48)), UDim2.fromOffset(inner, 44)
    self.noticeLabel.Visible, self.audioStatus.Visible = not tight, not tight
    self.leaveButton.Position = if tight
        then UDim2.new(1, -52, 0, 0)
        else UDim2.new(1, -148, 1, -70)
    self.leaveButton.Size = if tight then UDim2.fromOffset(44, 44) else UDim2.fromOffset(124, 44)
    self.leaveButton.Text = if tight then "QUAY" else "Back to Quay"
    for _, page in self.pages do
        page.Size = UDim2.new(1, -12, 1, -(if short then 148 else 98))
    end
    local capWidth = math.max(0, (inner - 18) / 4)
    for index = 1, 4 do
        local bank = self.bankButtons[index]
        bank.Position, bank.Size =
            UDim2.fromOffset((index - 1) * (capWidth + 6), 0), UDim2.fromOffset(capWidth, 44)
    end
    for index, action in { "Play", "Stop", "Record", "Overdub" } do
        local cap = self.transportButtons[action]
        cap.Position, cap.Size =
            UDim2.fromOffset((index - 1) * (capWidth + 6), 0), UDim2.fromOffset(capWidth, 44)
        cap.TextSize = if capWidth < 74 then 10 else 12
    end
    local knobWidth = math.min(math.clamp(inner * 0.31, 92, 200), inner * 0.45)
    local availableHeight = math.max(0, deckHeight - (if short then 8 else 112))
    local side = math.max(0, math.floor(math.min(inner - knobWidth - 8, availableHeight)))
    local padGap = if side >= 220 then 8 else 4
    local padSize = math.max(0, math.floor((side - padGap * 3) / 4))
    local groupWidth = side + 8 + knobWidth
    local x, y =
        8 + math.max(0, (inner - groupWidth) / 2),
        (if short then 4 else 56) + math.max(0, (availableHeight - side) / 2)
    self.padGrid.Position, self.padGrid.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(side, side)
    self.padLayout.CellSize, self.padLayout.CellPadding =
        UDim2.fromOffset(padSize, padSize), UDim2.fromOffset(padGap, padGap)
    self.padControls.root.Position = UDim2.fromOffset(x + side + 8, y)
    self.padControls:resize(knobWidth, side)
    self.performanceDeck:SetAttribute("PadTargetPixels", padSize)
    self.performanceDeck:SetAttribute("AllPadsFixed", true)
end

function View:absolutePad()
    return ((self.state and self.state.music and self.state.music.bank or 1) - 1) * 16
        + self.selectedPad
end
function View:beginPad(pad, token)
    if
        not self.panel.Visible
        or not self.state
        or not self.state.ready
        or not self.state.music
        or type(pad) ~= "number"
        or pad % 1 ~= 0
        or pad < 1
        or pad > 16
    then
        return false
    end
    self:selectPad(pad)
    return self.padInput:begin(self:absolutePad(), token)
end
function View:selectPad(pad)
    if type(pad) ~= "number" or pad % 1 ~= 0 or pad < 1 or pad > 16 then
        return
    end
    if self.selectedPad ~= pad then
        self.padControls:cancel()
    end
    self.selectedPad = pad
    self.renderKey = nil
    if self.state then
        self:update(self.state)
    end
end
function View:cancelInput(interrupted)
    self.padInput:cancel()
    self.padControls:cancel()
    if interrupted and self.callbacks.interrupt then
        self.callbacks.interrupt()
    end
end
function View:showPage(name)
    if not self.pages[name] then
        return
    end
    self.page = name
    for key, page in self.pages do
        page.Visible = key == name
        self.tabs[key]:SetAttribute("Selected", key == name)
        self.tabs[key].TextColor3 = if key == name then Theme.Amber else Theme.Cream
    end
    self.editorDeck:SetAttribute("ActivePage", name)
    self.context.Text = if name == "Song"
        then self.songPosition.Text
        else self.editorContext or self.context.Text
end
function View:setMuted(value)
    self.muted = value == true
    self.callbacks.mute(self.muted)
    self.soundButton.Text = if self.muted then "Sound MUTED" else "Sound ON"
end
function View:notice(text)
    self.noticeLabel.Text = text or ""
    if
        self.panel:GetAttribute("TightLayout")
        and text
        and text ~= ""
        and text ~= self.lastToast
    then
        self.lastToast = text
        self.toastText.Text, self.toast.Visible = text, true
        self.toastEpoch = (self.toastEpoch or 0) + 1
        local epoch = self.toastEpoch
        task.delay(3, function()
            if self.toast.Parent and self.toastEpoch == epoch then
                self.toast.Visible = false
            end
        end)
    end
end
function View:update(state)
    local wasVisible = self.panel.Visible
    local previous = self.state
    local oldMusic, newMusic = previous and previous.music, state.music
    if
        previous
        and (
            previous.station ~= state.station
            or (
                oldMusic
                and newMusic
                and (
                    oldMusic.projectId ~= newMusic.projectId
                    or oldMusic.trackId ~= newMusic.trackId
                    or oldMusic.sequenceId ~= newMusic.sequenceId
                    or oldMusic.bank ~= newMusic.bank
                    or (oldMusic.program and oldMusic.program.id)
                        ~= (newMusic.program and newMusic.program.id)
                )
            )
        )
    then
        self:cancelInput(false)
    end
    self.state = state
    self.panel.Visible = state.ready and state.station ~= nil
    if wasVisible and not self.panel.Visible then
        self:cancelInput(false)
    end
    local m = state.music
    if not m or not m.sequence or not m.track or not m.program or not state.pattern then
        self.panel.Visible = false
        return
    end
    self.fieldVersions = self.fieldVersions or {}
    local function syncField(field, value, context)
        local version = tostring(context) .. ":" .. tostring(value)
        if self.fieldVersions[field] ~= version then
            if Input:GetFocusedTextBox() ~= field then
                field.Text = tostring(value)
            end
            self.fieldVersions[field] = version
        end
    end
    syncField(self.bars, m.sequence.bars, m.sequenceId)
    syncField(self.velocity, m.velocity, m.projectId)
    syncField(self.swing, m.swing, m.projectId)
    syncField(self.songBpm, if m.draft then m.draft.bpm else 96, m.draftId)
    self.hardware:update(state, self:absolutePad())
    self.padControls:update(state, self:absolutePad())
    self.context.Text = string.format(
        "%s  /  %s  /  Bank %s  /  %d BPM  /  Bar %d of %d",
        m.sequence.name,
        m.track.name,
        string.char(64 + m.bank),
        m.sequence.bpm,
        m.bar,
        m.sequence.bars
    )
    self.editorContext = self.context.Text
    self.barLabel.Text = string.format("Bar %d / %d", m.bar, m.sequence.bars)
    self.padLabel.Text = address(self:absolutePad())
        .. " / "
        .. (
            Catalog.ById[state.pattern.assignments[self:absolutePad()]]
            or Catalog.RetiredById[state.pattern.assignments[self:absolutePad()]]
            or { label = "Unavailable source" }
        ).label
    self.padMute.Text = if state.pattern.muted[self:absolutePad()] then "Unmute pad" else "Mute pad"
    self.fullLevel.Text = if m.fullLevel then "Full Level 127" else "Full Level OFF"
    self.repeatButton.Text = if m.noteRepeat then "Note Repeat ON" else "Note Repeat OFF"
    self.countIn.Text = if m.countIn then "Count-in ON" else "Count-in OFF"
    self.trackMute.Text = if m.track.mix.muted then "Unmute track" else "Mute track"
    self.trackSolo.Text = if m.track.mix.solo then "Unsolo track" else "Solo track"
    self.broadcastButton.Text = if state.broadcast
        then "Street broadcast ON"
        else "Street broadcast OFF"
    for bank, b in self.bankButtons do
        b:SetAttribute("Selected", bank == m.bank)
        b.TextColor3 = if bank == m.bank then Theme.Amber else Theme.Cream
    end
    for physical, b in self.pads do
        local absolute = (m.bank - 1) * 16 + physical
        local sampleId = state.pattern.assignments[absolute]
        local sample = Catalog.ById[sampleId] or Catalog.RetiredById[sampleId]
        local sampleName = sample and sample.label or "Unavailable source"
        b:SetAttribute("AbsolutePad", absolute)
        b:SetAttribute("Address", address(absolute))
        b:SetAttribute("SampleName", sampleName)
        local legends = sample and padLegends[sample.bank]
        b:SetAttribute(
            "ShortName",
            if legends then legends[sample.pad] else string.upper(sampleName)
        )
        b:SetAttribute("SoundFamily", sample and sample.bank)
        b:SetAttribute("PadMuted", state.pattern.muted[absolute] == true)
        b:SetAttribute("PadSelected", physical == self.selectedPad)
        b:SetAttribute("PreviewAvailable", Catalog.isPreviewAvailable(sampleId, state.unlocked))
        b:SetAttribute("AudioReady", Catalog.isReady(sampleId, state.unlocked))
        Skin.setPadDown(b, self.padInput.held[absolute] ~= nil)
    end
    self.transportButtons.Play:SetAttribute("Selected", state.playing == true)
    self.transportButtons.Record:SetAttribute("Selected", state.recording == true)
    self.transportButtons.Play.Text = if state.playing then "PAUSE" else "PLAY"
    self.transportButtons.Record.TextColor3 = if state.recording then Theme.Coral else Theme.Cream
    local selectedRow = state.pattern.rows and state.pattern.rows[self:absolutePad()] or {}
    for step, b in self.steps do
        b.BackgroundColor3 = if selectedRow[step] then Theme.Amber else Theme.Graphite
        b:SetAttribute("EnabledStep", selectedRow[step] == true)
    end
    self.sampleEditor:update(state, self:absolutePad())
    self.guide:update(state)
    if state.notice then
        self:notice(state.notice)
    end
    self.saveStatus.Text = if state.saving
        then "Saving…"
        elseif state.dirty then "Unsaved edits"
        else "Saved snapshot"
    self.saveStatus.Text ..= if state.saveMode == "session"
        then " / this Studio session only"
        elseif state.saveMode == "unavailable" then " / storage unavailable"
        else " / cloud"
    local key = tostring(m.projectRevision)
        .. ":"
        .. m.sequenceId
        .. ":"
        .. m.trackId
        .. ":"
        .. m.program.id
        .. ":"
        .. m.bank
        .. ":"
        .. tostring(m.draftId)
        .. ":"
        .. m.bar
        .. ":"
        .. self.selectedPad
        .. ":"
        .. #m.finishedSongs
        .. ":"
        .. tostring(state.saving)
        .. ":"
        .. tostring(state.unlocked and state.unlocked.I01)
        .. ":"
        .. tostring(state.unlocked and state.unlocked.I02)
        .. ":"
        .. tostring(state.unlocked and state.unlocked.I03)
    if
        key ~= self.renderKey
        and not Input:GetFocusedTextBox()
        and (not state.recording or os.clock() >= (self.nextLibraryRenderAt or 0))
    then
        self.nextLibraryRenderAt = os.clock() + 0.25
        self.renderKey = key
        clear(self.sequenceList)
        clear(self.trackList)
        clear(self.kitList)
        clear(self.nextList)
        clear(self.draftList)
        clear(self.assignmentList)
        for _, seq in m.library.sequences do
            local id = seq.id
            orderedButton(
                self.sequenceList,
                seq.name .. (if seq.id == m.sequenceId then " / editing" else ""),
                function()
                    self.callbacks.command("SequenceSelect", id)
                end
            )
            orderedButton(self.nextList, seq.name, function()
                self.callbacks.command("NextSequence", id)
            end)
        end
        for _, track in m.library.tracks do
            local id = track.id
            orderedButton(self.trackList, track.name, function()
                self.callbacks.command("TrackSelect", id)
            end)
        end
        for _, program in m.library.programs do
            local id = program.id
            orderedButton(self.kitList, program.name .. " / shared " .. program.sharedBy, function()
                self.callbacks.command("TrackProgram", { programId = id })
            end)
        end
        for _, draft in m.library.drafts do
            local id = draft.id
            orderedButton(self.draftList, draft.name, function()
                self.callbacks.command("SongSelect", id)
            end)
        end
        for _, sample in Catalog.List do
            local id = sample.id
            if Catalog.isUnlocked(id, state.unlocked) then
                local ready = Catalog.isLocallyPlayable(id, state.unlocked)
                local preview = Catalog.isPreviewAvailable(id, state.unlocked)
                local item = orderedButton(
                    self.assignmentList,
                    sample.label
                        .. (
                            if ready
                                then " / ready"
                                elseif preview then " / local preview"
                                else " / no file"
                        ),
                    function()
                        if Catalog.isLocallyPlayable(id, self.state and self.state.unlocked) then
                            self.callbacks.command("Assign", self:absolutePad(), id)
                        end
                    end
                )
                item.Active, item.Selectable, item.AutoButtonColor = ready, ready, ready
                item.BackgroundColor3 = if ready then Theme.Teal else Theme.Graphite
            end
        end
        clear(self.eventList)
        for _, event in m.sequence.trackEvents[m.trackId] or {} do
            if
                event.pad == self:absolutePad()
                and event.tick >= (m.bar - 1) * 3840
                and event.tick < m.bar * 3840
            then
                local id = event.eventId
                local tick = event.tick
                local velocity = event.velocity
                label(
                    self.eventList,
                    string.format("%s / tick %d / velocity %d", address(event.pad), tick, velocity),
                    30
                )
                local row = flow(self.eventList)
                orderedButton(row, "Velocity −", function()
                    self.callbacks.command(
                        "EventVelocity",
                        { eventId = id, velocity = math.max(1, velocity - 8) }
                    )
                end)
                orderedButton(row, "Velocity +", function()
                    self.callbacks.command(
                        "EventVelocity",
                        { eventId = id, velocity = math.min(127, velocity + 8) }
                    )
                end)
                orderedButton(row, "Move +60 ticks", function()
                    self.callbacks.command("EventPut", {
                        eventId = id,
                        pad = event.pad,
                        tick = math.min(m.sequence.bars * 3840 - 1, tick + 60),
                        velocity = velocity,
                    })
                end)
                orderedButton(row, "Remove event", function()
                    self.callbacks.command("EventRemove", { eventId = id })
                end)
            end
        end
        clear(self.songSteps)
        local summary
        for _, draft in m.library.drafts do
            if draft.id == m.draftId then
                summary = draft
            end
        end
        if summary then
            self.songSummary.Text = string.format(
                "%s / %d bars / %.1f seconds / %s tempo / revision %d",
                summary.name,
                summary.totalBars,
                summary.duration,
                summary.tempoMode,
                summary.revision
            )
            self.tempoMode.Text = if summary.tempoMode == "song"
                then "Use Sequence tempo"
                else "Use Song tempo"
            for index, step in summary.steps do
                local id = step.stepId
                local card = Gui.round(
                    Gui.make("Frame", self.songSteps, {
                        Name = "ArrangementStep_" .. id,
                        Size = UDim2.new(1, -12, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundColor3 = Color3.fromRGB(29, 54, 45),
                        BorderSizePixel = 0,
                        LayoutOrder = index,
                    }),
                    7
                )
                card:SetAttribute("StepId", id)
                Gui.make(
                    "UIListLayout",
                    card,
                    { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
                )
                Gui.make("UIPadding", card, {
                    PaddingTop = UDim.new(0, 8),
                    PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 8),
                })
                local head = Gui.make(
                    "Frame",
                    card,
                    { Size = UDim2.new(1, -8, 0, 78), BackgroundTransparency = 1, LayoutOrder = 1 }
                )
                local number = Gui.label(head, string.format("%02d", index), 22, Theme.Amber)
                number.Font, number.Size = Enum.Font.Code, UDim2.fromOffset(40, 32)
                local title = Gui.label(head, step.name, 15, lcdText)
                title.Font, title.Position, title.Size =
                    Enum.Font.Code, UDim2.fromOffset(44, 0), UDim2.new(1, -142, 0, 30)
                local detail = Gui.label(
                    head,
                    string.format("%d bars × %d", step.bars, step.repeats),
                    12,
                    lcdText
                )
                detail.Font, detail.Position, detail.Size =
                    Enum.Font.Code, UDim2.fromOffset(44, 30), UDim2.new(1, -142, 0, 22)
                local strip = Gui.make("Frame", head, {
                    Name = "RepeatBlocks",
                    Position = UDim2.fromOffset(44, 60),
                    Size = UDim2.new(1, -54, 0, 10),
                    BackgroundTransparency = 1,
                })
                local blocks = math.min(16, step.repeats)
                for repeatIndex = 1, blocks do
                    Gui.round(
                        Gui.make("Frame", strip, {
                            Position = UDim2.fromScale((repeatIndex - 1) / blocks, 0),
                            Size = UDim2.new(1 / blocks, -3, 1, 0),
                            BackgroundColor3 = if index % 2 == 0
                                then Theme.Amber
                                else Theme.FadedTeal,
                            BorderSizePixel = 0,
                        }),
                        2
                    )
                end
                local edit = orderedButton(head, "EDIT", function()
                    self.expandedSongStep = if self.expandedSongStep == id then nil else id
                    self.renderKey = nil
                    self:update(self.state)
                end)
                edit.Position, edit.Size = UDim2.new(1, -92, 0, 2), UDim2.fromOffset(84, 44)
                edit:SetAttribute("UiIcon", "knob")
                local actions = flow(card)
                actions.LayoutOrder, actions.Visible = 2, self.expandedSongStep == id
                for _, item in
                    {
                        { "Up", "SongStepMove", { stepId = id, index = math.max(1, index - 1) } },
                        {
                            "Down",
                            "SongStepMove",
                            {
                                stepId = id,
                                index = math.min(#summary.steps, index + 1),
                            },
                        },
                        {
                            "Repeat −",
                            "SongStepUpdate",
                            { stepId = id, repeats = math.max(1, step.repeats - 1) },
                        },
                        {
                            "Repeat +",
                            "SongStepUpdate",
                            { stepId = id, repeats = math.min(32, step.repeats + 1) },
                        },
                        { "Duplicate", "SongStepDuplicate", { stepId = id, index = index + 1 } },
                        { "Remove", "SongStepRemove", { stepId = id } },
                        {
                            "Use selected sequence",
                            "SongStepUpdate",
                            { stepId = id, sequenceId = m.sequenceId },
                        },
                        { "Audition here", "SongSeek", index },
                    }
                do
                    local action, value = item[2], item[3]
                    orderedButton(actions, item[1], function()
                        self.callbacks.command(action, value)
                    end)
                end
            end
        else
            self.songSummary.Text =
                "Add a sequence to start your song. Create a draft, then add your selected sequence."
        end
        clear(self.libraryList)
        label(self.libraryList, "SEQUENCES / saved editable ideas", 32)
        for _, seq in m.library.sequences do
            local id = seq.id
            orderedButton(
                self.libraryList,
                string.format(
                    "%s / %d bars / %s",
                    seq.name,
                    seq.bars,
                    if seq.savedRevision == seq.revision then "saved" else "unsaved edits"
                ),
                function()
                    self.callbacks.command("SequenceSelect", id)
                    self:showPage("Sequence")
                end
            ).Size =
                UDim2.new(1, -12, 0, 48)
        end
        label(self.libraryList, "SONG DRAFTS / mutable arrangements", 32)
        for _, draft in m.library.drafts do
            local id = draft.id
            orderedButton(
                self.libraryList,
                draft.name .. " / " .. draft.totalBars .. " bars",
                function()
                    self.callbacks.command("SongSelect", id)
                    self:showPage("Song")
                end
            ).Size =
                UDim2.new(1, -12, 0, 48)
        end
        label(self.libraryList, "FINISHED SONGS / saved immutable revisions", 32)
        if #m.finishedSongs == 0 then
            label(
                self.libraryList,
                "No finished songs yet. Arrange sections in Song Mode, then Finish & Save Song once their audio is ready.",
                68
            )
        end
        for _, song in m.finishedSongs do
            local id = song.id
            label(self.libraryList, (song.title or "Song") .. " / revision " .. song.revision, 32)
            local actions = flow(self.libraryList)
            orderedButton(actions, "Select for performance", function()
                self.callbacks.command("FinishedSelect", id)
            end)
            orderedButton(actions, "Play selected song", function()
                self.callbacks.command("FinishedSelect", id)
                self.callbacks.command("FinishedPlay")
            end)
            orderedButton(actions, "Open editable copy", function()
                self.callbacks.command("FinishedOpen", id)
            end)
        end
        if m.hasRecovery then
            orderedButton(self.libraryList, "Open retained recovery project", function()
                self.callbacks.command("RecoveryOpen")
            end).Size =
                UDim2.new(1, -12, 0, 48)
        end
        label(self.libraryList, "LEGACY IMPORTS / original maps and notes retained", 32)
        for _, archive in m.archives do
            local id = archive.id
            orderedButton(self.libraryList, archive.name, function()
                self.callbacks.command("ArchiveOpen", id)
            end).Size =
                UDim2.new(1, -12, 0, 48)
        end
    end
    self:tick()
end
function View:playhead(step)
    for index, b in self.steps do
        b.Text = tostring(index)
        b:SetAttribute("Playhead", index == step)
    end
end
function View:pulsePad(pad, route)
    local m = self.state and self.state.music
    if
        not self.panel.Visible
        or not m
        or type(pad) ~= "number"
        or pad % 1 ~= 0
        or pad < 1
        or pad > 64
        or math.floor((pad - 1) / 16) + 1 ~= m.bank
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
function View:tick()
    self.hardware:signal(if self.callbacks.signal then self.callbacks.signal() else 0)
    local m = self.state and self.state.music
    if not m then
        return
    end
    local t = m.transport
    if not t then
        self.transportLabel.Text = "Stopped / editor selection is separate from playback"
        self.songPosition.Text = "Stopped / add sections, then play your song from the beginning."
        if self.page == "Song" then
            self.context.Text = self.songPosition.Text
        end
        return
    end
    local seconds = (t.offset or 0)
        + (if t.playing then math.max(0, workspace:GetServerTimeNow() - t.startedAt) else 0)
    if t.loop and t.schedule.duration > 0 then
        seconds %= t.schedule.duration
    end
    local cursor = Transport.cursor(t.schedule, seconds)
    self.transportLabel.Text = string.format(
        "%s / %s / bar %d beat %d / %.1f of %.1fs%s",
        if t.playing then (if self.state.recording then "RECORDING" else "PLAYING") else "PAUSED",
        cursor.sequenceName or t.schedule.title or "Song",
        cursor.bar,
        cursor.beat,
        seconds,
        t.schedule.duration,
        if m.queued then " / next queued" else ""
    )
    local lastSection = t.schedule.sections[#t.schedule.sections]
    self.songPosition.Text = if t.ref and (t.ref.kind == "song" or t.ref.kind == "finished")
        then string.format(
            "%s / Step %d of %d / %s / repeat %d of %d / bar %d beat %d / %.1f of %.1fs",
            if t.playing then "PLAYING" else "STOPPED / PAUSED",
            cursor.stepIndex or 1,
            lastSection and lastSection.stepIndex or 1,
            cursor.sequenceName or "Song",
            cursor.repetition or 1,
            cursor.repeats or 1,
            cursor.bar,
            cursor.beat,
            math.min(seconds, t.schedule.duration),
            t.schedule.duration
        )
        else "Sequence preview / " .. self.transportLabel.Text
    self.context.Text = if self.page == "Song"
        then self.songPosition.Text
        else self.editorContext or self.context.Text
    self:playhead(math.floor((cursor.sequenceTick or 0) % 3840 / 240) + 1)
end
return View
