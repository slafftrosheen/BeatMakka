-- Optional guidance over the normal workstation. Every musical edit uses the
-- existing command path; this view owns neither audio nor a second music model.
local W = require(script.Parent.DeviceWidgets)
local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.SampleCatalog)
local Groove = require(Shared.FirstGroove)
local Sequence = require(Shared.MusicSequence)
local VisualSteps = require(script.Parent.VisualSteps)
local Coach = {}
Coach.__index = Coach

local tips = {
    "Choose a sound below, then tap its physical pad.",
    "EDIT NOTES: tap a step to place a hit. Banks A–D change sounds.",
    "PLAY your loop. Mute a sound, bring it back, or UNDO an edit.",
    "Name it, then SAVE. Wait for SAVED or SESSION SAVED.",
    "REOPEN SAVE keeps current edits in recovery. Arrange loops in SONG when ready.",
}

local function enabled(button, value)
    button.Active, button.Selectable = value, value
    button.TextTransparency = if value then 0 else 0.5
    if not value then
        button.FocusRing.Enabled = false
    end
end

local function button(parent, name, text, callback)
    local b = W.make("TextButton", parent, {
        Name = name,
        Text = text,
        Font = Enum.Font.Code,
        TextSize = 13,
        TextWrapped = true,
        TextColor3 = W.ink,
        BackgroundColor3 = Color3.fromRGB(224, 211, 175),
        BorderSizePixel = 0,
        AutoButtonColor = true,
        Active = true,
        Selectable = true,
    })
    W.make("UICorner", b, { CornerRadius = UDim.new(0, 5) })
    local focus = W.make("UIStroke", b, {
        Name = "FocusRing",
        Color = W.amber,
        Thickness = 2,
        Enabled = false,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    b.SelectionGained:Connect(function()
        focus.Enabled = b.Active
    end)
    b.SelectionLost:Connect(function()
        focus.Enabled = false
    end)
    b.Activated:Connect(function()
        if b.Active then
            callback()
        end
    end)
    return b
end

local function context(state)
    local m = state and state.music
    if not m then
        return ""
    end
    return table.concat({
        tostring(state.station), m.projectId, tostring(m.workspaceGeneration or 0),
        tostring(m.projectRevision), tostring(state.editVersion),
        tostring(m.sequenceId), tostring(m.trackId), tostring(m.bank),
    }, ":")
end

local function saveStatus(state)
    if not state or not state.ready then
        return "LOADING"
    elseif state.saving then
        return "SAVING SNAPSHOT"
    elseif state.saveMode == "unavailable" then
        return "TEMPORARY / SAVE UNAVAILABLE"
    elseif state.dirty then
        return "UNSAVED CHANGES"
    elseif not state.hasSave then
        return "NEW / NOT SAVED"
    elseif state.saveMode == "session" then
        return "SESSION SAVED"
    end
    return "SAVED TO STORAGE"
end

function Coach.new(parent, api, changed)
    local self = setmetatable({ api = api, changed = changed, roles = {}, tip = 1, expanded = false }, Coach)
    self.root = W.frame(parent, "FirstGroove")
    self.root.Size = UDim2.fromScale(1, 1)
    self.status = W.label(self.root, "SaveStatus", "LOADING", 12, W.amber)
    self.toggle = button(self.root, "ToggleGuide", "FIRST GROOVE", function()
        self:setExpanded(not self.expanded)
    end)
    self.scroll = W.make("ScrollingFrame", self.root, {
        Name = "GuideContent", BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 4,
        ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false,
    })
    self.steps = VisualSteps.new(self.scroll, { { "SOUND", "pads" }, { "NOTES", "steps" }, { "LISTEN", "play" }, { "SAVE", "save" } })
    self.title = W.label(self.scroll, "Title", "MAKE A LOOP", 17, W.amber)
    self.example = button(self.scroll, "Example", "EXAMPLE LOOP", function()
        self:start("example")
    end)
    self.blank = button(self.scroll, "Blank", "START BLANK", function()
        self:start("blank")
    end)
    self.availability = W.label(self.scroll, "ExampleAvailability", "", 12)
    self.tipText = W.label(self.scroll, "OneStepHint", tips[1], 13)
    self.nextTip = button(self.scroll, "NextTip", "NEXT TIP", function()
        self.confirmation = nil
        self.tip = self.tip % #tips + 1
        self.message = nil
        self:paint()
    end)
    for index, role in Groove.Roles do
        local item = { root = W.frame(self.scroll, role.id), choices = {} }
        item.title = W.label(item.root, "Role", role.label .. " / " .. Groove.address(role.pad), 14, W.amber)
        item.select = button(item.root, "Select", Groove.address(role.pad), function()
            self:select(role.pad)
            self.message = role.hint .. " Tap " .. Groove.address(role.pad) .. " to hear it."
            self:paint()
        end)
        item.current = W.label(item.root, "CurrentSound", "", 12)
        for choiceIndex, slot in role.choices do
            item.choices[choiceIndex] = button(item.root, "Choice" .. choiceIndex, "", function()
                self:choose(index, slot)
            end)
        end
        self.roles[index] = item
    end
    self.nameLabel = W.label(self.scroll, "NameLabel", "NAME YOUR LOOP", 14, W.amber)
    self.nameBox = W.make("TextBox", self.scroll, {
        Name = "LoopName", Text = "", PlaceholderText = "Name this loop",
        ClearTextOnFocus = false, Font = Enum.Font.Code, TextSize = 16,
        TextColor3 = W.text, BackgroundColor3 = W.ink, BorderSizePixel = 0,
    })
    self.rename = button(self.scroll, "Rename", "RENAME LOOP", function()
        local s = self.state
        local text = self.nameBox.Text
        if not s or not s.music then
            return
        end
        if #text < 1 or #text > 64 or not text:find("%S") then
            self.message = "Use a non-empty name of at most 64 UTF-8 bytes."
            self:paint()
            return
        end
        self.nameBox:ReleaseFocus()
        self:send("SequenceRename", {
            name = text, sequenceId = s.music.sequenceId, expectedRevision = s.music.projectRevision,
        })
    end)
    self.undo = button(self.scroll, "Undo", "UNDO", function()
        self:send("Undo")
    end)
    self.copy = button(self.scroll, "CopyVariation", "COPY VARIATION", function()
        local m = self.state and self.state.music
        if m then
            self:send("SequenceDuplicate", {
                sequenceId = m.sequenceId, name = "My variation", expectedRevision = m.projectRevision,
            })
        end
    end)
    self.mute = button(self.scroll, "MuteSound", "MUTE SOUND", function()
        local m = self.state and self.state.music
        if m and self.pad then
            self:send("PadMute", {
                sequenceId = m.sequenceId, trackId = m.trackId, pad = self.pad,
                muted = not (self.state.pattern.muted[self.pad] == true),
                expectedRevision = m.projectRevision,
            })
        end
    end)
    self.reopen = button(self.scroll, "ReopenSave", "REOPEN SAVE", function()
        if self:confirm("restore", "Press REOPEN SAVE again: restore the saved project; current edits become recovery.") then
            self:send("Restore", self.state.editVersion)
        end
    end)
    self.recovery = button(self.scroll, "OpenRecovery", "OPEN RECOVERY", function()
        self:send("RecoveryOpen")
    end)
    self.leave = button(self.scroll, "ReturnToQuay", "BACK TO QUAY", function()
        self:send("Release")
    end)
    self.show = button(self.scroll, "ShowBoard", "SHOW BOARD", function()
        self:send("QuayStage")
    end)
    self.boundary = W.label(self.scroll, "StorageBoundary", "", 12)
    self.detailsButton = button(self.scroll, "StorageHelp", "SAVE + RECOVERY HELP", function()
        self.detailsOpen = not self.detailsOpen
        if self.layoutWidth then self:resize(self.layoutWidth, self.layoutHeight) end
        self:paint()
    end)
    self.notice = W.label(self.scroll, "Result", "", 13, W.amber)
    self.footer = W.frame(self.root, "GuideActions")
    self.edit = button(self.footer, "EditNotes", "EDIT NOTES", function()
        self.tip = 2
        self:setExpanded(false)
    end)
    self.play = button(self.footer, "PlayLoop", "PLAY LOOP", function()
        self:send(if self.state and self.state.playing then "Stop" else "PlayStart")
    end)
    self.save = button(self.footer, "SaveProject", "SAVE", function()
        self:send("SaveProject")
    end)
    self.footer.Visible = false
    self.root.Destroying:Connect(function()
        self.dead, self.confirmation = true, nil
    end)
    return self
end

function Coach:send(action, a, b)
    if not self.state or not self.state.ready or not self.state.station then
        return
    end
    self.confirmation, self.message = nil, nil
    self.api.command(action, a, b)
end

function Coach:confirm(action, message)
    local key = context(self.state)
    local old = self.confirmation
    if old and old.action == action and old.key == key and os.clock() < old.untilAt then
        self.confirmation, self.message = nil, nil
        return true
    end
    local pending = { action = action, key = key, untilAt = os.clock() + 5 }
    self.confirmation, self.message = pending, message
    self:paint()
    task.delay(5, function()
        if not self.dead and self.confirmation == pending then
            self.confirmation, self.message = nil, "Confirmation expired; nothing was changed."
            self:paint()
        end
    end)
    return false
end

function Coach:start(mode)
    local s = self.state
    local m = s and s.music
    if not m or s.saving then
        return
    end
    if not self:confirm(mode, "Press again to open a new loop. Your current workspace will be preserved in CRATES / Archives.") then
        return
    end
    self.pendingStart = m.projectId
    self:send("GrooveStart", {
        schema = 1, mode = mode, projectId = m.projectId,
        projectRevision = m.projectRevision, editVersion = s.editVersion,
        workspaceGeneration = m.workspaceGeneration or 0, station = s.station,
    })
end

function Coach:select(pad)
    if not self.state or not self.state.music then
        return
    end
    self:send("Bank", math.floor((pad - 1) / 16) + 1)
    self.api.selectPad((pad - 1) % 16 + 1)
end

function Coach:choose(index, slot)
    local m = self.state and self.state.music
    local role, sample = Groove.Roles[index], Catalog.List[slot]
    if not m or not role or not sample or not Catalog.isPlaybackReady(sample.id, self.state.unlocked) then
        return
    end
    self:select(role.pad)
    self:send("ProgramPad", {
        sequenceId = m.sequenceId, trackId = m.trackId, programId = m.program.id,
        pad = role.pad, sampleId = sample.id, expectedRevision = m.projectRevision,
    })
end

function Coach:cancel()
    self.confirmation, self.message = nil, nil
    self.nameBox:ReleaseFocus()
end

function Coach:setExpanded(value)
    self.expanded = value == true
    self:cancel()
    self.scroll.Visible, self.footer.Visible = self.expanded, self.expanded
    self.root:SetAttribute("GuidanceOpen", self.expanded)
    W.set(self.toggle, "Text", if self.expanded then "FULL EDITOR" else "FIRST GROOVE")
    if self.changed then
        self.changed()
    end
    self:paint()
end

function Coach:update(state, pad)
    local key = context(state)
    if self.contextKey and self.contextKey ~= key then
        self.confirmation, self.message = nil, nil
    end
    self.contextKey, self.state, self.pad = key, state, pad
    local m = state and state.music
    if not m or not m.sequence then
        self:cancel()
        return
    end
    local route = m.projectId .. ":" .. (m.workspaceGeneration or 0) .. ":" .. m.sequenceId
    if self.nameRoute ~= route then
        self.nameRoute = route
        self.nameBox:ReleaseFocus()
        self.nameBox.Text = m.sequence.name
    end
    if not self.initialized and state.ready and state.station then
        self.initialized = true
        self:setExpanded(not state.hasSave and Sequence.countEvents(m.sequence) == 0)
    end
    if self.pendingStart and m.projectId ~= self.pendingStart then
        self.pendingStart = nil
        if Groove.isStarter(m.sequence) then
            self:setExpanded(true)
            self.scroll.CanvasPosition = Vector2.new(0, self.firstRoleY or 0)
        end
    elseif self.pendingStart and state.notice then
        self.pendingStart = nil
        self.message = state.notice
    end
    self:paint()
end

function Coach:paint()
    if self.dead then
        return
    end
    local s = self.state
    local m = s and s.music
    local ready = s ~= nil and s.ready == true and s.station ~= nil and m ~= nil
    local solo = ready and not (s.jam and s.jam.active)
    local exampleReady, problem, preview = Groove.availability(s and s.unlocked)
    local confirmAction = self.confirmation and self.confirmation.action
    W.set(self.example, "Text", if confirmAction == "example" then "CONFIRM EXAMPLE" else "EXAMPLE LOOP")
    W.set(self.blank, "Text", if confirmAction == "blank" then "CONFIRM BLANK" else "START BLANK")
    W.set(self.reopen, "Text", if confirmAction == "restore" then "CONFIRM REOPEN" else "REOPEN SAVE")
    W.set(self.status, "Text", saveStatus(s))
    self.steps:update(if self.tip >= 4 then 4 elseif self.tip == 3 then 3 elseif self.tip == 2 then 2 else 1)
    self.status:SetAttribute("SaveState", saveStatus(s))
    W.set(self.tipText, "Text", tips[self.tip])
    W.set(self.availability, "Text", self.message or (if not exampleReady then problem
        elseif preview then "Local preview audio / listening review pending."
        else "Two bars to make your own."))
    enabled(self.example, solo and not s.saving and exampleReady)
    enabled(self.blank, solo and not s.saving)
    enabled(self.edit, ready)
    enabled(self.play, solo)
    enabled(self.save, ready and not s.saving and s.saveMode ~= "unavailable")
    enabled(self.rename, ready)
    enabled(self.copy, ready and not s.recording)
    enabled(self.undo, ready and (m.undo or 0) > 0)
    enabled(self.mute, ready and self.pad ~= nil)
    enabled(self.reopen, ready and s.hasSave and not s.saving and not m.hasRecovery)
    enabled(self.recovery, ready and m.hasRecovery == true and not s.saving)
    enabled(self.leave, ready)
    enabled(self.show, ready and #(m.finishedSongs or {}) > 0)
    W.set(self.play, "Text", if s and s.playing then "STOP" else "PLAY LOOP")
    W.set(self.mute, "Text", if s and s.pattern and self.pad and s.pattern.muted[self.pad]
        then "UNMUTE SOUND" else "MUTE SOUND")
    for index, item in self.roles do
        local role = Groove.Roles[index]
        local def = m and m.program and m.program.pads[tostring(role.pad)]
        W.set(item.current, "Text", if def then Catalog.label(def.sampleId) else "No selected kit")
        enabled(item.select, ready)
        item.select:SetAttribute("Selected", self.pad == role.pad)
        item.select.BackgroundColor3 = if self.pad == role.pad then W.amber else Color3.fromRGB(224, 211, 175)
        for choiceIndex, slot in role.choices do
            local sample = Catalog.List[slot]
            local choice = item.choices[choiceIndex]
            local playable = sample ~= nil and Catalog.isPlaybackReady(sample.id, s and s.unlocked)
            local label = if sample then Groove.address(slot) .. " / " .. sample.label else "MISSING SOUND"
            if not playable then
                label ..= " / UNAVAILABLE"
            end
            W.set(choice, "Text", label)
            enabled(choice, ready and not s.recording and playable)
            choice:SetAttribute("Selected", def ~= nil and sample ~= nil and def.sampleId == sample.id)
            choice.BackgroundColor3 = if def and sample and def.sampleId == sample.id
                then W.amber else Color3.fromRGB(224, 211, 175)
        end
    end
    local boundary = if s and s.saveMode == "session"
        then "Session saves last only for this Studio session."
        else "SAVE stores the whole project; REOPEN SAVE restores that snapshot."
    if m and m.hasRecovery then
        boundary ..= " Open the retained recovery before restoring again."
    end
    if s and s.jam and s.jam.active then
        boundary ..= " Leave the jam for solo playback."
    end
    boundary ..= " SONG arranges loops; FINISH makes a Song."
    W.set(self.boundary, "Text", boundary)
    W.set(self.detailsButton, "Text", if self.detailsOpen then "LESS HELP" else "SAVE + RECOVERY HELP")
    W.set(self.notice, "Text", self.message or (s and s.notice) or "")
end

function Coach:resize(width, height)
    self.layoutWidth, self.layoutHeight = width, height
    W.place(self.status, 0, 0, math.max(0, width - 114), 44)
    W.place(self.toggle, width - 110, 0, 110, 44)
    W.place(self.scroll, 0, 50, width, math.max(0, height - 102))
    W.place(self.footer, 0, math.max(50, height - 48), width, 48)
    for index, control in { self.edit, self.play, self.save } do
        W.place(control, (index - 1) * (width + 4) / 3, 0, (width - 8) / 3, 44)
    end
    local w, y = math.max(0, width - 8), 0
    local narrow = w < 260
    local function row(left, right, h)
        h = h or 48
        if narrow then
            W.place(left, 0, y, w, h)
            W.place(right, 0, y + h + 4, w, h)
            y += h * 2 + 12
        else
            W.place(left, 0, y, (w - 6) / 2, h)
            W.place(right, (w + 6) / 2, y, (w - 6) / 2, h)
            y += h + 8
        end
    end
    W.place(self.steps.root, 0, y, w, 56)
    y += 64
    W.place(self.title, 0, y, w, 28)
    y += 32
    row(self.example, self.blank)
    W.place(self.availability, 0, y, w, 48)
    y += 56
    self.firstRoleY = y
    for _, item in self.roles do
        local roleHeight = if narrow then 192 else 140
        W.place(item.root, 0, y, w, roleHeight)
        W.place(item.title, 0, 0, w, 24)
        W.place(item.select, 0, 26, math.min(104, w), 44)
        W.place(item.current, 110, 24, math.max(0, w - 110), 48)
        if narrow then
            W.place(item.choices[1], 0, 76, w, 52)
            W.place(item.choices[2], 0, 132, w, 52)
        else
            W.place(item.choices[1], 0, 76, (w - 6) / 2, 56)
            W.place(item.choices[2], (w + 6) / 2, 76, (w - 6) / 2, 56)
        end
        y += roleHeight + 6
    end
    W.place(self.tipText, 0, y, w, 56)
    y += 60
    W.place(self.nextTip, 0, y, w, 44)
    y += 52
    W.place(self.nameLabel, 0, y, w, 24)
    y += 28
    row(self.nameBox, self.rename)
    row(self.undo, self.copy)
    row(self.mute, self.reopen)
    row(self.recovery, self.leave)
    W.place(self.show, 0, y, w, 44)
    y += 52
    W.place(self.detailsButton, 0, y, w, 44)
    y += 52
    self.boundary.Visible = self.detailsOpen == true
    W.place(self.boundary, 0, y, w, 120)
    if self.detailsOpen then y += 128 end
    W.place(self.notice, 0, y, w, 128)
    self.scroll.CanvasSize = UDim2.fromOffset(0, y + 136)
end

return Coach
