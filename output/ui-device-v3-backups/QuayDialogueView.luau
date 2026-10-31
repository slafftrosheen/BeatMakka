local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
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
    self.name = label("HostName", 21, 1, Theme.Cream)
    self.name.Font = Theme.Bold
    self.role = label("HostRole", 13, 2, Theme.Amber)
    self.line = label("HostLine", 17, 3, Theme.Cream)
    self.toggle = Gui.button(self.root, "Ask a question", function()
        self.expanded = not self.expanded
        self:render()
    end)
    self.toggle.Name, self.toggle.Size, self.toggle.LayoutOrder =
        "ShowQuestions", UDim2.new(1, 0, 0, 44), 4
    for index, id in { "place", "music", "quay" } do
        local button = Gui.button(self.root, "", function()
            send("QuayTalk", id)
        end)
        button.Name, button.Size, button.LayoutOrder =
            "Ask_" .. id, UDim2.new(1, 0, 0, 44), 4 + index
        self.buttons[index] = button
    end
    return self
end
function View:render()
    self.toggle.Text = if self.expanded then "Close questions" else "Ask a question"
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
    for index, option in dialogue.options do
        self.buttons[index].Text = option.label
    end
    self:render()
end
return View
