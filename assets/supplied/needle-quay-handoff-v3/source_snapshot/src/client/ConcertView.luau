local Shared = game.ReplicatedStorage.Shared
local Samples = require(Shared.SampleCatalog)
local Theme = require(Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local View = {}
View.__index = View

function View.new(screen, command, mute)
    local self = setmetatable({ shelf = 1, pad = 1, slot = 2 }, View)
    self.panel = Gui.round(Gui.make("Frame", screen, {
        Name = "ChapterConcert",
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(1, -24, 1, -24),
        BackgroundColor3 = Theme.Ink,
        Visible = false,
    }))
    Gui.make("UISizeConstraint", self.panel, { MaxSize = Vector2.new(600, 640) })
    self.label = Gui.label(self.panel, "", 14, Theme.Cream)
    self.label.Position = UDim2.fromOffset(12, 8)
    self.label.Size = UDim2.new(1, -24, 0, 96)
    local body = Gui.make("ScrollingFrame", self.panel, {
        Name = "Actions",
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -24, 1, -72),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 4,
    })
    Gui.make(
        "UIListLayout",
        body,
        { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }
    )
    self.label.Parent = body
    self.label.Position = UDim2.new()
    self.label.Size = UDim2.new(1, -8, 0, 108)
    self.label.AutomaticSize = Enum.AutomaticSize.Y
    self.label.LayoutOrder = 0
    local function button(name, order, callback)
        local b = Gui.button(body, name, callback)
        b.Name = name
        b.Size = UDim2.new(1, -8, 0, 48)
        b.LayoutOrder = order
        return b
    end
    self.shelfButton = button("ShelfBeat", 1, function()
        self.shelf = self.shelf % 6 + 1
        self:refresh()
    end)
    self.start = button("StartSet", 2, function()
        command("ChapterStart", self.shelf)
    end)
    self.padButton = button("FeaturedPad", 3, function()
        self.pad = self.pad % 16 + 1
        self:refresh()
    end)
    self.slotButton = button("SavedPattern", 4, function()
        self.slot = self.slot % 4 + 1
        self:refresh()
    end)
    self.action = button("MusicalAction", 5, function()
        local phase = self.state and self.state.phase
        local actions = {
            "ChapterRhythm",
            "ChapterSupport",
            "ChapterBreak",
            "ChapterReturn",
            "ChapterSwitch",
            "ChapterFeature",
        }
        if phase and self.state.base and not self.state.waiting and actions[phase + 1] then
            command(actions[phase + 1], if phase == 4 then self.slot else self.pad)
        end
    end)
    self.switch = button("SwitchAgain", 6, function()
        command("ChapterSwitch", self.slot)
    end)
    self.save = button("RetryProgressSave", 7, function()
        command("ChapterSave")
    end)
    self.save.Text = "Save progress again"
    self.mute = Gui.button(self.panel, "Sound", mute)
    self.mute.Position = UDim2.new(0, 12, 1, -56)
    self.mute.Size = UDim2.new(0.5, -18, 0, 44)
    self.close = Gui.button(self.panel, "Leave / stop set", function()
        command("ChapterClose")
    end)
    self.close.Position = UDim2.new(0.5, 6, 1, -56)
    self.close.Size = UDim2.new(0.5, -18, 0, 44)
    return self
end

function View:refresh()
    local state = self.state
    if not state then
        return
    end
    self.shelfButton.Text = string.format("Saved shelf beat %02d / choose", self.shelf)
    self.start.Text = if state.completed
        then "Replay this section / earned progress kept"
        else "Start a solo chapter set"
    local sample = state.base and Samples.ById[state.base.assignments[self.pad]]
    self.padButton.Text = string.format(
        "Pad %02d / %s",
        self.pad,
        if sample then sample.label else "choose a saved part"
    )
    self.slotButton.Text = "Saved pattern " .. ({ "A", "B", "C", "D" })[self.slot] .. " / choose"
    self.action.Text = if state.waiting
        then "Let this full loop finish..."
        else ({
            "Bring in rhythm",
            "Layer supporting part",
            "Take support out",
            "Bring support back",
            "Change pattern",
            "Feature collected sound",
            "Final loop / section complete",
        })[state.phase + 1]
    self.action.Active = state.base ~= nil and not state.waiting and state.phase < 6
    self.action.Selectable = self.action.Active
    self.switch.Visible = state.phase == 5
    self.switch.Text = "Switch to chosen pattern for a collected sound"
    self.start.Active = state.eligible
end

function View:update(state, saveMode, muted, notice, saving, dirty)
    self.state = state
    self.panel.Visible = state ~= nil and state.open == true
    if not state then
        return
    end
    if notice then
        self.notice = notice
        self.noticeUntil = os.clock() + 6
    end
    self.label.Text = "NEEDLE QUAY / CHAPTER CONCERT\n"
        .. (if state.eligible
            then state.hint
            else "Complete neighborhood jobs and Mica's first courtyard request first.")
        .. (if self.notice and os.clock() < self.noticeUntil then "\n" .. self.notice else "")
        .. "\nEarned "
        .. state.checkpoint
        .. "/6 / "
        .. (
            if saveMode == "session"
                then "Studio session only"
                elseif saveMode == "unavailable" then "Temporary: saving unavailable"
                elseif saving then "SAVING"
                elseif dirty then "UNSAVED / temporary changes"
                else "Saved profile"
        )
    self.label.Text ..= "\nCrowd: " .. ({
        "quiet",
        "nodding",
        "dancing",
        "lights responding",
        "courtyard restored",
    })[(state.reaction or 0) + 1]
    self.mute.Text = if muted then "Sound MUTED" else "Sound ON"
    self:refresh()
end

return View
