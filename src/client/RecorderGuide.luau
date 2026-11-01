local Shared = game.ReplicatedStorage.Shared
local Discoveries = require(Shared.DiscoveryCatalog)
local Missions = require(Shared.NeighborhoodMissions)
local Catalog = require(Shared.SampleCatalog)
local Hunt = require(Shared.SoundHunt)
local Sequence = require(Shared.MusicSequence)
local Gui = require(script.Parent.GuiFactory)
local W = require(script.Parent.DeviceWidgets)
local Guide = {}
Guide.__index = Guide

local function visible(object)
    while object do
        if object:IsA("GuiObject") and not object.Visible then
            return false
        elseif object:IsA("ScreenGui") and not object.Enabled then
            return false
        end
        object = object.Parent
    end
    return true
end

function Guide.new(parent, api)
    local self = setmetatable({
        cards = {}, open = false, api = api, selectedId = "I01", step = 1,
        echoToken = 0, controls = {}, selectors = {}, connections = {},
    }, Guide)
    self.frame = Gui.make("Frame", parent, {
        Name = "VirtualRecorder", Size = UDim2.new(1, -8, 0, 48),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2,
    })
    Gui.make("UIListLayout", self.frame, {
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8),
    })
    self.toggle = Gui.button(self.frame, "Virtual recorder / Jobs 0/3 / Open guide", function()
        self:setOpen(not self.open)
    end)
    self.toggle.Size, self.toggle.LayoutOrder = UDim2.new(1, 0, 0, 48), 1
    self.body = Gui.make("Frame", self.frame, {
        Name = "RecorderDetails", Size = UDim2.fromScale(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        Visible = false, LayoutOrder = 2,
    })
    Gui.make("UIListLayout", self.body, {
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12),
    })
    self.intro = Gui.label(self.body, "", 14, if api then W.text else nil)
    self.intro.Size, self.intro.AutomaticSize, self.intro.LayoutOrder =
        UDim2.new(1, 0, 0, 84), Enum.AutomaticSize.Y, 1
    for index, id in Discoveries.Order do
        local card = Gui.label(self.body, "", 14, if api then W.text else nil)
        card.Name = "Recorder_" .. id
        card.Size, card.AutomaticSize, card.LayoutOrder =
            UDim2.new(1, 0, 0, 120), Enum.AutomaticSize.Y, index + 3
        self.cards[id] = card
    end
    if api then
        self:buildActions()
    end
    self.frame.Destroying:Connect(function()
        self.destroyed = true
        self:cancel()
        for _, connection in self.connections do
            connection:Disconnect()
        end
    end)
    return self
end

function Guide:buildActions()
    self.sources = W.frame(self.body, "DiscoverySources")
    self.sources.LayoutOrder = 2
    local sourceGrid = Gui.make("UIGridLayout", self.sources, {
        SortOrder = Enum.SortOrder.LayoutOrder, CellPadding = UDim2.fromOffset(4, 4),
    })
    for index, id in Discoveries.Order do
        local key = W.key(self.sources, id, ({ "waves", "knob", "sound" })[index],
            ({ "DOCK", "VENT", "CHIRP" })[index], function()
                self:cancel()
                self.selectedId, self.feedback = id, nil
                self:paint()
            end)
        key.LayoutOrder = index
        self.selectors[id] = key
    end
    self.actionInfo = W.label(self.body, "DiscoveryActionStatus", "", 13, W.amber)
    self.actionInfo.LayoutOrder = 8
    self.actionInfo.Size = UDim2.new(1, 0, 0, 72)
    self.actionInfo.AutomaticSize = Enum.AutomaticSize.Y
    self.actions = W.frame(self.body, "DiscoveryActions")
    self.actions.LayoutOrder = 9
    local grid = Gui.make("UIGridLayout", self.actions, {
        SortOrder = Enum.SortOrder.LayoutOrder, CellPadding = UDim2.fromOffset(4, 6),
    })
    local function add(name, icon, text, callback)
        local button = W.key(self.actions, name, icon, text, function()
            if self:canUse() then
                callback()
            end
        end)
        button.LayoutOrder = #self.controls + 1
        self[name] = button
        table.insert(self.controls, button)
    end
    add("audition", "sound", "AUDITION SOURCE", function()
        self:cancel()
        self.api.command("DiscoveryPreview", Hunt.packet(self.state, self.selectedId, self.step))
    end)
    add("locate", "pads", "FIND PAD / EDIT", function()
        local source = Hunt.source(self.selectedId)
        local pad = source and Hunt.pad(self.state.music.program, source.id)
        if pad then
            self:cancel()
            self.api.command("Bank", math.floor((pad - 1) / 16) + 1)
            self.api.selectPad((pad - 1) % 16 + 1)
            self.api.edit()
        end
    end)
    add("previousStep", "undo", "STEP -", function()
        self.step = math.max(1, self.step - 1)
        self:paint()
    end)
    add("nextStep", "redo", "STEP +", function()
        self.step = math.min(16, self.step + 1)
        self:paint()
    end)
    add("addNote", "plus", "ADD ONE NOTE", function()
        self:cancel()
        self.api.command("DiscoveryAdd", Hunt.packet(self.state, self.selectedId, self.step))
    end)
    add("play", "play", "PLAY MY LOOP", function()
        self:cancel()
        self.api.command("PlayStart")
    end)
    add("variation", "steps", "COPY VARIATION", function()
        self:cancel()
        self.api.command("SequenceDuplicate", { expectedRevision = self.state.music.projectRevision })
    end)
    add("save", "disc", "SAVE PROJECT", function()
        self:cancel()
        self.api.command("SaveProject")
    end)
    add("listen", "sound", "OPTIONAL ECHO", function()
        self:listenEcho()
    end)
    add("check", "check", "CHECK ECHO GRID", function()
        local source = Hunt.source(self.selectedId)
        local m = self.state.music
        local pad = source and Hunt.pad(m.program, source.id)
        self.feedback = if Hunt.echoMatches(m.sequence, m.trackId, pad, m.bar, self.selectedId)
            then "The note positions match this optional echo. No reward or listening score is awarded."
            else "Try the displayed steps, or skip. Your own rhythm can still complete the creative job."
        self:paint()
    end)
    add("skip", "close", "SKIP ECHO", function()
        self:cancel()
        self.feedback = "Echo skipped. Keep your own rhythm; save it for the creative job."
        self:paint()
    end)
    add("edit", "steps", "BACK TO NOTES", function()
        self:cancel()
        self.api.edit()
    end)
    local function resize()
        self:cancel()
        local width = math.max(0, self.frame.AbsoluteSize.X)
        local columns = if width >= 240 then 2 else 1
        grid.CellSize = UDim2.fromOffset(math.max(0, (width - (columns - 1) * 4) / columns), 44)
        self.actions.Size = UDim2.new(1, 0, 0, math.ceil(#self.controls / columns) * 50)
        local sourceColumns = if width >= 240 then 3 else 1
        sourceGrid.CellSize = UDim2.fromOffset(
            math.max(0, (width - (sourceColumns - 1) * 4) / sourceColumns), 44
        )
        self.sources.Size = UDim2.new(1, 0, 0, (3 / sourceColumns) * 48)
    end
    table.insert(self.connections, self.frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        -- AutomaticSize also changes height; only width affects grid layout.
        if self.lastWidth ~= self.frame.AbsoluteSize.X then
            self.lastWidth = self.frame.AbsoluteSize.X
            resize()
        end
    end))
    resize()
end

function Guide:canUse()
    local s = self.state
    return not self.destroyed and self.api ~= nil and self.frame.Parent ~= nil
        and self.open and visible(self.frame) and s ~= nil and s.ready == true
        and s.station ~= nil and s.music ~= nil and s.music.sequence ~= nil
end

function Guide:cancel()
    -- Already-submitted one-shot tails are left to the shared engine; only
    -- pending reference hits are invalidated, without stopping the player's music.
    self.echoToken += 1
end

function Guide:listenEcho()
    local s = self.state
    local source = Hunt.source(self.selectedId)
    if not self:canUse() or not source or not s.unlocked[self.selectedId]
        or not Catalog.isPlaybackReady(source.id, s.unlocked) or s.playing or s.recording
        or (s.jam and s.jam.active)
    then
        return
    end
    self:cancel()
    local token = self.echoToken
    local bpm = math.clamp(s.music.sequence.bpm, Sequence.MinBpm, Sequence.MaxBpm)
    self.feedback = "Reference playback requested. Copy the displayed steps, or skip and make your own rhythm."
    self:paint()
    for _, step in Hunt.Echo[self.selectedId] do
        task.delay((step - 1) * 60 / bpm / 4, function()
            if token == self.echoToken and self:canUse()
                and Catalog.isPlaybackReady(source.id, self.state.unlocked)
            then
                -- Reuse the same engine as ordinary cues/auditions, with the
                -- unprocessed authored source. No second audio engine or remote clock.
                Gui.Cue:Fire(source.id)
            end
        end)
    end
end

function Guide:setOpen(open)
    self:cancel()
    self.open = open == true
    self.body.Visible = self.open
    if self.state then
        self:paint()
    end
end

function Guide:update(state)
    local m = state.music or {}
    local route = table.concat({
        tostring(state.station), tostring(m.projectId), tostring(m.workspaceGeneration),
        tostring(m.projectRevision), tostring(m.sequenceId), tostring(m.trackId),
        tostring(m.bank), tostring(m.bar), tostring(state.epoch),
    }, ":")
    if route ~= self.route then
        self:cancel()
        self.feedback = nil
    end
    self.route, self.state = route, state
    self:paint()
end

function Guide:paint()
    local state = self.state
    if not state or self.destroyed then
        return
    end
    local progress = state.neighborhood or { completed = 0, earned = {}, objective = "Find a source and make your own rhythm." }
    self.toggle.Text = string.format("Virtual recorder / Jobs %d/3 / %s", progress.completed,
        if self.open then "Close guide" else "Open guide")
    self.intro.Text = "Authored game sounds, not microphone recording. Discovery adds context; your full instrument stays available. Exact echoes are optional. Creative jobs use your saved music.\nNEXT: "
        .. progress.objective
        .. (if state.saveMode == "session" then "\nSaved progress lasts for this Studio session only."
            elseif state.saveMode == "unavailable" then "\nStorage unavailable: current edits are temporary."
            else "")
    for index, id in Discoveries.Order do
        local definition = Discoveries.ById[id]
        local jobId, job = Missions.Order[index], Missions.Definitions[Missions.Order[index]]
        local collected = state.unlocked and state.unlocked[id] == true
        self.cards[id].Visible = self.api == nil or id == self.selectedId
        self.cards[id].Text = definition.label .. " / " .. (if collected then "COLLECTED" else "FIND THE SOURCE")
            .. "\n" .. definition.origin .. "\n" .. job.title .. ": "
            .. (if progress.earned[jobId] then "COMPLETE / " .. job.reward else job.objective)
        if self.selectors[id] then
            self.selectors[id]:SetAttribute("Selected", id == self.selectedId)
        end
    end
    if not self.api then
        return
    end
    local source = Hunt.source(self.selectedId)
    local m = state.music or {}
    local pad = source and Hunt.pad(m.program, source.id)
    local collected = state.unlocked and state.unlocked[self.selectedId] == true
    local playable = source ~= nil and Catalog.isPlaybackReady(source.id, state.unlocked)
    local usable = state.ready and state.station ~= nil and m.sequence ~= nil
    local status = if not collected then "Collect this source at its nearby quay prompt."
        elseif not playable then "Audio unavailable here. Your existing sounds are not replaced."
        elseif not pad then "This track has no matching pad. Assign the collected source through Sounds first."
        else "Current pad " .. Hunt.address(pad) .. "; bar " .. tostring(m.bar) .. ", step " .. tostring(self.step)
    local steps = {}
    for _, step in Hunt.Echo[self.selectedId] do
        table.insert(steps, tostring(step))
    end
    local saved = if state.saving then "SAVING SNAPSHOT"
        elseif state.saveMode == "unavailable" then "TEMPORARY / STORAGE UNAVAILABLE"
        elseif state.dirty then "UNSAVED CHANGES"
        elseif not state.hasSave then "NEW WORKSPACE"
        elseif state.saveMode == "session" then "SESSION SAVED"
        else "SAVED TO STORAGE"
    self.actionInfo.Text = status .. "\n" .. saved
        .. "\nOptional echo steps: " .. table.concat(steps, ", ")
        .. "\nCopy Variation copies notes; the track kit remains shared."
        .. (if source and source.sourceSubstitute then "\nExplicit Studio substitute; original recording/listening approval remains pending." else "")
        .. (if self.feedback then "\n" .. self.feedback else "")
        .. (if state.notice and state.notice ~= "" then "\nLast action: " .. state.notice else "")
    local enabled = {
        audition = usable and collected and playable and not (state.jam and state.jam.active),
        locate = usable and pad ~= nil,
        previousStep = usable and self.step > 1,
        nextStep = usable and self.step < 16,
        addNote = usable and collected and playable and pad ~= nil and not state.recording,
        play = usable and not (state.jam and state.jam.active),
        variation = usable and not state.recording,
        save = usable and not state.saving and state.saveMode ~= "unavailable",
        listen = usable and collected and playable and not state.playing and not state.recording
            and not (state.jam and state.jam.active),
        check = usable and pad ~= nil,
        skip = usable,
        edit = usable,
    }
    for name, active in enabled do
        local button = self[name]
        button.Active, button.Selectable = active == true, active == true
        button.Legend.TextTransparency = if active then 0 else 0.55
    end
    W.legend(self.addNote, "ADD AT STEP " .. self.step)
end

return Guide
