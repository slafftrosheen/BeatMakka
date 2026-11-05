-- Small, passive illustrated directions. A highlighted step is guidance, not an award.
local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Steps = {}
Steps.__index = Steps

function Steps.new(parent, definitions, z)
    local self = setmetatable({ items = {}, definitions = definitions }, Steps)
    self.root = Gui.make("Frame", parent, { Name = "VisualSteps", BackgroundTransparency = 1,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 56), ZIndex = z or 1 })
    for index, definition in definitions do
        local item = Gui.make("Frame", self.root, { Name = definition[1],
            Position = UDim2.fromScale((index - 1) / #definitions, 0),
            Size = UDim2.new(1 / #definitions, -4, 1, 0),
            BackgroundColor3 = Theme.Graphite, BorderSizePixel = 0, ZIndex = z or 1 })
        Gui.round(item, 5)
        local glyph = Icons.make(item, definition[2], Theme.Cream, 24)
        glyph.Position, glyph.ZIndex = UDim2.new(0.5, -12, 0, 5), (z or 1) + 1
        for _, child in glyph:GetDescendants() do
            if child:IsA("GuiObject") then child.ZIndex = glyph.ZIndex end
        end
        local caption = Gui.label(item, definition[1], 11, Theme.Cream)
        caption.Font, caption.TextXAlignment = Enum.Font.Code, Enum.TextXAlignment.Center
        caption.Position, caption.Size, caption.ZIndex = UDim2.fromOffset(2, 32), UDim2.new(1, -4, 0, 20), (z or 1) + 1
        caption.TextWrapped = false
        caption.TextTruncate = Enum.TextTruncate.AtEnd
        local mark = Gui.make("Frame", item, { Name = "CurrentStep", Position = UDim2.new(0, 6, 1, -3),
            Size = UDim2.new(1, -12, 0, 3), BorderSizePixel = 0, BackgroundColor3 = Theme.Amber,
            Visible = false, ZIndex = (z or 1) + 2 })
        self.items[index] = { root = item, glyph = glyph, caption = caption, mark = mark }
    end
    return self
end

function Steps:update(current, completed)
    for index, item in self.items do
        local active, done = index == current, completed and completed[index] == true
        local color = if active then Theme.Ink else Theme.Cream
        item.root.BackgroundColor3 = if active then Theme.Amber elseif done then Theme.Teal else Theme.Graphite
        item.caption.TextColor3, item.mark.Visible = color, active
        if item.color ~= color then Icons.tint(item.glyph, color); item.color = color end
        item.root:SetAttribute("AccessibleLabel", self.definitions[index][1]
            .. (if active then " / current step" elseif done then " / complete" else " / next"))
    end
end

return Steps
