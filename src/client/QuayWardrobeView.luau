local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Rewards = require(game.ReplicatedStorage.Shared.QuayRewards)
local View = {}
View.__index = View
function View.new(screen)
    local self = setmetatable({ category = "title", rows = {} }, View)
    self.panel = Gui.round(
        Gui.make("Frame", screen, {
            Name = "QuayWardrobe",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12, 0, 106),
            Size = UDim2.new(0, 320, 0.65, 0),
            BackgroundColor3 = Theme.Ink,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 20,
        }),
        12
    )
    local title = Gui.label(self.panel, "YOUR LOOK", 18, Theme.Amber)
    title.Position, title.Size = UDim2.fromOffset(12, 8), UDim2.new(1, -64, 0, 28)
    local close = Gui.button(self.panel, "", function()
        self.panel.Visible = false
    end)
    close.Position, close.Size = UDim2.new(1, -42, 0, 4), UDim2.fromOffset(38, 38)
    Icons.make(close, "close", Theme.Cream, 20).Position = UDim2.fromOffset(9, 9)
    self.tabs = {}
    for index, category in Rewards.Categories do
        local tab = Gui.button(self.panel, Rewards.Labels[category], function()
            self.category = category
            self:render()
        end)
        tab.TextSize = 11
        tab.Position, tab.Size =
            UDim2.fromOffset(8 + (index - 1) * 77, 44), UDim2.fromOffset(73, 40)
        self.tabs[category] = tab
    end
    self.list = Gui.make("ScrollingFrame", self.panel, {
        Position = UDim2.fromOffset(8, 92),
        Size = UDim2.new(1, -16, 1, -122),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    self.saveLabel = Gui.label(self.panel, "", 11, Theme.FadedTeal)
    self.saveLabel.Position, self.saveLabel.Size =
        UDim2.new(0, 12, 1, -26), UDim2.new(1, -24, 0, 22)
    return self
end
function View:render()
    if not self.state or not self.state.quay then
        return
    end
    for _, row in self.rows do
        row:Destroy()
    end
    table.clear(self.rows)
    for category, tab in self.tabs do
        tab.BackgroundColor3 = if category == self.category then Theme.Teal else Theme.Graphite
    end
    local q = self.state.quay
    local equipped = q.rewards and q.rewards[self.category] or "none"
    local items = {
        {
            id = "none",
            label = "NO " .. (if self.category == "title"
                then "TITLE"
                elseif self.category == "badge" then "PIN"
                elseif self.category == "companion" then "CHARM"
                else "ACCENT"),
            icon = "close",
        },
    }
    for _, item in Rewards.Items[self.category] do
        table.insert(items, item)
    end
    for index, item in items do
        local unlocked = item.id == "none" or Rewards.earned(q.progress, item)
        local selected = equipped == item.id
        local row = Gui.make(
            "Frame",
            self.list,
            {
                Position = UDim2.fromOffset(0, (index - 1) * 88),
                Size = UDim2.new(1, -6, 0, 82),
                BackgroundColor3 = Theme.Graphite,
                BorderSizePixel = 0,
            }
        )
        table.insert(self.rows, row)
        Icons.make(
            row,
            item.icon,
            item.color or (if unlocked then Theme.Amber else Theme.FadedTeal),
            32
        ).Position =
            UDim2.fromOffset(10, 10)
        local label = Gui.label(row, item.label, 12, Theme.Cream)
        label.Position, label.Size = UDim2.fromOffset(52, 5), UDim2.new(1, -60, 0, 28)
        local hint = Gui.label(
            row,
            if selected then "WEARING" elseif unlocked then "READY TO EQUIP" else Rewards.hint(item),
            11,
            Theme.FadedTeal
        )
        hint.Position, hint.Size = UDim2.fromOffset(52, 35), UDim2.new(1, -152, 0, 40)
        local category = self.category
        local button = Gui.button(
            row,
            if selected then "ON" elseif unlocked then "EQUIP" else "LOCKED",
            function()
                if not unlocked or selected then
                    return
                end
                game.ReplicatedStorage.MusicNetwork.Command:FireServer(
                    "QuayEquipReward",
                    { category = category, id = item.id }
                )
            end
        )
        button.Position, button.Size = UDim2.new(1, -92, 0, 36), UDim2.fromOffset(84, 40)
        button.BackgroundColor3 = if selected
            then Theme.Teal
            elseif unlocked then Theme.Ink
            else Theme.Graphite
        button.Active = unlocked and not selected
        button.Selectable = unlocked and not selected
        button.AutoButtonColor = unlocked and not selected
    end
    for _, object in self.panel:GetDescendants() do
        if object:IsA("GuiObject") then
            object.ZIndex = 21
        end
    end
    self.list.CanvasSize = UDim2.fromOffset(0, #items * 88)
    self.saveLabel.Text = if self.state.saveMode == "session"
        then "STUDIO / SESSION ONLY"
        elseif self.state.saveMode == "unavailable" then "SAVE UNAVAILABLE"
        else "LOOK SAVES WITH YOUR PROFILE"
end
function View:accept(state)
    self.state = state
    local q = state.quay
    if not q then
        return
    end
    local parts = { state.saveMode or "", tostring(state.saving), tostring(state.dirty) }
    for _, category in Rewards.Categories do
        table.insert(parts, q.rewards and q.rewards[category] or "none")
        for _, item in Rewards.Items[category] do
            table.insert(parts, tostring(Rewards.earned(q.progress, item)))
        end
    end
    local signature = table.concat(parts, "|")
    if signature ~= self.signature then
        self.signature = signature
        self:render()
    end
end
function View:destroy()
    self.panel:Destroy()
end
return View
