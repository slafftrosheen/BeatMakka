local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Fair = require(game.ReplicatedStorage.Shared.QuayFair)
local Games = require(game.ReplicatedStorage.Shared.QuayStreetGames)
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Steps = require(script.Parent.VisualSteps)
local RewardPicture = require(script.Parent.FairRewardPicture)
local Guide = require(script.Parent.QuayFairGuide)
local View = {}
View.__index = View
local function picture(parent, name, color, size)
    local icon = Icons.make(parent, name, color, size)
    icon.ZIndex = 4
    for _, child in icon:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 4 end end
    return icon
end
function View.new(screen, send, showGames, showReward)
    local self = setmetatable({ rows = {}, awaiting = {}, intent = 0, send = send, showGames = showGames, showReward = showReward }, View)
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
    self.flow = Steps.new(self.root, { { "PLAY", "pads" }, { "GET", "bag" }, { "WEAR", "check" } }, 2)
    self.flow.root.Position, self.flow.root.Size = UDim2.fromOffset(12, 62), UDim2.new(1, -24, 0, 56)
    self.scroll = Gui.make("ScrollingFrame", self.root, {
        Position = UDim2.fromOffset(12, 124), Size = UDim2.new(1, -24, 1, -184),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    Gui.make("UIListLayout", self.scroll, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    self.receipt = Gui.round(Gui.make("Frame", self.scroll, { Name = "AcknowledgedPrize", Visible = false,
        Size = UDim2.new(1, -8, 0, 134), BackgroundColor3 = Theme.Teal, BorderSizePixel = 0, LayoutOrder = 0 }), 8)
    self.receiptTitle = Gui.label(self.receipt, "", 15, Theme.Cream)
    self.receiptTitle.Position, self.receiptTitle.Size = UDim2.fromOffset(80, 6), UDim2.new(1, -88, 0, 30)
    self.receiptAction = Gui.button(self.receipt, "WEAR", function() self:receiptChoose() end)
    self.receiptAction.Position, self.receiptAction.Size = UDim2.fromOffset(80, 36), UDim2.new(1, -88, 0, 44)
    self.receiptDone = Gui.button(self.receipt, "OK", function()
        self.receiptId, self.receipt.Visible = nil, false
        self:render()
        if Input.GamepadEnabled then GuiService.SelectedObject = self.games end
    end)
    self.receiptDone.Position, self.receiptDone.Size = UDim2.fromOffset(80, 82), UDim2.new(1, -88, 0, 44)
    for index, prize in Fair.Prizes do
        local row = Gui.make("Frame", self.scroll, { Size = UDim2.new(1, -8, 0, 104), BackgroundColor3 = Theme.Graphite, BorderSizePixel = 0, LayoutOrder = index })
        local art = RewardPicture.new(row, prize)
        art.root.Position = UDim2.fromOffset(3, 12)
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
        local outline = Gui.make("UIStroke", row, { Color = Theme.Amber, Thickness = 2, Enabled = false })
        self.rows[prize.id] = { outline = outline, action = action, tokens = tokens, cost = cost, picture = art }
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
    if self.fair.prizes[prize.id] and self.state.quay.rewards[prize.category] == prize.id then
        self.receiptId = prize.id
        self.scroll.CanvasPosition = Vector2.zero
        self:render()
        if Input.GamepadEnabled then GuiService.SelectedObject = self.receiptAction end
        return
    end
    self.intent += 1
    local waiting = self.awaiting[prize.id] or {}
    self.awaiting[prize.id] = waiting
    if self.fair.prizes[prize.id] then
        waiting.wear = self.intent
        self.pending = { id = prize.id, kind = "wear", untilAt = os.clock() + 2 }
        self.send("QuayEquipReward", { category = prize.category, id = prize.id })
        self:render()
    elseif self.fair.balance >= prize.cost then
        waiting.claim = self.intent
        self.pending = { id = prize.id, kind = "claim", untilAt = os.clock() + 2 }
        self.send("QuaySideClaim", prize.id)
        self:render()
    else
        if next(waiting) == nil then self.awaiting[prize.id] = nil end
        self:gamesRoute()
    end
end
function View:receiptChoose()
    local prize = Fair.find(self.receiptId)
    local q = self.state and self.state.quay
    if not prize or not q or self.pending then return end
    if q.rewards[prize.category] ~= prize.id then self:choose(prize)
    elseif self.showReward then self.showReward(prize) end
end
function View:accept(state)
    local was = self.root.Visible
    self.state = state
    self.root.Visible = state.quay ~= nil and state.quay.fairShop == true
    if not self.root.Visible then self.pending, self.receiptId, self.receipt.Visible, self.awaiting = nil, nil, false, {}; return end
    self.fair = state.quay.fair
    local acknowledged, latest = false, -1
    for _, prize in Fair.Prizes do
        local waiting = self.awaiting[prize.id]
        if waiting then
            for _, kind in { "claim", "wear" } do
                local serial = waiting[kind]
                local accepted = serial ~= nil and (if kind == "claim" then self.fair.prizes[prize.id] == true
                    else state.quay.rewards[prize.category] == prize.id)
                if accepted then
                    if serial > latest then self.receiptId, latest = prize.id, serial end
                    waiting[kind], acknowledged = nil, true
                    if self.pending and self.pending.id == prize.id and self.pending.kind == kind then self.pending = nil end
                end
            end
            if next(waiting) == nil then self.awaiting[prize.id] = nil end
        end
    end
    self:render()
    if acknowledged then
        self.scroll.CanvasPosition = Vector2.zero
        if Input.GamepadEnabled then GuiService.SelectedObject = self.receiptAction end
    end
    if not was then
        local prize = Guide.prize(self.fair, state.quay.rewards)
        local index = if prize then table.find(Fair.Prizes, prize) else 1
        self.scroll.CanvasPosition = Vector2.new(0, ((index or 1) - 1) * 114)
        if Input.GamepadEnabled then GuiService.SelectedObject = if prize then self.rows[prize.id].action else self.games end
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
    local suggested = Guide.prize(self.fair, q.rewards)
    local gameId = Guide.nextGame(self.fair)
    self.games.Text = if gameId then "PLAY" else "PRACTICE"
    self.games:SetAttribute("UiIcon", if gameId then Games.ById[gameId].icon else "redo")
    self.games:SetAttribute("AccessibleLabel", if gameId then "Follow the picture route to a game with coins remaining" else "All fair coins earned; play again for fun without more coins")
    self.games.BackgroundColor3 = if not suggested and not self.receiptId then Theme.Amber else Theme.Teal
    self.games.TextColor3 = if not suggested and not self.receiptId then Theme.Ink else Theme.Cream
    local anyOwned, anyAffordable, anyUnworn, allOwned = false, false, false, true
    for _, prize in Fair.Prizes do
        local row = self.rows[prize.id]
        local owned = self.fair.prizes[prize.id] == true
        local equipped = q.rewards and q.rewards[prize.category] == prize.id
        local affordable = self.fair.balance >= prize.cost
        anyUnworn = anyUnworn or (owned and not equipped)
        allOwned = allOwned and owned
        anyOwned = anyOwned or owned
        anyAffordable = anyAffordable or (not owned and affordable)
        row.picture:update(owned)
        row.outline.Enabled = suggested ~= nil and suggested.id == prize.id and not self.receiptId and not self.pending
        local waiting = self.pending ~= nil
        local enabled = not waiting
        row.action.Text = if waiting and self.pending.id == prize.id then "…"
            elseif equipped then (if prize.category == "companion" then "PEOPLE" elseif prize.category == "roamer" then "SEE" else "SHOW") elseif owned then "WEAR" elseif affordable then "GET" else "PLAY"
        row.action:SetAttribute("UiIcon", if row.outline.Enabled then "hand" elseif equipped then
            (if prize.category == "companion" then "people" elseif prize.category == "roamer" then "van" else "badge")
            elseif owned then "check" elseif affordable then "bag" else "coin")
        row.action:SetAttribute("AccessibleLabel", prize.label .. (if equipped then " / equipped / show reward destination" elseif owned then " / equip owned prize"
            elseif affordable then " / claim for " .. prize.cost .. " coins" else " / play games for " .. (prize.cost - self.fair.balance) .. " more coins"))
        row.action.Active, row.action.Interactable, row.action.Selectable = enabled, enabled, enabled
        row.action.BackgroundColor3 = if equipped then Theme.Graphite elseif affordable and not owned then Theme.Amber else Theme.Teal
        row.action.TextColor3 = if affordable and not owned then Theme.Ink else Theme.Cream
        for index, token in row.tokens do
            Icons.tint(token, if owned or self.fair.balance >= index * Fair.CoinsPerHeat then Theme.Amber else Theme.Stone)
        end
        row.cost.Text = if owned then "" else tostring(prize.cost)
    end
    self.flow:update(if allOwned and not anyUnworn then 0 elseif self.receiptId or anyUnworn then 3 elseif anyAffordable then 2 else 1,
        { self.fair.earned > 0, anyOwned, allOwned and not anyUnworn })
    local receipt = Fair.find(self.receiptId)
    self.receipt.Visible = receipt ~= nil
    if receipt then
        if self.receiptPictureId ~= receipt.id then
            if self.receiptPicture then self.receiptPicture.root:Destroy() end
            self.receiptPicture = RewardPicture.new(self.receipt, receipt)
            self.receiptPicture.root.Position = UDim2.fromOffset(8, 18)
            self.receiptPictureId = receipt.id
        end
        self.receiptPicture:update(true)
        self.receiptTitle.Text = receipt.label
        local equipped = q.rewards[receipt.category] == receipt.id
        self.receiptAction.Text = if self.pending then "…" elseif not equipped then "WEAR"
            elseif receipt.category == "roamer" then "SEE" elseif receipt.category == "companion" then "PEOPLE" else "DONE"
        self.receiptAction:SetAttribute("UiIcon", if not equipped then "check" elseif receipt.category == "roamer" then "van"
            elseif receipt.category == "companion" then "people" else "door")
        self.receiptAction.Active, self.receiptAction.Interactable, self.receiptAction.Selectable = self.pending == nil, self.pending == nil, self.pending == nil
    end
    local focused = GuiService.SelectedObject
    if Input.GamepadEnabled and focused and focused:IsDescendantOf(self.root) and not focused.Selectable then
        GuiService.SelectedObject = self.games
    end
end
function View:destroy() self.connection:Disconnect(); self.root:Destroy() end
return View
