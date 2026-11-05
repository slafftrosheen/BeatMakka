local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Fair = require(game.ReplicatedStorage.Shared.QuayFair)
local View = {}
View.__index = View
function View.new(screen, send)
    local self = setmetatable({ rows = {} }, View)
    self.root = Gui.round(Gui.make("Frame", screen, {
        Name = "FairPrizes", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -24, 0.88, 0), BackgroundColor3 = Theme.Ink, BorderSizePixel = 0, Visible = false, ZIndex = 30,
    }), 12)
    Gui.make("UISizeConstraint", self.root, { MaxSize = Vector2.new(490, 430) })
    Icons.make(self.root, "disc", Theme.Amber, 32).Position = UDim2.fromOffset(16, 16)
    self.balance = Gui.label(self.root, "0", 24, Theme.Amber)
    self.balance.Position, self.balance.Size = UDim2.fromOffset(58, 12), UDim2.new(1, -126, 0, 44)
    local close = Gui.button(self.root, "", function() send("QuaySideClose") end)
    close.Position, close.Size = UDim2.new(1, -56, 0, 12), UDim2.fromOffset(44, 44)
    close:SetAttribute("NoActionIcon", true)
    Icons.make(close, "close", Theme.Cream, 24).Position = UDim2.fromOffset(10, 10)
    self.close = close
    local scroll = Gui.make("ScrollingFrame", self.root, {
        Position = UDim2.fromOffset(12, 68), Size = UDim2.new(1, -24, 1, -120),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    Gui.make("UIListLayout", scroll, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    for index, prize in Fair.Prizes do
        local row = Gui.make("Frame", scroll, { Size = UDim2.new(1, -8, 0, 76), BackgroundColor3 = Theme.Graphite, BorderSizePixel = 0, LayoutOrder = index })
        Icons.make(row, prize.icon, Theme.Amber, 36).Position = UDim2.fromOffset(10, 18)
        local title = Gui.label(row, prize.label, 13, Theme.Cream)
        title.Position, title.Size = UDim2.fromOffset(56, 6), UDim2.new(1, -66, 0, 24)
        local action = Gui.button(row, tostring(prize.cost), function()
            if self.fair and self.fair.prizes[prize.id] then
                send("QuayEquipReward", { category = prize.category, id = prize.id })
            else send("QuaySideClaim", prize.id) end
        end)
        action.Position, action.Size = UDim2.fromOffset(56, 30), UDim2.new(1, -66, 0, 44)
        self.rows[prize.id] = action
    end
    self.notice = Gui.label(self.root, "", 11, Theme.Cream)
    self.notice.Position, self.notice.Size = UDim2.new(0, 16, 1, -46), UDim2.new(1, -32, 0, 38)
    local elapsed = 0
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < 0.2 or not self.root.Visible then return end
        elapsed = 0
        local character = game:GetService("Players").LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root or (root.Position - Fair.PrizePosition).Magnitude > 15 then
            self.root.Visible = false
            send("QuaySideClose")
        end
    end)
    return self
end
function View:accept(state)
    local q = state.quay
    local was = self.root.Visible
    self.root.Visible = q and q.fairShop == true
    if not self.root.Visible then return end
    self.fair = q.fair
    self.balance.Text = tostring(self.fair.balance) .. "  /  COINS"
    self.notice.Text = if state.notice then state.notice elseif state.saving then "SAVING…"
        elseif state.saveMode == "session" then "Studio session / free games / 3 coin stamps each"
        elseif state.saveMode == "unavailable" then "Temporary progress / storage unavailable"
        else "Free games / 3 coin stamps each / prizes in Style"
    for _, prize in Fair.Prizes do
        local button = self.rows[prize.id]
        local owned = self.fair.prizes[prize.id] == true
        local equipped = q.rewards and q.rewards[prize.category] == prize.id
        local enabled = (owned and not equipped) or (not owned and self.fair.balance >= prize.cost)
        button.Text = if equipped then "✓" elseif owned then "WEAR" else tostring(prize.cost) .. "  COINS"
        button:SetAttribute("UiIcon", if owned then "check" else "disc")
        button:SetAttribute("AccessibleLabel", prize.label .. (if owned then " / owned" else " / " .. prize.cost .. " coins"))
        button.Active, button.Interactable, button.Selectable = enabled, enabled, enabled
        button.BackgroundColor3 = if enabled then Theme.Teal else Theme.Graphite
    end
    if not was and game:GetService("UserInputService").GamepadEnabled then
        game:GetService("GuiService").SelectedObject = self.close
    end
end
function View:destroy() self.connection:Disconnect(); self.root:Destroy() end
return View
