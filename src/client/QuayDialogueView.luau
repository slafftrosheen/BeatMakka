local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local View = {}
View.__index = View
function View.new(parent, send)
    local self = setmetatable({ buttons = {}, expanded = false }, View)
    self.root = Gui.round(
        Gui.make("Frame", parent, {
            Name = "HostConversation",
            Size = UDim2.new(1, -10, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Ink,
            BorderSizePixel = 0,
            LayoutOrder = 1,
            Visible = false,
        }),
        12
    )
    Gui.make("UIPadding", self.root, {
        PaddingTop = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 14),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
    })
    Gui.make(
        "UIListLayout",
        self.root,
        { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    local function label(name, size, order, color)
        local object = Gui.label(self.root, "", size, color)
        object.Name, object.Size, object.AutomaticSize, object.LayoutOrder =
            name, UDim2.fromScale(1, 0), Enum.AutomaticSize.Y, order
        return object
    end
    local header = Gui.make("Frame", self.root, {
        Name = "HostIdentity",
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
    })
    self.portrait = Gui.round(
        Gui.make("Frame", header, {
            Name = "HostBadge",
            Position = UDim2.fromOffset(0, 8),
            Size = UDim2.fromOffset(48, 48),
            BackgroundColor3 = Theme.Teal,
            BorderSizePixel = 0,
        }),
        12
    )
    Gui.make("UIStroke", self.portrait, { Name = "HostAccent", Color = Theme.Amber, Thickness = 2 })
    Icons.make(self.portrait, "people", Theme.Cream, 34).Position = UDim2.fromOffset(7, 7)
    self.name = Gui.label(header, "", 20, Theme.Cream)
    self.name.Name, self.name.Position, self.name.Size =
        "HostName", UDim2.fromOffset(60, 0), UDim2.new(1, -60, 0, 36)
    self.name.Font = Enum.Font.Code
    self.name.TextScaled = true
    Gui.make("UITextSizeConstraint", self.name, { MinTextSize = 14, MaxTextSize = 20 })
    self.role = Gui.label(header, "", 12, Theme.Amber)
    self.role.Name, self.role.Position, self.role.Size =
        "HostRole", UDim2.fromOffset(60, 36), UDim2.new(1, -60, 0, 32)
    self.role.Font = Enum.Font.Code
    self.line = label("HostLine", 17, 3, Theme.Cream)
    self.line.BackgroundColor3, self.line.BackgroundTransparency = Theme.Teal, 0
    Gui.round(self.line, 10)
    Gui.make("UIPadding", self.line, {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
    })
    self.toggle = Gui.button(self.root, "LET'S TALK", function()
        self.expanded = not self.expanded
        self:render()
    end)
    self.toggle.Name, self.toggle.Size, self.toggle.LayoutOrder =
        "ShowQuestions", UDim2.new(1, 0, 0, 48), 4
    self.toggle:SetAttribute("UiIcon", "people")
    for index, id in { "place", "music", "quay" } do
        local button = Gui.button(self.root, "", function()
            send("QuayTalk", id)
        end)
        button.Name, button.Size, button.LayoutOrder =
            "Ask_" .. id, UDim2.new(1, 0, 0, 56), 4 + index
        button:SetAttribute("UiIcon", ({ place = "route", music = "sound", quay = "city" })[id])
        self.buttons[index] = button
    end
    return self
end
function View:render()
    self.toggle.Text = if self.expanded then "CLOSE QUESTIONS" else "LET'S TALK"
    for _, button in self.buttons do
        button.Visible = self.expanded
    end
end
function View:update(dialogue, visible)
    self.root.Visible = dialogue ~= nil and visible
    if not dialogue then
        self.id = nil
        return
    end
    if self.id ~= dialogue.id then
        self.expanded = false
    end
    self.id = dialogue.id
    self.name.Text, self.role.Text, self.line.Text =
        dialogue.name, string.upper(dialogue.role), dialogue.line
    self.role.TextColor3 = Theme[dialogue.accent] or Theme.Amber
    self.portrait.HostAccent.Color = Theme[dialogue.accent] or Theme.Amber
    for index, option in dialogue.options do
        self.buttons[index].Text = option.label
    end
    self:render()
end
return View
