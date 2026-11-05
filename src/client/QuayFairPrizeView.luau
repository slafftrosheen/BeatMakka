local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Fair = require(game.ReplicatedStorage.Shared.QuayFair)
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local View = {}
View.__index = View
local function picture(parent, name, color, size)
    local icon = Icons.make(parent, name, color, size)
    icon.ZIndex = 4
    for _, child in icon:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 4 end end
    return icon
end
function View.new(screen, send, showGames)
    local self = setmetatable({ rows = {}, send = send, showGames = showGames }, View)
    self.root = Gui.round(Gui.make("Frame", screen, {
        Name = "FairPrizes", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -24, 0.92, 0), BackgroundColor3 = Theme.Ink, BorderSizePixel = 0, Visible = false, ZIndex = 30,
    }), 12)
    Gui.make("UISizeConstraint", self.root, { MaxSize = Vector2.new(490, 470) })
    picture(self.root, "coin", Theme.Amber, 32).Position = UDim2.fromOffset(16, 16)
    self.balance = Gui.label(self.root, "0", 24, Theme.Amber)
    self.balance.Position, self.balance.Size = UDim2.fromOffset(58, 12), UDim2.new(1, -126, 0, 44)
    self.close = Gui.button(self.root, "", function() send("QuaySideClose") end)
    self.close.Position, self.close.Size = UDim2.new(1, -56, 0, 12), UDim2.fromOffset(44, 44)
    self.close:SetAttribute("NoActionIcon", true)
    picture(self.close, "close", Theme.Cream, 24).Position = UDim2.fromOffset(10, 10)
    self.scroll = Gui.make("ScrollingFrame", self.root, {
        Position = UDim2.fromOffset(12, 66), Size = UDim2.new(1, -24, 1, -126),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    Gui.make("UIListLayout", self.scroll, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    for index, prize in Fair.Prizes do
        local row = Gui.make("Frame", self.scroll, { Size = UDim2.new(1, -8, 0, 104), BackgroundColor3 = Theme.Graphite, BorderSizePixel = 0, LayoutOrder = index })
        local art = picture(row, if prize.id == "fair_bell" then "bell" else prize.icon, Theme.Amber, 44)
        art.Position = UDim2.fromOffset(10, 26)
        local title = Gui.label(row, prize.label, 13, Theme.Cream)
        title.Position, title.Size = UDim2.fromOffset(68, 4), UDim2.new(1, -76, 0, 24)
        local tokens = {}
        for coin = 1, prize.cost / Fair.CoinsPerHeat do
            local token = picture(row, "coin", Theme.Stone, 18)
            token.Position = UDim2.fromOffset(68 + (coin - 1) * 23, 28)
            tokens[coin] = token
        end
        local cost = Gui.label(row, tostring(prize.cost), 12, Theme.Cream)
        cost.Position, cost.Size = UDim2.fromOffset(68 + #tokens * 23, 26), UDim2.fromOffset(36, 22)
        local action = Gui.button(row, "GET", function() self:choose(prize) end)
        action.Position, action.Size = UDim2.fromOffset(68, 52), UDim2.new(1, -76, 0, 44)
        self.rows[prize.id] = { action = action, tokens = tokens, cost = cost }
    end
    self.games = Gui.button(self.root, "PLAY", function() self:gamesRoute() end)
    self.games.Position, self.games.Size = UDim2.new(0, 12, 1, -52), UDim2.fromOffset(112, 44)
    self.games:SetAttribute("UiIcon", "pads")
    self.notice = Gui.label(self.root, "", 11, Theme.Cream)
    self.notice.Position, self.notice.Size = UDim2.new(0, 136, 1, -52), UDim2.new(1, -148, 0, 44)
    local elapsed = 0
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < 0.2 or not self.root.Visible then return end
        elapsed = 0
        local character = game:GetService("Players").LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root or (root.Position - Fair.PrizePosition).Magnitude > 13 then
            self.root.Visible = false
            send("QuaySideClose")
        else self:render() end
    end)
    return self
end
function View:gamesRoute()
    if self.showGames then self.showGames() end
    self.send("QuaySideClose")
end
function View:choose(prize)
    if not self.fair or self.pending then return end
    if self.fair.prizes[prize.id] then
        self.send("QuayEquipReward", { category = prize.category, id = prize.id })
    elseif self.fair.balance >= prize.cost then
        self.pending = { id = prize.id, untilAt = os.clock() + 2 }
        self.send("QuaySideClaim", prize.id)
        self:render()
    else self:gamesRoute() end
end
function View:accept(state)
    local was = self.root.Visible
    self.state = state
    self.root.Visible = state.quay ~= nil and state.quay.fairShop == true
    if not self.root.Visible then self.pending = nil; return end
    self.fair = state.quay.fair
    if self.pending and self.fair.prizes[self.pending.id] then self.pending = nil end
    self:render()
    if not was and Input.GamepadEnabled then
        local focus = self.games
        for _, prize in Fair.Prizes do
            if self.rows[prize.id].action.Selectable then focus = self.rows[prize.id].action; break end
        end
        GuiService.SelectedObject = focus
    end
end
function View:render()
    if not self.state or not self.fair then return end
    local state, q = self.state, self.state.quay
    if self.pending and os.clock() >= self.pending.untilAt then self.pending = nil end
    self.balance.Text = tostring(self.fair.balance)
    self.balance:SetAttribute("AccessibleLabel", self.fair.balance .. " earned fair coins")
    self.notice.Text = if state.saving then "SAVING…"
        elseif state.saveMode == "unavailable" then "TEMPORARY / SAVE UNAVAILABLE"
        elseif state.saveMode == "session" then "STUDIO SESSION"
        elseif state.dirty then "UNSAVED CHANGES" else "JOURNAL KEPT"
    if state.notice then self.notice.Text = state.notice end
    for _, prize in Fair.Prizes do
        local row = self.rows[prize.id]
        local owned = self.fair.prizes[prize.id] == true
        local equipped = q.rewards and q.rewards[prize.category] == prize.id
        local affordable = self.fair.balance >= prize.cost
        local waiting = self.pending ~= nil
        local enabled = not equipped and not waiting
        row.action.Text = if waiting and self.pending.id == prize.id then "…"
            elseif equipped then "ON" elseif owned then "WEAR" elseif affordable then "GET" else "PLAY"
        row.action:SetAttribute("UiIcon", if equipped or owned then "check" elseif affordable then "bag" else "pads")
        row.action:SetAttribute("AccessibleLabel", prize.label .. (if equipped then " / equipped" elseif owned then " / equip owned prize"
            elseif affordable then " / claim for " .. prize.cost .. " coins" else " / play games for " .. (prize.cost - self.fair.balance) .. " more coins"))
        row.action.Active, row.action.Interactable, row.action.Selectable = enabled, enabled, enabled
        row.action.BackgroundColor3 = if equipped then Theme.Graphite elseif affordable and not owned then Theme.Amber else Theme.Teal
        row.action.TextColor3 = if affordable and not owned then Theme.Ink else Theme.Cream
        for index, token in row.tokens do
            Icons.tint(token, if owned or self.fair.balance >= index * Fair.CoinsPerHeat then Theme.Amber else Theme.Stone)
        end
        row.cost.Text = if owned then "" else tostring(prize.cost)
    end
    local focused = GuiService.SelectedObject
    if Input.GamepadEnabled and focused and focused:IsDescendantOf(self.root) and not focused.Selectable then
        GuiService.SelectedObject = self.games
    end
end
function View:destroy() self.connection:Disconnect(); self.root:Destroy() end
return View
