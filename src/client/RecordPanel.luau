-- Native scrollable record panels share the current LCD palette and focus affordances.
local Gui = require(script.Parent.GuiFactory)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local GuiService = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Icons = require(script.Parent.GameIcons)
local VisualSteps = require(script.Parent.VisualSteps)
local Panel = {}
Panel.__index = Panel
function Panel.new(parent, name, z)
    local self = setmetatable({ connections = {}, z = z or 40 }, Panel)
    local host = parent:FindFirstAncestorWhichIsA("ScreenGui") or parent
    self.root = Gui.make("Frame", host, { Name = name, AnchorPoint = Vector2.new(0.5, 0.5),
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
    if host ~= parent then
        table.insert(self.connections, parent.Destroying:Connect(function() if not self.dead then self.root:Destroy() end end))
    end
    local ancestor = parent
    while ancestor do
        local surface = ancestor
        if surface:IsA("GuiObject") then
            table.insert(self.connections, surface:GetPropertyChangedSignal("Visible"):Connect(function()
                if not surface.Visible then self:show(false) end
            end))
        elseif surface:IsA("ScreenGui") then
            table.insert(self.connections, surface:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not surface.Enabled then self:show(false) end
            end))
            break
        end
        ancestor = ancestor.Parent
    end
    self.root.Destroying:Connect(function()
        self.dead = true
        for _, connection in self.connections do connection:Disconnect() end
    end)
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
    local stroke = Gui.make("UIStroke", b, { Name = "FocusRing", Color = Theme.Amber, Thickness = 2, Enabled = false,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    table.insert(self.connections, b.SelectionGained:Connect(function() stroke.Enabled = true end))
    table.insert(self.connections, b.SelectionLost:Connect(function() stroke.Enabled = false end))
    table.insert(self.connections, b.Activated:Connect(function() if b.Active then callback() end end))
    return b
end
function Panel.enable(button, enabled)
    button.Active, button.Interactable, button.Selectable = enabled == true, enabled == true, enabled == true
    button.TextTransparency = if enabled then 0 else 0.55
    if not enabled and button:FindFirstChild("FocusRing") then button.FocusRing.Enabled = false end
end
local function isVisible(object)
    while object do
        if object:IsA("GuiObject") and not object.Visible then return false end
        if object:IsA("ScreenGui") and not object.Enabled then return false end
        object = object.Parent
    end
    return true
end
function Panel:ensureFocus(fallback)
    if not self.root.Visible or not Input.GamepadEnabled then return end
    local selected = GuiService.SelectedObject
    if not selected or not selected:IsDescendantOf(self.root) or not selected.Selectable or not isVisible(selected) then
        GuiService.SelectedObject = if fallback and fallback.Selectable and isVisible(fallback) then fallback else nil
    end
end
function Panel:steps(definitions)
    local holder = self:add("Frame", { Name = "RecordFlow", Size = UDim2.new(1, -8, 0, 56), BackgroundTransparency = 1 })
    return VisualSteps.new(holder, definitions, self.z + 3)
end
function Panel:tabs(definitions, changed)
    local holder = self:add("Frame", { Name = "RecordSections", Size = UDim2.new(1, -8, 0, 56), BackgroundTransparency = 1 })
    local tabs = { root = holder, buttons = {} }
    for index, definition in definitions do
        local id = definition[1]
        local b = Gui.make("TextButton", holder, { Name = id, Text = "", BackgroundColor3 = Theme.Teal,
            Position = UDim2.fromScale((index - 1) / #definitions, 0), Size = UDim2.new(1 / #definitions, -4, 1, 0),
            BorderSizePixel = 0, Active = true, Selectable = true, ZIndex = self.z + 3 })
        b:SetAttribute("AccessibleLabel", definition[2])
        local glyph = Icons.make(b, definition[3], Theme.Cream, 22)
        glyph.Position, glyph.ZIndex = UDim2.new(0.5, -11, 0, 5), self.z + 4
        for _, child in glyph:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = glyph.ZIndex end end
        local caption = Gui.label(b, definition[2], 11, Theme.Cream)
        caption.Font, caption.TextXAlignment = Enum.Font.Code, Enum.TextXAlignment.Center
        caption.Position, caption.Size, caption.ZIndex = UDim2.fromOffset(2, 31), UDim2.new(1, -4, 0, 22), self.z + 4
        local ring = Gui.make("UIStroke", b, { Name = "FocusRing", Color = Theme.Amber, Thickness = 2, Enabled = false,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
        table.insert(self.connections, b.SelectionGained:Connect(function() ring.Enabled = true end))
        table.insert(self.connections, b.SelectionLost:Connect(function() ring.Enabled = false end))
        table.insert(self.connections, b.Activated:Connect(function() changed(id) end))
        tabs.buttons[id] = b
    end
    function tabs:select(id)
        for name, b in self.buttons do
            b.BackgroundColor3 = if name == id then Theme.Ink else Theme.Teal
            b:SetAttribute("Selected", name == id)
            b:SetAttribute("AccessibleLabel", name .. (if name == id then " / selected" else ""))
            local mark = b:FindFirstChild("SelectedMark")
            if not mark then
                mark = Gui.make("Frame", b, { Name = "SelectedMark", Position = UDim2.new(0, 8, 1, -3),
                    Size = UDim2.new(1, -16, 0, 3), BackgroundColor3 = Theme.Amber, BorderSizePixel = 0, ZIndex = b.ZIndex + 2 })
            end
            mark.Visible = name == id
        end
    end
    return tabs
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
            GuiService.SelectedObject = if previous and previous.Parent and previous.Selectable and isVisible(previous) then previous else nil
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
