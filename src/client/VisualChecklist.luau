-- Fixed native rows. Status has both a shape and readable words, never color alone.
local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Checklist = {}
Checklist.__index = Checklist
function Checklist.new(parent, capacity)
    local self = setmetatable({ rows = {} }, Checklist)
    self.root = Gui.make("Frame", parent, { Name = "VisualChecklist", Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
    Gui.make("UIListLayout", self.root, { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
    for index = 1, capacity do
        local row = Gui.make("Frame", self.root, { Name = "Requirement" .. index, LayoutOrder = index,
            Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Theme.Graphite, BorderSizePixel = 0 })
        local yes, no = Icons.make(row, "check", Theme.Cream, 22), Icons.make(row, "arrow", Theme.Amber, 22)
        yes.Position, no.Position = UDim2.fromOffset(8, 11), UDim2.fromOffset(8, 11)
        local text = Gui.label(row, "", 12, Theme.Cream)
        text.Font, text.Position, text.Size = Enum.Font.Code, UDim2.fromOffset(38, 0), UDim2.new(1, -46, 1, 0)
        self.rows[index] = { root = row, yes = yes, no = no, text = text }
    end
    return self
end
function Checklist:update(checks)
    for index, row in self.rows do
        local check = checks and checks[index]
        row.root.Visible = check ~= nil
        if check then
            row.yes.Visible, row.no.Visible = check.ok == true, check.ok ~= true
            row.root.BackgroundColor3 = if check.ok then Theme.Teal else Theme.Graphite
            row.text.Text = check.label
            row.root:SetAttribute("AccessibleLabel", (if check.ok then "Ready: " else "Needed: ") .. check.label)
        end
    end
end
return Checklist
