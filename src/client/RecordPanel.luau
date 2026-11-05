-- Native scrollable record panels share the current LCD palette and focus affordances.
local Gui = require(script.Parent.GuiFactory)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local GuiService = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Panel = {}
Panel.__index = Panel
function Panel.new(parent, name, z)
    local self = setmetatable({ connections = {}, z = z or 40 }, Panel)
    self.root = Gui.make("Frame", parent, { Name = name, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.95, 0.94),
        BackgroundColor3 = Theme.Screen, BorderSizePixel = 0, Visible = false, Active = true, ZIndex = self.z })
    Gui.make("UISizeConstraint", self.root, { MaxSize = Vector2.new(620, 580) })
    Gui.make("UIStroke", self.root, { Color = Theme.Amber, Thickness = 2 })
    self.body = Gui.make("ScrollingFrame", self.root, { Name = "RecordControls",
        Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 1, -24),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = self.z + 1 })
    Gui.make("UIListLayout", self.body, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    self.order = 0
    return self
end
function Panel:add(class, properties)
    self.order += 1
    properties.LayoutOrder, properties.ZIndex = self.order, self.z + 2
    return Gui.make(class, self.body, properties)
end
function Panel:label(name, size)
    return self:add("TextLabel", { Name = name, Text = "", Font = Enum.Font.Code,
        TextSize = size or 13, TextColor3 = Theme.Cream, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
end
function Panel:button(name, caption, callback)
    local b = self:add("TextButton", { Name = name, Text = caption, Font = Enum.Font.Code,
        TextSize = 13, TextWrapped = true, TextColor3 = Theme.Cream, BackgroundColor3 = Theme.Teal,
        BorderSizePixel = 0, Size = UDim2.new(1, -8, 0, 44), Selectable = true, Active = true })
    local stroke = Gui.make("UIStroke", b, { Color = Theme.Amber, Thickness = 2, Enabled = false,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    table.insert(self.connections, b.SelectionGained:Connect(function() stroke.Enabled = true end))
    table.insert(self.connections, b.SelectionLost:Connect(function() stroke.Enabled = false end))
    table.insert(self.connections, b.Activated:Connect(function() if b.Active then callback() end end))
    return b
end
function Panel.enable(button, enabled)
    button.Active, button.Selectable = enabled, enabled
    button.TextTransparency = if enabled then 0 else 0.55
end
function Panel:show(visible, focus)
    local changed = self.root.Visible ~= visible
    self.root.Visible = visible
    if changed and visible then
        self.previousFocus = GuiService.SelectedObject
        self.body.CanvasPosition = Vector2.zero
        if Input.GamepadEnabled and focus then GuiService.SelectedObject = focus end
    elseif changed and not visible then
        local selected = GuiService.SelectedObject
        if selected and selected:IsDescendantOf(self.root) then
            local previous = self.previousFocus
            GuiService.SelectedObject = if previous and previous.Parent and previous.Visible then previous else nil
        end
        self.previousFocus = nil
    end
end
function Panel.credits(item)
    local attribution = item and item.attribution
    if not attribution then return "Creator credit unavailable" end
    local lines = { "ORIGINAL CREATOR / " .. attribution.creator.name }
    local names = {}
    for _, author in attribution.contributors do table.insert(names, author.name .. " (" .. author.role .. ")") end
    table.insert(lines, "CREDITS / " .. table.concat(names, ", "))
    for _, source in attribution.sources do
        table.insert(lines, "FROM / " .. source.creator.name .. " / " .. source.releaseId .. " / v" .. source.revision)
    end
    return table.concat(lines, "\n")
end
function Panel.storage(mode)
    return if mode == "session" then "STUDIO SESSION ONLY / lost when this server closes"
        elseif mode == "cloud" then "SAVED / storage accepted this snapshot"
        else "TEMPORARY / storage unavailable"
end
return Panel
