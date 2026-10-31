-- A fixed step display. Creating/changing notes never rebuilds the interface.
local W = require(script.Parent.DeviceWidgets)
local Catalog = require(game.ReplicatedStorage.Shared.SampleCatalog)
local Screen = {}
Screen.__index = Screen
function Screen.new(parent, api)
    local self =
        setmetatable({ api = api, steps = {}, beats = {}, lanes = {}, laneGroup = 0 }, Screen)
    self.rootFrame = W.frame(parent, "Sequence")
    self.rootFrame.Size = UDim2.fromScale(1, 1)
    self.title = W.label(self.rootFrame, "SequenceTitle", "MY SECTION", 17, W.amber)
    self.padName = W.label(self.rootFrame, "SelectedSound", "A01 / KICK", 13)
    self.barName = W.label(self.rootFrame, "BarNumber", "01 / 01", 14, W.amber)
    self.previous = W.key(self.rootFrame, "PreviousBar", "undo", "BAR", function()
        local m = self.state and self.state.music
        if m then
            api.command("Bar", math.max(1, m.bar - 1))
        end
    end)
    self.next = W.key(self.rootFrame, "NextBar", "redo", "BAR", function()
        local m = self.state and self.state.music
        if m then
            api.command("Bar", math.min(m.sequence.bars, m.bar + 1))
        end
    end)
    self.grid = W.frame(self.rootFrame, "StepGrid")
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
    self.overview = W.frame(self.rootFrame, "LaneOverview")
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
    self.laneBack = W.key(self.rootFrame, "PreviousLanes", "undo", "LANES", function()
        self.laneGroup = (self.laneGroup + 3) % 4
        self:paint()
    end)
    self.laneNext = W.key(self.rootFrame, "NextLanes", "redo", "LANES", function()
        self.laneGroup = (self.laneGroup + 1) % 4
        self:paint()
    end)
    self.status = W.label(self.rootFrame, "SequenceStatus", "TAP A PAD • PLACE ITS NOTES", 11)
    self.rootFrame:SetAttribute("PersistentControls", true)
    return self
end
function Screen:update(state, pad)
    local changed = self.pad ~= pad
    self.state, self.pad = state, pad
    if changed then
        self.laneGroup = math.floor(((pad - 1) % 16) / 4)
    end
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
        local absolute = (m.bank - 1) * 16 + self.laneGroup * 4 + index
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
    local short = height < 220
    W.place(self.title, 0, 0, width - 116, 24)
    W.place(self.barName, width - 108, 0, 108, 24)
    self.barName.TextXAlignment = Enum.TextXAlignment.Right
    W.place(self.padName, 0, 27, width - 112, if short then 24 else 30)
    W.place(self.previous, width - 100, 26, 46, 44)
    W.place(self.next, width - 48, 26, 46, 44)
    local top = if short then 60 else 72
    local gridHeight =
        math.min(if short then 76 else 126, math.max(64, height - top - (if short then 0 else 96)))
    W.place(self.grid, 0, top, width, gridHeight)
    for i, cell in self.steps do
        local x = (i - 1) % 8
        local y = math.floor((i - 1) / 8)
        W.place(cell.button, x * width / 8, y * gridHeight / 2, width / 8 - 5, gridHeight / 2 - 5)
    end
    self.overview.Visible = not short
    self.laneBack.Visible = not short
    self.laneNext.Visible = not short
    self.status.Visible = height >= 280
    if not short then
        local y = top + gridHeight + 6
        local h = math.max(44, math.min(112, height - y - 48))
        W.place(self.overview, 0, y, width, h)
        for row, lane in self.lanes do
            W.place(lane.root, 0, (row - 1) * h / 4, width, h / 4 - 2)
            W.place(lane.name, 0, 0, width * 0.33, h / 4 - 2)
            for i, cell in lane.cells do
                W.place(
                    cell,
                    width * 0.34 + (i - 1) * width * 0.66 / 16,
                    4,
                    width * 0.66 / 16 - 2,
                    math.max(3, h / 4 - 10)
                )
            end
        end
        W.place(self.laneBack, 0, height - 44, 70, 40)
        W.place(self.laneNext, 76, height - 44, 70, 40)
        W.place(self.status, 156, height - 44, width - 160, 40)
    end
end
function Screen:destroy()
    self.rootFrame:Destroy()
end
return Screen
