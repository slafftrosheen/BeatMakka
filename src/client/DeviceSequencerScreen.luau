-- A fixed step display. Creating/changing notes never rebuilds the interface.
local W = require(script.Parent.DeviceWidgets)
local Coach = require(script.Parent.FirstGrooveCoach)
local RecorderGuide = require(script.Parent.RecorderGuide)
local Catalog = require(game.ReplicatedStorage.Shared.SampleCatalog)
local GuiService = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Screen = {}
Screen.__index = Screen
function Screen.new(parent, api)
    local self =
        setmetatable({ api = api, steps = {}, beats = {}, lanes = {}, laneGroup = 0, connections = {} }, Screen)
    self.rootFrame = W.frame(parent, "Sequence")
    self.rootFrame.Size = UDim2.fromScale(1, 1)
    self.editor = W.make("ScrollingFrame", self.rootFrame, {
        Name = "FullSequenceEditor", BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    })
    self.editorBody = W.frame(self.editor, "Controls")
    self.noteBody = W.frame(self.editorBody, "NoteControls")
    self.huntToggle = W.key(self.editorBody, "SoundHunts", "sound", "SOUND HUNTS", function()
        self:showHunts(not self.huntsOpen)
    end)
    self.huntGuide = RecorderGuide.new(self.editorBody, {
        command = api.command,
        selectPad = api.selectPad,
        edit = function()
            self:showHunts(false)
        end,
    })
    self.huntGuide.frame.Visible = false
    self.huntGuide:setOpen(true)
    table.insert(self.connections, self.huntGuide.frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:resizeContent()
    end))
    self.title = W.label(self.noteBody, "SequenceTitle", "MY SECTION", 17, W.amber)
    self.padName = W.label(self.noteBody, "SelectedSound", "A01 / KICK", 13)
    self.barName = W.label(self.noteBody, "BarNumber", "01 / 01", 14, W.amber)
    self.previous = W.key(self.noteBody, "PreviousBar", "undo", "BAR", function()
        local m = self.state and self.state.music
        if m then
            api.command("Bar", math.max(1, m.bar - 1))
        end
    end)
    self.next = W.key(self.noteBody, "NextBar", "redo", "BAR", function()
        local m = self.state and self.state.music
        if m then
            api.command("Bar", math.min(m.sequence.bars, m.bar + 1))
        end
    end)
    self.grid = W.frame(self.noteBody, "StepGrid")
    for i = 1, 16 do
        local b = W.make(
            "TextButton",
            self.grid,
            {
                Name = "Step" .. i,
                Text = "",
                BackgroundColor3 = W.ink,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Selectable = true,
            }
        )
        b:SetAttribute("Step", i)
        local corner = W.make("UICorner", b, { CornerRadius = UDim.new(0, 5) })
        corner.Name = "StepCorner"
        local lamp = W.line(b, "Light", Color3.fromRGB(65, 88, 67))
        lamp.Position, lamp.Size = UDim2.new(0.12, 0, 0, 5), UDim2.new(0.76, 0, 0, 4)
        local number = W.label(b, "StepNumber", string.format("%02d", i), 16)
        number.TextXAlignment = Enum.TextXAlignment.Center
        number.Size = UDim2.fromScale(1, 1)
        local focus = W.make(
            "UIStroke",
            b,
            { Color = W.amber, Thickness = 2, Enabled = false, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
        )
        b.SelectionGained:Connect(function()
            focus.Enabled = true
        end)
        b.SelectionLost:Connect(function()
            focus.Enabled = false
        end)
        b.Activated:Connect(function()
            api.command("Step", self.pad, i)
        end)
        self.steps[i] = { button = b, lamp = lamp, number = number }
    end
    self.overview = W.frame(self.noteBody, "LaneOverview")
    for row = 1, 4 do
        local lane = { root = W.frame(self.overview, "Lane" .. row), cells = {} }
        lane.name = W.make(
            "TextButton",
            lane.root,
            {
                Name = "SelectLane",
                Text = "",
                Font = Enum.Font.Code,
                TextSize = 11,
                TextColor3 = W.text,
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Selectable = true,
                BorderSizePixel = 0,
            }
        )
        lane.name.Activated:Connect(function()
            if lane.pad then
                api.selectPad((lane.pad - 1) % 16 + 1)
            end
        end)
        for i = 1, 16 do
            lane.cells[i] = W.line(lane.root, "Note" .. i, Color3.fromRGB(42, 63, 52))
        end
        self.lanes[row] = lane
    end
    self.laneBack = W.key(self.noteBody, "PreviousLanes", "undo", "LANES", function()
        self.laneGroup = (self.laneGroup + 3) % 4
        self:paint()
    end)
    self.laneNext = W.key(self.noteBody, "NextLanes", "redo", "LANES", function()
        self.laneGroup = (self.laneGroup + 1) % 4
        self:paint()
    end)
    self.status = W.label(self.noteBody, "SequenceStatus", "TAP A PAD • PLACE ITS NOTES", 11)
    self.coach = Coach.new(self.rootFrame, api, function()
        if self.coach and self.coach.expanded then
            self.huntGuide:cancel()
        end
        if self.width then
            self:resize(self.width, self.height)
        end
        local selected = GuiService.SelectedObject
        if not self.coach.expanded and (
            (selected and (selected:IsDescendantOf(self.coach.scroll) or selected:IsDescendantOf(self.coach.footer)))
            or (not selected and Input:GetLastInputType().Name:match("^Gamepad"))
        ) then
            GuiService.SelectedObject = if self.huntsOpen then self.huntToggle else self.steps[1].button
        end
    end)
    local function cancelCoach()
        self.coach:cancel()
        self.coach:paint()
        self.huntGuide:cancel()
    end
    -- View:update returns early on station exit. Watch the enclosing panel as
    -- well as the page so delayed previews/confirmations cannot survive re-entry.
    local ancestor = parent
    while ancestor do
        local object = ancestor
        if object:IsA("GuiObject") then
            table.insert(self.connections, object:GetPropertyChangedSignal("Visible"):Connect(function()
                if not object.Visible then
                    cancelCoach()
                end
            end))
        elseif object:IsA("ScreenGui") then
            table.insert(self.connections, object:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not object.Enabled then
                    cancelCoach()
                end
            end))
        end
        ancestor = ancestor.Parent
    end
    table.insert(self.connections, Input.WindowFocusReleased:Connect(cancelCoach))
    table.insert(self.connections, Input.TextBoxFocused:Connect(function()
        self.huntGuide:cancel()
    end))
    self.rootFrame.Destroying:Connect(function()
        for _, connection in self.connections do
            connection:Disconnect()
        end
    end)
    self.rootFrame:SetAttribute("PersistentControls", true)
    return self
end
function Screen:showHunts(open)
    self.huntsOpen = open == true
    self.huntGuide:cancel()
    self.coach:cancel()
    self.coach:paint()
    self.noteBody.Visible = not self.huntsOpen
    self.huntGuide.frame.Visible = self.huntsOpen
    W.legend(self.huntToggle, if self.huntsOpen then "BACK TO NOTES" else "SOUND HUNTS")
    self.editor.CanvasPosition = Vector2.zero
    self:resizeContent()
    local selected = GuiService.SelectedObject
    if not self.huntsOpen and selected and selected:IsDescendantOf(self.huntGuide.frame) then
        GuiService.SelectedObject = self.steps[self.huntGuide.step].button
    end
end
function Screen:resizeContent()
    if not self.width or not self.noteHeight then
        return
    end
    local height = 50 + (if self.huntsOpen then self.huntGuide.frame.AbsoluteSize.Y else self.noteHeight)
    self.editorBody.Size = UDim2.fromOffset(math.max(0, self.width - 8), height)
    self.editor.CanvasSize = UDim2.fromOffset(0, height)
end
function Screen:update(state, pad)
    local changed = self.pad ~= pad
    self.state, self.pad = state, pad
    if changed then
        self.laneGroup = math.floor(((pad - 1) % 16) / 4)
    end
    self.coach:update(state, pad)
    self.huntGuide:update(state)
    self:paint()
end
function Screen:paint()
    local s = self.state
    local m = s and s.music
    if not m or not s.pattern then
        return
    end
    local sample = Catalog.ById[s.pattern.assignments[self.pad]]
    W.set(self.title, "Text", m.sequence.name)
    W.set(
        self.padName,
        "Text",
        string.format(
            "%s%02d / %s",
            string.char(65 + math.floor((self.pad - 1) / 16)),
            (self.pad - 1) % 16 + 1,
            sample and sample.label or "CHOOSE A SOUND"
        )
    )
    W.set(self.barName, "Text", string.format("%02d / %02d", m.bar, m.sequence.bars))
    local rows = s.pattern.rows or {}
    local row = rows[self.pad] or {}
    for i, cell in self.steps do
        local active = row[i] == true
        local head = i == self.playhead and s.playing
        W.set(
            cell.button,
            "BackgroundColor3",
            if active then W.amber else Color3.fromRGB(31, 56, 46)
        )
        W.set(cell.number, "TextColor3", if active then W.ink else W.text)
        W.set(
            cell.lamp,
            "BackgroundColor3",
            if head
                then Color3.fromRGB(129, 255, 199)
                elseif active then Color3.fromRGB(255, 233, 174)
                else Color3.fromRGB(59, 82, 61)
        )
        cell.button:SetAttribute("EnabledStep", active)
        cell.button:SetAttribute("Playhead", head == true)
    end
    for index, lane in self.lanes do
        -- The pad argument includes an optimistic bank selection while the
        -- server acknowledgement is pending; keep its lane overview consistent.
        local bank = math.floor((self.pad - 1) / 16) + 1
        local absolute = (bank - 1) * 16 + self.laneGroup * 4 + index
        lane.pad = absolute
        local source = Catalog.ById[s.pattern.assignments[absolute]]
        W.set(lane.name, "Text", string.format("%02d %s", absolute, source and source.label or ""))
        W.set(lane.name, "TextColor3", if absolute == self.pad then W.amber else W.text)
        for i, cell in lane.cells do
            W.set(
                cell,
                "BackgroundColor3",
                if (rows[absolute] or {})[i] then W.amber else Color3.fromRGB(42, 63, 52)
            )
        end
    end
    W.set(
        self.status,
        "Text",
        if s.recording
            then "RECORDING / TAP YOUR RHYTHM"
            elseif s.playing then "PLAYING / EDIT NOTES LIVE"
            else "TAP A PAD • PLACE ITS NOTES"
    )
end
function Screen:setPlayhead(value)
    if self.playhead ~= value then
        self.playhead = value
        self:paint()
    end
end
function Screen:resize(width, height)
    if self.width and (self.width ~= width or self.height ~= height) then
        self.coach:cancel()
        self.coach:paint()
        self.huntGuide:cancel()
    end
    self.width, self.height = width, height
    self.coach:resize(width, height)
    self.editor.Visible = not self.coach.expanded
    W.place(self.editor, 0, 50, width, math.max(0, height - 50))
    local w = math.max(0, width - 8)
    W.place(self.huntToggle, 0, 0, w, 44)
    self.huntGuide.frame.Position = UDim2.fromOffset(0, 50)
    W.place(self.title, 0, 0, math.max(0, w - 116), 24)
    W.place(self.barName, w - 108, 0, 108, 24)
    self.barName.TextXAlignment = Enum.TextXAlignment.Right
    W.place(self.padName, 0, 27, math.max(0, w - 112), 40)
    W.place(self.previous, w - 100, 26, 46, 44)
    W.place(self.next, w - 48, 26, 46, 44)
    -- Reflow rather than squeeze sixteen controls into unusable narrow cells.
    -- The editor scrolls; the separate physical performance pads do not.
    local columns = if w >= 384 then 8 elseif w >= 192 then 4 else 2
    local gridHeight = (16 / columns) * 48
    W.place(self.grid, 0, 72, w, gridHeight)
    for i, cell in self.steps do
        local x, y = (i - 1) % columns, math.floor((i - 1) / columns)
        W.place(cell.button, x * w / columns, y * 48, w / columns - 4, 44)
    end
    local overviewY = 72 + gridHeight + 8
    W.place(self.overview, 0, overviewY, w, 176)
    for row, lane in self.lanes do
        W.place(lane.root, 0, (row - 1) * 44, w, 44)
        W.place(lane.name, 0, 0, w * 0.38, 44)
        for i, cell in lane.cells do
            W.place(cell, w * 0.4 + (i - 1) * w * 0.6 / 16, 18, w * 0.6 / 16 - 2, 8)
        end
    end
    local footerY = overviewY + 184
    W.place(self.laneBack, 0, footerY, 70, 44)
    W.place(self.laneNext, 76, footerY, 70, 44)
    W.place(self.status, 0, footerY + 48, w, 36)
    self.noteHeight = footerY + 88
    W.place(self.noteBody, 0, 50, w, self.noteHeight)
    self:resizeContent()
    self.rootFrame:SetAttribute("StepColumns", columns)
end
function Screen:destroy()
    self.rootFrame:Destroy()
end
return Screen
