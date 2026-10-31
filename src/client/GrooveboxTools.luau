local Shared = game:GetService("ReplicatedStorage").Shared
local Theme = require(Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local Tools = {}
Tools.__index = Tools

function Tools.new(parent, view, command)
    local self = setmetatable({ hits = 4, buttons = {} }, Tools)
    self.root = Gui.make("Frame", parent, {
        Name = "BeatTools",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 0, 142),
    })
    local title = Gui.label(self.root, "SHAPE YOUR LOOP", 11, Theme.Cream)
    title.Font, title.Size = Enum.Font.Code, UDim2.new(1, 0, 0, 20)
    local grid = Gui.make("Frame", self.root, {
        Name = "Actions",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 24),
        Size = UDim2.new(1, 0, 0, 92),
    })
    Gui.make("UIGridLayout", grid, {
        CellSize = UDim2.new(0.25, -5, 0, 44),
        CellPadding = UDim2.fromOffset(6, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    local actions = {
        { "Undo", "Undo" },
        { "Redo", "Redo" },
        { "Copy row", "RowTool", "copy" },
        { "Paste row", "RowTool", "paste" },
        { "Shift left", "RowTool", "left" },
        { "Shift right", "RowTool", "right" },
        { "Reverse", "RowTool", "reverse" },
        { "Clear row", "RowTool", "clear" },
    }
    for i, action in actions do
        local button = Gui.button(grid, action[1], function()
            if not self.state or not self.state.ready then
                return
            end
            if action[2] == "Undo" or action[2] == "Redo" then
                command(action[2])
            else
                command(action[2], view.selectedPad, action[3])
            end
        end)
        button.Name, button.LayoutOrder = action[1]:gsub(" ", ""), i
        button.TextSize, button.BackgroundColor3 = 12, Theme.Graphite
        self.buttons[action[1]] = button
    end
    self.hint = Gui.label(
        self.root,
        "Copy notes to another pad. Undo keeps experiments reversible.",
        10,
        Theme.Cream
    )
    self.hint.Position, self.hint.Size = UDim2.fromOffset(0, 120), UDim2.new(1, 0, 0, 20)
    self.rhythm = Gui.make("Frame", parent, {
        Name = "RhythmBuilder",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 0, 48),
    })
    local less = Gui.button(self.rhythm, "−", function()
        self.hits = math.max(1, self.hits - 1)
        self:refreshRhythm()
    end)
    less.Size = UDim2.fromOffset(44, 44)
    self.fill = Gui.button(self.rhythm, "", function()
        command("Rhythm", view.selectedPad, self.hits)
    end)
    self.fill.Position, self.fill.Size = UDim2.fromOffset(50, 0), UDim2.new(1, -100, 0, 44)
    local more = Gui.button(self.rhythm, "+", function()
        self.hits = math.min(16, self.hits + 1)
        self:refreshRhythm()
    end)
    more.Position, more.Size = UDim2.new(1, -44, 0, 0), UDim2.fromOffset(44, 44)
    self:refreshRhythm()
    return self
end

function Tools:refreshRhythm()
    self.fill.Text = string.format("Write %d hits / 16 steps", self.hits)
end

function Tools:update(state)
    self.state = state
    local history = state.history or {}
    for name, available in
        {
            Undo = (history.undo or 0) > 0,
            Redo = (history.redo or 0) > 0,
            ["Paste row"] = history.copiedPad ~= nil,
        }
    do
        local button = self.buttons[name]
        button.Active, button.Selectable, button.AutoButtonColor = available, available, available
        button.TextColor3 = if available then Theme.Cream else Theme.Stone
        button.BackgroundTransparency = if available then 0 else 0.45
    end
    self.hint.Text = if history.copiedPad
        then string.format(
            "Pad %02d copied · Select a pad, then Paste row. Undo stops playback.",
            history.copiedPad
        )
        else "Copy notes to another pad. Undo stops playback and restores the last edit."
end

return Tools
